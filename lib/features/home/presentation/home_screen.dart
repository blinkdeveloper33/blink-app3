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
    // TODO: Implement view details functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${transaction.merchantName}')),
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
          ],
        ),
        const Spacer(),
        SvgPicture.asset(
          _isDarkMode
              ? 'assets/images/blink-logo2.svg'
              : 'assets/images/blink-logo3.svg',
          height: 28,
          colorFilter: ColorFilter.mode(
            _isDarkMode ? Colors.white : Colors.blue[800]!,
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
                _performHapticFeedback(haptics.HapticsType.medium);
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
                    color: _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      _isDarkMode
                          ? 'assets/images/blink-logo2.svg'
                          : 'assets/images/blink-logo3.svg',
                      height: 28,
                      colorFilter: ColorFilter.mode(
                        _isDarkMode ? Colors.white : Colors.blue[800]!,
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
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: _isDarkMode ? Colors.white : Colors.blue[800],
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
                _performHapticFeedback(haptics.HapticsType.medium);
                // TODO: Implement contact support functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDarkMode ? Colors.white : Colors.blue[800],
                foregroundColor:
                    _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
              ),
              child: const Text('Contact Support'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBlinkAdvanceTap() {
    _performHapticFeedback(haptics.HapticsType.medium);
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

    return Slidable(
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
    );
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
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
        parent: _emojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _repaymentEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _repaymentEmojiAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _repaymentEmojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _insightsEmojiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _insightsEmojiAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _insightsEmojiAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Initialize services and load data
    _transactionService = TransactionService();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    await _loadData();
    await _fetchAndStoreDetailedBankAccounts();
    await _loadBlinkAdvanceStatus();
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: _isDarkMode
                ? const Color(0xFF141B2E).withOpacity(0.95)
                : Colors.white,
            boxShadow: [
              BoxShadow(
                color: _isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _performHapticFeedback(haptics.HapticsType.medium);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const AccountScreen()),
                        );
                      },
                      child: Hero(
                        tag: 'profilePicture',
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: _isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              color:
                                  _isDarkMode ? Colors.white : Colors.black54,
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
                                color:
                                    _isDarkMode ? Colors.white : Colors.black87,
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
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.black54,
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.notifications_none_rounded,
                              color:
                                  _isDarkMode ? Colors.white : Colors.black54,
                              size: 26,
                            ),
                            onPressed: () {
                              _performHapticFeedback(haptics.HapticsType.light);
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
                                border: Border.all(
                                  color: _isDarkMode
                                      ? const Color(0xFF1A2942)
                                      : Colors.white,
                                  width: 1.5,
                                ),
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
                  ),
                  const SizedBox(width: 8),
                  FadeIn(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.support_agent_rounded,
                          color: _isDarkMode ? Colors.white : Colors.black54,
                          size: 24,
                        ),
                        onPressed: () {
                          _performHapticFeedback(haptics.HapticsType.light);
                          // TODO: Implement support/help functionality
                        },
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

  Widget _buildFinancialSummary() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: _isDarkMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF141B2E).withOpacity(0.95),
                      const Color(0xFF1A2942).withOpacity(0.85),
                    ],
                  )
                : null,
            color: _isDarkMode ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: _isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              width: 1,
            ),
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
                  Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: AnimatedRotation(
                        turns: _isChartExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      onPressed: () {
                        _performHapticFeedback(haptics.HapticsType.light);
                        setState(() {
                          _isChartExpanded = !_isChartExpanded;
                        });
                        if (_isChartExpanded &&
                            _dailyTransactionSummary.isEmpty) {
                          _loadDailyTransactionSummary();
                        }
                      },
                    ),
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
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              '${currencyFormatter.format(animatedBalance).split('.')[0].substring(1)}.',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
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
                            color: _isDarkMode ? Colors.white : Colors.black,
                            fontSize: 22,
                            fontFamily: 'Onest',
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
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _isDarkMode ? const Color(0xFF1E2A45) : Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: _isBlinkAdvanceExpanded
                    ? _buildExpandedBlinkAdvanceContent()
                    : _buildCollapsedBlinkAdvanceContent(),
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
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? const Color(0xFF1E3B2F)
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Repayment',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white : Colors.green[800],
                            fontSize: 16,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? const Color(0xFF2A1E45)
                            : Colors.purple[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Insights',
                          style: TextStyle(
                            color:
                                _isDarkMode ? Colors.white : Colors.purple[800],
                            fontSize: 16,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
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

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentTransactions.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF141B2E).withOpacity(0.7)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 48,
                            color: _isDarkMode
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recent transactions',
                            style: TextStyle(
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 16,
                              fontFamily: 'Onest',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentTransactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionListItem(
                        Transaction.fromAuthTransaction(
                            _recentTransactions[index]),
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

  @override
  void dispose() {
    _animationController.dispose();
    _emojiAnimationController.dispose();
    _repaymentEmojiAnimationController.dispose();
    _insightsEmojiAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: _isDarkMode ? const Color(0xFF0A0F1F) : Colors.white,
      body: Container(
        decoration: _isDarkMode
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A0F1F),
                    const Color(0xFF141B2E),
                    const Color(0xFF0A0F1F),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildFinancialSummary(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black,
                              fontSize: 20,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
