import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class GrowthRateDetails extends StatelessWidget {
  final double growthRate;
  final String timeFrame;
  final bool isDarkMode;
  final List<FlSpot> trendData;
  final double previousPeriodFlow;
  final double currentPeriodFlow;

  static const azureBlue = Color(0xFF0078D4);

  const GrowthRateDetails({
    Key? key,
    required this.growthRate,
    required this.timeFrame,
    required this.isDarkMode,
    required this.trendData,
    required this.previousPeriodFlow,
    required this.currentPeriodFlow,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required double growthRate,
    required String timeFrame,
    required bool isDarkMode,
    required List<FlSpot> trendData,
    required double previousPeriodFlow,
    required double currentPeriodFlow,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) => GrowthRateDetails(
        growthRate: growthRate,
        timeFrame: timeFrame,
        isDarkMode: isDarkMode,
        trendData: trendData,
        previousPeriodFlow: previousPeriodFlow,
        currentPeriodFlow: currentPeriodFlow,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: azureBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: azureBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Understanding Growth Rate',
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
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Growth Rate shows how your net cash flow has changed compared to the previous period. A positive rate means your financial health is improving.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                icon: Icons.trending_up_rounded,
                color: Colors.green[400]!,
                title: 'Positive Growth',
                description:
                    'Your net cash flow has increased from the previous period',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.trending_down_rounded,
                color: Colors.red[400]!,
                title: 'Negative Growth',
                description:
                    'Your net cash flow has decreased from the previous period',
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
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
    final isPositive = growthRate >= 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
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
              // Enhanced header with better spacing
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: azureBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: azureBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Growth Rate',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            fontFamily: 'Onest',
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => _showInfoDialog(context),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        backgroundColor: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(8),
                        backgroundColor: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main content with enhanced styling
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  children: [
                    // Growth rate indicator
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withOpacity(isDarkMode ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isPositive ? Colors.green : Colors.red)
                              .withOpacity(isDarkMode ? 0.2 : 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: isPositive
                                    ? Colors.green[400]
                                    : Colors.red[400],
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(growthRate * 100).abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: isPositive
                                      ? Colors.green[400]
                                      : Colors.red[400],
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  fontFamily: 'Onest',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isPositive
                                ? 'Increase from Previous Period'
                                : 'Decrease from Previous Period',
                            style: TextStyle(
                              color: isPositive
                                  ? Colors.green[400]
                                  : Colors.red[400],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Period comparison with visual indicator
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.03)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.04),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Previous Period',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatter.format(previousPeriodFlow),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.black.withOpacity(0.3),
                                  size: 24,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Current Period',
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      formatter.format(currentPeriodFlow),
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Growth visualization bar
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxWidth = constraints.maxWidth;
                                final ratio =
                                    currentPeriodFlow / previousPeriodFlow;
                                final growthWidth =
                                    (ratio.abs() * (maxWidth / 2))
                                        .clamp(0.0, maxWidth / 2);

                                return Stack(
                                  children: [
                                    Positioned(
                                      left: isPositive ? maxWidth / 2 : null,
                                      right: isPositive ? null : maxWidth / 2,
                                      child: Container(
                                        width: growthWidth,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isPositive
                                              ? Colors.green[400]
                                              : Colors.red[400],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Container(
                                        width: 2,
                                        height: 16,
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Impact summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red)
                            .withOpacity(isDarkMode ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isPositive ? Colors.green : Colors.red)
                              .withOpacity(isDarkMode ? 0.2 : 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (isPositive ? Colors.green : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPositive
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.priority_high_rounded,
                              color: isPositive
                                  ? Colors.green[400]
                                  : Colors.red[400],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPositive
                                      ? 'Positive Financial Trend'
                                      : 'Attention Needed',
                                  style: TextStyle(
                                    color: isPositive
                                        ? Colors.green[400]
                                        : Colors.red[400],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPositive
                                      ? 'Your financial health is improving'
                                      : 'Consider reviewing your expenses',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 14,
                                    height: 1.4,
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
            ],
          ),
        ),
      ),
    );
  }
}
