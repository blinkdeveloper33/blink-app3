import 'package:flutter/foundation.dart';
import 'package:blink_app/models/transaction.dart';
import 'package:blink_app/services/api_service.dart';
import 'package:blink_app/services/storage_service.dart';

enum DataState { initial, loading, loaded, error }

class FinancialDataProvider with ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  List<Transaction> _transactions = [];
  DataState _state = DataState.initial;
  String? _error;

  FinancialDataProvider(this._apiService, this._storageService);

  List<Transaction> get transactions => _transactions;
  DataState get state => _state;
  String? get error => _error;

  Future<void> loadTransactions() async {
    _state = DataState.loading;
    notifyListeners();

    try {
      if (_storageService.isDataStale()) {
        await _fetchAndStoreTransactions();
      } else {
        final storedTransactions = _storageService.getStoredTransactions();
        if (storedTransactions != null && storedTransactions.isNotEmpty) {
          _transactions = storedTransactions;
          _state = DataState.loaded;
        } else {
          await _fetchAndStoreTransactions();
        }
      }
    } catch (e) {
      _error = e.toString();
      _state = DataState.error;
    }

    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    await _fetchAndStoreTransactions();
    notifyListeners();
  }

  Future<void> _fetchAndStoreTransactions() async {
    try {
      final fetchedTransactions = await _apiService.fetchAllTransactions();
      await _storageService.storeTransactions(fetchedTransactions);
      _transactions = fetchedTransactions;
      _state = DataState.loaded;
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch transactions: ${e.toString()}';
      _state = DataState.error;
    }
  }

  // Add more methods here for specific data operations or calculations
  // For example:
  double getTotalBalance() {
    return _transactions.fold(
        0, (sum, transaction) => sum + transaction.amount);
  }

  List<Transaction> getRecentTransactions({int count = 5}) {
    final sortedTransactions = List<Transaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedTransactions.take(count).toList();
  }

  Map<String, double> getCategoryTotals() {
    final categoryTotals = <String, double>{};
    for (var transaction in _transactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return categoryTotals;
  }

  getTotalOutflow() {}

  getTotalInflow() {}
}
