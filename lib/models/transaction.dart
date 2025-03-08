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
    // Handle category which can be a String or a List<dynamic>
    String category;
    if (json['category'] is String) {
      category = json['category'] ?? 'Uncategorized';
    } else if (json['category'] is List &&
        (json['category'] as List).isNotEmpty) {
      // Join all categories or just use the first one
      category = (json['category'] as List).join(', ');
    } else {
      category = 'Uncategorized';
    }

    return Transaction(
      id: json['id'] ?? Uuid().v4(),
      bankAccountId: json['bank_account_id'],
      transactionId: json['transaction_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      originalDescription: json['original_description'],
      category: category,
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

class TransactionDetail extends Transaction {
  final String? originalDescription;
  final String? categoryDetailed;
  final bool pending;
  final AccountDetails accountDetails;

  TransactionDetail({
    required String id,
    required String bankAccountId,
    required String transactionId,
    required double amount,
    required DateTime date,
    required String description,
    required String category,
    required String accountId,
    this.originalDescription,
    this.categoryDetailed,
    String? merchantName,
    this.pending = false,
    required this.accountDetails,
    required DateTime createdAt,
    String? userId,
  }) : super(
          id: id,
          bankAccountId: bankAccountId,
          transactionId: transactionId,
          amount: amount,
          date: date,
          description: description,
          category: category,
          merchantName: merchantName,
          pending: pending,
          createdAt: createdAt,
          accountId: accountId,
          userId: userId,
        );

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    // Handle category which can be a String or a List<dynamic>
    String category;
    if (json['category'] is String) {
      category = json['category'] ?? 'Uncategorized';
    } else if (json['category'] is List &&
        (json['category'] as List).isNotEmpty) {
      // Join all categories or just use the first one
      category = (json['category'] as List).join(', ');
    } else {
      category = 'Uncategorized';
    }

    return TransactionDetail(
      id: json['id'],
      bankAccountId: json['bank_account_id'],
      transactionId: json['transaction_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      description: json['description'],
      originalDescription: json['original_description'],
      category: category,
      categoryDetailed: json['category_detailed'],
      merchantName: json['merchant_name'],
      pending: json['pending'] ?? false,
      accountDetails: AccountDetails.fromJson(json['account_details']),
      createdAt: DateTime.parse(json['created_at']),
      accountId: json['account_id'],
      userId: json['user_id'],
    );
  }
}

class AccountDetails {
  final String name;
  final String type;
  final String institution;

  AccountDetails({
    required this.name,
    required this.type,
    required this.institution,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      name: json['name'],
      type: json['type'],
      institution: json['institution'],
    );
  }
}
