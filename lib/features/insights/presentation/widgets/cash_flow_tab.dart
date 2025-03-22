import 'package:flutter/material.dart';
import 'dart:developer' as dev;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../domain/cash_flow_data.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/trend_chart.dart';
import '../widgets/cash_flow_ratio_details.dart';
import '../widgets/net_cash_flow_details.dart';
import '../widgets/growth_rate_details.dart';
import '../widgets/volatility_details.dart';
import '../widgets/cash_flow_metrics.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/rendering.dart' as ui;
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';

class CashFlowTab extends StatelessWidget {
  final CashFlowData data;
  final bool isLoading;
  final bool showChart;

  const CashFlowTab({
    Key? key,
    required this.data,
    this.isLoading = false,
    this.showChart = true,
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding:
          EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.trends.isNotEmpty) ...[
            if (showChart)
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: _buildCashFlowChart(context),
              ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: _buildTrendAnalysis(context),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              duration: const Duration(milliseconds: 1100),
              child: CashFlowMetrics(data: data),
            ),
            if (data.detailedAnalysis != null) ...[
              const SizedBox(height: 20),
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: _buildDetailedAnalysis(context),
              ),
            ],
          ] else
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildNoTrendsMessage(context),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCashFlowChart(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final accentColor = const Color(0xFF0078D4);

    // Ensure we have trends to display
    if (data.trends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'No cash flow data available',
                style: TextStyle(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Get the appropriate trends data to display in the chart
    List<CashFlowTrend> trendsForChart = data.trends;

    // Use detailed analysis data if we only have one segment but detailed analysis is available
    if (trendsForChart.length <= 1 && data.detailedAnalysis != null) {
      final detailedAnalysis = data.detailedAnalysis!;

      // Determine which breakdown to use based on time frame
      String breakdownKey = '';
      switch (data.timeFrame.toLowerCase()) {
        case 'last_week':
        case 'week':
          breakdownKey = 'daily_breakdown';
          break;
        case 'last_month':
        case 'month':
          breakdownKey = 'weekly_breakdown';
          break;
        case 'last_quarter':
        case 'quarter':
        case 'last_year':
        case 'year':
          breakdownKey = 'monthly_breakdown';
          break;
      }

      // First check for segments directly
      if (detailedAnalysis.containsKey('segments') &&
          detailedAnalysis['segments'] is List &&
          (detailedAnalysis['segments'] as List).isNotEmpty) {
        final segments = detailedAnalysis['segments'] as List;
        trendsForChart = segments
            .map((segment) =>
                CashFlowTrend.fromJson(segment as Map<String, dynamic>))
            .toList();
      }
      // Then check for specific breakdown
      else if (breakdownKey.isNotEmpty &&
          detailedAnalysis.containsKey(breakdownKey) &&
          detailedAnalysis[breakdownKey] is List) {
        final breakdown = detailedAnalysis[breakdownKey] as List;
        trendsForChart = breakdown
            .map((item) => CashFlowTrend.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    // Reverse the existing trends (which might be in newest-to-oldest order)
    // Then sort them chronologically to ensure left-to-right is oldest-to-newest
    trendsForChart = trendsForChart.reversed.toList();
    trendsForChart.sort((a, b) => a.date.compareTo(b.date));

    dev.log(
        "Sorted trendsForChart dates (oldest to newest): ${trendsForChart.map((t) => t.date.toString()).join(', ')}");

    return Container(
      height: 380, // Adjusted height for better proportions
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AnimatedEmoji(
                  AnimatedEmojis.fire,
                  size: 22,
                  repeat: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatTimeFrame(data.timeFrame)} Cash Flow',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Income, expenses and net cash flow',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              // Add legend indicators
              Row(
                children: [
                  _buildLegendDot(Colors.green, 'In'),
                  const SizedBox(width: 8),
                  _buildLegendDot(const Color(0xFFE57373), 'Out'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SleekCashFlowChart(
              trends: trendsForChart,
              isDarkMode: isDarkMode,
              timeFrame: data.timeFrame,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = const Color(0xFF0078D4);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 375;

    String _getPeriodLabel() {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'year':
          return 'Monthly Breakdown';
        case 'last_quarter':
        case 'quarter':
          return '3-Month Breakdown';
        case 'last_month':
        case 'month':
          return '4-Week Breakdown';
        case 'last_week':
        case 'week':
          return 'Daily Breakdown';
        default:
          return 'Detailed Analysis';
      }
    }

    String _getSubtitle() {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'year':
          return 'Month-by-month analysis of your cash flow';
        case 'last_quarter':
        case 'quarter':
          return 'Three-month analysis of your cash flow';
        case 'last_month':
        case 'month':
          return 'Week-by-week analysis of your cash flow';
        case 'last_week':
        case 'week':
          return 'Day-by-day analysis of your cash flow';
        default:
          return 'Detailed breakdown of your cash flow';
      }
    }

    String _formatDate(DateTime date) {
      switch (data.timeFrame.toLowerCase()) {
        case 'last_year':
        case 'year':
          return DateFormat('MMMM yyyy').format(date);
        case 'last_quarter':
        case 'quarter':
          if (date.day == 1) {
            // If it's the first day of the month, just show the month name
            return DateFormat('MMMM yyyy').format(date);
          } else {
            // Otherwise show the date range
            return '${DateFormat('MMM').format(date)} - ${DateFormat('MMM yyyy').format(date.add(const Duration(days: 89)))}';
          }
        case 'last_month':
        case 'month':
          // Calculate date range for weekly period
          final endDate = date.add(const Duration(days: 6));
          if (date.month == endDate.month) {
            return '${DateFormat('MMM d').format(date)}-${DateFormat('d').format(endDate)}';
          } else {
            return '${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(endDate)}';
          }
        case 'last_week':
        case 'week':
          return DateFormat('EEEE, MMM d').format(date);
        default:
          return DateFormat('MMM d, yyyy').format(date);
      }
    }

    // Get appropriate trends to display - either from the trends field or from detailed_analysis
    List<CashFlowTrend> trendsToShow = data.trends;

    // If we only have one trend but detailed analysis is available, create trends from detailed analysis
    if (trendsToShow.length <= 1 && data.detailedAnalysis != null) {
      final detailedAnalysis = data.detailedAnalysis!;

      // Determine which breakdown to use based on time frame
      String breakdownKey = '';
      switch (data.timeFrame.toLowerCase()) {
        case 'last_week':
        case 'week':
          breakdownKey = 'daily_breakdown';
          break;
        case 'last_month':
        case 'month':
          breakdownKey = 'weekly_breakdown';
          break;
        case 'last_quarter':
        case 'quarter':
        case 'last_year':
        case 'year':
          breakdownKey = 'monthly_breakdown';
          break;
      }

      // First check for segments directly
      if (detailedAnalysis.containsKey('segments') &&
          detailedAnalysis['segments'] is List &&
          (detailedAnalysis['segments'] as List).isNotEmpty) {
        final segments = detailedAnalysis['segments'] as List;
        trendsToShow = segments
            .map((segment) =>
                CashFlowTrend.fromJson(segment as Map<String, dynamic>))
            .toList();
      }
      // Then check for specific breakdown
      else if (breakdownKey.isNotEmpty &&
          detailedAnalysis.containsKey(breakdownKey) &&
          detailedAnalysis[breakdownKey] is List) {
        final breakdown = detailedAnalysis[breakdownKey] as List;
        trendsToShow = breakdown
            .map((item) => CashFlowTrend.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    // Sort trends in descending order (most recent first)
    trendsToShow.sort((a, b) => b.date.compareTo(a.date));

    dev.log(
        "Sorted trendsToShow dates: ${trendsToShow.map((t) => t.date.toString()).join(', ')}");

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const AnimatedEmoji(
                        AnimatedEmojis.fire,
                        size: 22,
                        repeat: true,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 10 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPeriodLabel(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontFamily: 'Onest',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getSubtitle(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color:
                                  isDarkMode ? Colors.white60 : Colors.black54,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 16 : 18),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trendsToShow.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: isSmallScreen ? 8 : 10),
                  itemBuilder: (context, index) {
                    final trend = trendsToShow[index];
                    final isPositive = trend.netFlow >= 0;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            // Optional: add detailed view for a specific trend
                          },
                          child: Padding(
                            padding:
                                EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatDate(trend.date),
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: isSmallScreen ? 13 : 14,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                              fontFamily: 'Onest',
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            trend.period,
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white60
                                                  : Colors.black45,
                                              fontSize: isSmallScreen ? 11 : 12,
                                              height: 1.2,
                                              fontFamily: 'Onest',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 10,
                                        vertical: isSmallScreen ? 3 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (isPositive
                                                ? Colors.green
                                                : Colors.red)
                                            .withOpacity(
                                                isDarkMode ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isPositive
                                                    ? Colors.green
                                                    : Colors.red)
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
                                            size: isSmallScreen ? 12 : 14,
                                          ),
                                          SizedBox(
                                              width: isSmallScreen ? 3 : 4),
                                          Text(
                                            _formatCurrency(
                                                trend.netFlow.abs()),
                                            style: TextStyle(
                                              color: isPositive
                                                  ? Colors.green[400]
                                                  : Colors.red[400],
                                              fontSize: isSmallScreen ? 12 : 13,
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
                                SizedBox(height: isSmallScreen ? 8 : 10),
                                // Enhanced cash flow details section
                                Container(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.03),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      isSmallScreen ? 5 : 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_upward_rounded,
                                                    color: Colors.green[400],
                                                    size:
                                                        isSmallScreen ? 12 : 14,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        isSmallScreen ? 6 : 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Inflow',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white60
                                                              : Colors.black45,
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 11
                                                                  : 12,
                                                          height: 1.2,
                                                          fontFamily: 'Onest',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _formatCurrency(
                                                            trend.inflow),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.green[400],
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 13
                                                                  : 14,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                        height: 32,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 8 : 12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.05)
                                                  : Colors.black
                                                      .withOpacity(0.03),
                                              isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.1)
                                                  : Colors.black
                                                      .withOpacity(0.05),
                                              isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.05)
                                                  : Colors.black
                                                      .withOpacity(0.03),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(
                                                      isSmallScreen ? 5 : 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons
                                                        .arrow_downward_rounded,
                                                    color: Colors.red[400],
                                                    size:
                                                        isSmallScreen ? 12 : 14,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                        isSmallScreen ? 6 : 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Outflow',
                                                        style: TextStyle(
                                                          color: isDarkMode
                                                              ? Colors.white60
                                                              : Colors.black45,
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 11
                                                                  : 12,
                                                          height: 1.2,
                                                          fontFamily: 'Onest',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _formatCurrency(
                                                            trend.outflow),
                                                        style: TextStyle(
                                                          color:
                                                              Colors.red[400],
                                                          fontSize:
                                                              isSmallScreen
                                                                  ? 13
                                                                  : 14,
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildDetailedAnalysis(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final detailedAnalysis = data.detailedAnalysis!;

    // Get section title based on time frame
    String sectionTitle = '';
    String sectionSubtitle = '';
    List<Map<String, dynamic>> breakdownItems = [];

    // Store highlight information if available
    Map<String, dynamic>? highlights;
    if (detailedAnalysis.containsKey('highlights')) {
      highlights = detailedAnalysis['highlights'] as Map<String, dynamic>;
    }

    switch (data.timeFrame.toLowerCase()) {
      case 'last_week':
        sectionTitle = 'Daily Breakdown';
        sectionSubtitle = 'Day-by-day analysis of the past week';
        if (detailedAnalysis.containsKey('daily_breakdown')) {
          breakdownItems = List<Map<String, dynamic>>.from(
              detailedAnalysis['daily_breakdown']);
        }
        break;
      case 'last_month':
        sectionTitle = 'Weekly Breakdown';
        sectionSubtitle = 'Week-by-week analysis of the past month';
        if (detailedAnalysis.containsKey('weekly_breakdown')) {
          breakdownItems = List<Map<String, dynamic>>.from(
              detailedAnalysis['weekly_breakdown']);
        }
        break;
      case 'last_quarter':
        sectionTitle = 'Monthly Breakdown';
        sectionSubtitle = 'Month-by-month analysis of the past quarter';
        if (detailedAnalysis.containsKey('monthly_breakdown')) {
          breakdownItems = List<Map<String, dynamic>>.from(
              detailedAnalysis['monthly_breakdown']);
        }
        break;
      case 'last_year':
        sectionTitle = 'Monthly Breakdown';
        sectionSubtitle = 'Month-by-month analysis of the past year';
        if (detailedAnalysis.containsKey('monthly_breakdown')) {
          breakdownItems = List<Map<String, dynamic>>.from(
              detailedAnalysis['monthly_breakdown']);
        }
        break;
      default:
        sectionTitle = 'Period Breakdown';
        sectionSubtitle = 'Detailed analysis of your cash flow';
        for (final key in [
          'daily_breakdown',
          'weekly_breakdown',
          'monthly_breakdown'
        ]) {
          if (detailedAnalysis.containsKey(key)) {
            breakdownItems =
                List<Map<String, dynamic>>.from(detailedAnalysis[key]);
            break;
          }
        }
    }

    if (breakdownItems.isEmpty) {
      return Container();
    }

    // Sort breakdownItems in descending order (most recent first)
    // Try to extract dates from 'period' or 'start_date' fields
    breakdownItems.sort((a, b) {
      DateTime dateA = _extractDateFromBreakdownItem(a);
      DateTime dateB = _extractDateFromBreakdownItem(b);
      return dateB.compareTo(dateA); // Descending order
    });

    dev.log(
        "Sorted breakdownItems periods: ${breakdownItems.map((item) => item['period'] ?? '').join(', ')}");

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                child: const AnimatedEmoji(
                  AnimatedEmojis.fire,
                  size: 24,
                  repeat: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
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
                      sectionSubtitle,
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
          if (highlights != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0078D4)
                    .withOpacity(isDarkMode ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0078D4)
                      .withOpacity(isDarkMode ? 0.1 : 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highlights',
                    style: TextStyle(
                      color: const Color(0xFF0078D4),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (highlights.containsKey('highest_inflow'))
                    _buildHighlightItem(
                      context,
                      'Highest Inflow',
                      highlights['highest_inflow']['formatted_amount']
                              ?.toString() ??
                          '',
                      highlights['highest_inflow']['period']?.toString() ?? '',
                      Icons.arrow_upward_rounded,
                      Colors.green,
                      isDarkMode,
                    ),
                  if (highlights.containsKey('highest_outflow'))
                    _buildHighlightItem(
                      context,
                      'Highest Outflow',
                      highlights['highest_outflow']['formatted_amount']
                              ?.toString() ??
                          '',
                      highlights['highest_outflow']['period']?.toString() ?? '',
                      Icons.arrow_downward_rounded,
                      Colors.red,
                      isDarkMode,
                    ),
                  if (highlights.containsKey('lowest_net_flow'))
                    _buildHighlightItem(
                      context,
                      'Most Challenging',
                      highlights['lowest_net_flow']['formatted_amount']
                              ?.toString() ??
                          '',
                      highlights['lowest_net_flow']['period']?.toString() ?? '',
                      Icons.warning_amber_rounded,
                      Colors.amber,
                      isDarkMode,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breakdownItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 32,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final item = breakdownItems[index];
              final periodLabel = item['period'] ?? 'Unknown';
              final inflow = item['inflow'] is num
                  ? (item['inflow'] as num).toDouble()
                  : double.tryParse(item['inflow']?.toString() ?? '0') ?? 0.0;
              final outflow = item['outflow'] is num
                  ? (item['outflow'] as num).toDouble()
                  : double.tryParse(item['outflow']?.toString() ?? '0') ?? 0.0;
              final netFlow = inflow - outflow;
              final isPositive = netFlow >= 0;

              // Use formatted values if available
              final formattedInflow =
                  item['formatted_inflow'] ?? _formatCurrency(inflow);
              final formattedOutflow =
                  item['formatted_outflow'] ?? _formatCurrency(outflow);
              final formattedNetFlow =
                  item['formatted_net_flow'] ?? _formatCurrency(netFlow);

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
                                data.timeFrame.toLowerCase() == 'last_month' ||
                                        data.timeFrame.toLowerCase() == 'month'
                                    ? _formatDateRangeForMonthlyBreakdown(item)
                                    : periodLabel,
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
                                color: isPositive ? Colors.green : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                formattedNetFlow,
                                style: TextStyle(
                                  color: isPositive ? Colors.green : Colors.red,
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
                                      color: Colors.green,
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
                                          formattedInflow,
                                          style: TextStyle(
                                            color: Colors.green,
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
                                      color: Colors.red,
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
                                          formattedOutflow,
                                          style: TextStyle(
                                            color: Colors.red,
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
          if (detailedAnalysis.containsKey('totals')) ...[
            const SizedBox(height: 24),
            _buildTotalsSection(
                context, detailedAnalysis['totals'] as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightItem(
    BuildContext context,
    String title,
    String amount,
    String period,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                    height: 1.2,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$amount ($period)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
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
    );
  }

  Widget _buildTotalsSection(
      BuildContext context, Map<String, dynamic> totals) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final formattedTotalInflow = totals['formatted_total_inflow'] ??
        _formatCurrency((totals['total_inflow'] as num?)?.toDouble() ?? 0.0);
    final formattedTotalOutflow = totals['formatted_total_outflow'] ??
        _formatCurrency((totals['total_outflow'] as num?)?.toDouble() ?? 0.0);
    final formattedNetFlow = totals['formatted_net_flow'] ??
        _formatCurrency(((totals['total_inflow'] as num?)?.toDouble() ?? 0.0) -
            ((totals['total_outflow'] as num?)?.toDouble() ?? 0.0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF0078D4).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF0078D4).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Period Totals',
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF0078D4),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.2,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Inflow',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 13,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTotalInflow,
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Outflow',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 13,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTotalOutflow,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Cash Flow',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 13,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedNetFlow,
                      style: TextStyle(
                        color: ((totals['total_inflow'] as num?)?.toDouble() ??
                                    0.0) >=
                                ((totals['total_outflow'] as num?)
                                        ?.toDouble() ??
                                    0.0)
                            ? Colors.green
                            : Colors.red,
                        fontSize: 16,
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

  // Helper method to extract dates from breakdown items
  DateTime _extractDateFromBreakdownItem(Map<String, dynamic> item) {
    // Try to get date from start_date field
    if (item.containsKey('start_date') && item['start_date'] is String) {
      try {
        return DateTime.parse(item['start_date']);
      } catch (e) {
        // Parsing failed, continue to next method
      }
    }

    // Try to get date from period field which could be a date string
    if (item.containsKey('period') && item['period'] is String) {
      final period = item['period'] as String;
      try {
        // Try different date formats
        return DateTime.tryParse(period) ??
            DateFormat('MMMM yyyy').tryParse(period) ??
            _parsePeriodString(period);
      } catch (e) {
        // Parsing failed, continue to fallback
      }
    }

    // Fallback: return current date (items without dates will be sorted to the end)
    return DateTime.now();
  }

  DateTime _parsePeriodString(String period) {
    // Handle "Week X" format
    if (period.contains('Week')) {
      final weekMatch = RegExp(r'Week (\d+)').firstMatch(period);
      if (weekMatch != null) {
        final weekNum = int.parse(weekMatch.group(1)!);
        final monthYear = period.split(',').last.trim();
        final month = DateFormat('MMMM').parse(monthYear).month;
        final year = DateTime.now().year;
        return DateTime(year, month, (weekNum - 1) * 7 + 1);
      }
    }

    // Handle day names (Monday, Tuesday, etc.)
    for (int i = 1; i <= 7; i++) {
      final dayName = DateFormat('EEEE').format(DateTime(2023, 1, i));
      if (period.contains(dayName)) {
        // Extract the date part after the day name
        final datePart = period.split(',').last.trim();
        try {
          return DateFormat('MMM d').parse(datePart);
        } catch (e) {
          // If parsing fails, return a date with the correct day of week
          final now = DateTime.now();
          final dayOfWeek = DateFormat('EEEE').parse(dayName).weekday;
          final diff = dayOfWeek - now.weekday;
          return now.add(Duration(days: diff));
        }
      }
    }

    // Default fallback
    return DateTime.now();
  }

  // Helper method to format date range for monthly breakdown items
  String _formatDateRangeForMonthlyBreakdown(Map<String, dynamic> item) {
    // Check if period already contains a date range in parentheses
    if (item.containsKey('period') && item['period'] is String) {
      final period = item['period'] as String;

      // If format is "Week X (Date Range)" - extract just the date range without parentheses
      final parenthesesMatch = RegExp(r'\((.*?)\)').firstMatch(period);
      if (parenthesesMatch != null && parenthesesMatch.group(1) != null) {
        // Return just the date range without parentheses
        return parenthesesMatch.group(1)!;
      }
    }

    // Try to extract start date
    DateTime? startDate;
    if (item.containsKey('start_date') && item['start_date'] is String) {
      try {
        startDate = DateTime.parse(item['start_date']);
      } catch (e) {
        // Parsing failed, try other methods
      }
    }

    // If no start date, try to determine from period
    if (startDate == null &&
        item.containsKey('period') &&
        item['period'] is String) {
      final period = item['period'] as String;
      if (period.contains('Week')) {
        final weekMatch = RegExp(r'Week (\d+)').firstMatch(period);
        if (weekMatch != null) {
          final weekNum = int.parse(weekMatch.group(1)!);
          final monthYear = period.split(',').last.trim();
          try {
            final monthDate = DateFormat('MMMM').parse(monthYear);
            final month = monthDate.month;
            final year = DateTime.now().year;
            startDate = DateTime(year, month, (weekNum - 1) * 7 + 1);
          } catch (e) {
            // Parsing failed
          }
        }
      }
    }

    // If we couldn't determine the start date, return the original period
    if (startDate == null) {
      return item['period'] ?? 'Unknown Period';
    }

    // Calculate end date (typically 6 days after start for weekly periods)
    final endDate = startDate.add(const Duration(days: 6));

    // Format as "MMM d - MMM d" if in different months, or "MMM d-d" if same month
    if (startDate.month == endDate.month) {
      return '${DateFormat('MMM d').format(startDate)}-${DateFormat('d').format(endDate)}';
    } else {
      return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';
    }
  }
}

class SleekCashFlowChart extends StatefulWidget {
  final List<CashFlowTrend> trends;
  final bool isDarkMode;
  final String timeFrame;

  const SleekCashFlowChart({
    Key? key,
    required this.trends,
    required this.isDarkMode,
    required this.timeFrame,
  }) : super(key: key);

  @override
  SleekCashFlowChartState createState() => SleekCashFlowChartState();
}

class SleekCashFlowChartState extends State<SleekCashFlowChart> {
  int? _touchedIndex;
  bool _isInteracting = false;

  // Colors
  static const Color incomeColor = Color(0xFF4CAF50);
  static const Color expenseColor = Color(0xFFF44336);
  static const Color neutralColor = Color(0xFF0078D4);
  static const Color axisLabelColor = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;
    final gridColor = isDarkMode ? Colors.white24 : Colors.black12;

    // Calculate chart values
    double maxY = 0;
    for (var trend in widget.trends) {
      maxY = math.max(maxY, trend.inflow);
      maxY = math.max(maxY, trend.outflow);
      maxY = math.max(maxY, trend.netFlow.abs() * 1.2);
    }
    // Add less padding to better utilize the vertical space
    maxY *= 1.1;

    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isInteracting = true),
      onHorizontalDragEnd: (_) => setState(() => _isInteracting = false),
      onHorizontalDragUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPos = box.globalToLocal(details.globalPosition);

        if (localPos.dx < 0 || localPos.dx > box.size.width) return;

        // Calculate the index based on position, with precise alignment to data points
        final lastPointX =
            widget.trends.length > 1 ? box.size.width : box.size.width / 2;
        double percent = localPos.dx / lastPointX;
        percent = percent.clamp(0.0, 1.0);

        final indexDouble = percent * (widget.trends.length - 1);
        final int index = indexDouble.round();

        if (index >= 0 &&
            index < widget.trends.length &&
            _touchedIndex != index) {
          setState(() => _touchedIndex = index);
          HapticFeedback.selectionClick();
        }
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset localPos = box.globalToLocal(details.globalPosition);

        if (localPos.dx < 0 || localPos.dx > box.size.width) return;

        // Calculate the index based on position, with precise alignment to data points
        final lastPointX =
            widget.trends.length > 1 ? box.size.width : box.size.width / 2;
        double percent = localPos.dx / lastPointX;
        percent = percent.clamp(0.0, 1.0);

        final indexDouble = percent * (widget.trends.length - 1);
        final int index = indexDouble.round();

        setState(() {
          _touchedIndex = index;
          _isInteracting = true;
        });
      },
      onTapUp: (_) => setState(() => _isInteracting = false),
      onTapCancel: () => setState(() => _isInteracting = false),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
        child: Stack(
          children: [
            RepaintBoundary(
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (_) =>
                          [], // We'll use our custom tooltip
                    ),
                    handleBuiltInTouches: false,
                  ),
                  gridData: FlGridData(
                    show: false, // Remove all grid lines for a cleaner look
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false, // Remove top value display
                        reservedSize: 0,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget:
                          const SizedBox.shrink(), // Remove axis title
                      sideTitles: SideTitles(
                        showTitles: false, // Hide all bottom titles
                        reservedSize: 0,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget:
                          const SizedBox.shrink(), // Remove axis title
                      sideTitles: SideTitles(
                        showTitles: false, // Hide all left titles
                        reservedSize: 0,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false, // Remove border for a cleaner look
                  ),
                  minX: 0,
                  maxX: widget.trends.length - 1.toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    // Income Line
                    LineChartBarData(
                      spots: List.generate(widget.trends.length, (index) {
                        return FlSpot(
                            index.toDouble(), widget.trends[index].inflow);
                      }),
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: incomeColor.withOpacity(isDarkMode
                          ? 0.95
                          : 0.9), // Adjusted opacity based on theme
                      barWidth: 3.0, // Slightly refined width
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _touchedIndex != null && _isInteracting,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: index == _touchedIndex ? 6 : 0,
                          color: backgroundColor,
                          strokeWidth: 2.5,
                          strokeColor: incomeColor,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            incomeColor
                                .withOpacity(0.25), // More subtle gradient
                            incomeColor.withOpacity(0.08),
                            incomeColor.withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Expense Line
                    LineChartBarData(
                      spots: List.generate(widget.trends.length, (index) {
                        return FlSpot(
                            index.toDouble(), widget.trends[index].outflow);
                      }),
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: expenseColor.withOpacity(isDarkMode ? 0.95 : 0.9),
                      barWidth: 3.0,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: _touchedIndex != null && _isInteracting,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: index == _touchedIndex ? 6 : 0,
                          color: backgroundColor,
                          strokeWidth: 2.5,
                          strokeColor: expenseColor,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            expenseColor.withOpacity(0.15),
                            expenseColor.withOpacity(0.04),
                            expenseColor.withOpacity(0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    verticalLines: _touchedIndex != null && _isInteracting
                        ? [
                            VerticalLine(
                              x: _touchedIndex!.toDouble(),
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                              strokeWidth: 0.8,
                              dashArray: [4, 4],
                              label: VerticalLineLabel(
                                show: false, // Hide the default label
                                alignment: Alignment.topCenter,
                                padding: const EdgeInsets.only(bottom: 8),
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  fontFamily: 'Onest',
                                ),
                                labelResolver: (line) => DateFormat('MMM d')
                                    .format(widget.trends[_touchedIndex!].date),
                              ),
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            ),

            // Net Cash Flow Bars
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SleekNetCashFlowPainter(
                    trends: widget.trends,
                    maxY: maxY,
                    isDarkMode: isDarkMode,
                    highlightIndex: _isInteracting ? _touchedIndex : null,
                  ),
                ),
              ),
            ),

            // Data tooltip when interacting
            if (_touchedIndex != null && _isInteracting)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF202020) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: neutralColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: neutralColor,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM d, yyyy')
                                .format(widget.trends[_touchedIndex!].date),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTooltipItem(
                            'Income',
                            _formatCurrency(
                                widget.trends[_touchedIndex!].inflow),
                            incomeColor,
                            isDarkMode,
                          ),
                          _buildTooltipItem(
                            'Expenses',
                            _formatCurrency(
                                widget.trends[_touchedIndex!].outflow),
                            expenseColor,
                            isDarkMode,
                          ),
                          _buildTooltipItem(
                            'Net',
                            _formatCurrency(
                                widget.trends[_touchedIndex!].netFlow),
                            widget.trends[_touchedIndex!].netFlow >= 0
                                ? incomeColor
                                : expenseColor,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipItem(
      String label, String value, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    switch (widget.timeFrame.toLowerCase()) {
      case 'last_week':
      case 'week':
        return DateFormat('E').format(date); // Mon, Tue, etc.
      case 'last_month':
      case 'month':
        return DateFormat('d').format(date); // 1, 2, etc.
      case 'last_quarter':
      case 'quarter':
        return DateFormat('MMM').format(date); // Jan, Feb, etc.
      case 'last_year':
      case 'year':
        return DateFormat('MMM').format(date); // Jan, Feb, etc.
      default:
        return DateFormat('M/d').format(date);
    }
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${value.toInt()}';
    }
  }

  String _getXAxisTitle() {
    switch (widget.timeFrame.toLowerCase()) {
      case 'last_week':
      case 'week':
        return 'Day of Week';
      case 'last_month':
      case 'month':
        return 'Day of Month';
      case 'last_quarter':
      case 'quarter':
        return 'Month';
      case 'last_year':
      case 'year':
        return 'Month';
      default:
        return 'Time Period';
    }
  }
}

class SleekNetCashFlowPainter extends CustomPainter {
  final List<CashFlowTrend> trends;
  final double maxY;
  final bool isDarkMode;
  final int? highlightIndex;

  SleekNetCashFlowPainter({
    required this.trends,
    required this.maxY,
    required this.isDarkMode,
    this.highlightIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Adjust horizontal padding to better match FL Chart's internal spacing
    // This is the key to perfect alignment with line chart points
    final double horizontalPadding =
        size.width * 0.04; // Adjusted from 0.03 to 0.04
    final double availableWidth = size.width - (horizontalPadding * 2);

    // Fixed bar width for consistency - reduced for more compact look
    final double pointSpacing = trends.length > 1
        ? availableWidth / (trends.length - 1)
        : availableWidth;
    final double barWidth = math.min(pointSpacing * 0.3, 12.0);

    for (int i = 0; i < trends.length; i++) {
      final trend = trends[i];
      final netFlow = trend.netFlow;
      final isHighlighted = highlightIndex == i;

      // Skip very small values that would be barely visible
      if (netFlow.abs() / maxY < 0.01) continue;

      // Enhanced colors based on net flow direction and highlight status
      final bool isPositive = netFlow >= 0;
      final Color baseColor = isPositive
          ? const Color(0xFF4CAF50) // Green
          : const Color(0xFFE57373); // Lighter red for better visibility

      // Calculate precise x position that aligns with line chart points
      double xCenter;
      if (trends.length > 1) {
        // For perfect alignment with line chart points
        final double normalizedPosition = i / (trends.length - 1);
        xCenter = horizontalPadding + (normalizedPosition * availableWidth);
      } else {
        // Center the single bar
        xCenter = size.width / 2;
      }

      // Use the full height with a small buffer at the bottom
      final double scale = 0.85; // Use more vertical space
      final barHeight = (netFlow.abs() / maxY) * size.height * scale;
      final left = xCenter - (barWidth / 2);
      final top = size.height - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      // Create a more rounded rectangle for a modern look
      final radius = Radius.circular(barWidth / 3);
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: radius,
        topRight: radius,
      );

      // Enhanced shadow for highlighted bar
      if (isHighlighted) {
        final shadowPaint = Paint()
          ..color = baseColor.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(left - 2, top - 3, barWidth + 4, barHeight + 3),
              topLeft: radius,
              topRight: radius,
            ),
            shadowPaint);
      }

      // Draw the bar with enhanced gradient
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            baseColor.withOpacity(isHighlighted ? 0.9 : 0.7),
            baseColor.withOpacity(isHighlighted ? 0.7 : 0.5),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, barPaint);

      // Add an elegant highlight to the top edge for all bars
      final highlightPaint = Paint()
        ..color = baseColor.withOpacity(isHighlighted ? 0.95 : 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawRRect(rrect, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final SleekNetCashFlowPainter old = oldDelegate as SleekNetCashFlowPainter;
    return old.trends != trends ||
        old.maxY != maxY ||
        old.isDarkMode != isDarkMode ||
        old.highlightIndex != highlightIndex;
  }
}

// Helper function for currency formatting
String _formatCurrency(double value) {
  final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  return formatter.format(value);
}
