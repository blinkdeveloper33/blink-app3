import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class CashFlowRatioDetails extends StatelessWidget {
  final double cashFlowRatio;
  final String timeFrame;
  final bool isDarkMode;
  final double inflow;
  final double outflow;

  static const azureBlue = Color(0xFF0078D4);

  const CashFlowRatioDetails({
    Key? key,
    required this.cashFlowRatio,
    required this.timeFrame,
    required this.isDarkMode,
    required this.inflow,
    required this.outflow,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required double cashFlowRatio,
    required String timeFrame,
    required bool isDarkMode,
    required double inflow,
    required double outflow,
  }) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) =>
          CashFlowRatioDetails(
        cashFlowRatio: cashFlowRatio,
        timeFrame: timeFrame,
        isDarkMode: isDarkMode,
        inflow: inflow,
        outflow: outflow,
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
                      'Understanding Cash Flow Ratio',
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
                'Cash Flow Ratio shows how well your income covers your expenses. A ratio above 100% means you\'re saving money, while below 100% indicates you\'re spending more than you earn.',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow(
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green[400]!,
                title: 'Good Ratio (>100%)',
                description: 'Income comfortably covers expenses with savings',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.warning_amber_rounded,
                color: Colors.red[400]!,
                title: 'Poor Ratio (<100%)',
                description:
                    'Expenses exceed income, indicating potential financial stress',
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
    final isHealthy = cashFlowRatio >= 1.0;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: azureBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.pie_chart_rounded,
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
                        'Cash Flow Ratio',
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
                IconButton(
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
                const SizedBox(width: 8),
                IconButton(
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
              ],
            ),
            const SizedBox(height: 24),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Ratio',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          fontFamily: 'Onest',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: (isHealthy ? Colors.green : Colors.red)
                              .withOpacity(isDarkMode ? 0.15 : 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (isHealthy ? Colors.green : Colors.red)
                                .withOpacity(isDarkMode ? 0.2 : 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${(cashFlowRatio * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color:
                                isHealthy ? Colors.green[400] : Colors.red[400],
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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
                        width: 1,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    color: Colors.green[400],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  formatter.format(inflow),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Expenses',
                                  style: TextStyle(
                                    color: Colors.red[400],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  formatter.format(outflow),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: (isHealthy ? Colors.green : Colors.red)
                          .withOpacity(isDarkMode ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isHealthy ? Colors.green : Colors.red)
                            .withOpacity(isDarkMode ? 0.2 : 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isHealthy ? Colors.green : Colors.red)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isHealthy
                                ? Icons.check_circle_outline_rounded
                                : Icons.warning_amber_rounded,
                            color:
                                isHealthy ? Colors.green[400] : Colors.red[400],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isHealthy
                                ? 'Your income comfortably covers your expenses'
                                : 'Your expenses exceed your income',
                            style: TextStyle(
                              color: isHealthy
                                  ? Colors.green[400]
                                  : Colors.red[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              fontFamily: 'Onest',
                            ),
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
