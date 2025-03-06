class TransactionDetail {
  final String id;
  final String? merchantName;
  final double amount;
  final DateTime date;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? metadata;

  TransactionDetail({
    required this.id,
    this.merchantName,
    required this.amount,
    required this.date,
    this.category,
    this.metadata,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> json) {
    return TransactionDetail(
      id: json['id'] as String,
      merchantName: json['merchantName'] as String?,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}
