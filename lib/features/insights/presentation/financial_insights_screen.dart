import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/financial_data_provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/features/insights/presentation/widgets/expense_breakdown.dart';
import 'package:blink_app/features/insights/presentation/widgets/time_period_selector.dart';
import 'package:blink_app/features/insights/presentation/widgets/cash_flow_tab.dart';
import 'package:blink_app/models/time_period.dart';
import 'package:intl/intl.dart';

class FinancialInsightsScreen extends StatefulWidget {
  const FinancialInsightsScreen({super.key});

  @override
  State<FinancialInsightsScreen> createState() =>
      _FinancialInsightsScreenState();
}

class _FinancialInsightsScreenState extends State<FinancialInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimePeriod _selectedPeriod = TimePeriod.lastMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _loadData();
    }
  }

  String _getTimeFrame() {
    return _selectedPeriod.apiValue;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final provider = Provider.of<FinancialDataProvider>(context, listen: false);
    final timeFrame = _getTimeFrame();

    try {
      if (_tabController.index == 0) {
        await provider.loadExpenseData(timeFrame);
      } else {
        await provider.loadCashFlowData(timeFrame);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handlePeriodChanged(TimePeriod period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF0A0A0C) : const Color(0xFFFAFAFC),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [
                          const Color(0xFF1A1B1E),
                          const Color(0xFF0A0A0C),
                        ]
                      : [
                          const Color(0xFFF0F3F9),
                          const Color(0xFFFAFAFC),
                        ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header with back button
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                  child: Row(
                    children: [
                      // Back button with custom design
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.arrow_back_ios_rounded,
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Insights',
                              style: TextStyle(
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                fontFamily: 'Onest',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track your financial health',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.black45,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TimePeriodSelector(
                        selectedPeriod: _selectedPeriod,
                        onPeriodChanged: _handlePeriodChanged,
                        isDarkMode: isDarkMode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Custom tab bar with glass effect
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withAlpha(10)
                        : Colors.white.withAlpha(150),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withAlpha(15)
                          : Colors.black.withAlpha(10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withAlpha(50)
                            : Colors.black.withAlpha(5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: isDarkMode
                              ? Colors.white
                              : const Color(0xFF2D3142),
                          unselectedLabelColor: isDarkMode
                              ? Colors.white.withOpacity(0.5)
                              : const Color(0xFF2D3142).withOpacity(0.5),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            fontFamily: 'Onest',
                            letterSpacing: -0.2,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            fontFamily: 'Onest',
                            letterSpacing: -0.2,
                          ),
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? const Color(0xFF0078D4).withOpacity(0.2)
                                    : const Color(0xFF0078D4).withOpacity(0.15),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDarkMode
                                  ? [
                                      const Color(0xFF0078D4).withOpacity(0.3),
                                      const Color(0xFF0078D4).withOpacity(0.1),
                                    ]
                                  : [
                                      const Color(0xFF0078D4).withOpacity(0.15),
                                      const Color(0xFF0078D4).withOpacity(0.05),
                                    ],
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          splashBorderRadius: BorderRadius.circular(25),
                          overlayColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              return states.contains(MaterialState.focused)
                                  ? null
                                  : Colors.transparent;
                            },
                          ),
                          tabs: [
                            _buildTab('Expenses', 0),
                            _buildTab('Cash Flow', 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Content area
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildExpensesTab(
                          isDarkMode, MediaQuery.of(context).size.width < 600),
                      _buildCashFlowTab(isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesTab(bool isDarkMode, bool isSmallScreen) {
    final provider = context.watch<FinancialDataProvider>();
    final data = provider.categoryAnalysis?['data'];
    final isLoading = provider.expenseState == DataState.loading;
    final error = provider.expenseError;

    return isLoading
        ? _buildLoadingState(isDarkMode)
        : error != null
            ? _buildErrorState(error, isDarkMode)
            : data == null
                ? _buildEmptyState(isDarkMode)
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ExpenseBreakdown(
                          data: data,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 16 : 20),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0078D4),
                                  const Color(0xFF0078D4).withOpacity(0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0078D4).withOpacity(0.25),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, '/recurring-expenses');
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.repeat_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'View Recurring Expenses',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 15 : 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Onest',
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white70,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    const azureBlue = Color(0xFF0078D4);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: azureBlue.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              azureBlue.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1500),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value * 2 * 3.14159,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: azureBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.analytics_rounded,
                                  color: azureBlue,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    Text(
                      'Analyzing Your Finances',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preparing your financial insights',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black45,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
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

  Widget _buildErrorState(String error, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.red.withAlpha(30)
                    : Colors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: isDarkMode ? Colors.red.shade300 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withAlpha(10)
                    : Colors.black.withAlpha(5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 32,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for this period',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowTab(bool isDarkMode) {
    return Consumer<FinancialDataProvider>(
      builder: (context, provider, child) {
        if (provider.cashFlowState == DataState.loading) {
          return _buildLoadingState(isDarkMode);
        }

        if (provider.cashFlowState == DataState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.red.withAlpha(30)
                          : Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 32,
                      color: isDarkMode
                          ? Colors.red.shade300
                          : Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.cashFlowError ?? 'An error occurred',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.cashFlowData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withAlpha(10)
                          : Colors.black.withAlpha(5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      size: 32,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cash flow data available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return CashFlowTab(
          data: provider.cashFlowData!,
          isLoading: provider.cashFlowState == DataState.loading,
        );
      },
    );
  }

  Widget _buildTab(String text, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: _tabController.index == index ? 15 : 14,
                fontWeight: _tabController.index == index
                    ? FontWeight.w600
                    : FontWeight.w500,
                fontFamily: 'Onest',
                letterSpacing: -0.2,
                color: _tabController.index == index
                    ? (isDarkMode ? Colors.white : const Color(0xFF2D3142))
                    : (isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF2D3142).withOpacity(0.5)),
              ),
              child: Text(text),
            ),
          ),
          if (_tabController.index == index)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF0078D4)
                      .withOpacity(isDarkMode ? 0.7 : 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<FinancialDataProvider>(context);
    final trends = provider.cashFlowData?.trends ?? [];

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
                      'Detailed Analysis',
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
                      'Day-by-day breakdown of your cash flow',
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
            itemCount: trends.length,
            separatorBuilder: (context, index) => Divider(
              height: 32,
              color: isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final trend = trends[index];
              final isPositive = trend.netFlow >= 0;
              final date = DateFormat('MMM d, yyyy').format(trend.date);
              final dayOfWeek = DateFormat('EEEE').format(trend.date);

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
                                date,
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
                              const SizedBox(height: 2),
                              Text(
                                dayOfWeek,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black45,
                                  fontSize: 13,
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
                                _formatCurrency(trend.netFlow.abs()),
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
                                          _formatCurrency(trend.inflow),
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
                                          _formatCurrency(trend.outflow),
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }
}
