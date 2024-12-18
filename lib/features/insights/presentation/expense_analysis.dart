import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';
import 'package:blink_app/features/insights/presentation/animated_pie_chart.dart';

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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                16, 24, 16, 16), // Reduced bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 24),
                SizedBox(
                  height: constraints.maxWidth * 0.6,
                  child: AnimatedPieChart(
                    sections: _getPieChartSections(categories),
                    animationController: _animationController,
                  ),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio:
                        1.4, // Decreased to 1.4 to allow more height for cards
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index] as Map<String, dynamic>;
                    final categoryName =
                        category['name'] as String? ?? 'Unknown';
                    final amount =
                        (category['amount'] as num?)?.toDouble() ?? 0.0;
                    final percentage =
                        (category['percentage'] as num?)?.toDouble() ?? 0.0;

                    return SummaryCard(
                      categoryName: categoryName,
                      amount: amount,
                      totalSpending: totalSpending,
                      percentage: percentage,
                      emoji: _getCategoryEmoji(categoryName),
                    );
                  },
                ),
                const SizedBox(height: 16), // Added extra space at the bottom
              ],
            ),
          ),
        );
      },
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
        radius: 110,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Onest',
        ),
      );
    }).toList();
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food & groceries':
      case 'food':
        return '🍽️';
      case 'utilities':
        return '💡';
      case 'entertainment':
        return '🎭';
      case 'transportation':
        return '🚗';
      case 'housing':
        return '🏠';
      case 'healthcare':
        return '🏥';
      case 'education':
        return '📚';
      case 'shopping':
        return '🛍️';
      case 'travel':
        return '✈️';
      case 'payment':
        return '💳';
      case 'others':
        return '📦';
      default:
        return '💼';
    }
  }
}
