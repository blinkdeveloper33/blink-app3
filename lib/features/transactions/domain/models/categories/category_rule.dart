/// Represents a rule for automatic transaction categorization
class CategoryRule {
  final String id;
  final String categoryId;
  final String? merchantPattern;
  final double? minAmount;
  final double? maxAmount;
  final List<String> keywords;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastMatched;
  final int matchCount;
  final double confidence;

  const CategoryRule({
    required this.id,
    required this.categoryId,
    this.merchantPattern,
    this.minAmount,
    this.maxAmount,
    this.keywords = const [],
    this.isActive = true,
    required this.createdAt,
    this.lastMatched,
    this.matchCount = 0,
    this.confidence = 1.0,
  });

  /// Creates a copy of this rule with the given fields replaced with the new values
  CategoryRule copyWith({
    String? id,
    String? categoryId,
    String? Function()? merchantPattern,
    double? Function()? minAmount,
    double? Function()? maxAmount,
    List<String>? keywords,
    bool? isActive,
    DateTime? createdAt,
    DateTime? Function()? lastMatched,
    int? matchCount,
    double? confidence,
  }) {
    return CategoryRule(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      merchantPattern:
          merchantPattern != null ? merchantPattern() : this.merchantPattern,
      minAmount: minAmount != null ? minAmount() : this.minAmount,
      maxAmount: maxAmount != null ? maxAmount() : this.maxAmount,
      keywords: keywords ?? this.keywords,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastMatched: lastMatched != null ? lastMatched() : this.lastMatched,
      matchCount: matchCount ?? this.matchCount,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Converts the rule to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'merchantPattern': merchantPattern,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'keywords': keywords,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastMatched': lastMatched?.toIso8601String(),
      'matchCount': matchCount,
      'confidence': confidence,
    };
  }

  /// Creates a rule from a JSON map
  factory CategoryRule.fromJson(Map<String, dynamic> json) {
    return CategoryRule(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      merchantPattern: json['merchantPattern'] as String?,
      minAmount: json['minAmount'] as double?,
      maxAmount: json['maxAmount'] as double?,
      keywords: List<String>.from(json['keywords'] as List),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMatched: json['lastMatched'] != null
          ? DateTime.parse(json['lastMatched'] as String)
          : null,
      matchCount: json['matchCount'] as int,
      confidence: json['confidence'] as double,
    );
  }

  /// Checks if a transaction matches this rule
  bool matches({
    required String merchantName,
    required double amount,
    List<String> description = const [],
  }) {
    if (!isActive) return false;

    // Check merchant pattern
    if (merchantPattern != null &&
        !merchantName.toLowerCase().contains(merchantPattern!.toLowerCase())) {
      return false;
    }

    // Check amount range
    if (minAmount != null && amount < minAmount!) return false;
    if (maxAmount != null && amount > maxAmount!) return false;

    // Check keywords
    if (keywords.isNotEmpty) {
      final words = [...description, merchantName.toLowerCase()];
      final hasKeyword = keywords.any((keyword) => words
          .any((word) => word.toLowerCase().contains(keyword.toLowerCase())));
      if (!hasKeyword) return false;
    }

    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryRule &&
        other.id == id &&
        other.categoryId == categoryId &&
        other.merchantPattern == merchantPattern &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      categoryId,
      merchantPattern,
      minAmount,
      maxAmount,
      isActive,
    );
  }
}
