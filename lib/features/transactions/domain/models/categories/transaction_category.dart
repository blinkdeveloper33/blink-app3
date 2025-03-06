import 'package:flutter/material.dart';

/// Represents the level in the category hierarchy
enum CategoryLevel {
  main,
  sub,
  specific,
}

/// Represents the type of category for better organization
enum CategoryType {
  essential,
  lifestyle,
  transportation,
  financial,
  income,
  education,
  other,
}

/// Represents a transaction category in the system
class TransactionCategory {
  final String id;
  final String name;
  final String? parentId;
  final CategoryLevel level;
  final CategoryType type;
  final Color color;
  final IconData icon;
  final List<String> aliases;
  final bool isCustom;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final String? description;

  const TransactionCategory({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    required this.type,
    required this.color,
    required this.icon,
    this.aliases = const [],
    this.isCustom = false,
    required this.createdAt,
    this.lastUsed,
    this.description,
  });

  /// Creates a copy of this category with the given fields replaced with the new values
  TransactionCategory copyWith({
    String? id,
    String? name,
    String? Function()? parentId,
    CategoryLevel? level,
    CategoryType? type,
    Color? color,
    IconData? icon,
    List<String>? aliases,
    bool? isCustom,
    DateTime? createdAt,
    DateTime? Function()? lastUsed,
    String? Function()? description,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId != null ? parentId() : this.parentId,
      level: level ?? this.level,
      type: type ?? this.type,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      aliases: aliases ?? this.aliases,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed != null ? lastUsed() : this.lastUsed,
      description: description != null ? description() : this.description,
    );
  }

  /// Converts the category to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'level': level.toString(),
      'type': type.toString(),
      'color': color.value,
      'icon': icon.codePoint,
      'aliases': aliases,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'description': description,
    };
  }

  /// Creates a category from a JSON map
  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      level: CategoryLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
      ),
      type: CategoryType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      aliases: List<String>.from(json['aliases'] as List),
      isCustom: json['isCustom'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionCategory &&
        other.id == id &&
        other.name == name &&
        other.parentId == parentId &&
        other.level == level &&
        other.type == type &&
        other.color.value == color.value &&
        other.icon.codePoint == icon.codePoint &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      parentId,
      level,
      type,
      color.value,
      icon.codePoint,
      isCustom,
    );
  }
}
