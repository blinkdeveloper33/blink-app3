import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/features/insights/presentation/summary_card.dart';

class CashFlowChart extends StatelessWidget {
  final Map<String, dynamic> cashFlowData;
  final String timeFrame;
  final Function(String) onTimeFrameChanged;

  const CashFlowChart({
    required this.cashFlowData,
    required this.timeFrame,
    required this.onTimeFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final segments = cashFlowData['segments'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cashflow Analysis',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Onest',
            fontSize: 18,
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
                      const TextStyle(color: Colors.white, fontFamily: 'Onest'),
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
                          color: Color.fromARGB(255, 255, 255, 255),
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
                      final formatted = value >= 1000
                          ? '${(value / 1000).toStringAsFixed(1)}k'
                          : value.toStringAsFixed(0);
                      return Text(
                        '\$$formatted',
                        style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
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
              gridData: FlGridData(show: false),
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
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: (data['outflow'] as num?)?.toDouble() ?? 0,
            color: const Color(0xFFFF4081),
            width: 16,
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
    switch (timeFrame) {
      case 'YTD':
        return period.substring(0, 3);
      case 'QTD':
        return period;
      case 'MTD':
        return period.substring(0, 3);
      case 'WTD':
        return period;
      default:
        return period;
    }
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
      percentage:
          null, // Set to null to indicate we don't want to display percentage
      emoji: isInflow ? '💰' : '💸',
    );
  }
}
