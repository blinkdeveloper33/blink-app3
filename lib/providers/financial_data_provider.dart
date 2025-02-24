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
      final response = await _authService.getCashFlowAnalysis(timeFrame);
      _logger.d('Cash flow API response: $response');

      if (response['success'] == true && response['data'] != null) {
        try {
          final data = response['data'] as Map<String, dynamic>;
          _logger.d('Parsing cash flow data: $data');

          // Validate required fields
          if (data['segments'] == null) {
            throw FormatException('Missing segments in response');
          }
          if (!(data['segments'] is List)) {
            throw FormatException('Segments must be a list');
          }

          // Log segments data
          final segments = data['segments'] as List;
          _logger.d('Segments data: $segments');

          // Validate first segment format if available
          if (segments.isNotEmpty) {
            final firstSegment = segments.first;
            _logger.d('First segment format: $firstSegment');
          }

          _cashFlowData = CashFlowData.fromJson(data);
          _cashFlowState = DataState.loaded;

          // Log parsed data
          _logger.d('Successfully parsed cash flow data: $_cashFlowData');
          _logger.d('Number of trends: ${_cashFlowData?.trends.length}');
        } catch (e, stackTrace) {
          _logger.e(
              'Error parsing cash flow data\nError: $e\nStack trace: $stackTrace');
          _cashFlowError = 'Invalid data format received from server: $e';
          _cashFlowState = DataState.error;
        }
      } else {
        _cashFlowError = response['message'] ?? 'Failed to load cash flow data';
        _cashFlowState = DataState.error;
      }
    } catch (e, stackTrace) {
      _logger.e(
          'Error loading cash flow data\nError: $e\nStack trace: $stackTrace');
      _cashFlowError =
          'An unexpected error occurred while loading cash flow data';
      _cashFlowState = DataState.error;
    }

    notifyListeners();
  }

  Future<void> loadExpenseData(String timeFrame) async {
    _expenseState = DataState.loading;
    _categoryAnalysis = null;
    _expenseError = null;
    notifyListeners();

    try {
      final response = await _authService.getSpendingAnalysis(timeFrame);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;

        _categoryAnalysis = response;
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

  Future<void> loadFinancialData(
      String cashFlowTimeFrame, String expenseTimeFrame) async {
    await Future.wait([
      loadCashFlowData(cashFlowTimeFrame),
      loadExpenseData(expenseTimeFrame),
    ]);
  }
}
