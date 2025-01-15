import 'dart:math' show Random, max;
import 'dart:math' as math;
import 'dart:ui';
import 'package:blink_app/models/transaction.dart';
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
import 'package:blink_app/widgets/animated_gradient_background.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/home/presentation/news_stories_viewer.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:blink_app/features/transactions/domain/models/transaction_category.dart';
import 'package:blink_app/features/transactions/presentation/widgets/category_selector_sheet.dart';
import '../../../features/transactions/presentation/widgets/custom_category_creator.dart';
import '../../../features/transactions/domain/services/transaction_service.dart';
import '../../../models/transaction.dart';
import 'package:blink_app/services/supabase_storage_service.dart';
import 'package:blink_app/features/notifications/presentation/notifications_screen.dart';
import 'package:blink_app/providers/profile_provider.dart';
import 'package:blink_app/features/transactions/presentation/screens/all_transactions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Transaction {
  final String id;
  final String merchantName;
  final double amount;
  final DateTime date;
  TransactionCategory? category;
  final bool isOutflow;

  Transaction({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    this.category,
    required this.isOutflow,
  });

  // Factory constructor to convert from auth.Transaction
  factory Transaction.fromAuthTransaction(auth.Transaction authTransaction) {
    return Transaction(
      id: authTransaction.id,
      merchantName: authTransaction.merchantName,
      amount: authTransaction.amount,
      date: authTransaction.date,
      isOutflow: authTransaction.isOutflow,
    );
  }
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
  String? _profilePictureUrl;
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

  late final TransactionService _transactionService;

  // Initialize controller without late
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
    _performHapticFeedback(haptics.HapticsType.medium);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<auth.TransactionDetail>(
        future: Provider.of<auth.AuthService>(context, listen: false)
            .getTransactionDetails(transaction.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _logger.e('Error fetching transaction details: ${snapshot.error}');
            return TransactionDetailsSheet(
              transaction: Transaction(
                id: transaction.id,
                merchantName: transaction.merchantName ?? 'Unknown Merchant',
                amount: transaction.amount,
                date: transaction.date,
                category: transaction.category != null
                    ? TransactionCategory(
                        id: transaction.category!,
                        name: transaction.category!,
                        color: Colors.blue,
                        icon: _getCategoryIcon(transaction.category!),
                      )
                    : null,
                isOutflow: transaction.amount > 0,
              ),
              isDarkMode: _isDarkMode,
            );
          }

          final detailedTransaction = snapshot.data!;
          return TransactionDetailsSheet(
            transaction: Transaction(
              id: detailedTransaction.id,
              merchantName:
                  detailedTransaction.merchantName ?? 'Unknown Merchant',
              amount: detailedTransaction.amount,
              date: detailedTransaction.date,
              category: detailedTransaction.category != null
                  ? TransactionCategory(
                      id: detailedTransaction.category!,
                      name: detailedTransaction.category!,
                      color: Colors.blue,
                      icon: _getCategoryIcon(detailedTransaction.category!),
                    )
                  : null,
              isOutflow: detailedTransaction.amount > 0,
            ),
            isDarkMode: _isDarkMode,
            metadata: detailedTransaction.metadata,
          );
        },
      ),
    );
  }

  void _changeCategory(auth.Transaction transaction) {
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
            // TODO: Call backend API to update category
            setState(() {
              transaction.category = category.name;
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
                      transaction.category = currentCategory.name;
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

  void _addNote(auth.Transaction transaction) {
    _performHapticFeedback(haptics.HapticsType.medium);
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
                MaterialPageRoute(
                  builder: (context) =>
                      BlinkAdvanceScreen(bankAccountId: _bankAccountId),
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
          content: Text(
            _blinkAdvanceStatus == 'On Review'
                ? 'Your Blink Advance application is still under review. Please check back later.'
                : 'You are not currently eligible for Blink Advance. Please check back later or contact support for more information.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleTransactionCategorization(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDarkMode ? const Color(0xFF1D1E33) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: CustomCategoryCreator(
              onCategoryCreated: (category) async {
                try {
                  await _transactionService.updateTransactionCategory(
                    transactionId: transaction.id,
                    category: category as TransactionCategory,
                  );
                  setState(() {
                    transaction.category = category as TransactionCategory;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transaction category updated successfully',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      backgroundColor: _isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      action: SnackBarAction(
                        label: 'Dismiss',
                        textColor: _isDarkMode ? Colors.white70 : Colors.blue,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update transaction category',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      action: SnackBarAction(
                        label: 'Retry',
                        textColor: _isDarkMode ? Colors.white70 : Colors.red,
                        onPressed: () {
                          _handleTransactionCategorization(transaction);
                        },
                      ),
                    ),
                  );
                }
              },
              isDarkMode: _isDarkMode,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionListItem(Transaction transaction) {
    final formattedDate = DateFormat('MMM d, yyyy').format(transaction.date);

    return GestureDetector(
      onTap: () {
        // Find the corresponding auth.Transaction from _recentTransactions
        final authTransaction = _recentTransactions.firstWhere(
          (t) => t.id == transaction.id,
          orElse: () => throw Exception('Transaction not found'),
        );
        _viewDetails(authTransaction);
      },
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) {
                _performHapticFeedback(haptics.HapticsType.medium);
                _handleTransactionCategorization(transaction);
              },
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.fromLTRB(0, 4, 8, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _isDarkMode ? const Color(0xFF1A2942) : Colors.white,
                      _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      color: _isDarkMode ? Colors.white : Colors.orange[700],
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  _isDarkMode ? Colors.white12 : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: _isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (transaction.category != null)
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: transaction.category!.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: transaction.category!.color.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      transaction.category!.icon,
                      color: transaction.category!.color,
                      size: 24,
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      color: _isDarkMode ? Colors.white54 : Colors.black45,
                      size: 24,
                    ),
                  ),
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
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isDarkMode ? Colors.white60 : Colors.black54,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: transaction.isOutflow
                        ? Colors.red[400]
                        : (_isDarkMode ? Colors.green[400] : Colors.green[700]),
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

    _loadProfilePicture();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    _animationController.dispose();
    _emojiAnimationController.dispose();
    _repaymentEmojiAnimationController.dispose();
    _insightsEmojiAnimationController.dispose();
    _pulseController.dispose();
    _blinkCardExpandController.dispose();
    _shimmerController.dispose();
    _flipController.dispose();

    // Remove scroll controller listener and dispose
    _scrollController.removeListener(_updateBlurEffect);
    _scrollController.dispose();

    // Always call super.dispose() last
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
    if (!mounted) return;

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final supabaseStorage =
          Provider.of<SupabaseStorageService>(context, listen: false);

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
        _profilePictureUrl = profilePicture;
      });
    } catch (e) {
      _logger.e('Error loading user info: $e');
      rethrow;
    }
  }

  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;

    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final userId = storageService.getUserId();
      if (userId == null) throw Exception('User ID not found');

      final transactions = await authService.getRecentTransactions(userId);

      if (!mounted) return;

      setState(() {
        _recentTransactions = transactions;
      });
    } catch (e) {
      _logger.e('Error loading recent transactions: $e');
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
      final status = await authService.getBlinkAdvanceApprovalStatus();
      final activeAdvanceResponse = await authService.getActiveBlinkAdvance();

      if (!mounted) return;

      setState(() {
        _isBlinkAdvanceApproved = status['isApproved'] ?? false;
        _blinkAdvanceStatus = status['status'] ?? 'Unknown';
        _hasActiveAdvance = activeAdvanceResponse['hasActiveAdvance'] ?? false;
        _activeAdvance = activeAdvanceResponse['activeAdvance'];
        _isBlinkAdvanceLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading Blink Advance status: $e');
      if (mounted) {
        setState(() {
          _isBlinkAdvanceLoading = false;
          _blinkAdvanceStatus = 'Error';
          _hasActiveAdvance = false;
          _activeAdvance = null;
        });
      }
      rethrow;
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
    _repaymentEmojiAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _repaymentEmojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _insightsEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _insightsEmojiAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(
        parent: _insightsEmojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

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

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_shimmerController);
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
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_flipAnimation.value),
                  alignment: Alignment.center,
                  child: _isCardFlipped && _flipAnimation.value >= math.pi / 2
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: _buildBackCard(),
                        )
                      : _buildFrontCard(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color(0xFF1A2942).withOpacity(0.9),
                  const Color(0xFF141B2E).withOpacity(0.95),
                ]
              : [
                  Colors.blue[700]!.withOpacity(0.9),
                  Colors.blue[900]!.withOpacity(0.95),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.4)
                : Colors.blue[900]!.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: _buildShimmerEffect(),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Chip Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/blink-logo.png',
                        height: 28,
                        width: 100,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/chip.png',
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          _buildFlipButton(),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Balance Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Onest',
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                    fontSize: 32,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${currencyFormatter.format(animatedBalance).split('.')[0].substring(1)}.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
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
                                    fontSize: 24,
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
                  const SizedBox(height: 16),
                  // Account Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _primaryAccountName ?? 'Primary Account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Onest',
                        ),
                      ),
                      Row(
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
                              fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return GestureDetector(
      onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [
                    const Color(0xFF141B2E).withOpacity(0.95),
                    const Color(0xFF1A2942).withOpacity(0.9),
                  ]
                : [
                    Colors.blue[900]!.withOpacity(0.95),
                    Colors.blue[700]!.withOpacity(0.9),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.4)
                  : Colors.blue[900]!.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: _buildShimmerEffect(),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction History',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildFlipButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _isChartLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white.withOpacity(0.7),
                                ),
                              ),
                            )
                          : _dailyTransactionSummary.isEmpty
                              ? Center(
                                  child: Text(
                                    'No transaction data available',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
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
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 32,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            // Only show first and last dates
                                            if (value.toInt() == 0 ||
                                                value.toInt() ==
                                                    _dailyTransactionSummary
                                                            .length -
                                                        1) {
                                              final date =
                                                  _dailyTransactionSummary[
                                                          value.toInt()]
                                                      .date;
                                              // Ensure we're not duplicating labels
                                              if ((value.toInt() == 0 &&
                                                      meta.min != value) ||
                                                  (value.toInt() ==
                                                          _dailyTransactionSummary
                                                                  .length -
                                                              1 &&
                                                      meta.max != value)) {
                                                return const SizedBox();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  DateFormat('MMM d')
                                                      .format(date),
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                    fontFamily: 'Onest',
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const SizedBox();
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _dailyTransactionSummary
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return FlSpot(
                                            entry.key.toDouble(),
                                            entry.value.totalAmount,
                                          );
                                        }).toList(),
                                        isCurved: true,
                                        color: Colors.white.withOpacity(0.9),
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter:
                                              (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 2,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              strokeWidth: 2,
                                              strokeColor:
                                                  Colors.white.withOpacity(0.2),
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withOpacity(0.2),
                                              Colors.white.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        fitInsideHorizontally: true,
                                        fitInsideVertically: true,
                                        tooltipRoundedRadius: 12,
                                        tooltipPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        tooltipBorder: BorderSide(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                        tooltipMargin: 8,
                                        rotateAngle: 0,
                                        getTooltipItems:
                                            (List<LineBarSpot> touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final date =
                                                _dailyTransactionSummary[
                                                        spot.x.toInt()]
                                                    .date;
                                            final amount =
                                                spot.y.toStringAsFixed(2);
                                            return LineTooltipItem(
                                              '${DateFormat('MMM d').format(date)}',
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontFamily: 'Onest',
                                                fontWeight: FontWeight.w600,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: '\n\$${amount}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 16,
                                                    fontFamily: 'Onest',
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList();
                                        },
                                      ),
                                      handleBuiltInTouches: true,
                                      touchCallback: (event, response) {
                                        if (event.isInterestedForInteractions &&
                                            response?.lineBarSpots != null) {
                                          _performHapticFeedback(
                                              haptics.HapticsType.selection);
                                        }
                                      },
                                    ),
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

  Widget _buildQuickActions() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 56) / 2; // Half width minus padding and gap
    final cardHeight = cardWidth * 1.9; // Keep current height ratio

    return Container(
      height: cardHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Container(
              width: cardWidth,
              height: cardHeight,
              child: _buildBlinkAdvanceCard(),
            ),
          ),
          Container(
            width: cardWidth,
            height: cardHeight,
            margin: const EdgeInsets.only(left: 16),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildQuickActionCard(
                    title: 'Repayment',
                    color: _isDarkMode
                        ? const Color(0xFF1E3B2F)
                        : Colors.green[100]!,
                    textColor: _isDarkMode ? Colors.white : Colors.green[800]!,
                    onTap: () {
                      _performHapticFeedback(haptics.HapticsType.medium);
                      // TODO: Implement repayment functionality
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
                    textColor: _isDarkMode ? Colors.white : Colors.purple[800]!,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (_) {
            _performHapticFeedback(haptics.HapticsType.light);
            setState(() {
              if (title == 'Repayment') {
                _repaymentEmojiAnimationController.forward();
              } else {
                _insightsEmojiAnimationController.forward();
              }
            });
          },
          onTapUp: (_) {
            if (title == 'Repayment') {
              _repaymentEmojiAnimationController.reverse();
            } else {
              _insightsEmojiAnimationController.reverse();
            }
            onTap();
          },
          onTapCancel: () {
            if (title == 'Repayment') {
              _repaymentEmojiAnimationController.reverse();
            } else {
              _insightsEmojiAnimationController.reverse();
            }
          },
          child: AnimatedBuilder(
            animation: title == 'Repayment'
                ? _repaymentEmojiAnimationController
                : _insightsEmojiAnimationController,
            builder: (context, child) {
              final scale = title == 'Repayment'
                  ? Tween<double>(begin: 1.0, end: 0.95)
                      .animate(CurvedAnimation(
                        parent: _repaymentEmojiAnimationController,
                        curve: Curves.easeInOutCubic,
                      ))
                      .value
                  : Tween<double>(begin: 1.0, end: 0.95)
                      .animate(CurvedAnimation(
                        parent: _insightsEmojiAnimationController,
                        curve: Curves.easeInOutCubic,
                      ))
                      .value;

              return Transform.scale(
                scale: scale,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Shimmer effect
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Transform.rotate(
                              angle: -0.7853981634,
                              child: AnimatedBuilder(
                                animation: _shimmerAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      _shimmerAnimation.value * 200,
                                    ),
                                    child: Container(
                                      width: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.1),
                                            Colors.white.withOpacity(0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: title == 'Repayment'
                                    ? Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: textColor,
                                        size: 24,
                                      )
                                    : Image.asset(
                                        'assets/images/glasses_3d.png',
                                        width: 24,
                                        height: 24,
                                        color: textColor,
                                      ),
                              ),
                              const Spacer(),
                              Text(
                                title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    title == 'Repayment'
                                        ? 'View Details'
                                        : 'Analyze',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.7),
                                      fontSize: 14,
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: _isDarkMode ? Colors.white : Colors.black,
                fontSize: 24,
                fontFamily: 'Onest',
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF1A2942).withOpacity(0.7)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  foregroundColor: _isDarkMode ? Colors.white : Colors.blue,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.blue[700],
                        fontSize: 14,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _isDarkMode ? Colors.white : Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), // Reduced from 16 to 12
        _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isDarkMode ? Colors.white : Colors.blue,
                  ),
                ),
              )
            : _recentTransactions.isEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 32, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isDarkMode
                            ? [
                                const Color(0xFF1E2A45).withOpacity(0.7),
                                const Color(0xFF1A2942).withOpacity(0.7),
                              ]
                            : [
                                Colors.grey[100]!,
                                Colors.grey[50]!,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDarkMode
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 32,
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Recent Transactions',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your recent transactions will appear here',
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.7)
                                : Colors.black54,
                            fontSize: 14,
                            fontFamily: 'Onest',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero, // Remove default padding
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      final isLastItem =
                          index == _recentTransactions.length - 1;
                      return Column(
                        children: [
                          _buildTransactionListItem(
                            Transaction.fromAuthTransaction(
                                _recentTransactions[index]),
                          ),
                          if (!isLastItem)
                            const SizedBox(height: 4), // Reduced from 6 to 4
                        ],
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildNewsAndUpdates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            Container(
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? const Color(0xFF1A2942).withOpacity(0.7)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  _performHapticFeedback(haptics.HapticsType.light);
                  // TODO: Implement navigation to all news
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  foregroundColor: _isDarkMode ? Colors.white : Colors.blue,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : Colors.blue[700],
                        fontSize: 14,
                        fontFamily: 'Onest',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: _isDarkMode ? Colors.white : Colors.blue[700],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _newsItems.length,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 8),
            itemBuilder: (context, index) {
              return _buildNewsCard(_newsItems[index], index);
            },
          ),
        ),
      ],
    );
  }

  double _calculateInterval() {
    if (_dailyTransactionSummary.isEmpty) return 1.0;
    final values = _dailyTransactionSummary.map((e) => -e.totalAmount).toList();
    final range = values.reduce(math.max) - values.reduce(math.min);
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
    return _dailyTransactionSummary.map((e) => -e.totalAmount).reduce(math.min);
  }

  double _getMaxY() {
    if (_dailyTransactionSummary.isEmpty) return 1;
    return _dailyTransactionSummary.map((e) => -e.totalAmount).reduce(math.max);
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
            color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black12,
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
          color: _isDarkMode ? Colors.blue[400] : Colors.blue[600],
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isLast = index == _getChartSpots().length - 1;
              return FlDotCirclePainter(
                radius: isLast ? 6 * _pulseController.value : 0,
                color: _isDarkMode ? Colors.blue[400]! : Colors.blue[600]!,
                strokeWidth: isLast ? 2 : 0,
                strokeColor: _isDarkMode ? Colors.white : Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                (_isDarkMode ? Colors.blue[400]! : Colors.blue[600]!)
                    .withOpacity(0.2),
                (_isDarkMode ? Colors.blue[400]! : Colors.blue[600]!)
                    .withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassmorphicHeader() {
    final profileProvider = Provider.of<ProfileProvider>(context);
    _profilePictureUrl = profileProvider.profilePictureUrl;

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
                color: (_isDarkMode ? Colors.white : Colors.black)
                    .withOpacity(borderOpacity),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 8,
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
                        setState(() {
                          _profilePictureUrl = result;
                        });
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
                            child: _profilePictureUrl != null
                                ? Image.network(
                                    _profilePictureUrl!,
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
                                  )
                                : _buildAvatarFallback(),
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
                    _buildActionButton(
                      icon: Icons.add_rounded,
                      onPressed: () =>
                          _performHapticFeedback(haptics.HapticsType.light),
                      showBadge: false,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.favorite_outline_rounded,
                      onPressed: () =>
                          _performHapticFeedback(haptics.HapticsType.light),
                      showBadge: false,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.search_rounded,
                      onPressed: () =>
                          _performHapticFeedback(haptics.HapticsType.light),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.notifications_outlined,
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      showBadge: true,
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
    return Center(
      child: Text(
        _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _isDarkMode ? Colors.white : Colors.blue[700],
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Onest',
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool showBadge = false,
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
      child: Stack(
        children: [
          Material(
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
          if (showBadge)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlinkAdvanceCard() {
    return GestureDetector(
      onTap: () {
        _performHapticFeedback(haptics.HapticsType.medium);
        if (_hasActiveAdvance) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  BlinkAdvanceScreen(bankAccountId: _bankAccountId),
            ),
          );
        } else if (_isBlinkAdvanceApproved) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  BlinkAdvanceScreen(bankAccountId: _bankAccountId),
            ),
          );
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
            colors: _isDarkMode
                ? [
                    const Color(0xFF1E2A45).withOpacity(0.9),
                    const Color(0xFF1A2942).withOpacity(0.95),
                  ]
                : [
                    Colors.blue[100]!.withOpacity(0.9),
                    Colors.blue[50]!.withOpacity(0.95),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.blue.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: _isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_hasActiveAdvance || _isBlinkAdvanceApproved)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: -0.7853981634,
                      child: AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _shimmerAnimation.value * 200,
                            ),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0),
                                    Colors.white.withOpacity(0.1),
                                    Colors.white.withOpacity(0),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FluentUiEmojiIcon(
                      fl: Fluents.flHighVoltage,
                      w: 48,
                      h: 48,
                    ),
                    const Spacer(),
                    SvgPicture.asset(
                      _isDarkMode
                          ? 'assets/images/blink-logo2.svg'
                          : 'assets/images/blink-logo3.svg',
                      height: 28,
                      width: 100,
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white70
                                    : Colors.blue[600],
                                fontSize: 14,
                                fontFamily: 'Onest',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  _hasActiveAdvance
                                      ? 'Active'
                                      : _blinkAdvanceStatus,
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.blue[800],
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
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color:
                                _isDarkMode ? Colors.white : Colors.blue[800],
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedGradientBackground(
        isDarkMode: _isDarkMode,
        child: Column(
          children: [
            _buildGlassmorphicHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  _performHapticFeedback(haptics.HapticsType.medium);
                  await Future.wait([
                    _loadData(),
                    _loadBlinkAdvanceStatus(),
                  ]);
                },
                color: _isDarkMode ? Colors.white : Colors.blue,
                backgroundColor:
                    _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildFinancialSummary(),
                        const SizedBox(height: 20),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        _buildRecentTransactions(),
                        const SizedBox(height: 20), // Reduced from 24 to 20
                        _buildNewsAndUpdates(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
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
      _logger.e('Error loading daily transaction summary: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await Future.wait([
        _loadUserInfo(),
        _loadRecentTransactions(),
        _loadCurrentBalances(),
      ]);
    } catch (e) {
      _logger.e('Error loading data: $e');
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildShimmerEffect() {
    return IgnorePointer(
      child: Transform.rotate(
        angle: -0.7853981634, // -45 degrees in radians
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _shimmerAnimation.value * 400),
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _loadProfilePicture() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final userId = storageService.getUserId();

    if (userId != null) {
      await profileProvider.loadProfilePicture(userId);
    }
  }
}

class TransactionDetailsSheet extends StatefulWidget {
  final Transaction transaction;
  final bool isDarkMode;
  final Map<String, dynamic>? metadata;

  const TransactionDetailsSheet({
    Key? key,
    required this.transaction,
    required this.isDarkMode,
    this.metadata,
  }) : super(key: key);

  @override
  State<TransactionDetailsSheet> createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1A2942) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTransactionDetails(),
              if (widget.metadata != null && widget.metadata!.isNotEmpty)
                _buildMetadata(),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDarkMode
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.transaction.merchantName,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontSize: 24,
              fontFamily: 'Onest',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    final currencyFormatter = NumberFormat.currency(symbol: '\$');
    return Column(
      children: [
        // Amount Card with Transaction Status
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.transaction.isOutflow
                  ? [
                      Colors.red.withOpacity(0.1),
                      Colors.redAccent.withOpacity(0.05),
                    ]
                  : [
                      Colors.green.withOpacity(0.1),
                      Colors.greenAccent.withOpacity(0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Stack(
            children: [
              if (widget.metadata?['pending'] == true)
                Positioned(
                  right: 16,
                  top: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pending_outlined,
                          size: 14,
                          color: widget.isDarkMode
                              ? Colors.white70
                              : Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pending',
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white70
                                : Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Onest',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.transaction.isOutflow
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: widget.transaction.isOutflow
                              ? Colors.red[400]
                              : Colors.green[400],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyFormatter.format(widget.transaction.amount),
                          style: TextStyle(
                            color: widget.transaction.isOutflow
                                ? Colors.red[400]
                                : Colors.green[400],
                            fontSize: 36,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.transaction.isOutflow ? 'Expense' : 'Income',
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.white.withOpacity(0.7)
                            : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main Details Section
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildDetailSection(
                'Transaction Details',
                Icons.receipt_long_rounded,
                [
                  _buildDetailRowEnhanced(
                    'Date',
                    DateFormat('MMMM dd, yyyy').format(widget.transaction.date),
                    Icons.calendar_today_rounded,
                  ),
                  if (widget.metadata?['description'] != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRowEnhanced(
                      'Description',
                      widget.metadata!['description'],
                      Icons.description_outlined,
                    ),
                  ],
                  if (widget.metadata?['original_description'] != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRowEnhanced(
                      'Original Description',
                      widget.metadata!['original_description'],
                      Icons.description_outlined,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Category Section
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildDetailSection(
                'Category Information',
                Icons.category_rounded,
                [
                  _buildDetailRowEnhanced(
                    'Main Category',
                    widget.metadata?['category'] ?? 'Uncategorized',
                    Icons.folder_rounded,
                  ),
                  if (widget.metadata?['category_detailed'] != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRowEnhanced(
                      'Detailed Category',
                      widget.metadata!['category_detailed'],
                      Icons.folder_special_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Account Information
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildDetailSection(
                'Account Information',
                Icons.account_balance_rounded,
                [
                  if (widget.metadata?['account_id'] != null)
                    _buildDetailRowEnhanced(
                      'Account ID',
                      widget.metadata!['account_id'],
                      Icons.credit_card_rounded,
                    ),
                  if (widget.metadata?['bank_account_id'] != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRowEnhanced(
                      'Bank Account ID',
                      widget.metadata!['bank_account_id'],
                      Icons.account_balance_wallet_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Transaction IDs Section
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              _buildDetailSection(
                'Transaction IDs',
                Icons.numbers_rounded,
                [
                  _buildDetailRowEnhanced(
                    'Transaction ID',
                    widget.metadata?['transaction_id'] ?? widget.transaction.id,
                    Icons.tag_rounded,
                  ),
                  if (widget.metadata?['id'] != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRowEnhanced(
                      'Internal ID',
                      widget.metadata!['id'],
                      Icons.fingerprint_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(
      String title, IconData titleIcon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                titleIcon,
                color: widget.isDarkMode ? Colors.white70 : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRowEnhanced(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: widget.isDarkMode ? Colors.white70 : Colors.blue[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: widget.isDarkMode
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black54,
                  fontSize: 14,
                  fontFamily: 'Onest',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: widget.isDarkMode ? Colors.white70 : Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Details',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontFamily: 'Onest',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.metadata!.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildDetailRowEnhanced(
                      entry.key,
                      entry.value.toString(),
                      Icons.label_outline_rounded,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              // Implement edit category functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.isDarkMode ? Colors.white : Colors.blue[800],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: widget.isDarkMode ? Colors.black87 : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Category',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.black87 : Colors.white,
                    fontSize: 16,
                    fontFamily: 'Onest',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
