import 'package:flutter/material.dart';

class TransactionCategory {
  final String id;
  final String name;
  final Color color;
  final IconData icon;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
  });

  TransactionCategory copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'icon': icon.codePoint,
    };
  }

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    );
  }

  static List<TransactionCategory> defaultCategories = [
    TransactionCategory(
      id: 'shopping',
      name: 'Shopping',
      color: Colors.blue,
      icon: Icons.shopping_bag,
    ),
    TransactionCategory(
      id: 'food',
      name: 'Food & Drinks',
      color: Colors.orange,
      icon: Icons.restaurant,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Transport',
      color: Colors.green,
      icon: Icons.directions_car,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Entertainment',
      color: Colors.purple,
      icon: Icons.movie,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Bills',
      color: Colors.red,
      icon: Icons.receipt_long,
    ),
    TransactionCategory(
      id: 'health',
      name: 'Health',
      color: Colors.teal,
      icon: Icons.medical_services,
    ),
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionCategory &&
        other.id == id &&
        other.name == name &&
        other.color.value == color.value &&
        other.icon.codePoint == icon.codePoint;
  }

  @override
  int get hashCode => Object.hash(id, name, color.value, icon.codePoint);
}
