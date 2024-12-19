import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';
import 'package:blink_app/features/insights/presentation/animated_pie_chart.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:blink_app/features/insights/presentation/time_frame_selector.dart';

class ExpenseAnalysis extends StatefulWidget {
  final Map<String, dynamic> expenseData;
  final String timeFrame;
  final Function(String) onTimeFrameChanged;

  const ExpenseAnalysis({
    super.key,
    required this.expenseData,
    required this.timeFrame,
    required this.onTimeFrameChanged,
  });

  @override
  State<ExpenseAnalysis> createState() => _ExpenseAnalysisState();
}

class _ExpenseAnalysisState extends State<ExpenseAnalysis>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _useRocket = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.expenseData['categories'] as List<dynamic>? ?? [];
    final totalSpending =
        (widget.expenseData['totalSpending'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Onest',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TimeFrameSelector(
                selectedTimeFrame: widget.timeFrame,
                onChanged: widget.onTimeFrameChanged,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.4,
                      child: AnimatedPieChart(
                        sections: _getPieChartSections(categories),
                        animationController: _animationController,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category =
                              categories[index] as Map<String, dynamic>;
                          final categoryName =
                              category['name'] as String? ?? 'Unknown';
                          final amount =
                              (category['amount'] as num?)?.toDouble() ?? 0.0;
                          final percentage =
                              (category['percentage'] as num?)?.toDouble() ??
                                  0.0;

                          return SummaryCard(
                            categoryName: categoryName,
                            amount: amount,
                            totalSpending: totalSpending,
                            percentage: percentage,
                            animatedEmoji:
                                _getCategoryAnimatedEmoji(categoryName),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(List<dynamic> categories) {
    final colors = [
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF2196F3),
      const Color(0xFFF44336),
      const Color(0xFF4CAF50),
      const Color(0xFFFFEB3B),
    ];

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value as Map<String, dynamic>? ?? {};
      final percentage = (category['percentage'] as num?)?.toDouble() ?? 0.0;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: percentage >= 5.0 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Onest',
        ),
      );
    }).toList();
  }

  Widget _getCategoryAnimatedEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
      case 'food':
        return const AnimatedEmoji(AnimatedEmojis.spaghetti);
      case 'utilities':
        return const AnimatedEmoji(AnimatedEmojis.lightBulb);
      case 'entertainment':
        return const AnimatedEmoji(AnimatedEmojis.mirrorBall);
      case 'transportation':
        _useRocket = !_useRocket;
        return AnimatedEmoji(
            _useRocket ? AnimatedEmojis.rocket : AnimatedEmojis.flyingSaucer);
      case 'housing':
        return const AnimatedEmoji(AnimatedEmojis.hotBeverage);
      case 'payment':
        return const AnimatedEmoji(AnimatedEmojis.moneyWithWings);
      default:
        return const AnimatedEmoji(AnimatedEmojis.thinkingFace);
    }
  }
}
