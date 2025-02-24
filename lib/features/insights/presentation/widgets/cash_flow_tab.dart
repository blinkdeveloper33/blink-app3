import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import '../../domain/cash_flow_data.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../widgets/net_cash_flow_details.dart';
import '../widgets/cash_flow_ratio_details.dart';
import '../widgets/growth_rate_details.dart';
import '../widgets/volatility_details.dart';

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: LayoutBuilder(builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 16) / 2;
        final cardHeight = 120.0;
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
              subtitle: _formatTimeFrame(data.timeFrame),
              trend: data.growthRate,
              isPositiveTrend: data.growthRate >= 0,
              onTap: () {
                HapticFeedback.mediumImpact();
                NetCashFlowDetails.show(
                  context,
                  netCashFlow: data.netCashFlow,
                  trend: data.growthRate,
                  isPositiveTrend: data.growthRate >= 0,
                  timeFrame: _formatTimeFrame(data.timeFrame),
                  trendData: data.trends
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value.netFlow,
                          ))
                      .toList(),
                  isDarkMode: isDarkMode,
                );
              },
            ),
            MetricCard(
              title: 'Cash Flow Ratio',
              value: '${(data.cashFlowRatio * 100).toStringAsFixed(1)}%',
              subtitle: 'Inflow to Outflow',
              trend: data.cashFlowRatio - 1,
              isPositiveTrend: data.cashFlowRatio >= 1,
              onTap: () {
                HapticFeedback.mediumImpact();
                CashFlowRatioDetails.show(
                  context,
                  cashFlowRatio: data.cashFlowRatio,
                  timeFrame: _formatTimeFrame(data.timeFrame),
                  isDarkMode: isDarkMode,
                  inflow: data.totalInflow,
                  outflow: data.totalOutflow,
                );
              },
            ),
            MetricCard(
              title: 'Growth Rate',
              value: '${(data.growthRate * 100).toStringAsFixed(1)}%',
              subtitle: 'vs. Previous Period',
              trend: data.growthRate,
              isPositiveTrend: data.growthRate >= 0,
              onTap: () {
                HapticFeedback.mediumImpact();
                GrowthRateDetails.show(
                  context,
                  growthRate: data.growthRate,
                  timeFrame: _formatTimeFrame(data.timeFrame),
                  isDarkMode: isDarkMode,
                  trendData: data.trends
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value.netFlow,
                          ))
                      .toList(),
                  previousPeriodFlow: data.trends.first.netFlow,
                  currentPeriodFlow: data.trends.last.netFlow,
                );
              },
            ),
            MetricCard(
              title: 'Volatility',
              value: '${(data.volatility * 100).toStringAsFixed(1)}%',
              subtitle: 'Cash Flow Stability',
              trend: -data.volatility,
              isPositiveTrend: data.volatility < 0.15,
              onTap: () {
                HapticFeedback.mediumImpact();
                VolatilityDetails.show(
                  context,
                  volatility: data.volatility,
                  timeFrame: _formatTimeFrame(data.timeFrame),
                  isDarkMode: isDarkMode,
                );
              },
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String _getPeriodLabel() {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'this_year':
          return 'Monthly Breakdown';
        case 'last_quarter':
        case 'this_quarter':
          return '3-Month Breakdown';
        case 'last_month':
        case 'this_month':
          return '4-Week Breakdown';
        case 'last_week':
        case 'this_week':
          return 'Daily Breakdown';
        default:
          return 'Detailed Analysis';
      }
    }

    String _getSubtitle() {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'this_year':
          return 'Month-by-month analysis of your cash flow';
        case 'last_quarter':
        case 'this_quarter':
          return 'Three-month analysis of your cash flow';
        case 'last_month':
        case 'this_month':
          return 'Week-by-week analysis of your cash flow';
        case 'last_week':
        case 'this_week':
          return 'Day-by-day analysis of your cash flow';
        default:
          return 'Detailed breakdown of your cash flow';
      }
    }

    String _formatDate(DateTime date) {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'this_year':
          return DateFormat('MMMM yyyy').format(date);
        case 'last_quarter':
        case 'this_quarter':
          return '${DateFormat('MMM').format(date)} - ${DateFormat('MMM yyyy').format(date.add(const Duration(days: 89)))}';
        case 'last_month':
        case 'this_month':
          return 'Week ${((date.day - 1) ~/ 7) + 1}, ${DateFormat('MMMM').format(date)}';
        case 'last_week':
        case 'this_week':
          return DateFormat('EEEE, MMM d').format(date);
        default:
          return DateFormat('MMM d, yyyy').format(date);
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0078D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF0078D4),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPeriodLabel(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.trends.length,
            separatorBuilder: (context, index) => Divider(
              height: 32,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final trend = data.trends[index];
              final isPositive = trend.netFlow >= 0;
              final formattedDate = _formatDate(trend.date);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  fontFamily: 'Onest',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (isPositive ? Colors.green : Colors.red)
                                .withOpacity(isDarkMode ? 0.15 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (isPositive ? Colors.green : Colors.red)
                                  .withOpacity(isDarkMode ? 0.2 : 0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: isPositive
                                    ? Colors.green[400]
                                    : Colors.red[400],
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formatCurrency(trend.netFlow.abs()),
                                style: TextStyle(
                                  color: isPositive
                                      ? Colors.green[400]
                                      : Colors.red[400],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  fontFamily: 'Onest',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.arrow_upward_rounded,
                                      color: Colors.green[400],
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Inflow',
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white60
                                                : Colors.black45,
                                            fontSize: 13,
                                            height: 1.2,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(trend.inflow),
                                          style: TextStyle(
                                            color: Colors.green[400],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Colors.red[400],
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Outflow',
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white60
                                                : Colors.black45,
                                            fontSize: 13,
                                            height: 1.2,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatCurrency(trend.outflow),
                                          style: TextStyle(
                                            color: Colors.red[400],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

  String _formatTimeFrame(String timeFrame) {
    // Convert LAST_MONTH to "Last Month"
    final cleanText =
        timeFrame.replaceAll('(', '').replaceAll(')', '').toLowerCase();

    switch (cleanText) {
      case 'last_week':
        return 'Last Week';
      case 'last_month':
        return 'Last Month';
      case 'last_year':
        return 'Last Year';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'this_year':
        return 'This Year';
      default:
        return cleanText
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
