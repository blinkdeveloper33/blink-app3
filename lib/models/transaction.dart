import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String bankAccountId;
  final String transactionId;
  final double amount;
  final DateTime date;
  final String description;
  final String? originalDescription;
  final String category;
  final String? categoryDetailed;
  final String? merchantName;
  final bool pending;
  final DateTime createdAt;
  final String accountId;
  final String? userId;

  Transaction({
    required this.id,
    required this.bankAccountId,
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.description,
    this.originalDescription,
    required this.category,
    this.categoryDetailed,
    this.merchantName,
    required this.pending,
    required this.createdAt,
    required this.accountId,
    this.userId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? Uuid().v4(),
      bankAccountId: json['bank_account_id'],
      transactionId: json['transaction_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      originalDescription: json['original_description'],
      category: json['category'] ?? 'Uncategorized',
      categoryDetailed: json['category_detailed'],
      merchantName: json['merchant_name'],
      pending: json['pending'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      accountId: json['account_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bank_account_id': bankAccountId,
      'transaction_id': transactionId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'original_description': originalDescription,
      'category': category,
      'category_detailed': categoryDetailed,
      'merchant_name': merchantName,
      'pending': pending,
      'created_at': createdAt.toIso8601String(),
      'account_id': accountId,
      'user_id': userId,
    };
  }
}
