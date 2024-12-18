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
    super.key,
    required this.categoryName,
    required this.amount,
    required this.totalSpending,
    required this.percentage,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              currencyFormatter.format(amount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(height: 2),
              Text(
                '${percentage!.toStringAsFixed(1)}% of total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
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
