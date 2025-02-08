import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String? merchantName;
  final double amount;
  final DateTime date;
  final String? category;
  final bool isOutflow;
  final String? status;
  final String? description;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    this.merchantName,
    required this.amount,
    required this.date,
    this.category,
    required this.isOutflow,
    this.status,
    this.description,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String?,
      isOutflow: json['is_outflow'] as bool,
      status: json['status'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'is_outflow': isOutflow,
      'status': status,
      'description': description,
      'metadata': metadata,
    };
  }

  Transaction copyWith({
    String? id,
    String? merchantName,
    double? amount,
    DateTime? date,
    String? category,
    bool? isOutflow,
    String? status,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isOutflow: isOutflow ?? this.isOutflow,
      status: status ?? this.status,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  String get displayCategory => category ?? 'Uncategorized';
  String get displayStatus => status ?? 'Completed';
  String get displayMerchant => merchantName ?? 'Unknown Merchant';

  Color getCategoryColor(bool isDarkMode) {
    switch (category?.toLowerCase()) {
      case 'groceries':
        return Colors.green;
      case 'transportation':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'dining':
        return Colors.orange;
      case 'utilities':
        return Colors.red;
      default:
        return isDarkMode ? Colors.white70 : Colors.grey;
    }
  }

  IconData getCategoryIcon() {
    switch (category?.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'dining':
        return Icons.restaurant;
      case 'utilities':
        return Icons.power;
      default:
        return Icons.category_outlined;
    }
  }
}
