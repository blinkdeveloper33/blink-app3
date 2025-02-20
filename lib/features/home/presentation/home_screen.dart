import 'dart:math' show Random, max, min;
import 'dart:math' as math;
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
import 'package:blink_app/features/blink_advance/presentation/splash/blink_advance_splash_screen.dart';
import 'package:blink_app/widgets/confetti_overlay.dart';
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart'
    as insights;
import 'package:fluentui_emoji_icon/fluentui_emoji_icon.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/home/presentation/news_stories_viewer.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:blink_app/features/transactions/domain/models/transaction_category.dart';
import 'package:blink_app/features/transactions/presentation/widgets/category_selector_sheet.dart';
import '../../../features/transactions/domain/services/transaction_service.dart';
import '../../../features/transactions/domain/models/transaction.dart';
import 'package:blink_app/services/supabase_storage_service.dart';
import 'package:blink_app/features/notifications/presentation/notifications_screen.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:blink_app/features/transactions/presentation/screens/all_transactions_screen.dart';
import 'package:blink_app/features/quick_actions/presentation/screens/quick_actions_screen.dart';
import 'package:blink_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Logger _logger = Logger();
  bool _isDarkMode = false;
  static const cashAdvanceBlue = Color(0xFF1E3A4F);
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
  late AnimationController _insightsEmojiAnimationController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _blurIntensity = 0;

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

  // Add these to the existing animation controllers in _HomeScreenState
  late AnimationController _blinkCardExpandController;
  late Animation<double> _blinkCardScaleAnimation;
  late Animation<double> _blinkCardRotationAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  // Add these variables at the top of the class
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isCardFlipped = false;

  // Add new state variables for repayment card flip
  late AnimationController _repaymentFlipController;
  late Animation<double> _repaymentFlipAnimation;
  bool _isRepaymentCardFlipped = false;

  // Add this to the state variables at the top of _HomeScreenState
  bool _showHistoricalDataMessage = false;
  Timer? _messageTimer;

  // Add this timer variable
  Timer? _blinkAdvanceStatusTimer;

  // Add these variables to the _HomeScreenState class
  Map<String, dynamic>? _activeAdvanceData;

  void _performHapticFeedback(haptics.HapticsType type) {
    if (_hapticFeedbackEnabled) {
      haptics.Haptics.vibrate(type);
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
            child: GestureDetector(
              onTap: () {
                _performHapticFeedback(haptics.HapticsType.light);
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
              child: Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? const Color(0xFF1A2942).withOpacity(0.7)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'newsImage-$index',
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          image: DecorationImage(
                            image: AssetImage(newsItem['imageUrl']!),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              newsItem['title']!,
                              style: TextStyle(
                                color:
                                    _isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                newsItem['description']!,
                                style: TextStyle(
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 14,
                                  fontFamily: 'Onest',
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isDarkMode
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Financial Tips',
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.blue[700],
                                      fontSize: 12,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _isDarkMode
                                      ? Colors.white70
                                      : Colors.blue[700],
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedBlinkAdvanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: AnimatedBuilder(
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
                );
              },
            ),
          ],
        ),
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: SvgPicture.asset(
            _isDarkMode
                ? 'assets/images/blink-logo2.svg'
                : 'assets/images/blink-logo3.svg',
            height: 28,
            colorFilter: ColorFilter.mode(
              _isDarkMode ? Colors.white : Colors.blue[800]!,
              BlendMode.srcIn,
            ),
            key: ValueKey(_isDarkMode),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cash Advance',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.blue[800],
            fontSize: 24,
            fontFamily: 'Onest',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
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
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: _getStatusEmoji(),
                    );
                  },
                ),
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
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
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
                        color: _isDarkMode
                            ? const Color(0xFF141B2E)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedBlinkAdvanceContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section - Fixed height
              Container(
                height: 70, // Slightly reduced header height
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'blink-logo',
                            child: SvgPicture.asset(
                              _isDarkMode
                                  ? 'assets/images/blink-logo2.svg'
                                  : 'assets/images/blink-logo3.svg',
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                _isDarkMode ? Colors.white : Colors.blue[800]!,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Cash Advance',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.blue[800],
                              fontSize: 18,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _isBlinkAdvanceExpanded ? 0.25 : 0,
                        child: Icon(
                          Icons.close,
                          color:
                              _isDarkMode ? Colors.white70 : Colors.blue[800],
                        ),
                      ),
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        setState(() {
                          _isBlinkAdvanceExpanded = false;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content section - Flexible height
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      _buildStatusSection(),
                      const SizedBox(height: 16),
                      _buildInfoSection(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _hasActiveAdvance ? Icons.check_circle : Icons.pending,
              color: _isDarkMode ? Colors.white : Colors.blue[800],
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black54,
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasActiveAdvance ? 'Active' : _blinkAdvanceStatus,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: _isBlinkAdvanceExpanded ? 1.0 : 0.0,
            child: _getStatusEmoji(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _hasActiveAdvance ? 'Active Advance' : 'Application Status',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : Colors.black87,
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveAdvance
                ? 'You have an active advance. Make sure to repay on time.'
                : 'Review takes 1-2 business days.',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontFamily: 'Onest',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () {
            _performHapticFeedback(haptics.HapticsType.medium);
            if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      BlinkAdvanceSplashScreen(bankAccountId: _bankAccountId),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  // Disable swipe back gesture
                  settings: const RouteSettings(name: '/blink-advance'),
                  opaque: true,
                  barrierDismissible: false,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDarkMode ? Colors.white : Colors.blue[800],
            foregroundColor: _isDarkMode ? Colors.blue[800] : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _hasActiveAdvance
                ? 'View Details'
                : _isBlinkAdvanceApproved
                    ? 'Apply Now'
                    : 'Check Status',
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            _performHapticFeedback(haptics.HapticsType.light);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllTransactionsScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Contact Support',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.blue[800],
              fontSize: 12,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _handleBlinkAdvanceTap() {
    _performHapticFeedback(haptics.HapticsType.medium);
    setState(() {
      _isBlinkAdvanceExpanded = !_isBlinkAdvanceExpanded;
    });

    if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
      Navigator.of(context)
          .push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return BlinkAdvanceSplashScreen(bankAccountId: _bankAccountId);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      )
          .then((result) {
        if (result != null && result is Map<String, dynamic>) {
          setState(() {
            _activeAdvanceData = result;
            _hasActiveAdvance = true;
          });
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _blinkAdvanceStatus == 'On Review'
                ? 'Your Blink Advance application is still under review.'
                : 'You are not currently eligible for Blink Advance.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _changeCategory(Transaction transaction) {
    _performHapticFeedback(haptics.HapticsType.medium);

    // Find current category if exists
    final currentCategory = TransactionCategory.defaultCategories.firstWhere(
      (category) => category.id == transaction.category?.toLowerCase(),
      orElse: () => TransactionCategory.defaultCategories.first,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => CategorySelectorSheet(
          initialCategory: currentCategory,
          onCategorySelected: (category) {
            // Create a new auth.Transaction with updated category
            final updatedTransaction = auth.Transaction(
              id: transaction.id,
              merchantName: transaction.merchantName ?? '',
              amount: transaction.amount,
              date: transaction.date,
              category: category.name,
              isOutflow: transaction.isOutflow,
            );

            setState(() {
              _recentTransactions = _recentTransactions
                  .map((t) => t.id == transaction.id ? updatedTransaction : t)
                  .toList();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category updated to ${category.name}'),
                backgroundColor: category.color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: SnackBarAction(
                  label: 'Undo',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      // Convert back to auth.Transaction for the revert
                      final revertTransaction = auth.Transaction(
                        id: transaction.id,
                        merchantName: transaction.merchantName ?? '',
                        amount: transaction.amount,
                        date: transaction.date,
                        category: transaction.category ?? '',
                        isOutflow: transaction.isOutflow,
                      );

                      _recentTransactions = _recentTransactions
                          .map((t) => t.id == updatedTransaction.id
                              ? revertTransaction
                              : t)
                          .toList();
                    });
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Convert auth.Transaction to domain Transaction
  Transaction _convertAuthTransaction(auth.Transaction authTransaction) {
    return Transaction(
      id: authTransaction.id,
      merchantName: authTransaction.merchantName,
      amount: authTransaction.amount,
      date: authTransaction.date,
      category: authTransaction.category,
      isOutflow: authTransaction.isOutflow,
      status: 'Completed', // Default status
      description: null,
      metadata: null,
    );
  }

  // Update the transaction loading to use the conversion
  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final userId = storageService.getUserId();
      if (userId == null) throw Exception('User ID not found');

      final transactions = await authService.getRecentTransactions(userId);

      if (!mounted) return;

      setState(() {
        // Cast the list to the correct type
        _recentTransactions = (transactions as List<dynamic>)
            .map((t) => t as auth.Transaction)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading recent transactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    if (!mounted) return;

    try {
      _flipController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _flipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
        CurvedAnimation(
          parent: _flipController,
          curve: Curves.easeInOutBack,
        ),
      );

      // Initialize repayment flip controller
      _repaymentFlipController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      _repaymentFlipAnimation = Tween<double>(begin: 0, end: math.pi).animate(
        CurvedAnimation(
          parent: _repaymentFlipController,
          curve: Curves.easeInOutBack,
        ),
      );

      _initializeControllers();
      _initializeBlinkAdvanceAnimations();

      _scrollController.addListener(_updateBlurEffect);

      Future.microtask(() {
        if (mounted) {
          _safeLoadData();
        }
      });
    } catch (e) {
      _logger.e('Error in initState: $e');
    }

    // Load profile picture after a short delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadProfilePicture();
      }
    });

    // Set up periodic status check every 30 seconds
    _blinkAdvanceStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadBlinkAdvanceStatus();
    });
  }

  @override
  void dispose() {
    // Cancel timers
    _messageTimer?.cancel();

    // Dispose animation controllers
    _animationController.dispose();
    _emojiAnimationController.dispose();
    _repaymentEmojiAnimationController.dispose();
    _insightsEmojiAnimationController.dispose();
    _pulseController.dispose();
    _blinkCardExpandController.dispose();
    _shimmerController.dispose();
    _flipController.dispose();
    _repaymentFlipController.dispose();

    // Remove scroll controller listener and dispose
    _scrollController.removeListener(_updateBlurEffect);
    _scrollController.dispose();

    _blinkAdvanceStatusTimer?.cancel();

    super.dispose();
  }

  Future<void> _safeLoadData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Load data sequentially to avoid race conditions
      await _loadUserInfo().catchError((e) {
        _logger.e('Error loading user info: $e');
        return null;
      });

      if (!mounted) return;

      await _loadRecentTransactions().catchError((e) {
        _logger.e('Error loading transactions: $e');
        return null;
      });

      if (!mounted) return;

      await _loadCurrentBalances().catchError((e) {
        _logger.e('Error loading balances: $e');
        return null;
      });

      if (!mounted) return;

      await _loadBlinkAdvanceStatus().catchError((e) {
        _logger.e('Error loading Blink Advance status: $e');
        return null;
      });
    } catch (e) {
      _logger.e('Error in _safeLoadData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Future<void> _loadUserInfo() async {
    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final supabaseStorage =
          Provider.of<SupabaseStorageService>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);

      final userId = authService.currentUser?.id;
      String? profilePicture;

      if (userId != null) {
        try {
          final existingFiles = await supabaseStorage.listFiles(userId);
          String? latestProfilePic;
          DateTime latestTimestamp = DateTime(1970);

          for (final file in existingFiles) {
            if (file.name.startsWith('profile_')) {
              final timestamp =
                  int.tryParse(file.name.split('_')[1].split('.')[0]);
              if (timestamp != null) {
                final fileTimestamp =
                    DateTime.fromMillisecondsSinceEpoch(timestamp);
                if (fileTimestamp.isAfter(latestTimestamp)) {
                  latestTimestamp = fileTimestamp;
                  latestProfilePic = file.name;
                }
              }
            }
          }

          if (latestProfilePic != null) {
            profilePicture =
                supabaseStorage.getProfilePictureUrl(userId, latestProfilePic);
            if (profilePicture != null) {
              await profileProvider.updateProfilePicture(profilePicture);
            }
          }
        } catch (e) {
          debugPrint('Error loading profile picture: $e');
        }
      }

      final fullName = storageService.getFullName();
      final bankAccountId = storageService.getBankAccountId();
      final primaryAccountName = storageService.getPrimaryAccountName();

      if (!mounted) return;

      setState(() {
        _userName = fullName ?? 'User';
        _bankAccountId = bankAccountId ?? '';
        _primaryAccountName = primaryAccountName;
      });
    } catch (e) {
      _logger.e('Error loading user info: $e');
      rethrow;
    }
  }

  Future<void> _loadCurrentBalances() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final balances = await authService.getCurrentBalances();

      if (!mounted) return;

      if (balances.isNotEmpty && balances['accounts'] != null) {
        final accounts = List<Map<String, dynamic>>.from(balances['accounts']);
        if (accounts.isNotEmpty) {
          final firstAccount = accounts.first;
          final dynamic rawBalance = firstAccount['currentBalance'];
          double currentBalance = 0.0;

          if (rawBalance is num) {
            currentBalance = rawBalance.toDouble();
          } else if (rawBalance is String) {
            currentBalance = double.tryParse(rawBalance) ?? 0.0;
          }

          if (!mounted) return;

          setState(() {
            _currentBalance = currentBalance;
          });

          _animationController.reset();
          _animationController.forward();
        }
      }
    } catch (e) {
      _logger.e('Error loading current balances: $e');
      rethrow;
    }
  }

  Future<void> _loadBlinkAdvanceStatus() async {
    if (!mounted) return;

    try {
      setState(() {
        _isBlinkAdvanceLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);

      // Check approval status
      final approvalResponse =
          await authService.getBlinkAdvanceApprovalStatus();

      if (!mounted) return;

      // Handle the approval status response
      if (approvalResponse != null && approvalResponse['success'] == true) {
        setState(() {
          _isBlinkAdvanceApproved =
              approvalResponse['data']['isApproved'] ?? false;
          _blinkAdvanceStatus =
              _isBlinkAdvanceApproved ? 'Approved' : 'On Review';
          _hasActiveAdvance = false;
          _activeAdvance = null;
          _isBlinkAdvanceLoading = false;
        });
        return;
      }

      setState(() {
        _isBlinkAdvanceApproved = false;
        _blinkAdvanceStatus = 'On Review';
        _hasActiveAdvance = false;
        _activeAdvance = null;
        _isBlinkAdvanceLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isBlinkAdvanceApproved = false;
        _blinkAdvanceStatus = 'Error';
        _hasActiveAdvance = false;
        _activeAdvance = null;
        _isBlinkAdvanceLoading = false;
      });
    }
  }

  void _initializeControllers() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    _emojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _emojiAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _emojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _repaymentEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _insightsEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500), // Increased duration
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine, // Smoother curve
    ));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Add a curved animation for the pulse
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Initialize other controllers as needed
  }

  void _initializeBlinkAdvanceAnimations() {
    _blinkCardExpandController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _blinkCardScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _blinkCardExpandController,
        curve: Curves.easeInOutBack,
      ),
    );

    _blinkCardRotationAnimation = Tween<double>(
      begin: 0,
      end: 0.01,
    ).animate(
      CurvedAnimation(
        parent: _blinkCardExpandController,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  void _updateBlurEffect() {
    if (!mounted) return;
    setState(() {
      _scrollOffset = _scrollController.offset;
      _blurIntensity = (_scrollOffset / 100).clamp(0, 15);
    });
  }

  Widget _buildFinancialSummary() {
    return GestureDetector(
      onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
      child: Container(
        height: 200,
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            final showFrontSide = _flipAnimation.value < (math.pi / 2);
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_flipAnimation.value),
              alignment: Alignment.center,
              child: showFrontSide
                  ? _buildFrontCard()
                  : Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: _buildBackCard(),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color.fromARGB(255, 29, 38, 62).withOpacity(0.95),
                  const Color.fromARGB(255, 32, 48, 75).withOpacity(0.98),
                ]
              : [
                  Colors.blue[700]!.withOpacity(0.95),
                  Colors.blue[900]!.withOpacity(0.98),
                ],
          stops: const [0.2, 0.8],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? const Color(0xFF1A2942).withOpacity(0.5)
                : Colors.blue[700]!.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/blink-logo.png',
                    height: 32,
                    width: 120,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                  _buildFlipButton(),
                ],
              ),
              const Spacer(),
              // Balance Section with reduced spacing
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Last Known Balance',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${DateFormat('MMM d').format(DateTime.now())}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final animatedBalance =
                          _currentBalance * _animation.value;
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${currencyFormatter.format(animatedBalance).split('.')[0].substring(1)}.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: currencyFormatter
                                  .format(animatedBalance)
                                  .split('.')[1],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Account Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      _primaryAccountName ?? 'Primary Account',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: 'Onest',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '****${_bankAccountId.substring(max(0, _bankAccountId.length - 4))}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    final hasActiveAdvance = _hasActiveAdvance && _activeAdvance != null;
    final advanceAmount =
        hasActiveAdvance ? (_activeAdvance!['amount'] as num).toDouble() : 0.0;
    final repaymentDate = hasActiveAdvance
        ? DateTime.parse(_activeAdvance!['repayment_date'].toString())
        : DateTime.now();
    final repaymentAmount = hasActiveAdvance
        ? (_activeAdvance!['repayment_amount'] as num).toDouble()
        : 0.0;

    final paymentHistory = [
      {
        'date': DateTime.now().add(const Duration(days: 7)),
        'status': 'upcoming',
        'amount': repaymentAmount
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'status': 'completed',
        'amount': 150.0
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 14)),
        'status': 'completed',
        'amount': 200.0
      },
    ];

    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color(0xFF1E2942).withOpacity(0.98),
                  const Color(0xFF141B2E).withOpacity(0.95),
                ]
              : [
                  Colors.blue[900]!.withOpacity(0.98),
                  Colors.blue[800]!.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.blue[900]!.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side content
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasActiveAdvance || _isBlinkAdvanceApproved
                                ? const Color(0xFF40916C)
                                : const Color(0xFFB91C1C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasActiveAdvance || _isBlinkAdvanceApproved
                                    ? Icons.check_circle
                                    : Icons.pending,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasActiveAdvance
                                    ? 'Active'
                                    : _isBlinkAdvanceApproved
                                        ? 'Approved'
                                        : 'Under Review',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildFlipButton(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasActiveAdvance) ...[
                      Text(
                        currencyFormatter.format(advanceAmount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ] else ...[
                      Text(
                        _isBlinkAdvanceApproved
                            ? 'Ready for\nQuick Cash'
                            : 'Under\nReview',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isBlinkAdvanceApproved)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF40916C),
                                const Color(0xFF40916C).withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF40916C).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _performHapticFeedback(
                                    haptics.HapticsType.medium);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BlinkAdvanceScreen(
                                        bankAccountId: _bankAccountId),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Get \$200',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.white.withOpacity(0.8),
                                size: 14,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '1-2 business days',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),

              // Right side - Payment Timeline
              if (hasActiveAdvance) ...[
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          'Payment Schedule',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: paymentHistory.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final payment = paymentHistory[index];
                            final isUpcoming = payment['status'] == 'upcoming';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUpcoming
                                    ? const Color(0xFF40916C).withOpacity(0.15)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUpcoming
                                      ? const Color(0xFF40916C).withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isUpcoming
                                          ? const Color(0xFF40916C)
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('MMM d').format(
                                              payment['date'] as DateTime),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                                isUpcoming ? 1 : 0.7),
                                            fontSize: 11,
                                            fontFamily: 'Onest',
                                            fontWeight: isUpcoming
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          currencyFormatter
                                              .format(payment['amount']),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                                isUpcoming ? 1 : 0.6),
                                            fontSize: 10,
                                            fontFamily: 'Onest',
                                            fontWeight: isUpcoming
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlipButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () {
              _flipCard();
              _performHapticFeedback(haptics.HapticsType.medium);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: _isCardFlipped ? 0.5 : 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _flipCard() {
    if (_isCardFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
      // Load transaction data when flipping to back
      _loadDailyTransactionSummary();
    }
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });
    _performHapticFeedback(haptics.HapticsType.medium);
  }

  void _flipRepaymentCard() {
    if (_isRepaymentCardFlipped) {
      _repaymentFlipController.reverse();
    } else {
      _repaymentFlipController.forward();
    }
    setState(() {
      _isRepaymentCardFlipped = !_isRepaymentCardFlipped;
    });
    _performHapticFeedback(haptics.HapticsType.medium);
  }

  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 56) / 2; // Half width minus padding and gap

    return Container(
      height: cardWidth * 1.8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              width: cardWidth,
              child: _buildBlinkAdvanceCard(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              width: cardWidth,
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildQuickActionCard(
                      title: 'Repayment',
                      color: _isDarkMode
                          ? const Color(0xFF1E3B2F)
                          : Colors.green[100]!,
                      textColor:
                          _isDarkMode ? Colors.white : Colors.green[800]!,
                      onTap: () {
                        _performHapticFeedback(haptics.HapticsType.medium);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 1,
                    child: _buildQuickActionCard(
                      title: 'Insights',
                      color: _isDarkMode
                          ? const Color(0xFF2A1E45)
                          : Colors.purple[100]!,
                      textColor:
                          _isDarkMode ? Colors.white : Colors.purple[800]!,
                      onTap: () {
                        _performHapticFeedback(haptics.HapticsType.medium);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const insights.FinancialInsightsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    if (title == 'Repayment') {
      return GestureDetector(
        onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
        child: AnimatedBuilder(
          animation: _repaymentFlipAnimation,
          builder: (context, child) {
            final showFrontSide = _repaymentFlipAnimation.value < (math.pi / 2);
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_repaymentFlipAnimation.value),
              alignment: Alignment.center,
              child: showFrontSide
                  ? _buildRepaymentFrontCard(color, textColor)
                  : Transform(
                      transform: Matrix4.identity()..rotateX(math.pi),
                      alignment: Alignment.center,
                      child: _buildRepaymentBackCard(color, textColor),
                    ),
            );
          },
        ),
      );
    }

    // Insights card
    if (title == 'Insights') {
      const insightsBlue = Color.fromRGBO(55, 168, 222, 1.0);
      return GestureDetector(
        onTapDown: (_) {
          _performHapticFeedback(haptics.HapticsType.light);
          setState(() {
            _insightsEmojiAnimationController.forward();
          });
        },
        onTapUp: (_) {
          _insightsEmojiAnimationController.reverse();
          onTap();
        },
        onTapCancel: () {
          _insightsEmojiAnimationController.reverse();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                insightsBlue.withOpacity(0.98),
                insightsBlue.withOpacity(0.95),
              ],
              stops: const [0.2, 0.9],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: insightsBlue.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: insightsBlue.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                          Colors.black.withOpacity(0.05),
                        ],
                        stops: const [0.2, 0.5, 0.8],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -100,
                  left: -100,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/icons/icons8-pie-chart-96.png',
                              width: 32,
                              height: 32,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Blink\n',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                                height: 0.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Insights',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 22,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Original implementation for other cards
    return GestureDetector(
      onTapDown: (_) {
        _performHapticFeedback(haptics.HapticsType.light);
        setState(() {
          _insightsEmojiAnimationController.forward();
        });
      },
      onTapUp: (_) {
        _insightsEmojiAnimationController.reverse();
        onTap();
      },
      onTapCancel: () {
        _insightsEmojiAnimationController.reverse();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.1)
                : textColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(_isDarkMode ? 0.3 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/images/icons/icons8-transaction-100.png',
                  color: textColor,
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analyze',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'Onest',
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: textColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: textColor,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              _isDarkMode ? Colors.white70 : Colors.blue[700]!,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Header Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    'Your latest financial activities',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                      fontFamily: 'Onest',
                    ),
                  ),
                ],
              ),
            ),
            // Enhanced View All Button
            Container(
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400.withOpacity(0.2),
                    Colors.purple.shade400.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _performHapticFeedback(haptics.HapticsType.light);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTransactionsScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : Colors.blue.shade700,
                            fontSize: 14,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color:
                              _isDarkMode ? Colors.white : Colors.blue.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Enhanced Transaction List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: _recentTransactions.length,
          itemBuilder: (context, index) {
            final transaction = _recentTransactions[index];
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: safeOpacity,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildEnhancedTransactionItem(transaction, index),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedTransactionItem(
      auth.Transaction transaction, int index) {
    final formattedDate = DateFormat('MMM d, yyyy').format(transaction.date);
    final wholeNumber = transaction.amount.floor();
    final decimal = ((transaction.amount - wholeNumber) * 100)
        .toInt()
        .toString()
        .padLeft(2, '0');
    final formattedWholeNumber = NumberFormat('#,###').format(wholeNumber);
    final domainTransaction = _convertAuthTransaction(transaction);

    return GestureDetector(
      onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
      onTap: () => _viewDetails(domainTransaction),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white,
              _isDarkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Icon with Gradient Border
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      domainTransaction.getCategoryColor(_isDarkMode),
                      domainTransaction
                          .getCategoryColor(_isDarkMode)
                          .withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: domainTransaction
                        .getCategoryColor(_isDarkMode)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    domainTransaction.getCategoryIcon(),
                    color: domainTransaction.getCategoryColor(_isDarkMode),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontFamily: 'Onest',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: domainTransaction
                                .getCategoryColor(_isDarkMode)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            domainTransaction.displayCategory,
                            style: TextStyle(
                              color: domainTransaction
                                  .getCategoryColor(_isDarkMode),
                              fontSize: 12,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _isDarkMode ? Colors.white60 : Colors.black54,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount with Gradient Effect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: transaction.isOutflow
                        ? [Colors.red[400]!, Colors.red[300]!]
                        : [
                            _isDarkMode
                                ? Colors.green[400]!
                                : Colors.green[700]!,
                            _isDarkMode
                                ? Colors.green[300]!
                                : Colors.green[600]!,
                          ],
                  ).createShader(bounds),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '\$',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextSpan(
                          text: formattedWholeNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: '.$decimal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Onest',
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
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

  Widget _buildNewsAndUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.orange.shade400,
                          Colors.pink.shade400,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Onest',
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Text(
                      'Stay informed with latest updates',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade400.withOpacity(0.2),
                      Colors.orange.shade400.withOpacity(0.2),
                      Colors.pink.shade400.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _performHapticFeedback(haptics.HapticsType.light);
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  FadeTransition(
                            opacity: animation,
                            child: NewsStoriesViewer(
                              newsItems: _newsItems,
                              initialIndex: 0,
                            ),
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white
                                  : Colors.purple.shade700,
                              fontSize: 14,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _isDarkMode
                                ? Colors.white
                                : Colors.purple.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _newsItems.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 200 + (index * 100)),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(20 * (1 - value), 0),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: _buildEnhancedStoryCard(
                        _newsItems[index],
                        index,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Remove the duplicate build method and keep only one
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0A0F1E) : Colors.white,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _updateBlurEffect();
              return false;
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 60,
                  bottom: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildFinancialSummary(),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(),
                    ),
                    const SizedBox(height: 32),
                    _buildNewsAndUpdates(),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecentTransactions(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildGlassmorphicHeader(),
        ],
      ),
    );
  }

  Widget _buildBlinkAdvanceCard() {
    const cashAdvanceBlue = Color(0xFF1E3A4F);
    return GestureDetector(
      onTap: () {
        _performHapticFeedback(haptics.HapticsType.medium);
        if (_hasActiveAdvance || _isBlinkAdvanceApproved) {
          Navigator.of(context)
              .push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return BlinkAdvanceSplashScreen(bankAccountId: _bankAccountId);
              },
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          )
              .then((result) {
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                _activeAdvanceData = result;
                _hasActiveAdvance = true;
              });
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _blinkAdvanceStatus == 'On Review'
                    ? 'Your Blink Advance application is still under review.'
                    : 'You are not currently eligible for Blink Advance.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cashAdvanceBlue.withOpacity(0.98),
              const Color(0xFF0A2540).withOpacity(0.95),
            ],
            stops: const [0.2, 0.9],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cashAdvanceBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: cashAdvanceBlue.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle gradient overlay for depth
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                        Colors.black.withOpacity(0.05),
                      ],
                      stops: const [0.2, 0.5, 0.8],
                    ),
                  ),
                ),
              ),
              // Premium shine effect
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern icon container with refined styling
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/icons/icons8-check-dollar-96.png',
                        width: 32,
                        height: 32,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const Spacer(),
                    // Title and subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cash Advance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quick Funds',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'Onest',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Status and action section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                fontFamily: 'Onest',
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _hasActiveAdvance
                                      ? 'Active'
                                      : _blinkAdvanceStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _getStatusEmoji(),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
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
  }

  Widget _buildRepaymentFrontCard(Color color, Color textColor) {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);
    return GestureDetector(
      onTap: () {
        _flipRepaymentCard();
        _performHapticFeedback(haptics.HapticsType.medium);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              repaymentBlue.withOpacity(0.98),
              repaymentBlue.withOpacity(0.95),
            ],
            stops: const [0.2, 0.9],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: repaymentBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: repaymentBlue.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Subtle gradient overlay for depth
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                      Colors.black.withOpacity(0.05),
                    ],
                    stops: const [0.2, 0.5, 0.8],
                  ),
                ),
              ),
            ),
            // Premium shine effect
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Modern icon container with refined styling
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/icons/icons8-time-is-money-96.png',
                          width: 28,
                          height: 28,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      // Flip button
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _isRepaymentCardFlipped ? 0.75 : 0.25,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Professional title with trademark
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Blink\n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                            height: 0.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Repay',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 22,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepaymentBackCard(Color color, Color textColor) {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);
    final hasActiveAdvance = _activeAdvanceData != null;
    final repaymentAmount = hasActiveAdvance
        ? (double.tryParse(
                _activeAdvanceData!['total_repayment_amount']?.toString() ??
                    '0') ??
            0.0)
        : 0.0;
    final repaymentDate = hasActiveAdvance
        ? DateTime.tryParse(
                _activeAdvanceData!['repayment_date']?.toString() ?? '') ??
            DateTime.now()
        : DateTime.now();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            repaymentBlue.withOpacity(0.98),
            repaymentBlue.withOpacity(0.95),
          ],
          stops: const [0.2, 0.9],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 36),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: RichText(
                              textAlign: TextAlign.left,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '\$',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${currencyFormatter.format(repaymentAmount).split('.')[0].substring(1)}.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: currencyFormatter
                                        .format(repaymentAmount)
                                        .split('.')[1],
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Container(
                            width: 160,
                            height: 32,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: StreamBuilder<int>(
                              stream: Stream.periodic(
                                  const Duration(seconds: 1), (count) => count),
                              builder: (context, snapshot) {
                                final now = DateTime.now();
                                final difference =
                                    repaymentDate.difference(now);

                                final days = difference.inDays;
                                final hours = difference.inHours.remainder(24);
                                final minutes =
                                    difference.inMinutes.remainder(60);
                                final seconds =
                                    difference.inSeconds.remainder(60);

                                return Center(
                                  child: Text(
                                    '$days days, $hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Onest',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: GestureDetector(
                              onTap: () {
                                _performHapticFeedback(
                                    haptics.HapticsType.medium);
                                // TODO: Implement repayment action
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF40916C),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF40916C)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Repay Now',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.all(
                                          3), // Reduced padding
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 12, // Reduced size
                                      ),
                                    ),
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
              ],
            ),
          ),
          // Flip button positioned at top right
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () {
                _flipRepaymentCard();
                _performHapticFeedback(haptics.HapticsType.medium);
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isRepaymentCardFlipped ? 0.75 : 0.25,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(Transaction transaction) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _performHapticFeedback(haptics.HapticsType.light);
          _changeCategory(transaction);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: transaction
                      .getCategoryColor(_isDarkMode)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  transaction.getCategoryIcon(),
                  color: transaction.getCategoryColor(_isDarkMode),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.displayCategory,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: 16,
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    bool showCopy = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ??
                          (_isDarkMode ? Colors.blue[400] : Colors.blue[700]))!
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ??
                      (_isDarkMode ? Colors.blue[400] : Colors.blue[700]),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 16,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showCopy)
                IconButton(
                  onPressed: () {
                    _performHapticFeedback(haptics.HapticsType.light);
                    Clipboard.setData(ClipboardData(text: subtitle));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color:
                _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      _isDarkMode ? Colors.blue[400]! : Colors.blue[700]!,
                      _isDarkMode ? Colors.blue[500]! : Colors.blue[800]!,
                    ],
                  )
                : null,
            color: isPrimary
                ? null
                : _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : _isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary
                    ? Colors.white
                    : (_isDarkMode ? Colors.white : Colors.blue[700]),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? Colors.white
                      : (_isDarkMode ? Colors.white : Colors.blue[700]),
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _viewDetails(Transaction transaction) {
    _showTransactionDetails(transaction);
  }

  Color _getTransactionColor(Transaction transaction) {
    return transaction.getCategoryColor(_isDarkMode);
  }

  IconData _getTransactionIcon(Transaction transaction) {
    return transaction.getCategoryIcon();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetadataRows(Map<String, dynamic> metadata) {
    return metadata.entries
        .where(
            (entry) => entry.value != null && entry.value.toString().isNotEmpty)
        .map((entry) {
      final key =
          entry.key.split('_').map((word) => word.capitalize()).join(' ');
      final value = entry.value.toString();
      return _buildDetailRow(key, value);
    }).toList();
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

  Widget _buildGlassmorphicHeader() {
    final darkModeOpacity = (0.65 + (_scrollOffset / 1000)).clamp(0.0, 0.8);
    final lightModeOpacity = (0.8 + (_scrollOffset / 1000)).clamp(0.0, 0.95);
    final borderOpacity = (0.05 + (_scrollOffset / 500)).clamp(0.0, 0.1);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: math.max(8, _blurIntensity),
          sigmaY: math.max(8, _blurIntensity),
        ),
        child: Container(
          height: MediaQuery.of(context).padding.top + 52,
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF141B2E).withOpacity(darkModeOpacity)
                : Colors.white.withOpacity(lightModeOpacity),
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode
                    ? Colors.white.withOpacity(borderOpacity)
                    : Colors.black.withOpacity(borderOpacity),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 20,
              right: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Profile section
                GestureDetector(
                  onTap: () {
                    _performHapticFeedback(haptics.HapticsType.light);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    ).then((result) {
                      // If we got a new profile picture URL back, update it
                      if (result != null && result is String) {
                        final profileProvider = Provider.of<ProfileProvider>(
                            context,
                            listen: false);
                        profileProvider.updateProfilePicture(result);
                      }
                    });
                  },
                  child: Row(
                    children: [
                      // Avatar with Hero animation
                      Hero(
                        tag: 'profileAvatar',
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            border: Border.all(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isDarkMode
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Consumer<ProfileProvider>(
                              builder: (context, profileProvider, child) {
                                final profilePictureUrl =
                                    profileProvider.profilePictureUrl;
                                if (profilePictureUrl == null) {
                                  return _buildAvatarFallback();
                                }
                                return Image.network(
                                  profilePictureUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Log the error
                                    _logger.e(
                                        'Error loading profile image: $error');
                                    // Return fallback widget
                                    return _buildAvatarFallback();
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Greeting and Name
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black45,
                              fontSize: 12,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userName,
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right side - Action buttons
                Row(
                  children: [
                    _buildIconButton(
                      icon: Icons.add_rounded,
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        showDialog(
                          context: context,
                          builder: (context) => const QuickActionsScreen(),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.favorite_outline_rounded,
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        showDialog(
                          context: context,
                          builder: (context) => const FavoritesScreen(),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.notifications_outlined,
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        // TODO: Show notifications
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.blue[50],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.blue[700],
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Onest',
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStoryCard(Map<String, String> newsItem, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: 200,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF1A2942).withOpacity(0.7)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'newsImage-$index',
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        image: DecorationImage(
                          image: AssetImage(newsItem['imageUrl']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            newsItem['title']!,
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              newsItem['description']!,
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 12,
                                fontFamily: 'Onest',
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Financial Tips',
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.blue[700],
                                    fontSize: 10,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.blue[700],
                                size: 16,
                              ),
                            ],
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
  }

  Future<void> _loadProfilePicture() async {
    if (!mounted) return;

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final userId = storageService.getUserId();

      if (userId != null) {
        await profileProvider.loadProfilePicture(userId);
      }
    } catch (e) {
      _logger.e('Error in _loadProfilePicture: $e');
    }
  }

  Future<void> _loadDailyTransactionSummary() async {
    if (!mounted) return;

    try {
      setState(() {
        _isChartLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final response = await authService.getDailyTransactionSummary();

      final List<auth.DailyTransactionSummary> summary =
          (response['summary'] as List)
              .map((item) => auth.DailyTransactionSummary.fromJson(item))
              .toList();

      if (!mounted) return;

      setState(() {
        _dailyTransactionSummary = summary;
        _isChartLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading daily transaction summary: $e');
      if (mounted) {
        setState(() {
          _isChartLoading = false;
        });
      }
    }
  }

  void _showTransactionDetails(Transaction transaction) {
    _performHapticFeedback(haptics.HapticsType.medium);
    // Implementation of transaction details view
    // This can be expanded based on your needs
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
}
