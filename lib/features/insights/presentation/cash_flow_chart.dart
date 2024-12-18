import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';

class CashFlowChart extends StatelessWidget {
  final Map<String, dynamic> cashFlowData;
  final String timeFrame;
  final Function(String) onTimeFrameChanged;

  const CashFlowChart({
    super.key,
    required this.cashFlowData,
    required this.timeFrame,
    required this.onTimeFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final segments = cashFlowData['segments'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cashflow Analysis',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Onest',
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(segments),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final amount = rod.toY;
                      return BarTooltipItem(
                        currencyFormatter.format(amount),
                        const TextStyle(
                            color: Colors.white, fontFamily: 'Onest'),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getXAxisLabel(
                            segments[value.toInt()]['period'] as String? ?? '',
                            timeFrame),
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontFamily: 'Onest'),
                      ),
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          currencyFormatter.format(value),
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontFamily: 'Onest'),
                        );
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withAlpha(25),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _getBarGroups(segments),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryCard(true)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard(false)),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(List<dynamic> segments) {
    return segments.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value as Map<String, dynamic>;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data['inflow'] as num?)?.toDouble() ?? 0,
            color: const Color(0xFF4CAF50),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: (data['outflow'] as num?)?.toDouble() ?? 0,
            color: const Color(0xFFFF4081),
            width: 8,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY(List<dynamic> segments) {
    double maxValue = 0;
    for (var segment in segments) {
      final inflow = (segment['inflow'] as num?)?.toDouble() ?? 0;
      final outflow = (segment['outflow'] as num?)?.toDouble() ?? 0;
      maxValue = [maxValue, inflow, outflow]
          .reduce((curr, next) => curr > next ? curr : next);
    }
    return (maxValue * 1.2).ceilToDouble();
  }

  String _getXAxisLabel(String period, String timeFrame) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    switch (timeFrame) {
      case 'YTD':
      case 'QTD':
        // For Year to Date and Quarter to Date, return month abbreviations
        if (monthNames.contains(period)) {
          return period;
        } else {
          // Try to extract month from string like "2023-01" or "2023-1"
          final parts = period.split('-');
          if (parts.length == 2) {
            final monthIndex = int.tryParse(parts[1]);
            if (monthIndex != null && monthIndex >= 1 && monthIndex <= 12) {
              return monthNames[monthIndex - 1];
            }
          }
        }
        break;

      case 'MTD':
        // For Month to Date, return week numbers
        final weekMatch = RegExp(r'(?:Week\s*)?(\d+)').firstMatch(period);
        if (weekMatch != null) {
          return 'W${weekMatch.group(1)}';
        }
        break;

      case 'WTD':
        // For Week to Date, return day of week abbreviations
        for (var day in dayNames) {
          if (period.toLowerCase().contains(day.toLowerCase())) {
            return day;
          }
        }
        // If day name not found, try to parse as date
        try {
          final date = DateTime.parse(period);
          return dayNames[date.weekday - 1];
        } catch (_) {
          // If parsing fails, return the original string
        }
        break;
    }

    // If all else fails, return a shortened version of the original string
    return period.length > 3 ? period.substring(0, 3) : period;
  }

  Widget _buildSummaryCard(bool isInflow) {
    final totalAmount =
        (cashFlowData[isInflow ? 'totalInflow' : 'totalOutflow'] as num?)
                ?.toDouble() ??
            0.0;

    return SummaryCard(
      categoryName: isInflow ? 'Inflow' : 'Outflow',
      amount: totalAmount,
      totalSpending: totalAmount,
      percentage: null,
      emoji: isInflow ? '💰' : '💸',
    );
  }
}
