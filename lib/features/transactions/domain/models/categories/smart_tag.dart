import 'package:flutter/material.dart';

/// Represents the type of smart tag
enum TagType {
  frequency, // recurring, one-time
  necessity, // essential, discretionary
  purpose, // business, personal
  location, // local, online
  custom, // user-defined
}

/// Represents a smart tag that can be applied to transactions
class SmartTag {
  final String id;
  final String name;
  final TagType type;
  final bool isAutomatic;
  final Color color;
  final IconData? icon;
  final String? description;
  final DateTime createdAt;
  final DateTime? lastUsed;
  final int usageCount;

  const SmartTag({
    required this.id,
    required this.name,
    required this.type,
    this.isAutomatic = false,
    required this.color,
    this.icon,
    this.description,
    required this.createdAt,
    this.lastUsed,
    this.usageCount = 0,
  });

  /// Creates a copy of this tag with the given fields replaced with the new values
  SmartTag copyWith({
    String? id,
    String? name,
    TagType? type,
    bool? isAutomatic,
    Color? color,
    IconData? Function()? icon,
    String? Function()? description,
    DateTime? createdAt,
    DateTime? Function()? lastUsed,
    int? usageCount,
  }) {
    return SmartTag(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      color: color ?? this.color,
      icon: icon != null ? icon() : this.icon,
      description: description != null ? description() : this.description,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed != null ? lastUsed() : this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
    );
  }

  /// Converts the tag to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'isAutomatic': isAutomatic,
      'color': color.value,
      'icon': icon?.codePoint,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  /// Creates a tag from a JSON map
  factory SmartTag.fromJson(Map<String, dynamic> json) {
    return SmartTag(
      id: json['id'] as String,
      name: json['name'] as String,
      type: TagType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      isAutomatic: json['isAutomatic'] as bool,
      color: Color(json['color'] as int),
      icon: json['icon'] != null
          ? IconData(json['icon'] as int, fontFamily: 'MaterialIcons')
          : null,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: json['lastUsed'] != null
          ? DateTime.parse(json['lastUsed'] as String)
          : null,
      usageCount: json['usageCount'] as int,
    );
  }

  /// Predefined smart tags for common use cases
  static List<SmartTag> get defaultTags {
    return [
      SmartTag(
        id: 'recurring',
        name: 'Recurring',
        type: TagType.frequency,
        isAutomatic: true,
        color: Colors.blue,
        icon: Icons.repeat,
        description: 'Automatically detected recurring transactions',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'one_time',
        name: 'One-time',
        type: TagType.frequency,
        isAutomatic: true,
        color: Colors.purple,
        icon: Icons.event_available,
        description: 'Non-recurring transactions',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'essential',
        name: 'Essential',
        type: TagType.necessity,
        isAutomatic: true,
        color: Colors.red,
        icon: Icons.priority_high,
        description: 'Essential expenses for living',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'discretionary',
        name: 'Discretionary',
        type: TagType.necessity,
        isAutomatic: true,
        color: Colors.orange,
        icon: Icons.shopping_bag,
        description: 'Optional or leisure expenses',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'business',
        name: 'Business',
        type: TagType.purpose,
        isAutomatic: false,
        color: Colors.green,
        icon: Icons.business,
        description: 'Business-related expenses',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'personal',
        name: 'Personal',
        type: TagType.purpose,
        isAutomatic: false,
        color: Colors.teal,
        icon: Icons.person,
        description: 'Personal expenses',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'online',
        name: 'Online',
        type: TagType.location,
        isAutomatic: true,
        color: Colors.indigo,
        icon: Icons.language,
        description: 'Online purchases',
        createdAt: DateTime.now(),
      ),
      SmartTag(
        id: 'local',
        name: 'Local',
        type: TagType.location,
        isAutomatic: true,
        color: Colors.brown,
        icon: Icons.location_on,
        description: 'Local purchases',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmartTag &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.isAutomatic == isAutomatic &&
        other.color.value == color.value &&
        other.icon?.codePoint == icon?.codePoint;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      isAutomatic,
      color.value,
      icon?.codePoint,
    );
  }
}
