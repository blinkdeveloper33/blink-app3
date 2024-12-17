import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:blink_app/services/auth_service.dart' as auth;
import 'package:blink_app/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:blink_app/features/account/presentation/account_screen.dart';
import 'package:blink_app/features/blink_advance/presentation/blink_advance_screen.dart';
import 'package:blink_app/widgets/confetti_overlay.dart';
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart'
    as insights;
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final Logger _logger = Logger();
  bool _isDarkMode = false;
  final NumberFormat currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  List<auth.Transaction> _recentTransactions = [];
  double _currentBalance = 0.0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _userName = '';
  String _bankAccountId = '';
  String? _primaryAccountName;
  bool _isLoading = false;
  List<auth.DailyTransactionSummary> _dailyTransactionSummary = [];
  bool _isChartExpanded = false;
  bool _isChartLoading = false;
  bool _isBlinkAdvanceApproved = false;
  String _blinkAdvanceStatus = 'On Review';
  bool _isBlinkAdvanceLoading = false;
  bool _isBlinkAdvanceExpanded = false;
  bool _hasActiveAdvance = false;
  Map<String, dynamic>? _activeAdvance;

  final List<Map<String, String>> _newsItems = [
    {
      'title': 'Roth IRA vs. 401(k): What\'s the Difference?',
      'description':
          'Both Roth IRAs and 401(k)s are popular tax-advantaged retirement savings accounts that allow your savings to grow tax-free. Understanding the differences can help you choose the best option for your financial goals...',
      'imageUrl': 'assets/images/roth_ira_vs_401k.png',
    },
    {
      'title': 'The Basics of Budgeting: A Step-by-Step Guide',
      'description':
          'Creating and sticking to a budget is a fundamental step in managing your finances. This guide walks you through the process of setting up a budget that works for your lifestyle and financial goals...',
      'imageUrl': 'assets/images/budgeting_basics.png',
    },
    {
      'title': 'Understanding Credit Scores: What You Need to Know',
      'description':
          'Your credit score plays a crucial role in your financial life. Learn what factors influence your credit score, how to check it, and steps you can take to improve it over time...',
      'imageUrl': 'assets/images/credit_scores.png',
    },
    {
      'title': 'Investing for Beginners: Getting Started in the Stock Market',
      'description':
          'Thinking about investing in stocks? This article covers the basics of stock market investing, including how to open a brokerage account, understanding stock types, and strategies for beginners...',
      'imageUrl': 'assets/images/investing_beginners.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.reset();

    _loadData();
    _fetchAndStoreDetailedBankAccounts();
    _loadBlinkAdvanceStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([
      _loadUserInfo(),
      _loadRecentTransactions(),
      _loadCurrentBalances(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAndStoreDetailedBankAccounts() async {
    final authService = Provider.of<auth.AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      final detailedBankAccounts = await authService.getDetailedBankAccounts();
      if (detailedBankAccounts.isEmpty) {
        _logger.w('No detailed bank accounts found for the user.');
        return;
      }

      await storageService.setDetailedBankAccounts(detailedBankAccounts);
      _logger.i('Detailed bank accounts fetched and stored successfully');

      final primaryBankAccount = detailedBankAccounts.first;

      final bankAccountId = primaryBankAccount['bankAccountId'] as String?;
      if (bankAccountId != null && bankAccountId.isNotEmpty) {
        await storageService.setBankAccountId(bankAccountId);
        setState(() {
          _bankAccountId = bankAccountId;
        });
        _logger.i('Bank account ID updated: $bankAccountId');
      } else {
        _logger.w('Bank account ID is missing in bank account details.');
      }

      final primaryAccountName = primaryBankAccount['accountName'] as String?;
      if (primaryAccountName != null && primaryAccountName.isNotEmpty) {
        await storageService.setPrimaryAccountName(primaryAccountName);
        setState(() {
          _primaryAccountName = primaryAccountName;
        });
        _logger.i('Primary account name set: $primaryAccountName');
      } else {
        _logger.w('Primary account name is missing in bank account details.');
      }

      _animationController.reset();
      _animationController.forward();
    } catch (e) {
      _logger.e('Error fetching detailed bank accounts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to fetch bank account details. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    setState(() {
      _userName = storageService.getFullName() ?? 'User';
      _bankAccountId = storageService.getBankAccountId() ?? '';
      _primaryAccountName = storageService.getPrimaryAccountName();
    });
    _logger.i('User Info - Name: $_userName, Bank Account ID: $_bankAccountId');
  }

  Future<void> _loadRecentTransactions() async {
    final authService = Provider.of<auth.AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      final userId = storageService.getUserId();
      if (userId != null) {
        final transactions = await authService.getRecentTransactions(userId);
        setState(() {
          _recentTransactions = transactions;
        });
        _logger.i('Loaded recent transactions: $_recentTransactions');
      } else {
        throw Exception('User ID not found');
      }
    } catch (e) {
      _logger.e('Error loading recent transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to load recent transactions. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentBalances() async {
    final authService = Provider.of<auth.AuthService>(context, listen: false);

    try {
      final balances = await authService.getCurrentBalances();
      _logger.i('Balances Response: $balances');

      if (balances.isNotEmpty &&
          balances['accounts'] != null &&
          balances['accounts'] is List) {
        final accounts = List<Map<String, dynamic>>.from(balances['accounts']);
        if (accounts.isNotEmpty) {
          final firstAccount = accounts.first;
          final dynamic rawBalance = firstAccount['currentBalance'];
          double currentBalance = 0.0;

          if (rawBalance is int) {
            currentBalance = rawBalance.toDouble();
          } else if (rawBalance is double) {
            currentBalance = rawBalance;
          } else if (rawBalance is String) {
            currentBalance = double.tryParse(rawBalance) ?? 0.0;
            if (currentBalance == 0.0) {
              _logger
                  .w('Failed to parse currentBalance from String: $rawBalance');
            }
          } else {
            _logger.w(
                'Unexpected type for currentBalance: ${rawBalance.runtimeType}');
          }

          _logger.i('Extracted Current Balance: $currentBalance');

          setState(() {
            _currentBalance = currentBalance;
          });
          _logger.i('Loaded current balance: $_currentBalance');
          _animationController.reset();
          _animationController.forward();
        } else {
          _logger.w('No accounts found in balances.');
          setState(() {
            _currentBalance = 0.0;
          });
        }
      } else {
        _logger.w('No accounts information found in balances.');
        setState(() {
          _currentBalance = 0.0;
        });
      }
    } catch (e) {
      _logger.e('Error loading current balances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load current balances. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDailyTransactionSummary() async {
    if (_isChartLoading) return;

    setState(() {
      _isChartLoading = true;
    });

    final authService = Provider.of<auth.AuthService>(context, listen: false);

    try {
      final summary = await authService.getDailyTransactionSummary();
      setState(() {
        _dailyTransactionSummary = summary;
        _isChartLoading = false;
      });
      _logger.i('Loaded daily transaction summary: $_dailyTransactionSummary');
    } catch (e) {
      _logger.e('Error loading daily transaction summary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to load daily transaction summary. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isChartLoading = false;
      });
    }
  }

  Future<void> _loadBlinkAdvanceStatus() async {
    setState(() {
      _isBlinkAdvanceLoading = true;
    });

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final status = await authService.getBlinkAdvanceApprovalStatus();
      final activeAdvanceResponse = await authService.getActiveBlinkAdvance();

      setState(() {
        _isBlinkAdvanceApproved = status['isApproved'];
        _blinkAdvanceStatus = status['status'];
        _hasActiveAdvance = activeAdvanceResponse['hasActiveAdvance'];
        _activeAdvance = activeAdvanceResponse['activeAdvance'];
        _isBlinkAdvanceLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading Blink Advance status: $e');
      setState(() {
        _isBlinkAdvanceLoading = false;
        _blinkAdvanceStatus = 'Error';
        _hasActiveAdvance = false;
        _activeAdvance = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to load Blink Advance status. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String _getCreativeGreeting() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final random = Random();

    final greetings = [
      // Monday
      [
        "Monday blues? Let's turn them into green!",
        "New week, new financial goals!",
        "Monday: Your wallet's fresh start!",
        "Mondays are for money moves!",
        "Ready to rock this Money Monday?",
      ],
      // Tuesday
      [
        "Taco Tuesday or Saving Tuesday?",
        "Tuesday: The day your budget gets real!",
        "Two-sday: Double down on your savings!",
        "It's Choose-day: Choose to save!",
        "Tuesday: Small changes, big impacts!",
      ],
      // Wednesday
      [
        "Wednesday: Halfway to financial freedom!",
        "It's Hump Day for your money too!",
        "Wednesday wisdom: Save a little, earn a lot!",
        "Midweek money check: How're we doing?",
        "Wednesday: Your wallet's halftime show!",
      ],
      // Thursday
      [
        "Thursday: Almost payday, stay strong!",
        "Thrifty Thursday: Every penny counts!",
        "Thursday thought: What's your money doing?",
        "Pre-Friday financial check-in!",
        "Thursday: Budget's last stand before the weekend!",
      ],
      // Friday
      [
        "TGIF: Thank Goodness It's Financially savvy Friday!",
        "Friday fun doesn't have to break the bank!",
        "Friyay! Time to celebrate (responsibly)!",
        "Friday: Treat yourself, but don't cheat yourself!",
        "Weekend's here! Time for some R&R (Relaxation & Responsible spending)!",
      ],
      // Saturday
      [
        "Saturday: Spend time, not just money!",
        "Weekend vibes and smart financial decisions!",
        "Saturday's special: Free fun with friends!",
        "Savvy Saturday: Mix pleasure with financial leisure!",
        "Weekend warrior or weekend saver?",
      ],
      // Sunday
      [
        "Sunday: Plan your week, plan your wealth!",
        "Lazy Sunday? Your money never rests!",
        "Sunday funday: Enjoy life's free pleasures!",
        "Reflect, relax, and review your finances!",
        "Sunday: Your wallet's day of rest too!",
      ],
    ];

    return greetings[dayOfWeek - 1][random.nextInt(5)];
  }

  String _getDayContext() {
    return _getCreativeGreeting();
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF1C2A4D) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: _isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const AccountScreen()),
                    );
                  },
                  child: Hero(
                    tag: 'profilePicture',
                    child: FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            _isDarkMode ? Colors.white24 : Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: _isDarkMode ? Colors.white : Colors.black54,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        from: 20,
                        child: Text(
                          '${_getGreeting()}, ${_userName.split(' ')[0]}',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Onest',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        from: 20,
                        child: Text(
                          _getDayContext(),
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            fontFamily: 'Onest',
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_none,
                        color: _isDarkMode ? Colors.white : Colors.black54,
                        size: 28,
                      ),
                      onPressed: () {
                        // TODO: Implement notification screen navigation
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FadeIn(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 400),
                child: IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                    color: _isDarkMode ? Colors.white : Colors.black54,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF2C3E50) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Financial Summary",
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: AnimatedRotation(
                  turns: _isChartExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isChartExpanded = !_isChartExpanded;
                  });
                  if (_isChartExpanded && _dailyTransactionSummary.isEmpty) {
                    _loadDailyTransactionSummary();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Total Balance',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
              fontFamily: 'Onest',
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedBalance = _currentBalance * _animation.value;
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '\$',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 32,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          '${currencyFormatter.format(animatedBalance).split('.')[0].substring(1)}.',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 32,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: currencyFormatter
                          .format(animatedBalance)
                          .split('.')[1],
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontFamily: 'NunitoSans',
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Primary Account:',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _primaryAccountName ?? 'Not Available',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _isChartExpanded
                ? Column(
                    children: [
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: _isChartLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _isDarkMode ? Colors.white : Colors.blue,
                                  ),
                                ),
                              )
                            : _dailyTransactionSummary.isEmpty
                                ? Center(
                                    child: Text(
                                      'No transaction data available',
                                      style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 16,
                                        fontFamily: 'Onest',
                                      ),
                                    ),
                                  )
                                : LineChart(
                                    LineChartData(
                                      gridData: FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        bottomTitles: AxisTitles(
                                          sideTitles:
                                              SideTitles(showTitles: false),
                                        ),
                                        rightTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        topTitles: AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      minX: 0,
                                      maxX:
                                          (_dailyTransactionSummary.length - 1)
                                              .toDouble(),
                                      minY: _dailyTransactionSummary
                                          .map((e) => -e.totalAmount)
                                          .reduce(min),
                                      maxY: _dailyTransactionSummary
                                          .map((e) => -e.totalAmount)
                                          .reduce(max),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _dailyTransactionSummary
                                              .asMap()
                                              .entries
                                              .map((entry) => FlSpot(
                                                  entry.key.toDouble(),
                                                  -entry.value.totalAmount))
                                              .toList(),
                                          isCurved: true,
                                          color: _isDarkMode
                                              ? Colors.greenAccent
                                              : Colors.blue,
                                          barWidth: 3,
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(show: false),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            color: _isDarkMode
                                                ? Colors.greenAccent
                                                    .withOpacity(0.1)
                                                : Colors.blue.withOpacity(0.1),
                                          ),
                                        ),
                                      ],
                                      lineTouchData: LineTouchData(
                                        touchTooltipData: LineTouchTooltipData(
                                          fitInsideHorizontally: true,
                                          fitInsideVertically: true,
                                          getTooltipItems: (List<LineBarSpot>
                                              touchedBarSpots) {
                                            return touchedBarSpots
                                                .map((barSpot) {
                                              final flSpot = barSpot;
                                              if (flSpot.x >= 0 &&
                                                  flSpot.x <
                                                      _dailyTransactionSummary
                                                          .length) {
                                                final date =
                                                    _dailyTransactionSummary[
                                                            flSpot.x.toInt()]
                                                        .date;
                                                return LineTooltipItem(
                                                  '${DateFormat('MM/dd').format(date)}\n${currencyFormatter.format(-flSpot.y)}',
                                                  TextStyle(
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }
                                              return null;
                                            }).toList();
                                          },
                                        ),
                                        handleBuiltInTouches: true,
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(
            flex: _isBlinkAdvanceExpanded ? 2 : 1,
            child: GestureDetector(
              onTap: _handleBlinkAdvanceTap,
              child: Hero(
                tag: 'blinkAdvanceCard',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.blue[900] : Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isBlinkAdvanceExpanded
                      ? _buildExpandedBlinkAdvanceContent()
                      : _buildCollapsedBlinkAdvanceContent(),
                ),
              ),
            ),
          ),
          if (!_isBlinkAdvanceExpanded) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color:
                            _isDarkMode ? Colors.green[900] : Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance,
                            color:
                                _isDarkMode ? Colors.white : Colors.green[800],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Repayment',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.green[800],
                              fontSize: 16,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const insights.FinancialInsightsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(50),
                        decoration: BoxDecoration(
                          color: _isDarkMode
                              ? Colors.purple[900]
                              : Colors.purple[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insights,
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.purple[800],
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Insights',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.purple[800],
                                fontSize: 16,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedBlinkAdvanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.attach_money,
              color: Colors.blue[800],
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Blink',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.blue[800],
            fontSize: 24,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Advance',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.blue[800],
            fontSize: 24,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status:',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _hasActiveAdvance ? 'Active' : _blinkAdvanceStatus,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.blue[800],
                    fontSize: 14,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                _getStatusEmoji(),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Know more',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isBlinkAdvanceExpanded = true;
                });
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.white : Colors.blue[800],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward,
                    color: _isDarkMode ? Colors.blue[800] : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedBlinkAdvanceContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blink Advance',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.blue[800],
                    fontSize: 24,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _isDarkMode ? Colors.white : Colors.blue[800],
                  ),
                  onPressed: () {
                    setState(() {
                      _isBlinkAdvanceExpanded = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveAdvance
                  ? 'Active Blink Advance'
                  : 'Application Status: $_blinkAdvanceStatus',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.blue[800],
                fontSize: 18,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveAdvance
                  ? 'You currently have an active Blink Advance. Make sure to repay it on time to maintain your good standing.'
                  : 'We\'re reviewing your application. This usually takes 1-2 business days.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Next Steps:',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.blue[800],
                fontSize: 16,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveAdvance
                  ? '• Monitor your repayment date and ensure sufficient funds are available.'
                  : '• You\'ll receive a notification once your application is approved.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'About Blink Advance:',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.blue[800],
                fontSize: 16,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Blink Advance is a short-term cash advance service designed to help you manage unexpected expenses or cash flow gaps.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FAQs:',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.blue[800],
                fontSize: 16,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hasActiveAdvance
                  ? '1. When is my repayment due?\n   Check your account details for the exact date.\n\n2. Can I repay early?\n   Yes, you can repay at any time without penalties.'
                  : '1. How long does the review process take?\n   Usually 1-2 business days.\n\n2. Can I cancel my application?\n   Yes, contact support for assistance.',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.blue[600],
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement contact support functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode ? Colors.white : Colors.blue[800],
                foregroundColor: _isDarkMode ? Colors.blue[800] : Colors.white,
              ),
              child: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusEmoji() {
    if (_hasActiveAdvance) {
      return const Text('✅', style: TextStyle(fontSize: 16));
    }
    switch (_blinkAdvanceStatus.toLowerCase()) {
      case 'on review':
        return const Text('🕒', style: TextStyle(fontSize: 16));
      case 'approved':
        return const Text('✅', style: TextStyle(fontSize: 16));
      case 'rejected':
        return const Text('❌', style: TextStyle(fontSize: 16));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTransactionItem(auth.Transaction transaction) {
    final String formattedAmount =
        currencyFormatter.format(transaction.amount.abs());
    final String formattedDate =
        DateFormat('dd MMM, yyyy').format(transaction.date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isDarkMode ? Colors.white24 : Colors.grey[200],
            ),
            child: Icon(
              _getCategoryIcon(transaction.category ?? ''),
              color: _isDarkMode ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.category ?? 'Uncategorized',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction.isOutflow ? '-$formattedAmount' : '+$formattedAmount',
            style: TextStyle(
              color: transaction.isOutflow ? Colors.red : Colors.green,
              fontSize: 16,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement navigation to all transactions
              },
              child: Text(
                'See all',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentTransactions.isEmpty
                ? Center(
                    child: Text(
                      'No recent transactions',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                        fontFamily: 'Onest',
                      ),
                    ),
                  )
                : Column(
                    children: _recentTransactions
                        .map(
                            (transaction) => _buildTransactionItem(transaction))
                        .toList(),
                  ),
      ],
    );
  }

  Widget _buildNewsAndUpdates() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'News & Updates',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement navigation to all news
              },
              child: Text(
                'See all',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              return _buildNewsCard(_newsItems[index], index);
            },
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, String> newsItem, int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          // TODO: Implement news item tap action
        },
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode ? Colors.white24 : Colors.black12,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(
                  newsItem['imageUrl']!,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsItem['title']!,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsItem['description']!,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

  void _handleBlinkAdvanceTap() {
    if (_hasActiveAdvance) {
      // TODO: Navigate to active Blink Advance details screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You have an active Blink Advance. Repayment details coming soon.'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (_isBlinkAdvanceApproved) {
      if (_bankAccountId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                BlinkAdvanceScreen(bankAccountId: _bankAccountId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Bank account ID not found. Please link your bank account.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_blinkAdvanceStatus == 'On Review'
              ? 'Your Blink Advance application is still under review. Please check back later.'
              : 'You are not currently eligible for Blink Advance. Please check back later or contact support for more information.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'finance':
        return Icons.account_balance;
      case 'dining':
        return Icons.restaurant;
      case 'utilities':
        return Icons.power;
      default:
        return Icons.attach_money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      child: Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF061535) : Colors.grey[100],
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadData(),
                      _loadBlinkAdvanceStatus(),
                    ]);
                  },
                  color: _isDarkMode ? Colors.white : Colors.blue,
                  backgroundColor:
                      _isDarkMode ? Colors.blue[700] : Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildFinancialSummary(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          _buildRecentTransactions(),
                          const SizedBox(height: 32),
                          _buildNewsAndUpdates(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
