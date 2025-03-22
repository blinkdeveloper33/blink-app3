import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/cash_flow_data.dart';
import '../widgets/cash_flow_ratio_details.dart';
import '../widgets/net_cash_flow_details.dart';
import '../widgets/growth_rate_details.dart';
import '../widgets/volatility_details.dart';

class CashFlowMetrics extends StatelessWidget {
  final CashFlowData data;

  const CashFlowMetrics({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      child: LayoutBuilder(builder: (context, constraints) {
        // Adjust card sizing based on screen width
        final availableWidth = constraints.maxWidth;
        final cardWidth =
            (availableWidth - 8) / 2; // Reduced spacing from 12 to 8
        // Reduce card height slightly to fix overflow
        final cardHeight = isSmallScreen
            ? 105.0
            : 110.0; // Further reduced from 110/116 to 105/110
        final aspectRatio = cardWidth / cardHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: 4, bottom: 8), // Reduced bottom padding from 12 to 8
              child: Text(
                'Key Metrics',
                style: TextStyle(
                  fontSize: isSmallScreen
                      ? 14
                      : 15, // Reduced font size from 15/16 to 14/15
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                  fontFamily: 'Onest',
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SizedBox(
              // Define an explicit height for the GridView to prevent overflow
              height: cardHeight * 2 + 8, // Reduced spacing from 12 to 8
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8, // Reduced spacing from 12 to 8
                crossAxisSpacing: 8, // Reduced spacing from 12 to 8
                childAspectRatio: aspectRatio,
                children: [
                  _buildModernMetricCard(
                    context,
                    title: 'Net Cash Flow',
                    value: formatCurrency(data.netCashFlow),
                    subtitle: _formatTimeFrame(data.timeFrame),
                    isPositive: data.netCashFlow >= 0,
                    gradientColors: isDarkMode
                        ? [
                            const Color(0xFF1A237E).withOpacity(0.7),
                            const Color(0xFF0D47A1).withOpacity(0.6),
                          ]
                        : [
                            const Color(0xFF42A5F5).withOpacity(0.7),
                            const Color(0xFF1976D2).withOpacity(0.9),
                          ],
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
                  _buildModernMetricCard(
                    context,
                    title: 'Cash Flow Ratio',
                    value: '${(data.cashFlowRatio * 100).toStringAsFixed(1)}%',
                    subtitle: 'Inflow to Outflow',
                    isPositive: data.cashFlowRatio >= 1,
                    gradientColors: isDarkMode
                        ? [
                            const Color(0xFF006064).withOpacity(0.7),
                            const Color(0xFF00796B).withOpacity(0.6),
                          ]
                        : [
                            const Color(0xFF26A69A).withOpacity(0.7),
                            const Color(0xFF00897B).withOpacity(0.9),
                          ],
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
                  _buildModernMetricCard(
                    context,
                    title: 'Growth Rate',
                    value: '${(data.growthRate * 100).toStringAsFixed(1)}%',
                    subtitle: 'vs. Previous Period',
                    isPositive: data.growthRate >= 0,
                    gradientColors: isDarkMode
                        ? [
                            const Color(0xFF4A148C).withOpacity(0.7),
                            const Color(0xFF7B1FA2).withOpacity(0.6),
                          ]
                        : [
                            const Color(0xFF9C27B0).withOpacity(0.7),
                            const Color(0xFF7B1FA2).withOpacity(0.9),
                          ],
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
                  _buildModernMetricCard(
                    context,
                    title: 'Volatility',
                    value: '${(data.volatility * 100).toStringAsFixed(1)}%',
                    subtitle: 'Cash Flow Stability',
                    isPositive: data.volatility < 0.15,
                    gradientColors: isDarkMode
                        ? [
                            const Color(0xFF5D4037).withOpacity(0.7),
                            const Color(0xFF795548).withOpacity(0.6),
                          ]
                        : [
                            const Color(0xFF8D6E63).withOpacity(0.7),
                            const Color(0xFF795548).withOpacity(0.9),
                          ],
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
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModernMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required bool isPositive,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    // Calculate font sizes based on screen width for better text scaling
    final titleFontSize =
        isSmallScreen ? 11.0 : 12.0; // Reduced from 12/13 to 11/12
    final valueFontSize =
        isSmallScreen ? 16.0 : 18.0; // Reduced from 18/20 to 16/18
    final subtitleFontSize =
        isSmallScreen ? 9.0 : 10.0; // Reduced from 10/11 to 9/10

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(14), // Reduced from 16 to 14
          boxShadow: [
            BoxShadow(
              color: gradientColors[0]
                  .withOpacity(isDarkMode ? 0.25 : 0.15), // Reduced opacity
              blurRadius: 10, // Reduced from 12 to 10
              offset: const Offset(0, 3), // Reduced from 0,4 to 0,3
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14), // Reduced from 16 to 14
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen
                      ? 10.0
                      : 12.0, // Reduced from 12/16 to 10/12
                  vertical:
                      isSmallScreen ? 8.0 : 10.0, // Reduced from 10/14 to 8/10
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 6), // Reduced from 8 to 6
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Onest',
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Onest',
                            ),
                          ),
                        ),
                        Container(
                          width: 6, // Reduced from 8 to 6
                          height: 6, // Reduced from 8 to 6
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPositive
                                ? Colors.green[300]
                                : Colors.red[300],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeFrame(String timeFrame) {
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

// Helper function for currency formatting
String formatCurrency(double value) {
  return value < 1000000
      ? '\$${value.toStringAsFixed(0)}'
      : '\$${(value / 1000000).toStringAsFixed(1)}M';
}
