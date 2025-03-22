import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:logger/logger.dart';
import 'dart:math' as math;

class ExpenseBreakdown extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDarkMode;
  final _logger = Logger();

  ExpenseBreakdown({
    super.key,
    required this.data,
    required this.isDarkMode,
  }) {
    _logger.d('ExpenseBreakdown initialized with raw data: $data');
  }

  String _getHistoricalLabel(String timeFrame) {
    switch (timeFrame) {
      case 'LAST_WEEK':
        return 'Last 7 Days';
      case 'LAST_MONTH':
        return 'Last 4 Weeks';
      case 'LAST_QUARTER':
        return 'Last 3 Months';
      case 'LAST_YEAR':
        return 'Last 12 Months';
      case 'ALL':
        return 'All Time';
      default:
        return 'Previous Period';
    }
  }

  String _getHistoricalKey(String timeFrame) {
    switch (timeFrame) {
      case 'LAST_WEEK':
        return 'lastWeek';
      case 'LAST_MONTH':
        return 'lastMonth';
      case 'LAST_QUARTER':
        return 'lastQuarter';
      case 'LAST_YEAR':
        return 'lastYear';
      case 'ALL':
        return 'all';
      default:
        return 'lastMonth';
    }
  }

  String _getTimeFrameLabel(String timeFrame) {
    if (data['period']?['label'] != null) {
      return data['period']['label'];
    }

    switch (timeFrame) {
      case 'LAST_WEEK':
        return 'Last 7 Days';
      case 'LAST_MONTH':
        return 'Last 4 Weeks';
      case 'LAST_QUARTER':
        return 'Last 3 Months';
      case 'LAST_YEAR':
        return 'Last 12 Months';
      case 'ALL':
        return 'All Time';
      default:
        return 'Current Period';
    }
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null || end == null) return '';

    try {
      final startDate = DateTime.parse(start);
      final endDate = DateTime.parse(end);
      final formatter = DateFormat('MMMM d, y');
      return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
    } catch (e) {
      _logger.e('Error formatting date range: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('Raw data structure: $data');

    final categories =
        (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalSpending = data['totalSpending'] is String
        ? double.tryParse(data['totalSpending'].toString()) ?? 0.0
        : (data['totalSpending'] as num?)?.toDouble() ?? 0.0;
    final timeFrame = data['timeFrame'] as String? ?? 'LAST_MONTH';
    final period = data['period'] as Map<String, dynamic>? ?? {};
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Log the data for debugging
    _logger.d('ExpenseBreakdown build with data keys: ${data.keys}');
    _logger.d('Categories count: ${categories.length}');
    if (categories.isNotEmpty) {
      _logger.d('First category: ${categories.first}');
    }

    // Validate categories data and handle any unexpected structures
    final validCategories = categories
        .where((category) =>
            category != null &&
            category.containsKey('name') &&
            category.containsKey('percentage') &&
            category.containsKey('amount'))
        .toList();

    if (validCategories.length != categories.length) {
      _logger.w(
          'Found ${categories.length - validCategories.length} invalid categories, Valid: ${validCategories.length}, Total: ${categories.length}');
    }

    final theme = Theme.of(context).copyWith(
      primaryColor: const Color(0xFF0078D4),
    );

    return Theme(
      data: theme,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, timeFrame, period),
                  SizedBox(height: isSmallScreen ? 24 : 32),
                  _buildTotalSpendingCard(
                      totalSpending, currencyFormatter, timeFrame, context),
                  if (validCategories.isNotEmpty) ...[
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildPieChartSection(
                        validCategories, totalSpending, context),
                  ] else if (categories.isNotEmpty) ...[
                    // Try with original categories as fallback
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildPieChartSection(categories, totalSpending, context),
                  ] else ...[
                    const SizedBox(height: 40),
                    _buildEmptyState(
                        "No spending data available for this period"),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String timeFrame, Map<String, dynamic> period) {
    final dateRange = _formatDateRange(
        period['startDate'] as String?, period['endDate'] as String?);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0078D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedEmoji(
                    AnimatedEmojis.moneyWithWings,
                    size: 22,
                    repeat: true,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expense Analysis',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: isSmallScreen ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Onest',
                        ),
                      ),
                      if (dateRange.isNotEmpty)
                        Text(
                          dateRange,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white60 : Colors.black45,
                            fontSize: isSmallScreen ? 12 : 13,
                            fontFamily: 'Onest',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSpendingCard(double totalSpending, NumberFormat formatter,
      String timeFrame, BuildContext context) {
    const azureBlue = Color(0xFF0078D4);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    azureBlue.withOpacity(0.9),
                    azureBlue,
                  ],
                  stops: const [0.2, 0.9],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: azureBlue.withOpacity(0.25),
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
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const AnimatedEmoji(
                          AnimatedEmojis.moneyWithWings,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Text(
                        'Total Spending',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: totalSpending),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Text(
                        formatter.format(value),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Onest',
                          letterSpacing: -1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChartSection(List<Map<String, dynamic>> categories,
      double totalSpending, BuildContext context) {
    // Log received data for debugging
    _logger.d(
        'Building pie chart section with ${categories.length} categories: $categories');

    if (categories.isEmpty) {
      _logger.w('No categories available for pie chart');
      return _buildEmptyState('No data available');
    }

    // Check the first category to see its structure for debugging
    if (categories.isNotEmpty) {
      _logger.d('First category structure: ${categories.first}');
      _logger.d(
          'First category properties: name=${categories.first['name']}, percentage=${categories.first['percentage']}, amount=${categories.first['amount']}');

      // Log all percentages to see distribution
      _logger.d(
          'Category percentages: ${categories.map((c) => "${c['name'] ?? 'Unknown'}: ${c['percentage']}").join(', ')}');

      // Calculate total percentage for verification
      final totalPercentage = categories.fold<double>(
          0.0,
          (sum, category) =>
              sum +
              (category['percentage'] is String
                  ? double.tryParse(category['percentage'] as String) ?? 0.0
                  : (category['percentage'] as num?)?.toDouble() ?? 0.0));
      _logger.d('Total percentage sum: $totalPercentage%');
    }

    // Filter out any null or invalid categories
    categories = categories
        .where((category) =>
            category != null &&
            category.containsKey('name') &&
            category.containsKey('percentage'))
        .toList();

    if (categories.isEmpty) {
      _logger.w('No valid categories after filtering');
      return _buildEmptyState('No valid data available');
    }

    categories.sort((a, b) {
      // Safely convert percentage values to double regardless of whether they're strings or numbers
      final percentageA = a['percentage'] is String
          ? double.tryParse(a['percentage'] as String) ?? 0.0
          : (a['percentage'] as num).toDouble();

      final percentageB = b['percentage'] is String
          ? double.tryParse(b['percentage'] as String) ?? 0.0
          : (b['percentage'] as num).toDouble();

      return percentageB.compareTo(percentageA);
    });
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.pie_chart_outline_rounded,
                          color: const Color(0xFF2196F3),
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Text(
                        'Spending Distribution',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 20 : 24),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: isSmallScreen ? 28 : 32,
                          child: Row(
                            children: categories.map((category) {
                              final percentage = category['percentage']
                                      is String
                                  ? double.tryParse(
                                          category['percentage'] as String) ??
                                      0.0
                                  : (category['percentage'] as num?)
                                          ?.toDouble() ??
                                      0.0;
                              final name =
                                  category['name'] as String? ?? 'Other';
                              final color = _getCategoryColor(name);
                              return _buildBarSegment(
                                  context, category, percentage, color);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.2)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey[100]!,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: isSmallScreen ? 12 : 16,
                          runSpacing: isSmallScreen ? 12 : 16,
                          children: categories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final category = entry.value;
                            final name = category['name'] as String? ?? 'Other';
                            final percentage = category['percentage'] is String
                                ? double.tryParse(
                                        category['percentage'] as String) ??
                                    0.0
                                : (category['percentage'] as num?)
                                        ?.toDouble() ??
                                    0.0;
                            final color = _getCategoryColor(name);

                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration:
                                  Duration(milliseconds: 400 + (index * 100)),
                              curve: Curves.easeOutCubic,
                              builder: (context, itemValue, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - itemValue)),
                                  child: Opacity(
                                    opacity: itemValue,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        minWidth: (constraints.maxWidth -
                                                (isSmallScreen ? 36 : 48)) /
                                            2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 3,
                                            height: isSmallScreen ? 24 : 28,
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(
                                                  isDarkMode ? 0.8 : 1.0),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(
                                              width: isSmallScreen ? 8 : 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize:
                                                        isSmallScreen ? 13 : 14,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Onest',
                                                  ),
                                                ),
                                                Text(
                                                  '${percentage.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    color: color.withOpacity(
                                                        isDarkMode ? 0.9 : 0.8),
                                                    fontSize:
                                                        isSmallScreen ? 12 : 13,
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
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedEmoji(
            AnimatedEmojis.moneyWithWings,
            size: 64,
            repeat: true,
          ),
          const SizedBox(height: 24),
          Text(
            'No Spending Data',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: isDarkMode ? Colors.white60 : Colors.black45,
              fontSize: 14,
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _createPieSections(
      List<dynamic> categories, double total) {
    _logger.i('Creating pie sections from ${categories.length} categories');
    _logger.d('Total spending for pie chart: $total');

    if (total <= 0 || categories.isEmpty) {
      _logger.w(
          'No data for pie chart - Total: $total, Categories: ${categories.length}');
      return [
        PieChartSectionData(
          color: Colors.grey.withOpacity(0.2),
          value: 100,
          title: 'No Data',
          radius: 100,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white60 : Colors.black54,
            fontFamily: 'Onest',
          ),
        ),
      ];
    }

    return categories.where((category) => category != null).map((category) {
      final name = category['name'] as String? ?? 'Unknown';
      final amount = category['amount'] is String
          ? double.tryParse(category['amount'] as String) ?? 0.0
          : (category['amount'] as num?)?.toDouble() ?? 0.0;
      final percentage = category['percentage'] is String
          ? double.tryParse(category['percentage'] as String) ?? 0.0
          : (category['percentage'] as num?)?.toDouble() ?? 0.0;

      _logger.d(
          'Creating pie section - Category: $name, Amount: $amount, Percentage: $percentage%');

      final color = _getCategoryColor(name);

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: percentage >= 5.0 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
          fontFamily: 'Onest',
        ),
        badgeWidget: percentage < 5.0
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontFamily: 'Onest',
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 0.8,
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    // Normalize category name for case-insensitive comparison
    final normalizedCategory = category.toLowerCase().trim();

    // Check for common category patterns
    if (normalizedCategory.contains('food') ||
        normalizedCategory.contains('dining') ||
        normalizedCategory.contains('restaurant') ||
        normalizedCategory.contains('grocery')) {
      return const Color(0xFF4CAF50); // Fresh Green
    } else if (normalizedCategory.contains('shop') ||
        normalizedCategory.contains('purchase') ||
        normalizedCategory.contains('retail')) {
      return const Color(0xFF2196F3); // Vibrant Blue
    } else if (normalizedCategory.contains('transport') ||
        normalizedCategory.contains('auto') ||
        normalizedCategory.contains('car') ||
        normalizedCategory.contains('gas')) {
      return const Color(0xFFFFA726); // Warm Orange
    } else if (normalizedCategory.contains('util') ||
        normalizedCategory.contains('bill') ||
        normalizedCategory.contains('service')) {
      return const Color(0xFF9C27B0); // Rich Purple
    } else if (normalizedCategory.contains('entertain') ||
        normalizedCategory.contains('recreation') ||
        normalizedCategory.contains('movie') ||
        normalizedCategory.contains('game')) {
      return const Color(0xFFE91E63); // Bright Pink
    } else if (normalizedCategory.contains('health') ||
        normalizedCategory.contains('medical') ||
        normalizedCategory.contains('doctor')) {
      return const Color(0xFF00BCD4); // Cyan
    } else if (normalizedCategory.contains('travel') ||
        normalizedCategory.contains('hotel') ||
        normalizedCategory.contains('flight')) {
      return const Color(0xFFFF5722); // Deep Orange
    } else if (normalizedCategory.contains('transfer') ||
        normalizedCategory.contains('payment')) {
      return const Color(0xFF8BC34A); // Light Green
    } else if (normalizedCategory.contains('education') ||
        normalizedCategory.contains('school')) {
      return const Color(0xFF3F51B5); // Indigo
    } else if (normalizedCategory.contains('uncategorized')) {
      return const Color(0xFF9E9E9E); // Gray
    } else {
      // Assign a color based on the first letter of the category for consistent coloring
      final firstLetter = normalizedCategory.isNotEmpty
          ? normalizedCategory[0].codeUnitAt(0)
          : 0;
      final colorSet = [
        const Color(0xFF42A5F5), // Blue
        const Color(0xFFFFA726), // Orange
        const Color(0xFF66BB6A), // Green
        const Color(0xFFEC407A), // Pink
        const Color(0xFF5C6BC0), // Indigo
        const Color(0xFF26C6DA), // Cyan
        const Color(0xFFAB47BC), // Purple
        const Color(0xFFEF5350), // Red
      ];
      return colorSet[firstLetter % colorSet.length];
    }
  }

  Widget _getCategoryEmoji(String category) {
    // Normalize category name for case-insensitive comparison
    final normalizedCategory = category.toLowerCase().trim();

    // Check for common category patterns
    if (normalizedCategory.contains('food') ||
        normalizedCategory.contains('dining') ||
        normalizedCategory.contains('restaurant')) {
      return const AnimatedEmoji(AnimatedEmojis.hotBeverage);
    } else if (normalizedCategory.contains('shop') ||
        normalizedCategory.contains('purchase') ||
        normalizedCategory.contains('retail')) {
      return const AnimatedEmoji(AnimatedEmojis.sparkles);
    } else if (normalizedCategory.contains('transport') ||
        normalizedCategory.contains('auto') ||
        normalizedCategory.contains('car')) {
      return const AnimatedEmoji(AnimatedEmojis.bicycle);
    } else if (normalizedCategory.contains('util') ||
        normalizedCategory.contains('bill') ||
        normalizedCategory.contains('service')) {
      return const AnimatedEmoji(AnimatedEmojis.lightBulb);
    } else if (normalizedCategory.contains('entertain') ||
        normalizedCategory.contains('recreation')) {
      return const AnimatedEmoji(AnimatedEmojis.mirrorBall);
    } else if (normalizedCategory.contains('health') ||
        normalizedCategory.contains('medical')) {
      return const AnimatedEmoji(AnimatedEmojis.sparkles);
    } else if (normalizedCategory.contains('travel') ||
        normalizedCategory.contains('hotel') ||
        normalizedCategory.contains('flight')) {
      return const AnimatedEmoji(AnimatedEmojis.airplaneDeparture);
    } else if (normalizedCategory.contains('transfer') ||
        normalizedCategory.contains('payment')) {
      return const AnimatedEmoji(AnimatedEmojis.moneyWithWings);
    } else if (normalizedCategory.contains('education') ||
        normalizedCategory.contains('school')) {
      return const AnimatedEmoji(AnimatedEmojis.sparkles);
    } else if (normalizedCategory.contains('uncategorized')) {
      return const AnimatedEmoji(AnimatedEmojis.moneyWithWings);
    } else {
      return const AnimatedEmoji(AnimatedEmojis.moneyWithWings);
    }
  }

  Widget _buildBarSegment(BuildContext context, Map<String, dynamic> category,
      double percentage, Color color) {
    final amount = category['amount'] is String
        ? double.tryParse(category['amount'] as String) ?? 0.0
        : (category['amount'] as num?)?.toDouble() ?? 0.0;
    final name = category['name'] as String? ?? 'Other';
    final transactionCount = category['transactionCount'] is String
        ? int.tryParse(category['transactionCount'] as String) ?? 0
        : (category['transactionCount'] as int?) ?? 0;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Ensure minimum flex value for better visibility of small segments
    // Use at least 1 and add a small minimum width for tiny percentages
    final flexValue = math.max((percentage * 100).round(), 3);

    return Expanded(
      flex: flexValue,
      child: GestureDetector(
        onLongPressStart: (details) async {
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.heavyImpact();

          if (!context.mounted) return;

          showDialog(
            context: context,
            barrierColor: Colors.black54,
            builder: (BuildContext context) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        width: isSmallScreen ? 280 : 300,
                        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 10 : 12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _getCategoryEmoji(name),
                                ),
                                SizedBox(width: isSmallScreen ? 12 : 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: isSmallScreen ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$transactionCount transaction${transactionCount != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black45,
                                          fontSize: isSmallScreen ? 13 : 14,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        'Amount',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black45,
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        formatter.format(amount),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: isSmallScreen ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: color.withOpacity(0.2),
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        'Percentage',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white60
                                              : Colors.black45,
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontFamily: 'Onest',
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: isSmallScreen ? 18 : 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Onest',
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
                    ),
                  );
                },
              );
            },
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.7 : 0.9),
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.black12 : Colors.white,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
