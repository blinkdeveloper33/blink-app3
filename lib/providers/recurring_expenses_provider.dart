import 'package:flutter/material.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/features/insights/domain/recurring_expense.dart';
import 'package:logger/logger.dart';

class RecurringExpensesProvider extends ChangeNotifier {
  final AuthService _authService;
  final _logger = Logger();

  RecurringExpensesData? _recurringExpensesData;
  bool _isLoading = false;
  String? _error;
  String _timeFrame = 'LAST_MONTH';

  RecurringExpensesProvider(this._authService);

  RecurringExpensesData? get recurringExpensesData => _recurringExpensesData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get timeFrame => _timeFrame;

  Future<void> loadRecurringExpenses({String? timeFrame}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (timeFrame != null) {
        _timeFrame = timeFrame;
      }

      final response = await _authService.getRecurringExpensesAnalysis(
          timeFrame: _timeFrame);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        _logger.d('Received recurring expenses data: $data');

        // Group expenses by frequency
        final List<dynamic> allExpenses = data['recurring_expenses'] ?? [];
        final Map<String, List<dynamic>> expensesByFrequency = {
          'weekly': [],
          'biWeekly': [],
          'monthly': [],
          'quarterly': [],
          'annual': [],
        };

        // Calculate totals by frequency
        final Map<String, double> totalsByFrequency = {
          'weekly': 0.0,
          'biWeekly': 0.0,
          'monthly': 0.0,
          'quarterly': 0.0,
          'annual': 0.0,
        };

        // Process and group recurring expenses by frequency
        for (final expense in allExpenses) {
          final String frequency =
              (expense['frequency'] as String).toLowerCase();

          // Map API frequency to our model's frequency groups
          String mappedFrequency;
          if (frequency.contains('weekly') || frequency == 'weekly') {
            mappedFrequency = 'weekly';
          } else if (frequency.contains('biweekly') ||
              frequency == 'biweekly') {
            mappedFrequency = 'biWeekly';
          } else if (frequency.contains('monthly') || frequency == 'monthly') {
            mappedFrequency = 'monthly';
          } else if (frequency.contains('quarterly') ||
              frequency == 'quarterly') {
            mappedFrequency = 'quarterly';
          } else if (frequency.contains('annual') ||
              frequency.contains('yearly') ||
              frequency == 'annually') {
            mappedFrequency = 'annual';
          } else if (frequency.contains('bimonthly')) {
            // Handle bimonthly as every two months - closer to quarterly
            mappedFrequency = 'quarterly';
          } else {
            // Default to monthly for unknown frequencies
            mappedFrequency = 'monthly';
          }

          // Add expense to the appropriate frequency group
          expensesByFrequency[mappedFrequency]?.add(expense);

          // Add amount to the corresponding frequency total
          final double amount = expense['avg_amount'] is num
              ? (expense['avg_amount'] as num).toDouble()
              : 0.0;

          totalsByFrequency[mappedFrequency] =
              (totalsByFrequency[mappedFrequency] ?? 0.0) + amount;
        }

        // Prepare upcoming expenses (take top 5 from all expenses sorted by next payment date)
        final upcomingExpenses = [...allExpenses];
        upcomingExpenses.sort((a, b) {
          final String dateA = a['estimated_next_payment'] as String? ?? '';
          final String dateB = b['estimated_next_payment'] as String? ?? '';
          return dateA.compareTo(dateB);
        });

        final topUpcomingExpenses = upcomingExpenses.take(5).toList();

        // Convert the response data to the correct format for RecurringExpensesData
        final Map<String, dynamic> formattedData = {
          'timeFrame': _timeFrame,
          'period': {
            'start': data['startDate'] ??
                DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
            'end': data['endDate'] ?? DateTime.now().toIso8601String(),
          },
          'summary': {
            'totalRecurringExpenses': data['recurring_expenses_count'] ?? 0,
            'totalMonthlyCommitment': data['total_recurring_amount'] ?? 0.0,
            'unusualChanges': 0, // This value isn't provided by API
          },
          'frequencyGroups': {
            'weekly':
                _formatExpensesForModel(expensesByFrequency['weekly'] ?? []),
            'biWeekly':
                _formatExpensesForModel(expensesByFrequency['biWeekly'] ?? []),
            'monthly':
                _formatExpensesForModel(expensesByFrequency['monthly'] ?? []),
            'quarterly':
                _formatExpensesForModel(expensesByFrequency['quarterly'] ?? []),
            'annual':
                _formatExpensesForModel(expensesByFrequency['annual'] ?? []),
          },
          'totals': {
            'weekly': totalsByFrequency['weekly'] ?? 0.0,
            'biWeekly': totalsByFrequency['biWeekly'] ?? 0.0,
            'monthly': totalsByFrequency['monthly'] ?? 0.0,
            'quarterly': totalsByFrequency['quarterly'] ?? 0.0,
            'annual': totalsByFrequency['annual'] ?? 0.0,
          },
          'upcomingExpenses': _formatExpensesForModel(topUpcomingExpenses),
        };

        _logger.d('Formatted data for model: $formattedData');

        _recurringExpensesData = RecurringExpensesData.fromJson(formattedData);
        _error = null;
      } else {
        _error =
            response['message'] ?? 'Failed to load recurring expenses data';
        _recurringExpensesData = null;
      }
    } catch (e) {
      _logger.e('Error loading recurring expenses: $e');
      _error = 'Failed to load recurring expenses';
      _recurringExpensesData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to format expenses from API to our model format
  List<Map<String, dynamic>> _formatExpensesForModel(List<dynamic> expenses) {
    return expenses.map((expense) {
      // Parse dates
      DateTime lastDate;
      DateTime nextExpectedDate;
      try {
        lastDate = DateTime.parse(
            expense['last_payment_date'] ?? DateTime.now().toIso8601String());

        // Handle the next payment date which might be a string date or just a formatted string
        if (expense['estimated_next_payment'] != null) {
          if (expense['estimated_next_payment'] is String &&
              expense['estimated_next_payment'].contains('T')) {
            nextExpectedDate =
                DateTime.parse(expense['estimated_next_payment']);
          } else {
            // Try to parse in MM/DD/YYYY format
            final parts = (expense['formatted_next_payment'] ?? '').split('/');
            if (parts.length == 3) {
              nextExpectedDate = DateTime(int.parse(parts[2]),
                  int.parse(parts[0]), int.parse(parts[1]));
            } else {
              nextExpectedDate = DateTime.now().add(const Duration(days: 30));
            }
          }
        } else {
          nextExpectedDate = DateTime.now().add(const Duration(days: 30));
        }
      } catch (e) {
        _logger.e('Error parsing dates: $e');
        lastDate = DateTime.now();
        nextExpectedDate = DateTime.now().add(const Duration(days: 30));
      }

      return {
        'merchant': expense['merchant'] ?? 'Unknown',
        'frequency': expense['frequency'] ?? 'Monthly',
        'averageAmount': expense['avg_amount'] ?? 0.0,
        'recentAmount': expense['avg_amount'] ?? 0.0,
        'hasUnusualChange': false,
        'amountChangePercent': 0.0,
        'lastDate': lastDate.toIso8601String(),
        'nextExpectedDate': nextExpectedDate.toIso8601String(),
        'transactionCount': expense['transaction_count'] ?? 1,
        'category': expense['primary_category'] ?? 'Uncategorized',
        'confidence': expense['confidence'] ?? 50,
        'transactions': _createSampleTransactions(expense),
      };
    }).toList();
  }

  // Create sample transactions from the expense data
  List<Map<String, dynamic>> _createSampleTransactions(dynamic expense) {
    final sampleTransaction = {
      'date': expense['last_payment_date'] ?? DateTime.now().toIso8601String(),
      'amount': expense['avg_amount'] ?? 0.0,
      'description': expense['merchant'] ?? 'Transaction',
    };

    return [sampleTransaction];
  }

  void setTimeFrame(String timeFrame) {
    if (_timeFrame != timeFrame) {
      _timeFrame = timeFrame;
      loadRecurringExpenses();
    }
  }
}
