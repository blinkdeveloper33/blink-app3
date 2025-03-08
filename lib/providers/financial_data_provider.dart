import 'package:flutter/foundation.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/features/insights/domain/cash_flow_data.dart';
import 'package:logger/logger.dart';

enum DataState { initial, loading, loaded, error }

class FinancialDataProvider with ChangeNotifier {
  final AuthService _authService;
  final _logger = Logger();
  Map<String, dynamic>? _categoryAnalysis;
  CashFlowData? _cashFlowData;
  DataState _cashFlowState = DataState.initial;
  DataState _expenseState = DataState.initial;
  String? _cashFlowError;
  String? _expenseError;

  FinancialDataProvider(this._authService);

  Map<String, dynamic>? get categoryAnalysis => _categoryAnalysis;
  CashFlowData? get cashFlowData => _cashFlowData;
  DataState get cashFlowState => _cashFlowState;
  DataState get expenseState => _expenseState;
  String? get cashFlowError => _cashFlowError;
  String? get expenseError => _expenseError;

  Future<void> loadCashFlowData(String timeFrame) async {
    _cashFlowState = DataState.loading;
    _cashFlowData = null;
    _cashFlowError = null;
    notifyListeners();

    try {
      final response =
          await _authService.getCashFlowAnalysis(timeFrame: timeFrame);
      _logger.d('Cash flow API response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          final data = response['data'] as Map<String, dynamic>;
          _logger.d('Parsing cash flow data: $data');

          // Validate required fields
          if (!data.containsKey('segments')) {
            throw FormatException('Missing segments in response');
          }

          if (!(data['segments'] is List)) {
            throw FormatException('Segments must be a list');
          }

          final segments = data['segments'] as List;
          _logger.d('Segments data: $segments');

          // Validate first segment format if available
          if (segments.isNotEmpty) {
            final firstSegment = segments.first;
            _logger.d('First segment format: $firstSegment');

            // Check first segment has required fields
            if (firstSegment is! Map<String, dynamic> ||
                !firstSegment.containsKey('period') ||
                !firstSegment.containsKey('inflow') ||
                !firstSegment.containsKey('outflow')) {
              _logger.e('Invalid segment format: $firstSegment');
              throw FormatException(
                  'Invalid segment format. Required fields: period, inflow, outflow');
            }
          }

          // Log detailed analysis data if present
          if (data.containsKey('detailedAnalysis')) {
            _logger.d('Detailed analysis data present in the response');
            final detailedAnalysis =
                data['detailedAnalysis'] as Map<String, dynamic>?;
            if (detailedAnalysis != null) {
              _logger.d(
                  'Detailed analysis keys: ${detailedAnalysis.keys.join(', ')}');

              // Check for specific breakdown types based on timeFrame
              final String breakdownType;
              switch (timeFrame.toUpperCase()) {
                case 'LAST_WEEK':
                  breakdownType = 'daily_breakdown';
                  break;
                case 'LAST_MONTH':
                  breakdownType = 'weekly_breakdown';
                  break;
                case 'LAST_QUARTER':
                case 'LAST_YEAR':
                  breakdownType = 'monthly_breakdown';
                  break;
                default:
                  breakdownType = '';
              }

              if (breakdownType.isNotEmpty &&
                  detailedAnalysis.containsKey(breakdownType)) {
                final breakdown = detailedAnalysis[breakdownType];
                if (breakdown is List && breakdown.isNotEmpty) {
                  _logger
                      .d('$breakdownType contains ${breakdown.length} items');
                  _logger.d('First item in $breakdownType: ${breakdown.first}');
                }
              }
            }
          }

          _cashFlowData = CashFlowData.fromJson(data);
          _cashFlowState = DataState.loaded;

          // Log parsed data
          _logger.d('Successfully parsed cash flow data: $_cashFlowData');
          _logger.d('Number of trends: ${_cashFlowData?.trends.length}');
          _logger.d('Growth rate: ${_cashFlowData?.growthRate}');
          _logger.d(
              'Detailed analysis available: ${_cashFlowData?.detailedAnalysis != null}');
        } catch (e, stackTrace) {
          _logger.e(
              'Error parsing cash flow data\nError: $e\nStack trace: $stackTrace');
          _cashFlowError = 'Invalid data format received from server: $e';
          _cashFlowState = DataState.error;
        }
      } else {
        _cashFlowError = response['message'] ?? 'Failed to load cash flow data';
        if (response['error'] != null) {
          _logger.e('Server error details: ${response['error']}');

          // Extract more informative error messages if possible
          final error = response['error']?.toString() ?? '';
          if (error.contains('current_period')) {
            _cashFlowError = 'API format has changed. Please contact support.';
          } else if (error.contains('invalid_enum_value')) {
            _cashFlowError = 'Invalid time period selected.';
          }
        }
        _cashFlowState = DataState.error;
      }
    } catch (e, stackTrace) {
      _logger.e(
          'Error loading cash flow data\nError: $e\nStack trace: $stackTrace');
      _cashFlowError = 'Failed to load cash flow data: ${e.toString()}';
      _cashFlowState = DataState.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadExpenseData(String timeFrame) async {
    _expenseState = DataState.loading;
    _categoryAnalysis = null;
    _expenseError = null;
    notifyListeners();

    try {
      final response =
          await _authService.getSpendingAnalysis(timeFrame: timeFrame);

      _logger.d('Raw expense API response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        // Log the raw data structure for debugging
        _logger.d('Raw expense data: $data');

        // Validate that categories field exists
        if (!data.containsKey('categories')) {
          _expenseError = 'Invalid data format: missing categories field';
          _expenseState = DataState.error;
          notifyListeners();
          return;
        }

        // Map categories from new API format to the expected format
        final categoriesData = data['categories'] as List<dynamic>;
        final mappedCategories = categoriesData.map((category) {
          // Make sure it has name instead of category field for backward compatibility
          return {
            'name': category['category'],
            'amount': category['amount'],
            'percentage': category['percentage'],
            'transactionCount': 1, // Default value if not provided
          };
        }).toList();

        // Add timeFrame to the data for UI reference
        data['timeFrame'] = timeFrame;

        // Format the data for the UI
        _categoryAnalysis = {
          'data': {
            'categories': mappedCategories, // Use mapped categories
            'totalSpending': data['totalSpending'],
            'timeFrame': timeFrame,
            'period': {
              'startDate': data['startDate'],
              'endDate': data['endDate'],
              'label': data['timeFrameLabel'] ?? _getTimeFrameLabel(timeFrame),
            },
          }
        };

        _logger.d('Formatted category analysis data: $_categoryAnalysis');

        _expenseState = DataState.loaded;
      } else {
        final errorMessage =
            response['message'] ?? 'Failed to load expense data';
        final errorResponse = response['error']?.toString() ?? '';

        if (errorResponse.contains('Invalid timeFrame')) {
          _expenseError = 'Invalid time period selected';
        } else if (errorResponse.contains('Unauthorized')) {
          _expenseError = 'Please log in again to view your expense data';
        } else {
          _expenseError = errorMessage;
        }
        _expenseState = DataState.error;
      }
    } catch (e) {
      _logger.e('Error in loadExpenseData: $e');
      if (e is ApiException) {
        _expenseError = e.message;
      } else {
        _expenseError =
            'An unexpected error occurred while loading expense data';
      }
      _expenseState = DataState.error;
    }

    notifyListeners();
  }

  String _getTimeFrameLabel(String timeFrame) {
    switch (timeFrame) {
      case 'LAST_WEEK':
        return 'Last 7 Days';
      case 'LAST_MONTH':
        return 'Last 4 Weeks';
      case 'LAST_QUARTER':
        return 'Last 3 Months';
      case 'LAST_YEAR':
        return 'Last 12 Months';
      default:
        return 'Current Period';
    }
  }

  Future<void> loadFinancialData(
      String cashFlowTimeFrame, String expenseTimeFrame) async {
    await Future.wait([
      loadCashFlowData(cashFlowTimeFrame),
      loadExpenseData(expenseTimeFrame),
    ]);
  }
}
