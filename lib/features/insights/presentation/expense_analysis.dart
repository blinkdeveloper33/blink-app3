import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';

class ExpenseAnalysis extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final categories = expenseData['categories'] as List<dynamic>? ?? [];
    final totalSpending =
        (expenseData['totalSpending'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 38),
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
          const SizedBox(height: 77),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _getPieChartSections(categories),
                centerSpaceRadius: 50,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category =
                      categories[index] as Map<String, dynamic>? ?? {};
                  final categoryName = category['name'] as String? ?? 'Unknown';
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
              );
            },
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
        title: percentage >= 1.0 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 110,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Onest',
        ),
        titlePositionPercentageOffset: 0.55,
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
