import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/recurring_expenses_provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/features/insights/domain/recurring_expense.dart';
import 'package:intl/intl.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:blink_app/features/insights/presentation/widgets/time_period_selector.dart';
import 'package:blink_app/models/time_period.dart';

class RecurringExpensesScreen extends StatefulWidget {
  const RecurringExpensesScreen({super.key});

  @override
  State<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecurringExpensesProvider>().loadRecurringExpenses();
    });
  }

  void _handlePeriodChanged(TimePeriod period) {
    if (!mounted) return;
    context.read<RecurringExpensesProvider>().setTimeFrame(period.toString());
    context.read<RecurringExpensesProvider>().loadRecurringExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<RecurringExpensesProvider>();
    final data = provider.recurringExpensesData;
    final isLoading = provider.isLoading;
    final error = provider.error;
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Recurring Expenses',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Onest',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TimePeriodSelector(
              selectedPeriod: TimePeriod.values.firstWhere(
                (p) => p.toString() == provider.timeFrame,
                orElse: () => TimePeriod.lastMonth,
              ),
              onPeriodChanged: _handlePeriodChanged,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
      body: isLoading
          ? _buildLoadingState()
          : error != null
              ? _buildErrorState(error)
              : data == null
                  ? _buildEmptyState()
                  : _buildContent(
                      data, isDarkMode, isSmallScreen, currencyFormatter),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<RecurringExpensesProvider>().loadRecurringExpenses();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'No Recurring Expenses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We haven\'t detected any recurring expenses yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RecurringExpensesData data, bool isDarkMode,
      bool isSmallScreen, NumberFormat formatter) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
              data.summary, data.totals, isDarkMode, isSmallScreen, formatter),
          _buildFrequencyBreakdown(
              data.totals, isDarkMode, isSmallScreen, formatter),
          _buildRecurringTransactionsList(
              data.frequencyGroups, isDarkMode, isSmallScreen, formatter),
          if (data.upcomingExpenses.isNotEmpty)
            _buildUpcomingExpensesTimeline(
                data.upcomingExpenses, isDarkMode, isSmallScreen, formatter),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Summary summary, Totals totals, bool isDarkMode,
      bool isSmallScreen, NumberFormat formatter) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Recurring',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black45,
                      fontSize: isSmallScreen ? 12 : 13,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(summary.totalMonthlyCommitment.abs()),
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: summary.unusualChanges > 0
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF0078D4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      summary.unusualChanges > 0
                          ? Icons.warning_rounded
                          : Icons.info_outline_rounded,
                      size: isSmallScreen ? 14 : 16,
                      color: summary.unusualChanges > 0
                          ? Colors.red
                          : const Color(0xFF0078D4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${summary.totalRecurringExpenses} recurring expenses',
                      style: TextStyle(
                        color: summary.unusualChanges > 0
                            ? Colors.red
                            : const Color(0xFF0078D4),
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem(
                  'Weekly',
                  totals.weekly.toInt(),
                  formatter.format(totals.weekly.abs()),
                  isDarkMode,
                  isSmallScreen,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200],
                ),
                _buildSummaryItem(
                  'Monthly',
                  totals.monthly.toInt(),
                  formatter.format(totals.monthly.abs()),
                  isDarkMode,
                  isSmallScreen,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200],
                ),
                _buildSummaryItem(
                  'Annual',
                  totals.annual.toInt(),
                  formatter.format(totals.annual.abs()),
                  isDarkMode,
                  isSmallScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, String amount,
      bool isDarkMode, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white60 : Colors.black45,
            fontSize: isSmallScreen ? 12 : 13,
            fontFamily: 'Onest',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Onest',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count items',
          style: TextStyle(
            color: isDarkMode ? Colors.white38 : Colors.black38,
            fontSize: isSmallScreen ? 11 : 12,
            fontFamily: 'Onest',
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyBreakdown(Totals totals, bool isDarkMode,
      bool isSmallScreen, NumberFormat formatter) {
    final frequencies = [
      {
        'label': 'Weekly',
        'amount': totals.weekly,
        'icon': Icons.calendar_view_week_rounded
      },
      {
        'label': 'Bi-Weekly',
        'amount': totals.biWeekly,
        'icon': Icons.calendar_view_month_rounded
      },
      {
        'label': 'Monthly',
        'amount': totals.monthly,
        'icon': Icons.calendar_today_rounded
      },
      {
        'label': 'Quarterly',
        'amount': totals.quarterly,
        'icon': Icons.calendar_view_day_rounded
      },
      {
        'label': 'Annual',
        'amount': totals.annual,
        'icon': Icons.calendar_month_rounded
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency Breakdown',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: frequencies.map((freq) {
                final amount = freq['amount'] as double;
                final label = freq['label'] as String;
                final icon = freq['icon'] as IconData;
                final hasValue = amount != 0;

                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color: hasValue
                                  ? (isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white)
                                  : (isDarkMode
                                      ? Colors.grey[900]!.withOpacity(0.5)
                                      : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: hasValue
                                        ? const Color(0xFF0078D4)
                                            .withOpacity(0.1)
                                        : (isDarkMode
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: hasValue
                                        ? const Color(0xFF0078D4)
                                        : (isDarkMode
                                            ? Colors.white38
                                            : Colors.grey[400]!),
                                    size: isSmallScreen ? 16 : 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasValue
                                      ? formatter.format(amount.abs())
                                      : '-',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTransactionsList(FrequencyGroups groups,
      bool isDarkMode, bool isSmallScreen, NumberFormat formatter) {
    final allGroups = [
      {'label': 'Weekly', 'items': groups.weekly},
      {'label': 'Bi-Weekly', 'items': groups.biWeekly},
      {'label': 'Monthly', 'items': groups.monthly},
      {'label': 'Quarterly', 'items': groups.quarterly},
      {'label': 'Annual', 'items': groups.annual},
    ]
        .where((group) =>
            (group['items'] as List<RecurringExpense>?)?.isNotEmpty ?? false)
        .toList();

    if (allGroups.isEmpty) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Recurring Transactions',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 16),
          ...allGroups.map((group) {
            final label = group['label'] as String;
            final items = group['items'] as List<RecurringExpense>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label (${items.length})',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: isSmallScreen ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 12),
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode ? Colors.grey[900] : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[200]!,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0078D4)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(item.category),
                                        color: const Color(0xFF0078D4),
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.merchant,
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: isSmallScreen ? 14 : 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Onest',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.category,
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white60
                                                  : Colors.black45,
                                              fontSize: isSmallScreen ? 12 : 13,
                                              fontFamily: 'Onest',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatter
                                              .format(item.recentAmount.abs()),
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                        if (item.hasUnusualChange) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.red.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item.amountChangePercent > 0 ? '+' : ''}${item.amountChangePercent.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize:
                                                    isSmallScreen ? 11 : 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Onest',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey[100]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: isSmallScreen ? 14 : 16,
                                            color: isDarkMode
                                                ? Colors.white60
                                                : Colors.black45,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Next: ${DateFormat('MMM d').format(item.nextExpectedDate)}',
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white60
                                                  : Colors.black45,
                                              fontSize: isSmallScreen ? 12 : 13,
                                              fontFamily: 'Onest',
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0078D4)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.confidence}% confidence',
                                          style: TextStyle(
                                            color: const Color(0xFF0078D4),
                                            fontSize: isSmallScreen ? 11 : 12,
                                            fontWeight: FontWeight.w500,
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
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'payment':
        return Icons.payment_rounded;
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'subscription':
        return Icons.subscriptions_rounded;
      case 'utilities':
        return Icons.lightbulb_outline_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transportation':
        return Icons.directions_car_rounded;
      case 'health':
        return Icons.medical_services_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'housing':
        return Icons.home_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Widget _buildUpcomingExpensesTimeline(List<RecurringExpense> upcomingExpenses,
      bool isDarkMode, bool isSmallScreen, NumberFormat formatter) {
    if (upcomingExpenses.isEmpty) {
      return Container();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Upcoming Expenses',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 16),
          ...upcomingExpenses.asMap().entries.map((entry) {
            final index = entry.key;
            final expense = entry.value;
            final isLast = index == upcomingExpenses.length - 1;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('MMM')
                                      .format(expense.nextExpectedDate),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white60
                                        : Colors.black45,
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                                Text(
                                  DateFormat('d')
                                      .format(expense.nextExpectedDate),
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Onest',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0078D4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey[900]!
                                        : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[200],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0078D4)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(expense.category),
                                      color: const Color(0xFF0078D4),
                                      size: isSmallScreen ? 16 : 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.merchant,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white
                                                : Colors.black87,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          expense.category,
                                          style: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white60
                                                : Colors.black45,
                                            fontSize: isSmallScreen ? 12 : 13,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatter
                                        .format(expense.recentAmount.abs()),
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Onest',
                                    ),
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }
}
