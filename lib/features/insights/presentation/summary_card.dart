import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/glass_container.dart';
import 'package:animated_emoji/emoji.dart';

class SummaryCard extends StatelessWidget {
  final String categoryName;
  final double amount;
  final double totalSpending;
  final double? percentage;
  final AnimatedEmoji animatedEmoji;
  final Color? textColor;
  final double? width;
  final double? height;
  final bool isDarkMode;

  const SummaryCard({
    super.key,
    required this.categoryName,
    required this.amount,
    required this.totalSpending,
    this.percentage,
    required this.animatedEmoji,
    this.textColor,
    this.width,
    this.height,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = isDarkMode ? Colors.white : Colors.black87;
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      color: textColor ?? defaultTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Onest',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormatter.format(amount),
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Onest',
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(height: 4),
              Text(
                '${percentage!.toStringAsFixed(1)}% of total',
                style: TextStyle(
                  color: (textColor ?? Colors.white).withOpacity(0.7),
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
