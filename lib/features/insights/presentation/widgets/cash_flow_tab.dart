import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/cash_flow_data.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../../../shared/utils/currency_formatter.dart';

class CashFlowTab extends StatelessWidget {
  final CashFlowData data;
  final bool isLoading;

  const CashFlowTab({
    Key? key,
    required this.data,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading cash flow data...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              'Cash Flow Summary',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryMetrics(context),
          if (data.trends.isNotEmpty) ...[
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildCashFlowChart(context),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildTrendAnalysis(context),
            ),
          ] else
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildNoTrendsMessage(context),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetrics(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: LayoutBuilder(builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;
        final cardHeight = 120.0; // Fixed height that accommodates content
        final aspectRatio = cardWidth / cardHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            MetricCard(
              title: 'Net Cash Flow',
              value: formatCurrency(data.netCashFlow),
              subtitle: data.timeFrame,
              trend: data.growthRate,
              isPositiveTrend: data.growthRate >= 0,
            ),
            MetricCard(
              title: 'Cash Flow Ratio',
              value: '${(data.cashFlowRatio * 100).toStringAsFixed(1)}%',
              subtitle: 'Inflow to Outflow',
              trend: data.cashFlowRatio - 1,
              isPositiveTrend: data.cashFlowRatio >= 1,
            ),
            MetricCard(
              title: 'Growth Rate',
              value: '${(data.growthRate * 100).toStringAsFixed(1)}%',
              subtitle: 'vs. Previous Period',
              trend: data.growthRate,
              isPositiveTrend: data.growthRate >= 0,
            ),
            MetricCard(
              title: 'Volatility',
              value: '${(data.volatility * 100).toStringAsFixed(1)}%',
              subtitle: 'Cash Flow Stability',
              trend: -data.volatility,
              isPositiveTrend: data.volatility < 0.15,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCashFlowChart(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TrendChart(
        title: 'Cash Flow Trends',
        data: data.trends
            .asMap()
            .entries
            .map((entry) => FlSpot(
                  entry.key.toDouble(),
                  entry.value.netFlow,
                ))
            .toList(),
        yAxisFormatter: (value) => formatCurrency(value),
        xAxisFormatter: (value) => DateFormat('MMM d').format(
          data.trends[value.toInt()].date,
        ),
      ),
    );
  }

  Widget _buildTrendAnalysis(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.trends.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final trend = data.trends[index];
              final isPositive = trend.netFlow >= 0;
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      DateFormat('MMM d, yyyy').format(trend.date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Inflow: ${formatCurrency(trend.inflow)}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Outflow: ${formatCurrency(trend.outflow)}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: isPositive
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Net: ${formatCurrency(trend.netFlow)}',
                                  style: TextStyle(
                                    color: isPositive
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrendsMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
      margin: const EdgeInsets.only(top: 32.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Trend Data Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll show your cash flow trends here once we have enough data.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}
