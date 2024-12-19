import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/glass_container.dart';

class SummaryCard extends StatelessWidget {
  final String categoryName;
  final double amount;
  final double totalSpending;
  final double? percentage;
  final Widget animatedEmoji;
  final Color textColor;

  const SummaryCard({
    super.key,
    required this.categoryName,
    required this.amount,
    required this.totalSpending,
    required this.percentage,
    required this.animatedEmoji,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(12), // Update 1: Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: animatedEmoji,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14, // Update 3: Reduced font size
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Onest',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // Update 2: Adjusted SizedBox height
            Text(
              currencyFormatter.format(amount),
              style: TextStyle(
                color: textColor,
                fontSize: 18, // Update 3: Reduced font size
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(height: 4), // Update 2: Adjusted SizedBox height
              Text(
                '${percentage!.toStringAsFixed(1)}% of total',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
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
