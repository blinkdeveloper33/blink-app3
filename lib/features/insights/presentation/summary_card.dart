import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/glass_container.dart';

class SummaryCard extends StatelessWidget {
  final String categoryName;
  final double amount;
  final double totalSpending;
  final double? percentage;
  final String emoji;

  const SummaryCard({
    Key? key,
    required this.categoryName,
    required this.amount,
    required this.totalSpending,
    required this.percentage,
    required this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Onest',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormatter.format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(height: 4),
              Text(
                '${percentage!.toStringAsFixed(1)}% of total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
