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

      final data = await _authService.getRecurringExpenses(_timeFrame);
      _recurringExpensesData = RecurringExpensesData.fromJson(data);
      _error = null;
    } catch (e) {
      _logger.e('Error loading recurring expenses: $e');
      _error = 'Failed to load recurring expenses';
      _recurringExpensesData = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTimeFrame(String timeFrame) {
    if (_timeFrame != timeFrame) {
      _timeFrame = timeFrame;
      loadRecurringExpenses();
    }
  }
}
