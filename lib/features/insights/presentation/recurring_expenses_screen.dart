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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
              padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [const Color(0xFF1F1F1F), const Color(0xFF2D2D2D)]
                      : [const Color(0xFF0078D4), const Color(0xFF00B2FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : const Color(0xFF0078D4).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isSmallScreen ? 12 : 13,
                              fontFamily: 'Onest',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatter.format(
                                    summary.totalMonthlyCommitment.abs()),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '/month',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontFamily: 'Onest',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: summary.unusualChanges > 0
                              ? Colors.red.withOpacity(0.2)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              summary.unusualChanges > 0
                                  ? Icons.warning_rounded
                                  : Icons.analytics_outlined,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${summary.totalRecurringExpenses} expenses',
                              style: TextStyle(
                                color: Colors.white,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          'Weekly',
                          totals.weekly.toInt(),
                          formatter.format(totals.weekly.abs()),
                          true,
                          isSmallScreen,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildSummaryItem(
                          'Monthly',
                          totals.monthly.toInt(),
                          formatter.format(totals.monthly.abs()),
                          true,
                          isSmallScreen,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildSummaryItem(
                          'Annual',
                          totals.annual.toInt(),
                          formatter.format(totals.annual.abs()),
                          true,
                          isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (summary.unusualChanges > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${summary.unusualChanges} unusual price changes detected this period',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
  }

  Widget _buildSummaryItem(String label, int count, String amount,
      bool isInColoredCard, bool isSmallScreen) {
    final Color textColor = isInColoredCard ? Colors.white : Colors.black87;
    final Color labelColor =
        isInColoredCard ? Colors.white.withOpacity(0.7) : Colors.black45;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: isSmallScreen ? 12 : 13,
            fontFamily: 'Onest',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: textColor,
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Onest',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count items',
          style: TextStyle(
            color: isInColoredCard
                ? Colors.white.withOpacity(0.5)
                : Colors.black38,
            fontSize: isSmallScreen ? 11 : 12,
            fontFamily: 'Onest',
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyBreakdown(Totals totals, bool isDarkMode,
      bool isSmallScreen, NumberFormat formatter) {
    // Get the maximum amount across all frequencies to calculate relative sizes
    final frequencies = [
      {
        'label': 'Weekly',
        'amount': totals.weekly,
        'icon': Icons.calendar_view_week_rounded,
        'gradient': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      },
      {
        'label': 'Bi-Weekly',
        'amount': totals.biWeekly,
        'icon': Icons.calendar_view_month_rounded,
        'gradient': [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      },
      {
        'label': 'Monthly',
        'amount': totals.monthly,
        'icon': Icons.calendar_today_rounded,
        'gradient': [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
      },
      {
        'label': 'Quarterly',
        'amount': totals.quarterly,
        'icon': Icons.calendar_view_day_rounded,
        'gradient': [const Color(0xFFF83600), const Color(0xFFF9D423)],
      },
      {
        'label': 'Annual',
        'amount': totals.annual,
        'icon': Icons.calendar_month_rounded,
        'gradient': [const Color(0xFFFF0844), const Color(0xFFFFB199)],
      },
    ];

    double maxAmount = 0;
    for (final freq in frequencies) {
      if ((freq['amount'] as double) > maxAmount) {
        maxAmount = freq['amount'] as double;
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: isSmallScreen ? 14 : 16,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'By Frequency',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
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
          const SizedBox(height: 16),

          // Chart visualization
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: frequencies.map((freq) {
                final amount = freq['amount'] as double;
                final hasValue = amount > 0;
                final portion =
                    hasValue && maxAmount > 0 ? amount / maxAmount : 0.0;
                final width = portion * 100;
                final gradient = freq['gradient'] as List<Color>;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: width > 0
                      ? width * 0.9
                      : 0, // Adjust for proportionate display
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasValue
                          ? gradient
                          : [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.1)
                            ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Frequency cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: frequencies.asMap().entries.map((entry) {
                final index = entry.key;
                final freq = entry.value;
                final amount = freq['amount'] as double;
                final label = freq['label'] as String;
                final icon = freq['icon'] as IconData;
                final gradient = freq['gradient'] as List<Color>;
                final hasValue = amount > 0;

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            gradient: hasValue
                                ? LinearGradient(
                                    colors: [
                                      gradient[0]
                                          .withOpacity(isDarkMode ? 0.3 : 0.7),
                                      gradient[1]
                                          .withOpacity(isDarkMode ? 0.3 : 0.7)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: hasValue
                                ? null
                                : (isDarkMode
                                    ? Colors.grey[900]!.withOpacity(0.5)
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[200]!,
                            ),
                            boxShadow: hasValue
                                ? [
                                    BoxShadow(
                                      color: gradient[0]
                                          .withOpacity(isDarkMode ? 0.1 : 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: hasValue
                                          ? Colors.white.withOpacity(0.2)
                                          : (isDarkMode
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.grey[200]!),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: hasValue
                                          ? Colors.white
                                          : (isDarkMode
                                              ? Colors.white38
                                              : Colors.grey[400]!),
                                      size: isSmallScreen ? 16 : 18,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                label,
                                style: TextStyle(
                                  color: hasValue
                                      ? (isDarkMode
                                          ? Colors.white
                                          : Colors.white)
                                      : (isDarkMode
                                          ? Colors.white70
                                          : Colors.black54),
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                hasValue ? formatter.format(amount.abs()) : '-',
                                style: TextStyle(
                                  color: hasValue
                                      ? (isDarkMode
                                          ? Colors.white
                                          : Colors.white)
                                      : (isDarkMode
                                          ? Colors.white
                                          : Colors.black87),
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Onest',
                                ),
                              ),
                              if (hasValue) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${(amount / (totals.weekly + totals.biWeekly + totals.monthly + totals.quarterly + totals.annual) * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Onest',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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

    // Group expenses by date
    final Map<String, List<RecurringExpense>> groupedByDate = {};
    for (final expense in upcomingExpenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.nextExpectedDate);
      if (!groupedByDate.containsKey(dateKey)) {
        groupedByDate[dateKey] = [];
      }
      groupedByDate[dateKey]!.add(expense);
    }

    // Sort dates
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Expenses',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Onest',
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: isSmallScreen ? 14 : 16,
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Next 30 days',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
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

          // Date-grouped timeline
          ...sortedDates.asMap().entries.map((dateEntry) {
            final index = dateEntry.key;
            final dateKey = dateEntry.value;
            final dateExpenses = groupedByDate[dateKey]!;
            final date = DateTime.parse(dateKey);
            final isToday = DateTime.now().difference(date).inDays == 0;
            final isWithinWeek = DateTime.now().difference(date).inDays < 7;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF0078D4)
                              : (isDarkMode
                                  ? Colors.grey[800]
                                  : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isToday
                              ? 'Today'
                              : DateFormat('E, MMM d').format(date),
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : (isDarkMode
                                    ? Colors.white70
                                    : Colors.black54),
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ),
                      if (isWithinWeek && !isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.purple.withOpacity(0.2)
                                : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'This week',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: isSmallScreen ? 10 : 11,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Expenses for this date
                ...dateExpenses.asMap().entries.map((expenseEntry) {
                  final expenseIndex = expenseEntry.key;
                  final expense = expenseEntry.value;
                  final isLastInGroup = expenseIndex == dateExpenses.length - 1;

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + (expenseIndex * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            margin: EdgeInsets.only(
                                left: 30,
                                right: 0,
                                bottom: isLastInGroup ? 20 : 12),
                            child: Stack(
                              children: [
                                // Card with subtle shadow
                                Container(
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding:
                                      EdgeInsets.all(isSmallScreen ? 14 : 18),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0078D4)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getCategoryIcon(expense.category),
                                          color: const Color(0xFF0078D4),
                                          size: isSmallScreen ? 18 : 22,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
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
                                                fontSize:
                                                    isSmallScreen ? 15 : 16,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Onest',
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black45,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  expense.frequency,
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white60
                                                        : Colors.black45,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 13,
                                                    fontFamily: 'Onest',
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.event_outlined,
                                                  size: isSmallScreen ? 12 : 14,
                                                  color: isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black45,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormat('MMM d').format(
                                                      expense.nextExpectedDate),
                                                  style: TextStyle(
                                                    color: isDarkMode
                                                        ? Colors.white60
                                                        : Colors.black45,
                                                    fontSize:
                                                        isSmallScreen ? 12 : 13,
                                                    fontFamily: 'Onest',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formatter.format(
                                                expense.recentAmount.abs()),
                                            style: TextStyle(
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                              fontSize: isSmallScreen ? 15 : 16,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Onest',
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: expense.confidence > 80
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : (expense.confidence > 60
                                                      ? Colors.orange
                                                          .withOpacity(0.1)
                                                      : Colors.red
                                                          .withOpacity(0.1)),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${expense.confidence}% sure',
                                              style: TextStyle(
                                                color: expense.confidence > 80
                                                    ? Colors.green
                                                    : (expense.confidence > 60
                                                        ? Colors.orange
                                                        : Colors.red),
                                                fontSize:
                                                    isSmallScreen ? 11 : 12,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Onest',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Left connector line and dot
                                Positioned(
                                  left: -20,
                                  top: 0,
                                  bottom: 0,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 2,
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey[300],
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color(0xFF0078D4)
                                              : (isDarkMode
                                                  ? Colors.white38
                                                  : Colors.grey[400]),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDarkMode
                                                ? Colors.grey[900]!
                                                : Colors.white,
                                            width: 2,
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
              ],
            );
          }).toList(),

          // Add bottom padding to ensure content doesn't get cut off
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
