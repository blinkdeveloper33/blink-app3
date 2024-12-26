import 'dart:math';
import 'dart:ui';
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
import 'package:fluentui_emoji_icon/fluentui_emoji_icon.dart';
import 'package:flutter/scheduler.dart';
import 'package:blink_app/widgets/animated_gradient_background.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:blink_app/features/home/presentation/news_stories_viewer.dart';
import 'package:blink_app/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
  bool _hapticFeedbackEnabled = true;

  late AnimationController _emojiAnimationController;
  late Animation<double> _emojiAnimation;

  late AnimationController _repaymentEmojiAnimationController;
  late Animation<double> _repaymentEmojiAnimation;
  late AnimationController _insightsEmojiAnimationController;
  late Animation<double> _insightsEmojiAnimation;

  late AnimationController _pulseController;

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

  void _performHapticFeedback(HapticsType type) {
    if (_hapticFeedbackEnabled) {
      Haptics.vibrate(type);
    }
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
          _performHapticFeedback(HapticsType.light);
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  FadeTransition(
                opacity: animation,
                child: NewsStoriesViewer(
                  newsItems: _newsItems,
                  initialIndex: index,
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
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
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
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
        ),
      ),
    );
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

  void _viewDetails(auth.Transaction transaction) {
    _performHapticFeedback(HapticsType.medium);
    // TODO: Implement view details functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${transaction.merchantName}')),
    );
  }

  void _changeCategory(auth.Transaction transaction) {
    _performHapticFeedback(HapticsType.medium);
    // TODO: Implement change category functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Change category for ${transaction.merchantName}')),
    );
  }

  void _addNote(auth.Transaction transaction) {
    _performHapticFeedback(HapticsType.medium);
    // TODO: Implement add note functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add note for ${transaction.merchantName}')),
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

  Widget _buildCollapsedBlinkAdvanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _emojiAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _emojiAnimation.value,
              child: FluentUiEmojiIcon(
                fl: Fluents.flHighVoltage,
                w: 48,
                h: 48,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
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
                _performHapticFeedback(HapticsType.medium);
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
                    _performHapticFeedback(HapticsType.light);
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
                _performHapticFeedback(HapticsType.medium);
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

  void _handleBlinkAdvanceTap() {
    _performHapticFeedback(HapticsType.medium);
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

    _emojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _emojiAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _emojiAnimationController, curve: Curves.easeInOut),
    );

    _repaymentEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _repaymentEmojiAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _repaymentEmojiAnimationController, curve: Curves.easeInOut),
    );

    _insightsEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _insightsEmojiAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
          parent: _insightsEmojiAnimationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadData();
    _fetchAndStoreDetailedBankAccounts();
    _loadBlinkAdvanceStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emojiAnimationController.dispose();
    _repaymentEmojiAnimationController.dispose();
    _insightsEmojiAnimationController.dispose();
    _pulseController.dispose();
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

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final response = await authService.getDailyTransactionSummary();

      if (!mounted) return;
      setState(() {
        _dailyTransactionSummary = (response['data'] as List)
            .map((item) => auth.DailyTransactionSummary.fromJson(
                Map<String, dynamic>.from(item)))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        _isChartLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChartLoading = false;
        _dailyTransactionSummary = [];
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
                    _performHapticFeedback(HapticsType.medium);
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
                        _performHapticFeedback(HapticsType.light);
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
                    _performHapticFeedback(HapticsType.light);
                    final themeProvider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    themeProvider.setThemeMode(
                        themeProvider.themeMode == ThemeMode.light
                            ? ThemeMode.dark
                            : ThemeMode.light);
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.7),
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
                      _performHapticFeedback(HapticsType.light);
                      setState(() {
                        _isChartExpanded = !_isChartExpanded;
                      });
                      if (_isChartExpanded &&
                          _dailyTransactionSummary.isEmpty) {
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
                                        _isDarkMode
                                            ? Colors.white
                                            : Colors.blue,
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
                                        _getChartData(),
                                      ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:
                            _isDarkMode ? Colors.blue[900] : Colors.blue[100],
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
            ),
          ),
          if (!_isBlinkAdvanceExpanded) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _performHapticFeedback(HapticsType.medium);
                        // TODO: Implement repayment functionality
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.green[900]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _repaymentEmojiAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _repaymentEmojiAnimation.value,
                                      child: Image.asset(
                                        'assets/animations/Spiral Calendar.png',
                                        width: 48,
                                        height: 48,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _performHapticFeedback(HapticsType.medium);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const insights.FinancialInsightsScreen()),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(47),
                            decoration: BoxDecoration(
                              color: _isDarkMode
                                  ? Colors.purple[900]
                                  : Colors.purple[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _insightsEmojiAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _insightsEmojiAnimation.value,
                                      child: Image.asset(
                                        'assets/animations/Bar Chart.png',
                                        width: 48,
                                        height: 40,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
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

  Widget _buildTransactionItem(auth.Transaction transaction) {
    final String formattedAmount =
        currencyFormatter.format(transaction.amount.abs());
    final String formattedDate =
        DateFormat('dd MMM, yyyy').format(transaction.date);

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (context) => _addNote(transaction),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[600]!.withOpacity(0.95),
                    Colors.blue[400]!.withOpacity(0.95),
                  ],
                  stops: const [0.2, 0.8],
                ),
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (context) => _changeCategory(transaction),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.orange[400]!.withOpacity(0.95),
                    Colors.orange[600]!.withOpacity(0.95),
                  ],
                  stops: const [0.2, 0.8],
                ),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: Hero(
        tag: 'transaction-${transaction.id}',
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: _isDarkMode ? const Color(0xFF1C2A4D) : Colors.white,
          child: InkWell(
            onTap: () => _viewDetails(transaction),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDarkMode ? Colors.white24 : Colors.grey[200],
                    ),
                    child: Icon(
                      _getCategoryIcon(transaction.category ?? ''),
                      color: _isDarkMode ? Colors.white : Colors.black54,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            color:
                                _isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Onest',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    transaction.isOutflow
                        ? '-$formattedAmount'
                        : '+$formattedAmount',
                    style: TextStyle(
                      color: transaction.isOutflow
                          ? Colors.red
                          : _isDarkMode
                              ? Colors.green[300]
                              : Colors.green,
                      fontSize: 16,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                _performHapticFeedback(HapticsType.light);
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
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionItem(_recentTransactions[index]);
                    },
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
                _performHapticFeedback(HapticsType.light);
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

  double _calculateInterval() {
    if (_dailyTransactionSummary.isEmpty) return 1.0;
    final values = _dailyTransactionSummary.map((e) => -e.totalAmount).toList();
    final range = values.reduce(max) - values.reduce(min);
    return range / 5;
  }

  double _calculateDateInterval() {
    if (_dailyTransactionSummary.isEmpty) return 1.0;
    return (_getMaxX() - _getMinX()) / 5;
  }

  double _getMinX() {
    if (_dailyTransactionSummary.isEmpty) return 0;
    return _dailyTransactionSummary.first.date.millisecondsSinceEpoch
        .toDouble();
  }

  double _getMaxX() {
    if (_dailyTransactionSummary.isEmpty) return 1;
    return _dailyTransactionSummary.last.date.millisecondsSinceEpoch.toDouble();
  }

  double _getMinY() {
    if (_dailyTransactionSummary.isEmpty) return 0;
    return _dailyTransactionSummary.map((e) => -e.totalAmount).reduce(min);
  }

  double _getMaxY() {
    if (_dailyTransactionSummary.isEmpty) return 1;
    return _dailyTransactionSummary.map((e) => -e.totalAmount).reduce(max);
  }

  List<FlSpot> _getChartSpots() {
    if (_dailyTransactionSummary.isEmpty) return [];
    return _dailyTransactionSummary
        .map((entry) => FlSpot(
            entry.date.millisecondsSinceEpoch.toDouble(), -entry.totalAmount))
        .toList();
  }

  LineTouchTooltipData _getTooltipData() {
    return LineTouchTooltipData(
      tooltipBorder: BorderSide(
        color: _isDarkMode ? Colors.white : Colors.black87,
      ),
      fitInsideHorizontally: true,
      fitInsideVertically: true,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tooltipMargin: 16,
      tooltipRoundedRadius: 8,
      getTooltipColor: (touchedSpot) =>
          _isDarkMode ? Colors.white : Colors.black87,
      getTooltipItems: (touchedSpots) {
        return touchedSpots.map((LineBarSpot touchedSpot) {
          final date =
              DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
          return LineTooltipItem(
            DateFormat('MMM d, yyyy').format(date),
            TextStyle(
              color: _isDarkMode ? Colors.black87 : Colors.white,
              fontFamily: 'Onest',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            children: [
              const TextSpan(text: '\n'),
              TextSpan(
                text: currencyFormatter.format(-touchedSpot.y),
                style: TextStyle(
                  color:
                      -touchedSpot.y >= 0 ? Colors.green[400] : Colors.red[400],
                  fontFamily: 'Onest',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }).toList();
      },
    );
  }

  LineChartData _getChartData() {
    if (_dailyTransactionSummary.isEmpty) {
      return LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [],
      );
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _calculateInterval(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: _isDarkMode ? Colors.white12 : Colors.black12,
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: _getMinY(),
      maxY: _getMaxY(),
      minX: _getMinX(),
      maxX: _getMaxX(),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: _getTooltipData(),
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: Colors.blue.withOpacity(0.3),
                strokeWidth: 2,
                dashArray: [3, 3],
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: Colors.white,
                    strokeWidth: 3,
                    strokeColor: Colors.blue[600]!,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _getChartSpots(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: Colors.blue[600],
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isLast = index == _getChartSpots().length - 1;
              return FlDotCirclePainter(
                radius: isLast ? 6 * _pulseController.value : 0,
                color: Colors.blue[600]!,
                strokeWidth: isLast ? 2 : 0,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue[600]!.withOpacity(0.2),
                Colors.blue[600]!.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return ConfettiOverlay(
      child: AnimatedGradientBackground(
        isDarkMode: isDarkMode,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _performHapticFeedback(HapticsType.medium);
                      await Future.wait([
                        _loadData(),
                        _loadBlinkAdvanceStatus(),
                      ]);
                    },
                    color: isDarkMode ? Colors.white : Colors.blue,
                    backgroundColor:
                        isDarkMode ? Colors.blue[700] : Colors.white,
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
      ),
    );
  }
}
