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
    // Handle category which can be a String or a List<dynamic>
    String? category;
    if (json['category'] is String) {
      category = json['category'] as String?;
    } else if (json['category'] is List &&
        (json['category'] as List).isNotEmpty) {
      // Join all categories or just use the first one
      category = (json['category'] as List).join(', ');
    }

    return Transaction(
      id: json['id'] as String,
      merchantName: json['merchant_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: category,
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

  String get displayCategory {
    if (category == null) return 'Uncategorized';

    // Get the last part after the last comma (the most specific subcategory)
    if (category!.contains(',')) {
      String lastPart = category!.split(',').last.trim();

      // Special case for airlines
      if (lastPart.toLowerCase() == 'airlines and aviation services') {
        return 'Airlines';
      }

      return lastPart;
    }

    // If no comma, return the whole category (it's already specific enough)
    return category!;
  }

  String get displayStatus => status ?? 'Completed';
  String get displayMerchant => merchantName ?? 'Unknown Merchant';

  Color getCategoryColor(bool isDarkMode) {
    String categoryToUse = category?.toLowerCase() ?? '';
    if (categoryToUse.contains(',')) {
      categoryToUse = categoryToUse.split(',').last.trim();
    }

    // Special case for airlines
    if (categoryToUse == 'airlines and aviation services') {
      categoryToUse = 'airlines';
    }

    switch (categoryToUse) {
      case 'groceries':
        return Colors.green;
      case 'restaurants':
        return Colors.orange;
      case 'fast food':
        return Colors.orange.shade700;
      case 'coffee shop':
        return Colors.brown;
      case 'transportation':
        return Colors.blue;
      case 'taxi':
        return Colors.amber;
      case 'entertainment':
        return Colors.purple;
      case 'airlines':
        return Colors.lightBlue;
      case 'dining':
        return Colors.deepOrange;
      case 'utilities':
        return Colors.red;
      default:
        return isDarkMode ? Colors.white70 : Colors.grey;
    }
  }

  IconData getCategoryIcon() {
    String categoryToUse = category?.toLowerCase() ?? '';
    if (categoryToUse.contains(',')) {
      categoryToUse = categoryToUse.split(',').last.trim();
    }

    // Special case for airlines
    if (categoryToUse == 'airlines and aviation services') {
      categoryToUse = 'airlines';
    }

    switch (categoryToUse) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'restaurants':
        return Icons.restaurant;
      case 'fast food':
        return Icons.fastfood;
      case 'coffee shop':
        return Icons.coffee;
      case 'transportation':
        return Icons.directions_car;
      case 'taxi':
        return Icons.local_taxi;
      case 'entertainment':
        return Icons.movie;
      case 'airlines':
        return Icons.flight;
      case 'dining':
        return Icons.restaurant_menu;
      case 'utilities':
        return Icons.power;
      default:
        return Icons.category_outlined;
    }
  }
}
