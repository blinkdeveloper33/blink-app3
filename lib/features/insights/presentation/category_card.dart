import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/glass_container.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;
  final AnimationController animationController;

  const CategoryCard({
    super.key,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animationController.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animationController.value)),
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormatter.format(amount),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: 12,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
