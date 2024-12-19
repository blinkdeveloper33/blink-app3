import 'package:flutter/foundation.dart';
import 'package:blink_app/services/auth_service.dart';

enum DataState { initial, loading, loaded, error }

class FinancialDataProvider with ChangeNotifier {
  final AuthService _authService;
  Map<String, dynamic>? _categoryAnalysis;
  Map<String, dynamic>? _cashFlowAnalysis;
  DataState _cashFlowState = DataState.initial;
  DataState _expenseState = DataState.initial;
  String? _cashFlowError;
  String? _expenseError;

  FinancialDataProvider(this._authService);

  Map<String, dynamic>? get categoryAnalysis => _categoryAnalysis;
  Map<String, dynamic>? get cashFlowAnalysis => _cashFlowAnalysis;
  DataState get cashFlowState => _cashFlowState;
  DataState get expenseState => _expenseState;
  String? get cashFlowError => _cashFlowError;
  String? get expenseError => _expenseError;

  Future<void> loadCashFlowData(String timeFrame) async {
    _cashFlowState = DataState.loading;
    notifyListeners();

    try {
      final response = await _authService.getCashFlowAnalysis(timeFrame);
      if (response['success']) {
        _cashFlowAnalysis = response['data'];
        _cashFlowState = DataState.loaded;
      } else {
        _cashFlowError = 'Failed to load cash flow data';
        _cashFlowState = DataState.error;
      }
    } catch (e) {
      _cashFlowError = e.toString();
      _cashFlowState = DataState.error;
    }

    notifyListeners();
  }

  Future<void> loadExpenseData(String timeFrame) async {
    _expenseState = DataState.loading;
    notifyListeners();

    try {
      final response = await _authService.getCategoryAnalysis(timeFrame);
      if (response['success']) {
        _categoryAnalysis = response['data'];
        _expenseState = DataState.loaded;
      } else {
        _expenseError = 'Failed to load expense data';
        _expenseState = DataState.error;
      }
    } catch (e) {
      _expenseError = e.toString();
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
