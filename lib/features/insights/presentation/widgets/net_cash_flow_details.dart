import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NetCashFlowDetails extends StatelessWidget {
  final double netCashFlow;
  final double trend;
  final bool isPositiveTrend;
  final String timeFrame;
  final List<FlSpot> trendData;
  final bool isDarkMode;

  static const azureBlue = Color(0xFF0078D4);

  const NetCashFlowDetails({
    Key? key,
    required this.netCashFlow,
    required this.trend,
    required this.isPositiveTrend,
    required this.timeFrame,
    required this.trendData,
    required this.isDarkMode,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required double netCashFlow,
    required double trend,
    required bool isPositiveTrend,
    required String timeFrame,
    required List<FlSpot> trendData,
    required bool isDarkMode,
  }) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          NetCashFlowDetails(
        netCashFlow: netCashFlow,
        trend: trend,
        isPositiveTrend: isPositiveTrend,
        timeFrame: timeFrame,
        trendData: trendData,
        isDarkMode: isDarkMode,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutExpo,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * curvedAnimation.value,
            sigmaY: 8 * curvedAnimation.value,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: curvedAnimation,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: azureBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: azureBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Understanding Net Cash Flow',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Net Cash Flow shows the difference between your money coming in (inflow) and going out (outflow) during this period.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.arrow_upward_rounded,
                color: Colors.green[400]!,
                title: 'Cash Inflow',
                description:
                    'Money coming in from income, transfers, and deposits',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.arrow_downward_rounded,
                color: Colors.red[400]!,
                title: 'Cash Outflow',
                description: 'Money going out through expenses and withdrawals',
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                  fontSize: 13,
                  height: 1.4,
                  fontFamily: 'Onest',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Sample data - replace with actual data from your model
    final inflow = netCashFlow.abs();
    final outflow = netCashFlow.abs() * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with improved spacing
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: azureBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: azureBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Net Cash ',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                fontFamily: 'Onest',
                              ),
                            ),
                            TextSpan(
                              text: 'Flow',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                fontFamily: 'Onest',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeFrame,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                          height: 1.2,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showInfoDialog(context),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cash Flow Summary with enhanced styling
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  // Net Cash Flow Amount with improved contrast
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Cash Flow',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                          height: 1.2,
                          fontFamily: 'Onest',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: (netCashFlow >= 0 ? Colors.green : Colors.red)
                              .withOpacity(isDarkMode ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          formatter.format(netCashFlow),
                          style: TextStyle(
                            color: netCashFlow >= 0
                                ? Colors.green[400]
                                : Colors.red[400],
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Enhanced Bar Chart
                  SizedBox(
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: [inflow, outflow].reduce(
                                  (max, value) => max > value ? max : value) *
                              1.2,
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) {
                                  final text =
                                      value == 0 ? 'Inflow' : 'Outflow';
                                  final color = value == 0
                                      ? Colors.green[400]
                                      : Colors.red[400];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 13,
                                        height: 1.2,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 80,
                                interval: (inflow / 4).roundToDouble(),
                                getTitlesWidget: (value, meta) {
                                  if (value == 0)
                                    return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      formatter.format(value),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white60
                                            : Colors.black45,
                                        fontSize: 11,
                                        height: 1.2,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: inflow / 4,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchCallback: (FlTouchEvent event,
                                BarTouchResponse? touchResponse) {
                              if (touchResponse?.spot == null) return;

                              if (event is FlTapUpEvent ||
                                  event is FlLongPressStart) {
                                HapticFeedback.lightImpact();

                                final value =
                                    touchResponse!.spot!.touchedBarGroup.x == 0
                                        ? inflow
                                        : outflow;

                                Navigator.of(context).popUntil((route) {
                                  if (route.settings.name == 'tooltip_dialog') {
                                    return false;
                                  }
                                  return true;
                                });

                                final isLeftBar =
                                    touchResponse.spot!.touchedBarGroup.x == 0;
                                final chartPadding = 20.0;
                                final chartWidth =
                                    MediaQuery.of(context).size.width -
                                        (chartPadding * 2);
                                final barSpacing =
                                    chartWidth / 4; // Space between bars

                                final leftBarX = chartPadding + barSpacing;
                                final rightBarX =
                                    chartPadding + (barSpacing * 2.2);

                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  barrierDismissible: true,
                                  routeSettings: const RouteSettings(
                                      name: 'tooltip_dialog'),
                                  builder: (context) => Stack(
                                    children: [
                                      Positioned.fill(
                                        child: GestureDetector(
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          behavior: HitTestBehavior.translucent,
                                          child: Container(
                                            color: Colors.transparent,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 240,
                                        left: isLeftBar ? leftBarX : rightBarX,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            width: 120,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode
                                                  ? const Color(0xFF2D3142)
                                                      .withOpacity(0.98)
                                                  : Colors.white
                                                      .withOpacity(0.98),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDarkMode
                                                    ? Colors.white
                                                        .withOpacity(0.1)
                                                    : Colors.black
                                                        .withOpacity(0.05),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  touchResponse
                                                              .spot!
                                                              .touchedBarGroup
                                                              .x ==
                                                          0
                                                      ? 'Cash Inflow'
                                                      : 'Cash Outflow',
                                                  style: TextStyle(
                                                    color: touchResponse
                                                                .spot!
                                                                .touchedBarGroup
                                                                .x ==
                                                            0
                                                        ? Colors.green[400]
                                                        : Colors.red[400],
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    height: 1.2,
                                                    fontFamily: 'Onest',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  formatter.format(value.abs()),
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.2,
                                                    fontFamily: 'Onest',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: inflow,
                                  color: Colors.green[400],
                                  width: 50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: [inflow, outflow].reduce(
                                            (max, value) =>
                                                max > value ? max : value) *
                                        1.2,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.02),
                                  ),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: outflow,
                                  color: Colors.red[400],
                                  width: 50,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(6),
                                    topRight: Radius.circular(6),
                                  ),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: [inflow, outflow].reduce(
                                            (max, value) =>
                                                max > value ? max : value) *
                                        1.2,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.02),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Enhanced Trend Percentage
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.03)
                          : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          netCashFlow >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: netCashFlow >= 0
                              ? Colors.green[400]
                              : Colors.red[400],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(trend * 100).abs().toStringAsFixed(1)}% vs Previous Period',
                          style: TextStyle(
                            color: netCashFlow >= 0
                                ? Colors.green[400]
                                : Colors.red[400],
                            fontSize: 14,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Onest',
                          ),
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
    );
  }
}
