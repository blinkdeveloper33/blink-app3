import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class VolatilityDetails extends StatelessWidget {
  final double volatility;
  final String timeFrame;
  final bool isDarkMode;

  static const azureBlue = Color(0xFF0078D4);

  const VolatilityDetails({
    Key? key,
    required this.volatility,
    required this.timeFrame,
    required this.isDarkMode,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required double volatility,
    required String timeFrame,
    required bool isDarkMode,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) => VolatilityDetails(
        volatility: volatility,
        timeFrame: timeFrame,
        isDarkMode: isDarkMode,
      ),
    );
  }

  String _getVolatilityLevel(double volatility) {
    if (volatility < 0.15) {
      return 'Low';
    } else if (volatility < 0.30) {
      return 'Medium';
    } else {
      return 'High';
    }
  }

  Color _getVolatilityColor(double volatility) {
    if (volatility < 0.15) {
      return Colors.green[400] ?? Colors.green;
    } else if (volatility < 0.30) {
      return Colors.orange[400] ?? Colors.orange;
    } else {
      return Colors.red[400] ?? Colors.red;
    }
  }

  String _getVolatilityDescription(double volatility) {
    if (volatility < 0.15) {
      return 'Your cash flow shows consistent and predictable patterns, indicating stable financial management.';
    } else if (volatility < 0.30) {
      return 'Your cash flow shows moderate fluctuations. Consider strategies to stabilize income and expenses.';
    } else {
      return 'Your cash flow shows significant variations. Review your financial patterns to identify areas for stabilization.';
    }
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
                      'Understanding Volatility',
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
                'Volatility measures how much your cash flow fluctuates over time. Lower volatility indicates more stable and predictable finances.',
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
                title: 'Low Volatility (<15%)',
                description: 'Stable cash flow with predictable patterns',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.warning_amber_rounded,
                color: Colors.orange[400]!,
                title: 'Medium Volatility (15-30%)',
                description: 'Moderate fluctuations in cash flow',
                isDarkMode: isDarkMode,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.error_outline_rounded,
                color: Colors.red[400]!,
                title: 'High Volatility (>30%)',
                description: 'Significant variations that may need attention',
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
    final volatilityLevel = _getVolatilityLevel(volatility);
    final volatilityColor = _getVolatilityColor(volatility);
    final volatilityDescription = _getVolatilityDescription(volatility);

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
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: azureBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
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
                        'Cash Flow Volatility',
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

            // Main content
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
                  // Volatility gauge
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          volatilityColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: volatilityColor
                            .withOpacity(isDarkMode ? 0.2 : 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Volatility meter
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    width: constraints.maxWidth *
                                        (volatility.clamp(0.0, 1.0)),
                                    height: 12,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green[400]!,
                                          Colors.orange[400]!,
                                          Colors.red[400]!,
                                        ],
                                        stops: const [0.15, 0.3, 0.6],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  Positioned(
                                    left: constraints.maxWidth *
                                            (volatility.clamp(0.0, 1.0)) -
                                        2,
                                    top: -4,
                                    child: Container(
                                      width: 4,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Volatility percentage and level
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(volatility * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: volatilityColor,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: volatilityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: volatilityColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  volatilityLevel,
                                  style: TextStyle(
                                    color: volatilityColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 24),

                  // Volatility explanation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color:
                          volatilityColor.withOpacity(isDarkMode ? 0.1 : 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            volatilityColor.withOpacity(isDarkMode ? 0.2 : 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: volatilityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            volatility < 0.15
                                ? Icons.check_circle_outline_rounded
                                : volatility < 0.30
                                    ? Icons.warning_amber_rounded
                                    : Icons.error_outline_rounded,
                            color: volatilityColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$volatilityLevel Volatility',
                                style: TextStyle(
                                  color: volatilityColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                volatilityDescription,
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
    );
  }
}
