import 'package:flutter/foundation.dart';
import 'package:blink_app/services/auth_service.dart';

enum DataState { initial, loading, loaded, error }

class FinancialDataProvider with ChangeNotifier {
  final AuthService _authService;
  Map<String, dynamic>? _categoryAnalysis;
  Map<String, dynamic>? _cashFlowAnalysis;
  DataState _state = DataState.initial;
  String? _error;

  FinancialDataProvider(this._authService);

  Map<String, dynamic>? get categoryAnalysis => _categoryAnalysis;
  Map<String, dynamic>? get cashFlowAnalysis => _cashFlowAnalysis;
  DataState get state => _state;
  String? get error => _error;

  Future<void> loadFinancialData(String timeFrame) async {
    _state = DataState.loading;
    notifyListeners();

    try {
      final categoryResponse =
          await _authService.getCategoryAnalysis(timeFrame);
      final cashFlowResponse =
          await _authService.getCashFlowAnalysis(timeFrame);

      if (categoryResponse['success'] && cashFlowResponse['success']) {
        _categoryAnalysis = categoryResponse['data'];
        _cashFlowAnalysis = cashFlowResponse['data'];
        _state = DataState.loaded;
      } else {
        _error = 'Failed to load financial data';
        _state = DataState.error;
      }
    } catch (e) {
      _error = e.toString();
      _state = DataState.error;
    }

    notifyListeners();
  }

  Future<void> refreshFinancialData(String timeFrame) async {
    await loadFinancialData(timeFrame);
  }
}
