import 'package:blink_app/features/transactions/domain/models/transaction.dart';
import 'package:blink_app/services/auth_service.dart' as auth;

/// Utility class to convert between different Transaction implementations
class TransactionConverter {
  /// Converts an auth service Transaction to a feature domain Transaction
  static Transaction convertToFeatureTransaction(
      auth.Transaction authTransaction) {
    return Transaction(
      id: authTransaction.id,
      merchantName: authTransaction.merchantName,
      amount: authTransaction.amount,
      date: authTransaction.date,
      category: authTransaction.category,
      isOutflow: authTransaction.isOutflow,
      // Map other fields as needed
      status: null, // Set appropriate default or map from auth transaction
      description: null, // Set appropriate default or map from auth transaction
      metadata: null, // Set appropriate default or map from auth transaction
    );
  }
}
