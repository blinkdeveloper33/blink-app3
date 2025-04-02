import 'dart:math' show Random, max, min;
import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
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
import 'package:blink_app/features/home/presentation/news_story_detail_screen.dart';
import 'package:blink_app/services/auth_service.dart' show TransactionDetail;
import 'package:blink_app/features/transactions/domain/services/category_service.dart';
import 'package:blink_app/utils/temp_localizations.dart'; // Added temporary localization
import 'package:http/http.dart' as http;
import 'package:blink_app/config/api_config.dart';
import 'package:blink_app/core/utils/responsive_utils.dart'
    show ResponsiveUtils, DeviceType;
import 'package:animated_emoji/animated_emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:blink_app/features/home/presentation/widgets/blink_advance_card.dart';
import 'package:blink_app/features/insights/presentation/widgets/insights_quick_action_card.dart';
import 'package:blink_app/features/repayment/presentation/widgets/blink_repay_card.dart';
import 'package:blink_app/features/home/presentation/widgets/recent_transactions_section.dart';
import 'package:blink_app/features/home/presentation/widgets/stories_section.dart';
import 'package:blink_app/features/home/domain/services/news_service.dart';
import 'package:blink_app/features/home/domain/models/news_item.dart';

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
  double _currentBalance = 0.0;
  DateTime? _balanceLastUpdated;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _userName = '';
  String _bankAccountId = '';
  String? _primaryAccountName;
  String? _primaryAccountMask;
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

  // News items related state
  List<Map<String, String>> _newsItems = [];
  bool _isNewsLoading = true;
  NewsService? _newsService;

  // Feature flags - can be switched on/off
  // NOTE: The news section is temporarily disabled.
  // To re-enable it, simply change the value below to 'true'
  bool _showNewsSection = false; // Turn off news section temporarily

  // Asset report status related variables
  bool _hasPendingAssetReport = false;
  String? _pendingAssetReportToken;
  DateTime? _assetReportCreatedAt;
  String _assetReportStatus = '';
  bool _isAssetReportLoading = false;
  Timer? _assetReportCheckTimer;

  late AnimationController _emojiAnimationController;
  late Animation<double> _emojiAnimation;

  late AnimationController _repaymentEmojiAnimationController;
  late AnimationController _insightsEmojiAnimationController;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _blurIntensity = 0;

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

  // Add a pulse animation controller for urgent repayments
  late AnimationController _repayPulseController;
  late Animation<double> _repayPulseAnimation;

  void _performHapticFeedback(haptics.HapticsType type) {
    if (_hapticFeedbackEnabled) {
      haptics.Haptics.vibrate(type);
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

    // Setup pulse animation for repayment button if needed
    _setupRepaymentPulseAnimation();

    // Check for pending asset reports
    _checkForPendingAssetReports();

    // If an active advance exists, show the repayment details by flipping the card
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted && _hasActiveAdvance && _activeAdvanceData != null) {
        print("🔄 Auto-flipping repayment card to show active advance details");
        if (!_isRepaymentCardFlipped) {
          _flipRepaymentCard();
        }
      }
    });

    // Initialize NewsService and load news only if the feature is enabled
    if (_showNewsSection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final authService =
            Provider.of<auth.AuthService>(context, listen: false);
        _newsService = NewsService(authService);
        _loadNewsItems();
      });
    }
  }

  Future<void> _loadNewsItems() async {
    if (!mounted || _newsService == null) return;

    setState(() {
      _isNewsLoading = true;
    });

    try {
      final newsItems = await _newsService!.getNewsItems();

      if (mounted) {
        setState(() {
          // Convert NewsItem objects to the Map<String, String> format used by the app
          _newsItems = newsItems.map((item) => item.toDisplayMap()).toList();
          _isNewsLoading = false;
        });
      }
    } catch (e) {
      _logger.e('Error loading news items: $e');

      if (mounted) {
        setState(() {
          _isNewsLoading = false;
        });
      }
    }
  }

  void _setupRepaymentPulseAnimation() {
    _repayPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _repayPulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1.0,
      ),
    ]).animate(_repayPulseController);

    _repayPulseController.repeat();
  }

  @override
  void dispose() {
    // Dispose of all animation controllers
    _animationController.dispose();
    _emojiAnimationController.dispose();
    _repaymentEmojiAnimationController.dispose();
    _insightsEmojiAnimationController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();

    // Check if _blinkCardExpandController is initialized before disposing it
    if (_blinkCardExpandController != null) {
      _blinkCardExpandController.dispose();
    }

    _flipController.dispose();
    _repaymentFlipController.dispose();
    _repayPulseController.dispose();

    // Cancel any active timers
    _messageTimer?.cancel();
    _assetReportCheckTimer?.cancel();

    // Dispose of scroll controller
    _scrollController.dispose();

    _assetReportCheckTimer?.cancel();

    super.dispose();
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
                      child: NewsStoryDetailScreen(
                        story: newsItem,
                        index: index,
                        allStories: _newsItems,
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
                            image: NetworkImage(newsItem['imageUrl']!),
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
                            child: Image.network(
                              'https://fcmptjhsrbsbuwuctlsr.supabase.co/storage/v1/object/public/assets//blinklogo.png',
                              height: 24,
                              // Add error and loading placeholder handlers
                              errorBuilder: (context, error, stackTrace) {
                                return SvgPicture.asset(
                                  _isDarkMode
                                      ? 'assets/images/blink-logo2.svg'
                                      : 'assets/images/blink-logo3.svg',
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    _isDarkMode
                                        ? Colors.white
                                        : Colors.blue[800]!,
                                    BlendMode.srcIn,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return SizedBox(
                                  height: 24,
                                  width: 80,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.blue[800],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Advance',
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
                Flexible(
                  child: Text(
                    _hasActiveAdvance ? 'Active' : _blinkAdvanceStatus,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontFamily: 'Onest',
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
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
              Navigator.of(context)
                  .push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return BlinkAdvanceSplashScreen(
                        bankAccountId: _bankAccountId);
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
                    _hasActiveAdvance = result['has_active_advance'] == true;

                    if (result.containsKey('quick_action_status')) {
                      String newStatus =
                          result['quick_action_status'].toString();
                      _blinkAdvanceStatus = newStatus.isNotEmpty
                          ? _capitalizeFirstLetter(
                              newStatus.replaceAll('_', ' '))
                          : 'Approved';
                    }

                    // Trigger the repayment card flip if needed
                    if (result['show_repay_card'] == true) {
                      // Use a small delay to ensure UI is updated first
                      Future.delayed(Duration(milliseconds: 300), () {
                        if (mounted) {
                          _flipRepaymentCard();
                        }
                      });
                    }
                  });
                }
              });
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

  void _changeCategory(Transaction transaction) {
    _performHapticFeedback(haptics.HapticsType.medium);

    // Find current category if exists
    String categoryToMatch = transaction.category?.toLowerCase() ?? '';
    // Extract the most specific subcategory (last part after the last comma)
    if (categoryToMatch.contains(',')) {
      categoryToMatch = categoryToMatch.split(',').last.trim();
    }

    // Special case for airlines
    if (categoryToMatch == 'airlines and aviation services') {
      categoryToMatch = 'airlines';
    }

    final currentCategory = TransactionCategory.defaultCategories.firstWhere(
      (category) => category.id == categoryToMatch,
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
            // Update the transaction category in the database
            final authService =
                Provider.of<auth.AuthService>(context, listen: false);

            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category updated to ${category.name}'),
                backgroundColor: category.color,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

  // Recent transactions loading is now handled by the RecentTransactionsSection component

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

      // Recent transactions are now loaded by the RecentTransactionsSection component

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
          // Use the optimized method from SupabaseStorageService instead of manual file iteration
          profilePicture =
              await supabaseStorage.getLatestProfilePictureUrl(userId);
          if (profilePicture != null) {
            await profileProvider.updateProfilePicture(profilePicture);
            _logger.i('Profile picture loaded: $profilePicture');
          } else {
            _logger.i('No profile picture found for user');
          }
        } catch (e) {
          _logger.e('Error loading profile picture: $e');
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
      _logger.i('Loading current balances');
      final authService = Provider.of<auth.AuthService>(context, listen: false);

      // Use the new bank account balance endpoint
      final response = await authService.getBankAccountBalance();

      if (!mounted) return;

      _logger.i('Bank account balance response: $response');

      // The API returns {accounts: [account1, account2, ...]} directly without success/data wrapper
      if (response != null &&
          response['accounts'] != null &&
          response['accounts'] is List &&
          (response['accounts'] as List).isNotEmpty) {
        final accounts = List<Map<String, dynamic>>.from(response['accounts']);
        _logger.i('Processing accounts: ${accounts.length} accounts found');

        if (accounts.isNotEmpty) {
          final account = accounts.first;
          _logger.i('Processing primary account: ${account.toString()}');

          // Extract the available and current balance
          final balances = account['balance'] ?? account['balances'];
          if (balances != null) {
            final dynamic availableBalance = balances['available'];
            final dynamic currentBalance = balances['current'];

            _logger.i(
                'Available balance: $availableBalance, Current balance: $currentBalance');

            double balance = 0.0;

            // Prefer available balance, fallback to current balance
            if (availableBalance != null) {
              if (availableBalance is num) {
                balance = availableBalance.toDouble();
                _logger.i('Using available balance (num): $balance');
              } else if (availableBalance is String) {
                balance = double.tryParse(availableBalance) ?? 0.0;
                _logger.i('Using available balance (string): $balance');
              }
            } else if (currentBalance != null) {
              if (currentBalance is num) {
                balance = currentBalance.toDouble();
                _logger.i('Using current balance (num): $balance');
              } else if (currentBalance is String) {
                balance = double.tryParse(currentBalance) ?? 0.0;
                _logger.i('Using current balance (string): $balance');
              }
            }

            // Update account details if available
            String? accountName;
            String? accountMask;

            if (account['name'] != null) {
              accountName = account['name'].toString();
              _logger.i('Account name: $accountName');
            }

            if (account['mask'] != null) {
              accountMask = account['mask'].toString();
              _logger.i('Account mask: $accountMask');
            }

            if (!mounted) return;

            // Remove the hardcoded fallback value and use the actual balance
            if (balance <= 0) {
              _logger.w('Balance is $balance, using actual value for display');
              // No longer forcing a minimum balance for testing
            }

            _logger.i('Setting balance: $balance and animating');

            setState(() {
              _currentBalance = balance;
              _logger.i('Setting current balance to: $_currentBalance');

              if (accountName != null) {
                _primaryAccountName = accountName;
                _logger
                    .i('Setting primary account name to: $_primaryAccountName');
              }

              if (accountMask != null) {
                _primaryAccountMask = accountMask;
                _logger
                    .i('Setting primary account mask to: $_primaryAccountMask');
              }
            });

            // Make sure animation controller is properly initialized
            if (_animationController.isAnimating) {
              _animationController.stop();
            }

            _logger.i('Starting balance animation from 0 to $_currentBalance');
            _animationController.reset();
            _animationController.forward();

            // Force a rebuild of the UI
            if (mounted) {
              setState(() {});
            }

            // Return early since we successfully processed the response
            return;
          }
        }
      }

      // We reach here if the response wasn't in the expected format or we couldn't extract the balance
      _logger.w(
          'Failed to parse response from new endpoint, format was unexpected');

      // Instead of using a hardcoded test balance, try to load from stored preferences
      if (!mounted) return;

      // Try to get stored balance data from preferences
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final userPreferences = await storageService.getUserPreferences() ?? {};

      if (userPreferences.containsKey('financial_summary')) {
        try {
          final storedSummary =
              jsonDecode(userPreferences['financial_summary']);
          if (storedSummary != null &&
              storedSummary.containsKey('total_balance')) {
            final storedBalance = storedSummary['total_balance'];
            if (storedBalance is num && storedBalance > 0) {
              _logger
                  .i('Using stored balance from preferences: $storedBalance');

              setState(() {
                _currentBalance = storedBalance.toDouble();
                // Make sure to update the last updated date too
                if (userPreferences.containsKey('asset_report_processed_at')) {
                  _balanceLastUpdated = DateTime.parse(
                      userPreferences['asset_report_processed_at']);
                }
              });

              // Make sure animation controller is properly initialized
              if (_animationController.isAnimating) {
                _animationController.stop();
              }

              _animationController.reset();
              _animationController.forward();

              // Return early since we successfully loaded from preferences
              return;
            }
          }
        } catch (e) {
          _logger.e('Error parsing stored financial summary: $e');
        }
      }

      // If all else fails, try loading using the account screen's method
      _loadBankAccountFromAPI();
    } catch (e) {
      _logger.e('Error loading current balances: $e');

      // Use a test balance on error
      if (mounted) {
        final testBalance = 200.0;
        _logger.w('Using test balance of $testBalance after error');

        setState(() {
          _currentBalance = testBalance;
        });

        // Make sure animation controller is properly initialized
        if (_animationController.isAnimating) {
          _animationController.stop();
        }

        _animationController.reset();
        _animationController.forward();
      }
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

      // Log the API response for debugging
      _logger.d('Approval status response: $approvalResponse');

      if (!mounted) return;

      // Handle the approval status response
      if (approvalResponse != null) {
        setState(() {
          try {
            // The response contains: {"userId":"user-id-here","approvalStatus":"approved"}
            final status = approvalResponse['approvalStatus'];
            _logger.d('Status from API: $status');

            _isBlinkAdvanceApproved =
                status?.toString().toLowerCase() == 'approved';
            _blinkAdvanceStatus =
                _isBlinkAdvanceApproved ? 'Approved' : 'On Review';
            _hasActiveAdvance = false;
            _activeAdvance = null;
          } catch (e) {
            _logger.e('Error parsing approval response: $e');
            _isBlinkAdvanceApproved = false;
            _blinkAdvanceStatus = 'Error';
            _hasActiveAdvance = false;
            _activeAdvance = null;
          } finally {
            _isBlinkAdvanceLoading = false;
          }
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
      _logger.e('Error loading blink advance status: $e');
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
      duration:
          const Duration(milliseconds: 1500), // Reduced from 2000ms to 1500ms
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

    // Initialize the _blinkCardExpandController to fix the LateInitializationError
    _blinkCardExpandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
    final localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
      child: Container(
        height: 230, // Updated to match new card height
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
    final localizations = AppLocalizations.of(context)!;
    return Container(
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color.fromARGB(255, 29, 38, 62).withOpacity(0.95),
                  const Color.fromARGB(255, 34, 50, 78).withOpacity(0.98),
                ]
              : [
                  Colors.blue[800]!.withOpacity(0.95),
                  Colors.blue[900]!.withOpacity(0.98),
                ],
          stops: const [0.3, 0.9],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? const Color(0xFF1A2942).withOpacity(0.5)
                : Colors.blue[800]!.withOpacity(0.35),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.blue[900]!.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              22, 20, 22, 22), // Slightly reduced vertical padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Row - more compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/blink-logo.png',
                    height: 26, // Slightly smaller for better proportion
                    width: 105,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Debug refresh button
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: Colors.white.withOpacity(0.8),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _logger.i('Manual balance refresh requested');
                          _refreshBalanceDebug();
                        },
                      ),
                      const SizedBox(width: 10), // Slightly increased spacing
                      _buildFlipButton(),
                    ],
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Balance Section - optimized spacing
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    localizations.last_known_balance,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                      fontFamily: 'Onest',
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _balanceLastUpdated != null
                            ? localizations.updated_on(DateFormat('MMM d')
                                .format(_balanceLastUpdated!))
                            : 'Not yet updated', // Use a default string since the localization is missing
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontFamily: 'Onest',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      // Use the actual balance without fallback to a hardcoded value
                      final actualBalance = _currentBalance;

                      // Use a curve to make animation more interesting
                      final curve = Curves.easeOutCubic;
                      final curvedValue = curve.transform(_animation.value);
                      final curvedBalance = actualBalance * curvedValue;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add a subtle indicator that updates during animation
                          if (_animation.value < 1.0)
                            LinearProgressIndicator(
                              value: _animation.value,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.5),
                              ),
                              minHeight: 2,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${currencyFormatter.format(curvedBalance).split('.')[0].substring(1)}.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                    // Add shadow during animation
                                    shadows: _animation.value < 1.0
                                        ? [
                                            Shadow(
                                              color:
                                                  Colors.blue.withOpacity(0.8),
                                              blurRadius: 10,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      '${currencyFormatter.format(curvedBalance).split('.')[1]}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 20,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // Account Info - more compact with better alignment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      _primaryAccountName ?? 'Primary Account',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontFamily: 'Onest',
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '****${_bankAccountId.substring(max(0, _bankAccountId.length - 4))}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontFamily: 'Onest',
                          letterSpacing: 0.5,
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

    // Page controller to track current page for dot indicators
    final _pageController = PageController();
    final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

    return Container(
      height: 230,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [
                  const Color(0xFF1E2942).withOpacity(0.98),
                  const Color(0xFF16213B).withOpacity(0.95),
                ]
              : [
                  Colors.blue[900]!.withOpacity(0.98),
                  Colors.blue[800]!.withOpacity(0.95),
                ],
          stops: const [0.3, 0.9],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.25),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.45)
                : Colors.blue[900]!.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: _isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.blue[900]!.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollUpdateNotification) {
                  if (_pageController.page != null) {
                    final currentPage = _pageController.page!.round();
                    if (_currentPage.value != currentPage) {
                      _currentPage.value = currentPage;

                      // Trigger subtle haptic feedback on page change
                      HapticFeedback.lightImpact();
                    }
                  }
                }
                return false;
              },
              child: PageView(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                children: [
                  // First Section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enhanced Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Improved status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: hasActiveAdvance ||
                                          _isBlinkAdvanceApproved
                                      ? [
                                          const Color(0xFF40916C),
                                          const Color(0xFF2D6A4F),
                                        ]
                                      : [
                                          const Color(0xFFB91C1C)
                                              .withOpacity(0.9),
                                          const Color(0xFF991B1B),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: (hasActiveAdvance ||
                                                _isBlinkAdvanceApproved
                                            ? const Color(0xFF40916C)
                                            : const Color(0xFFB91C1C))
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasActiveAdvance || _isBlinkAdvanceApproved
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    hasActiveAdvance
                                        ? 'Active'
                                        : _isBlinkAdvanceApproved
                                            ? 'Approved'
                                            : 'Under Review',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildFlipButton(),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Improved main content section
                        if (hasActiveAdvance) ...[
                          // Enhanced active advance display
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormatter.format(advanceAmount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 14,
                                      fontFamily: 'Onest',
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF40916C)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Blink Advance',
                                      style: TextStyle(
                                        color: const Color(0xFF40916C),
                                        fontSize: 10,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ] else ...[
                          // Enhanced non-active state
                          Text(
                            _isBlinkAdvanceApproved
                                ? 'Ready for\nQuick Cash'
                                : 'Under\nReview',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isBlinkAdvanceApproved)
                            // Enhanced action button
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF40916C),
                                    const Color(0xFF2D6A4F),
                                  ],
                                ),
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
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    _performHapticFeedback(
                                        haptics.HapticsType.medium);

                                    if (_hasActiveAdvance ||
                                        _isBlinkAdvanceApproved) {
                                      Navigator.of(context)
                                          .push(
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation,
                                              secondaryAnimation) {
                                            return BlinkAdvanceSplashScreen(
                                                bankAccountId: _bankAccountId);
                                          },
                                          transitionsBuilder: (context,
                                              animation,
                                              secondaryAnimation,
                                              child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          transitionDuration:
                                              const Duration(milliseconds: 500),
                                        ),
                                      )
                                          .then((result) {
                                        if (result != null &&
                                            result is Map<String, dynamic>) {
                                          setState(() {
                                            _activeAdvanceData = result;
                                            _hasActiveAdvance =
                                                result['has_active_advance'] ==
                                                    true;

                                            if (result.containsKey(
                                                'quick_action_status')) {
                                              String newStatus =
                                                  result['quick_action_status']
                                                      .toString();
                                              _blinkAdvanceStatus =
                                                  newStatus.isNotEmpty
                                                      ? _capitalizeFirstLetter(
                                                          newStatus.replaceAll(
                                                              '_', ' '))
                                                      : 'Approved';
                                            }

                                            // Trigger the repayment card flip if needed
                                            if (result['show_repay_card'] ==
                                                true) {
                                              // Use a small delay to ensure UI is updated first
                                              Future.delayed(
                                                  Duration(milliseconds: 300),
                                                  () {
                                                if (mounted) {
                                                  _flipRepaymentCard();
                                                }
                                              });
                                            }
                                          });
                                        }
                                      });
                                    }
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
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                            // Enhanced waiting indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '1-2 business days',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // Removed swipe indicator arrow
                        const Spacer(),
                      ],
                    ),
                  ),

                  // New Second Section - Asset Report Status (if pending)
                  if (_hasPendingAssetReport)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with section title and back button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Data Analysis',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontFamily: 'Onest',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              _buildFlipButton(),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Asset report status information
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: _isAssetReportLoading
                                        ? SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.analytics_outlined,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            size: 16,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _assetReportStatus,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                          fontFamily: 'Onest',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (_assetReportCreatedAt != null)
                                        Text(
                                          'Started ${_formatTimeAgo(_assetReportCreatedAt!)}',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontFamily: 'Onest',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Add retry button if more than 10 minutes have elapsed
                                if (_assetReportCreatedAt != null &&
                                    DateTime.now()
                                            .difference(_assetReportCreatedAt!)
                                            .inMinutes >
                                        10)
                                  GestureDetector(
                                    onTap: () async {
                                      _checkAssetReportStatus();
                                      _performHapticFeedback(
                                          haptics.HapticsType.medium);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.refresh,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),

                  // Third Section (was Second) - Payment Information
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small header with section title and back button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Details',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                            _buildFlipButton(),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Bottom Information Area based on status
                        if (hasActiveAdvance) ...[
                          // Enhanced payment information section
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Section title
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.calendar_today_outlined,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Payment Information',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Two-column layout for payment details
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column - Next Payment
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Next Payment',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 11,
                                                fontFamily: 'Onest',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            DateFormat('MMM d, yyyy')
                                                .format(repaymentDate),
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                              fontFamily: 'Onest',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currencyFormatter
                                                .format(repaymentAmount),
                                            style: TextStyle(
                                              color: const Color(0xFF40916C),
                                              fontSize: 16,
                                              fontFamily: 'Onest',
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Divider
                                    Container(
                                      height: 65,
                                      width: 1,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 12),
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

                                    // Right column - Payment Method
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Payment Method',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 11,
                                                fontFamily: 'Onest',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.account_balance,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  size: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _primaryAccountName ??
                                                          'Primary Account',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                        fontSize: 13,
                                                        fontFamily: 'Onest',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      '****${_bankAccountId.substring(max(0, _bankAccountId.length - 4))}',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.7),
                                                        fontSize: 11,
                                                        fontFamily: 'Onest',
                                                        letterSpacing: 0.5,
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
                          ),
                        ] else if (!_isBlinkAdvanceApproved) ...[
                          // Only show payment history for non-approved, non-active state
                          // Simple payment history preview
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section title
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Application Status',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Your application is being reviewed. This typically takes 1-2 business days.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontFamily: 'Onest',
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // For approved but not active state
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section title
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.info_outline,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Advance Details',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13,
                                        fontFamily: 'Onest',
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You are approved for a \$200 cash advance. Get instant access to funds when you need them.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontFamily: 'Onest',
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Removed swipe indicator arrow
                        const Spacer(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Enhanced pagination indicator dots
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildPaginationIndicator(_pageController),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotIndicator(int pageIndex, int currentPage) {
    final isActive = pageIndex == currentPage;

    // Create a more subtle, professional dot indicator
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isActive ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          width: 4,
          height: isActive ? 22 : 12,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Color.lerp(
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.85),
              value,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15 * value),
                blurRadius: 4 * value,
                spreadRadius: 0.5 * value,
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced pagination indicator with a professional look
  Widget _buildPaginationIndicator(PageController pageController) {
    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        // Calculate the exact page position with more precise tracking
        final page = pageController.page ?? 0;

        return Container(
          width: 6,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100), // Faster animation
                curve: Curves.fastLinearToSlowEaseIn, // More responsive curve
                top: page * 25.0,
                child: Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
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
              padding: const EdgeInsets.all(6), // Slightly smaller padding
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10), // Tighter radius
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: _isCardFlipped ? 0.5 : 0,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.95), // More visible
                  size: 20, // Smaller size
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
    setState(() {
      _isRepaymentCardFlipped = !_isRepaymentCardFlipped;
    });

    if (_isRepaymentCardFlipped) {
      _repaymentFlipController.forward();
    } else {
      _repaymentFlipController.reverse();
    }

    // Add haptic feedback for the flip
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
              child: BlinkAdvanceCard(
                bankAccountId: _bankAccountId,
                isDarkMode: _isDarkMode,
                onAdvanceDataUpdated: (advanceData) {
                  setState(() {
                    _activeAdvanceData = advanceData;

                    // Update other related state variables
                    _hasActiveAdvance = advanceData != null;
                    if (advanceData != null &&
                        advanceData.containsKey('quick_action_status')) {
                      _blinkAdvanceStatus = _capitalizeFirstLetter(
                          advanceData['quick_action_status']
                              .toString()
                              .replaceAll('_', ' '));
                    }
                  });
                },
                onHapticFeedback: (type) => _performHapticFeedback(type),
              ),
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
                    child: BlinkRepayCard(
                      isDarkMode: _isDarkMode,
                      onHapticFeedback: (type) => _performHapticFeedback(type),
                      activeAdvanceData: _activeAdvanceData,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    flex: 1,
                    child: InsightsQuickActionCard(
                      isDarkMode: _isDarkMode,
                      onHapticFeedback: (type) => _performHapticFeedback(type),
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
    // Original implementation for other cards (removed Insights card specific implementation)
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
    // Use the modularized component instead of building it directly
    return RecentTransactionsSection(
      isDarkMode: _isDarkMode,
      onHapticFeedback: _performHapticFeedback,
      onViewTransactionDetails: _viewDetails,
    );
  }

  Widget _buildNewsAndUpdates() {
    if (_isNewsLoading) {
      return SizedBox(
        height: 220,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              _isDarkMode ? Colors.white : Colors.blue[800]!,
            ),
          ),
        ),
      );
    }

    // Use the modularized component with news items from the service
    return StoriesSection(
      isDarkMode: _isDarkMode,
      onHapticFeedback: _performHapticFeedback,
      newsItems: _newsItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkMode;

    // Set status bar style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      _isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

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
                  top: (MediaQuery.of(context).padding.top + 60) *
                      1.2, // Increased by 1.2x
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

                    // Quick action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildQuickActions(),
                    ),

                    // News section - conditionally rendered based on feature flag
                    if (_showNewsSection) ...[
                      const SizedBox(height: 32),
                      _buildNewsAndUpdates(),
                    ],

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

  Widget _buildRepaymentFrontCard(Color color, Color textColor) {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);
    final deviceMultiplier = ResponsiveUtils.getElementSizeMultiplier(context);
    final hasActiveAdvance = _activeAdvanceData != null;

    return GestureDetector(
      onTap: () {
        _performHapticFeedback(haptics.HapticsType.medium);
        // Always flip the card regardless of active advance status
        _flipRepaymentCard();
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20 * deviceMultiplier),
        child: Container(
          clipBehavior: Clip.antiAlias,
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
            borderRadius: BorderRadius.circular(20 * deviceMultiplier),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: repaymentBlue.withOpacity(0.4),
                blurRadius: 12 * deviceMultiplier,
                offset: Offset(0, 6 * deviceMultiplier),
                spreadRadius: -2 * deviceMultiplier,
              ),
              BoxShadow(
                color: repaymentBlue.withOpacity(0.2),
                blurRadius: 24 * deviceMultiplier,
                offset: Offset(0, 12 * deviceMultiplier),
                spreadRadius: -4 * deviceMultiplier,
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
                          child: AnimatedEmoji(
                            AnimatedEmojis.alarmClock,
                            size: 28,
                            repeat: true,
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
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 24),
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
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 24),
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
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
      ),
    );
  }

  Widget _buildRepaymentBackCard(Color color, Color textColor) {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);
    final hasActiveAdvance = _activeAdvanceData != null;

    // Debug print to see what data we're receiving
    print("💰 Active advance data in repayment card: $_activeAdvanceData");

    // More robust handling of repayment amount with fallbacks
    final repaymentAmount = hasActiveAdvance
        ? (double.tryParse(
                _activeAdvanceData!['total_repayment_amount']?.toString() ??
                    _activeAdvanceData!['amount']?.toString() ??
                    '0') ??
            0.0)
        : 0.0;

    // More robust handling of repayment date with fallbacks
    DateTime repaymentDate;
    if (hasActiveAdvance) {
      try {
        // Try multiple date field names that might be present
        final dateStr = _activeAdvanceData!['repayment_date']?.toString() ??
            _activeAdvanceData!['repayment_due_date']?.toString();

        repaymentDate = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();

        // If the parsed date is more than 30 days away, it's likely invalid, use fallback
        if (repaymentDate.difference(DateTime.now()).inDays > 30) {
          print("⚠️ Invalid repayment date detected, using fallback");
          repaymentDate = DateTime.now().add(const Duration(days: 7));
        }
      } catch (e) {
        print("⚠️ Error parsing repayment date: $e");
        repaymentDate = DateTime.now().add(const Duration(days: 7));
      }
    } else {
      repaymentDate = DateTime.now();
    }

    // Debug print for specific fields
    if (hasActiveAdvance) {
      print("💰 Repayment amount: $repaymentAmount, date: $repaymentDate");
      print(
          "💰 Raw values - Amount: ${_activeAdvanceData!['total_repayment_amount'] ?? _activeAdvanceData!['amount']}, Date: ${_activeAdvanceData!['repayment_date'] ?? _activeAdvanceData!['repayment_due_date']}");
      print("💰 Active advance status: ${_activeAdvanceData!['status']}");
    }

    final deviceMultiplier = ResponsiveUtils.getElementSizeMultiplier(context);
    final fontSizeMultiplier = ResponsiveUtils.getFontSizeMultiplier(context);

    // Get dynamic color based on repayment timeframe - more vivid colors
    final dynamicColor = hasActiveAdvance
        ? _getRepaymentTimeBasedColor(repaymentDate)
        : repaymentBlue;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20 * deviceMultiplier),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20 * deviceMultiplier),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            clipBehavior: Clip.antiAlias,
            // Fix overflow by ensuring the container doesn't expand beyond available space
            width: double.infinity,
            constraints: const BoxConstraints(
                maxHeight: 138), // Hard constraint on height
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dynamicColor.withOpacity(0.85),
                  dynamicColor.withOpacity(0.75),
                ],
                stops: const [0.3, 1.0],
              ),
              borderRadius: BorderRadius.circular(20 * deviceMultiplier),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: dynamicColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content - ULTRA MINIMALIST VERSION with glass morphism
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center vertically
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align to the left
                    children: [
                      // 1. HEADER ROW (WITH REPAY TEXT + FLIP BUTTON)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Title text
                          Text(
                            'Blink Repay',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 15),
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),

                          // Integrated flip button
                          GestureDetector(
                            onTap: () {
                              _flipRepaymentCard();
                              _performHapticFeedback(
                                  haptics.HapticsType.medium);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: AnimatedRotation(
                                  duration: const Duration(milliseconds: 300),
                                  turns: _isRepaymentCardFlipped ? 0.75 : 0.25,
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (hasActiveAdvance) ...[
                        const SizedBox(height: 8),

                        // 2. AMOUNT OWED - Now comes second - GLASS MORPHISM DESIGN
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.85),
                              ],
                            ).createShader(bounds);
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                // Dollar sign
                                TextSpan(
                                  text: '\$',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 28),
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                // Dollars amount
                                TextSpan(
                                  text: currencyFormatter
                                      .format(repaymentAmount)
                                      .split('.')[0]
                                      .substring(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 28),
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                // Decimal point
                                TextSpan(
                                  text: '.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 28),
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                // Cents amount in smaller font
                                TextSpan(
                                  text: currencyFormatter
                                      .format(repaymentAmount)
                                      .split('.')[1],
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize:
                                        ResponsiveUtils.getResponsiveFontSize(
                                            context, 16),
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 3. REPAY BUTTON - GLASS MORPHISM DESIGN
                        StreamBuilder<int>(
                          stream: Stream.periodic(
                              const Duration(seconds: 1), (count) => count),
                          builder: (context, snapshot) {
                            // Early return if widget is not mounted anymore
                            if (!mounted) return Container();

                            final now = DateTime.now();
                            final difference = repaymentDate.difference(now);

                            // Determine button styling based on due date
                            bool isUrgent =
                                difference.isNegative || difference.inDays < 1;
                            String buttonText =
                                difference.isNegative ? 'Repay Now' : 'Repay';

                            return GestureDetector(
                              onTap: () {
                                // Check if widget is still mounted before performing actions
                                if (!mounted) return;
                                _performHapticFeedback(
                                    haptics.HapticsType.medium);
                                // TODO: Implement repayment action
                              },
                              child: AnimatedBuilder(
                                animation: isUrgent
                                    ? _repayPulseAnimation
                                    : const AlwaysStoppedAnimation(1.0),
                                builder: (context, child) {
                                  // Additional mounted check for animation callback
                                  if (!mounted) return Container();

                                  return Transform.scale(
                                    scale: isUrgent
                                        ? _repayPulseAnimation.value
                                        : 1.0,
                                    child: Center(
                                      child: Container(
                                        // Modern glass button
                                        width: 140,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius:
                                              BorderRadius.circular(19),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            buttonText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: dynamicColor,
                                              fontSize: 15,
                                              fontFamily: 'Onest',
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        // Show a simple message for no active advance
                        Center(
                          child: Text(
                            'No Active Advance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 16),
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    try {
      // Get actual transaction information from the transaction itself
      final transactionDate = transaction.date;
      final formattedDate = DateFormat('MMM d, yyyy').format(transactionDate);
      final formattedTime = DateFormat('h:mm a').format(transactionDate);

      // Create a TransactionDetail object with useful metadata
      final transactionDetail = TransactionDetail(
        id: transaction.id,
        merchantName: transaction.merchantName,
        amount: transaction.amount,
        date: transaction.date,
        category:
            null, // Set category to null as the expected type is incompatible
        metadata: {
          'pending': false,
          'payment_method': 'credit_card', // Default value
          'account_number':
              'xxxx-xxxx-xxxx-${transaction.id}', // Create a masked account number
          'description': transaction.merchantName,
          'category':
              transaction.category, // Store category in metadata instead
          'date': formattedDate,
          'time': formattedTime,
          'status': transaction.isOutflow ? 'Outflow' : 'Inflow',
          'type': transaction.isOutflow ? 'Purchase' : 'Deposit',
        },
      );

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize:
              0.58, // Reduced from 0.7 to show less of the sheet initially
          minChildSize: 0.45, // Also reduced this value to match
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF141B2E) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Centered handle bar
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with merchant and amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.merchantName ?? 'Unknown Merchant',
                              style: TextStyle(
                                color:
                                    _isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 26,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormatter.format(transaction.amount),
                              style: TextStyle(
                                color: transaction.isOutflow
                                    ? Colors.red[400]
                                    : Colors.green[400],
                                fontSize: 36,
                                fontFamily: 'Onest',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: (transaction.isOutflow
                                        ? Colors.red
                                        : Colors.green)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    transaction.isOutflow
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 16,
                                    color: transaction.isOutflow
                                        ? Colors.red[400]
                                        : Colors.green[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    transaction.isOutflow
                                        ? 'Money Out'
                                        : 'Money In',
                                    style: TextStyle(
                                      color: transaction.isOutflow
                                          ? Colors.red[400]
                                          : Colors.green[400],
                                      fontSize: 14,
                                      fontFamily: 'Onest',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Enhanced Transaction card with category, date, status
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _isDarkMode
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white,
                                _isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.white.withOpacity(0.97),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.04),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(_isDarkMode ? 0.3 : 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            // Added Material widget to prevent text rendering issues
                            color: Colors.transparent,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category and Date
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      transaction
                                                          .getCategoryColor(
                                                              _isDarkMode),
                                                      transaction
                                                          .getCategoryColor(
                                                              _isDarkMode)
                                                          .withOpacity(0.7),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: transaction
                                                          .getCategoryColor(
                                                              _isDarkMode)
                                                          .withOpacity(0.4),
                                                      blurRadius: 8,
                                                      offset:
                                                          const Offset(0, 2),
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  transaction.getCategoryIcon(),
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                CategoryService
                                                    .formatDisplayCategory(
                                                        transaction.category),
                                                style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  fontSize: 18,
                                                  fontFamily: 'Onest',
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _isDarkMode
                                                  ? Colors.white
                                                      .withOpacity(0.08)
                                                  : Colors.blue
                                                      .withOpacity(0.05),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              formattedDate,
                                              style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white70
                                                    : Colors.black54,
                                                fontSize: 12,
                                                fontFamily: 'Onest',
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      const Divider(height: 1, thickness: 0.5),
                                      const SizedBox(height: 20),
                                      // Transaction Status - Enhanced visual style
                                      _buildTransactionCardRow(
                                        'Status',
                                        transactionDetail
                                                    .metadata?['pending'] ==
                                                true
                                            ? 'Pending'
                                            : 'Complete',
                                        transactionDetail
                                                    .metadata?['pending'] ==
                                                true
                                            ? Colors.amber[800]!
                                            : Colors.green[600]!,
                                        _isDarkMode,
                                      ),
                                      const SizedBox(height: 16),
                                      // Payment Method - Enhanced visual style
                                      _buildTransactionCardRow(
                                        'Payment Method',
                                        'Credit Card',
                                        null,
                                        _isDarkMode,
                                      ),
                                      const SizedBox(height: 16),
                                      // Transaction Type - Enhanced visual style
                                      _buildTransactionCardRow(
                                        'Type',
                                        transaction.isOutflow
                                            ? 'Purchase'
                                            : 'Deposit',
                                        null,
                                        _isDarkMode,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Transaction Details section
                        Text(
                          'Transaction Details',
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 18,
                            fontFamily: 'Onest',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Detail rows
                        _buildTransactionDetailRow(
                            'Date', formattedDate, _isDarkMode),
                        _buildTransactionDetailRow(
                            'Time', formattedTime, _isDarkMode),
                        _buildTransactionDetailRow(
                            'Type',
                            transaction.isOutflow ? 'Purchase' : 'Deposit',
                            _isDarkMode),
                        _buildTransactionDetailRow(
                            'Status', 'Completed', _isDarkMode),
                        if (transaction.merchantName != null)
                          _buildTransactionDetailRow('Merchant',
                              transaction.merchantName!, _isDarkMode),
                        _buildTransactionDetailRow(
                            'Account',
                            'xxxx-xxxx-xxxx-${transaction.id.length > 4 ? transaction.id.substring(0, 4) : transaction.id}',
                            _isDarkMode),
                        _buildTransactionDetailRow('Transaction ID',
                            '#${transaction.id}', _isDarkMode),

                        // Add extra bottom padding to ensure all content is accessible
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _logger.e('Error showing transaction details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load transaction details: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTransactionDetailRow(
      String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontFamily: 'Onest',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 14,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
    String emoji;
    if (_hasActiveAdvance) {
      emoji = '✅';
    } else {
      switch (_blinkAdvanceStatus.toLowerCase()) {
        case 'Reviewing':
          emoji = '🕒';
          break;
        case 'approved':
          emoji = '✅';
          break;
        case 'rejected':
          emoji = '❌';
          break;
        default:
          emoji = '';
          break;
      }
    }

    // Return a fixed-size container with the emoji
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
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
          height: (MediaQuery.of(context).padding.top + 52) *
              1.2, // Increased by 1.2x to match content spacing
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
            child: GestureDetector(
              onTapDown: (_) =>
                  _performHapticFeedback(haptics.HapticsType.light),
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        FadeTransition(
                      opacity: animation,
                      child: NewsStoryDetailScreen(
                        story: newsItem,
                        index: index,
                        allStories: _newsItems,
                      ),
                    ),
                  ),
                );
              },
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
                      tag: 'story-image-$index',
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          image: DecorationImage(
                            image: NetworkImage(newsItem['imageUrl']!),
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
                            Hero(
                              tag: 'story-title-$index',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  newsItem['title']!,
                                  style: TextStyle(
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'Onest',
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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

      // Commenting out the API call as it's no longer used and causing errors
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      // final summaries = await authService.getDailyTransactionSummary(days: 30);

      // Use empty list instead of API call
      final summaries = <auth.DailyTransactionSummary>[];

      if (!mounted) return;

      setState(() {
        _dailyTransactionSummary = summaries;
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  // Helper method to format category for display - extract the last part after comma
  String _formatDisplayCategory(String? category) {
    // Handle null or empty categories
    if (category == null || category.isEmpty) {
      return 'Uncategorized';
    }

    // Special cases for specific categories
    if (category.contains('Airlines and Aviation Services')) {
      return 'Airlines';
    } else if (category.contains('Supermarkets and Groceries')) {
      return 'Groceries';
    } else if (category.contains('Department Stores')) {
      return 'Stores';
    } else if (category.contains('Movies and Theatres')) {
      return 'Movies';
    } else if (category.contains('Professional Services')) {
      return 'Services';
    } else if (category.contains('Telecommunication Services')) {
      return 'Services';
    } else if (category.contains('Streaming Services')) {
      return 'Streaming';
    } else if (category.contains('Gyms and Fitness Centers')) {
      return 'Gym';
    }

    // For all other categories, get the last part of the string
    final parts = category.split(',');
    final lastPart = parts.last.trim();
    return lastPart;
  }

  // Enhanced method to get category color with comprehensive handling of categories
  Color _getCategoryColor(String? category, bool isDarkMode) {
    if (category == null || category.isEmpty) {
      return isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    }

    // Check main category first
    if (category.contains('Food and Drink')) {
      return Colors.orange[400]!;
    } else if (category.contains('Auto and Transport')) {
      return Colors.blue[400]!;
    } else if (category.contains('Travel')) {
      return Colors.purple[400]!;
    } else if (category.contains('Shops')) {
      return Colors.teal[400]!;
    } else if (category.contains('Recreation')) {
      return Colors.green[400]!;
    } else if (category.contains('Entertainment')) {
      return Colors.indigo[400]!;
    } else if (category.contains('Service')) {
      return Colors.amber[400]!;
    } else if (category.contains('Transfer')) {
      return Colors.deepOrange[400]!;
    }

    // Then check subcategories
    if (category.contains('Groceries') || category.contains('Supermarkets')) {
      return Colors.lightGreen[400]!;
    } else if (category.contains('Restaurants') ||
        category.contains('Fast Food')) {
      return Colors.orange[400]!;
    } else if (category.contains('Coffee')) {
      return Colors.brown[400]!;
    } else if (category.contains('Gas')) {
      return Colors.red[400]!;
    } else if (category.contains('Airlines') || category.contains('Aviation')) {
      return Colors.lightBlue[400]!;
    } else if (category.contains('Lodging')) {
      return Colors.purple[300]!;
    } else if (category.contains('Taxi')) {
      return Colors.yellow[700]!;
    } else if (category.contains('Stores') || category.contains('Department')) {
      return Colors.cyan[400]!;
    } else if (category.contains('Digital') || category.contains('Purchase')) {
      return Colors.blue[300]!;
    } else if (category.contains('Improvement')) {
      return Colors.brown[300]!;
    } else if (category.contains('Pharmacy') ||
        category.contains('Pharmacies')) {
      return Colors.redAccent[400]!;
    } else if (category.contains('Streaming')) {
      return Colors.deepPurple[400]!;
    } else if (category.contains('Movies') || category.contains('Theatres')) {
      return Colors.pinkAccent[400]!;
    } else if (category.contains('Gym') || category.contains('Fitness')) {
      return Colors.green[500]!;
    } else if (category.contains('Insurance')) {
      return Colors.blueGrey[400]!;
    } else if (category.contains('Pet')) {
      return Colors.amber[600]!;
    } else if (category.contains('Professional') ||
        category.contains('Telecommunication')) {
      return Colors.indigo[300]!;
    }

    // Default color
    return isDarkMode ? Colors.teal[200]! : Colors.teal[700]!;
  }

  // Enhanced method to get category icon with comprehensive handling of categories
  IconData _getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) {
      return Icons.category;
    }

    // Check main category first
    if (category.contains('Food and Drink')) {
      return Icons.restaurant;
    } else if (category.contains('Auto and Transport')) {
      return Icons.directions_car;
    } else if (category.contains('Travel')) {
      return Icons.airplanemode_active;
    } else if (category.contains('Shops')) {
      return Icons.shopping_cart;
    } else if (category.contains('Recreation')) {
      return Icons.sports;
    } else if (category.contains('Entertainment')) {
      return Icons.movie;
    } else if (category.contains('Service')) {
      return Icons.build;
    } else if (category.contains('Transfer')) {
      return Icons.swap_horiz;
    }

    // Then check subcategories
    if (category.contains('Groceries') || category.contains('Supermarkets')) {
      return Icons.shopping_basket;
    } else if (category.contains('Restaurants')) {
      return Icons.restaurant_menu;
    } else if (category.contains('Fast Food')) {
      return Icons.fastfood;
    } else if (category.contains('Coffee')) {
      return Icons.coffee;
    } else if (category.contains('Gas')) {
      return Icons.local_gas_station;
    } else if (category.contains('Airlines') || category.contains('Aviation')) {
      return Icons.flight_takeoff;
    } else if (category.contains('Lodging')) {
      return Icons.hotel;
    } else if (category.contains('Taxi')) {
      return Icons.local_taxi;
    } else if (category.contains('Stores') || category.contains('Department')) {
      return Icons.store;
    } else if (category.contains('Digital') || category.contains('Purchase')) {
      return Icons.shopping_bag;
    } else if (category.contains('Improvement')) {
      return Icons.home_repair_service;
    } else if (category.contains('Pharmacy') ||
        category.contains('Pharmacies')) {
      return Icons.local_pharmacy;
    } else if (category.contains('Streaming')) {
      return Icons.stream;
    } else if (category.contains('Movies') || category.contains('Theatres')) {
      return Icons.theaters;
    } else if (category.contains('Gym') || category.contains('Fitness')) {
      return Icons.fitness_center;
    } else if (category.contains('Insurance')) {
      return Icons.security;
    } else if (category.contains('Pet')) {
      return Icons.pets;
    } else if (category.contains('Professional') ||
        category.contains('Telecommunication')) {
      return Icons.support_agent;
    }

    // Default icon
    return Icons.category;
  }

  // Helper method to build transaction card detail rows with enhanced styling
  Widget _buildTransactionCardRow(
      String label, String value, Color? valueColor, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
            fontFamily: 'Onest',
          ),
        ),
        if (valueColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontFamily: 'Onest',
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 14,
              fontFamily: 'Onest',
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // Debug method to manually refresh balance
  Future<void> _refreshBalanceDebug() async {
    try {
      _logger.i('DEBUG: Manually refreshing balance');

      // Force the balance to reset to 0 first for visual feedback
      setState(() {
        _currentBalance = 0.0;
      });

      // Wait a moment for visual effect
      await Future.delayed(Duration(milliseconds: 300));

      // Load balance using our improved method that fetches from real accounts
      await _loadBankAccountFromAPI();

      _logger.i(
          'DEBUG: Manual balance refresh completed. Current balance: $_currentBalance');
    } catch (e) {
      _logger.e('DEBUG: Error during manual balance refresh: $e');
    }
  }

  // Add this helper method anywhere in the class
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;

    final words = text.split(' ');
    final capitalizedWords = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalizedWords.join(' ');
  }

  // Add this helper method to calculate color based on time remaining for repayment - with more vivid colors
  Color _getRepaymentTimeBasedColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    // Calculate days remaining
    final daysRemaining = difference.inDays;

    if (difference.isNegative) {
      // Overdue - intense vivid red
      return const Color(0xFFF5222D);
    } else if (daysRemaining < 1) {
      // Less than 24 hours - vivid orange-red
      final hoursRemaining = difference.inHours;
      final urgencyFactor = hoursRemaining / 24.0; // 0 to 1 scale
      return Color.lerp(
            const Color(0xFFF5222D), // Vivid red
            const Color(0xFFFA541C), // Vivid orange
            urgencyFactor.clamp(0.0, 1.0),
          ) ??
          const Color(0xFFF5222D);
    } else if (daysRemaining < 3) {
      // 1-3 days - vivid orange to yellow
      final factor = (daysRemaining - 1) / 2.0; // 0 to 1 scale
      return Color.lerp(
            const Color(0xFFFA541C), // Vivid orange
            const Color(0xFFFADB14), // Vivid yellow
            factor.clamp(0.0, 1.0),
          ) ??
          const Color(0xFFFA541C);
    } else if (daysRemaining < 7) {
      // 3-7 days - vivid yellow to green
      final factor = (daysRemaining - 3) / 4.0; // 0 to 1 scale
      return Color.lerp(
            const Color(0xFFFADB14), // Vivid yellow
            const Color(0xFF52C41A), // Vivid green
            factor.clamp(0.0, 1.0),
          ) ??
          const Color(0xFF52C41A);
    } else {
      // More than 7 days - vivid green to teal
      return const Color(0xFF52C41A); // Vivid green
    }
  }

  // Add the missing _viewDetails method to fix linter error
  void _viewDetails(Transaction transaction) {
    // Show transaction details in a modal or navigate to a details page
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.white38 : Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Onest',
                        color: _isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Transaction information
                        _buildTransactionCardRow(
                          'Merchant',
                          transaction.merchantName ??
                              'Unknown Merchant', // Add null check
                          null,
                          _isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionCardRow(
                          'Amount',
                          currencyFormatter.format(transaction.amount),
                          transaction.isOutflow
                              ? Colors.red[400]
                              : Colors.green[400],
                          _isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionCardRow(
                          'Date',
                          DateFormat('MMMM d, yyyy').format(transaction.date),
                          null,
                          _isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionCardRow(
                          'Category',
                          transaction.category ??
                              'Uncategorized', // Add null check
                          null,
                          _isDarkMode,
                        ),
                        const SizedBox(height: 12),
                        _buildTransactionCardRow(
                          'Status',
                          transaction.status ??
                              'Completed', // Use status property with fallback
                          null,
                          _isDarkMode,
                        ),
                        if (transaction.description != null &&
                            transaction.description!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Onest',
                              color:
                                  _isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            transaction.description!, // Add null assertion
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Onest',
                              color: _isDarkMode ? Colors.white : Colors.black,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Add the missing _buildIconButton method to fix linter error
  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: iconColor ??
                (_isDarkMode ? Colors.white : Colors.black.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }

  // Check user preferences for pending asset report tokens
  Future<void> _checkForPendingAssetReports() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final userPreferences = await storageService.getUserPreferences() ?? {};

      // First check if there's a need to retry asset report creation
      await _checkAndRetryAssetReport();

      // Check preferences for stored token
      if (userPreferences.containsKey('pending_asset_report_token')) {
        _pendingAssetReportToken =
            userPreferences['pending_asset_report_token'];
        _assetReportCreatedAt =
            userPreferences['asset_report_created_at'] != null
                ? DateTime.parse(userPreferences['asset_report_created_at'])
                : DateTime.now();

        if (_pendingAssetReportToken != null) {
          setState(() {
            _hasPendingAssetReport = true;
            _assetReportStatus = 'Analyzing your bank data...';
          });

          // Check status immediately
          await _checkAssetReportStatus();

          // Set up periodic checking (every 30 seconds)
          _assetReportCheckTimer = Timer.periodic(
            const Duration(seconds: 30),
            (_) => _checkAssetReportStatus(),
          );
        }
      } else {
        // No pending token in preferences, check with backend
        await _fetchPendingAssetReports();
      }
    } catch (e) {
      _logger.e('Error checking for pending asset reports: $e');
    }
  }

  // Check if a retry is needed for asset report creation and perform it
  Future<void> _checkAndRetryAssetReport() async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final userPrefs = await storageService.getUserPreferences() ?? {};

      if (userPrefs['should_retry_asset_report'] == 'true' &&
          userPrefs['asset_report_retry_access_token'] != null) {
        // Check how many retry attempts have been made
        int retryAttempts = 0;
        if (userPrefs['asset_report_retry_attempts'] != null) {
          retryAttempts =
              int.tryParse(userPrefs['asset_report_retry_attempts']) ?? 0;
        }

        // Only retry if we haven't exceeded max attempts (3)
        if (retryAttempts < 3) {
          _logger.i(
              'Attempting to retry asset report creation, attempt #${retryAttempts + 1}');

          setState(() {
            _hasPendingAssetReport = true;
            _assetReportStatus = 'Retrying analysis of your bank data...';
            _isAssetReportLoading = true;
          });

          try {
            final authService =
                Provider.of<auth.AuthService>(context, listen: false);

            // Call the retry endpoint with reduced timeframe
            final retryResponse = await authService.retryAssetReport(
              accessTokens: [userPrefs['asset_report_retry_access_token']],
              daysRequested: 365, // Use smaller timeframe as recommended
            );

            if (retryResponse['asset_report_token'] != null) {
              // Update the token to the new one
              userPrefs['pending_asset_report_token'] =
                  retryResponse['asset_report_token'];
              userPrefs['asset_report_created_at'] =
                  DateTime.now().toIso8601String();

              // Remove retry flags since we succeeded
              userPrefs.remove('should_retry_asset_report');
              userPrefs.remove('asset_report_retry_access_token');
              userPrefs.remove('asset_report_retry_attempts');
              userPrefs.remove('asset_report_last_retry');

              await storageService.setUserPreferences(userPrefs);

              setState(() {
                _pendingAssetReportToken = retryResponse['asset_report_token'];
                _assetReportCreatedAt = DateTime.now();
                _assetReportStatus = 'Analyzing your bank data...';
              });

              _logger.i('Successfully retried asset report creation');

              // Set up periodic checking
              _assetReportCheckTimer?.cancel();
              _assetReportCheckTimer = Timer.periodic(
                const Duration(seconds: 30),
                (_) => _checkAssetReportStatus(),
              );
            }
          } catch (e) {
            _logger.e('Error retrying asset report: $e');

            // Increment retry count
            userPrefs['asset_report_retry_attempts'] =
                (retryAttempts + 1).toString();
            userPrefs['asset_report_last_retry'] =
                DateTime.now().toIso8601String();
            await storageService.setUserPreferences(userPrefs);

            // If this was the last attempt, clear the retry flags
            if (retryAttempts >= 2) {
              _logger.w(
                  'Maximum retry attempts reached, giving up on asset report creation');
              userPrefs.remove('should_retry_asset_report');
              userPrefs.remove('asset_report_retry_access_token');
              userPrefs.remove('asset_report_retry_attempts');
              userPrefs.remove('asset_report_last_retry');
              await storageService.setUserPreferences(userPrefs);
            }
          } finally {
            setState(() {
              _isAssetReportLoading = false;
            });
          }
        } else {
          // Clear retry flags if max attempts exceeded
          _logger.w(
              'Maximum retry attempts already reached, clearing retry flags');
          userPrefs.remove('should_retry_asset_report');
          userPrefs.remove('asset_report_retry_access_token');
          userPrefs.remove('asset_report_retry_attempts');
          userPrefs.remove('asset_report_last_retry');
          await storageService.setUserPreferences(userPrefs);
        }
      }
    } catch (e) {
      _logger.e('Error in _checkAndRetryAssetReport: $e');
    }
  }

  // Fetch pending asset reports from the backend
  Future<void> _fetchPendingAssetReports() async {
    try {
      setState(() {
        _isAssetReportLoading = true;
      });

      // Use the new method we added to AuthService
      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final response = await authService.getPendingAssetReports();

      if (response['count'] > 0) {
        final reports = response['pending_reports'] as List<dynamic>;
        if (reports.isNotEmpty) {
          // Use the most recent pending report
          final latestReport = reports.first;

          setState(() {
            _pendingAssetReportToken = latestReport['token'];
            _hasPendingAssetReport = true;
            _assetReportStatus = 'Analyzing your bank data...';
            _assetReportCreatedAt = DateTime.parse(latestReport['created_at']);
          });

          // Store in preferences for future reference
          final storageService =
              Provider.of<StorageService>(context, listen: false);
          final userPreferences =
              await storageService.getUserPreferences() ?? {};
          userPreferences['pending_asset_report_token'] =
              _pendingAssetReportToken;
          userPreferences['asset_report_created_at'] =
              _assetReportCreatedAt!.toIso8601String();
          await storageService.setUserPreferences(userPreferences);

          // Set up periodic checking
          _assetReportCheckTimer = Timer.periodic(
            const Duration(seconds: 30),
            (_) => _checkAssetReportStatus(),
          );
        }
      }
    } catch (e) {
      _logger.e('Error fetching pending asset reports: $e');
    } finally {
      setState(() {
        _isAssetReportLoading = false;
      });
    }
  }

  // Check status of the pending asset report
  Future<void> _checkAssetReportStatus() async {
    if (_pendingAssetReportToken == null) return;

    try {
      setState(() {
        _isAssetReportLoading = true;
      });

      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final response = await authService.getAssetReportStatus(
        assetReportToken: _pendingAssetReportToken!,
      );

      // Update the state based on response
      if (response['status'] == 'ready') {
        _logger.i('Asset report is ready');

        try {
          // Fetch the complete asset report
          _logger.i('Fetching complete asset report data');
          final reportData = await authService.getAssetReport(
            assetReportToken: _pendingAssetReportToken!,
            includeInsights: true, // Get detailed insights if available
          );

          // Process the asset report data
          await _processAssetReportData(reportData);

          _logger.i('Asset report successfully processed');
        } catch (reportError) {
          _logger.e('Error fetching or processing asset report: $reportError');
          // Even if there's an error fetching the report, we'll continue with cleanup
        }

        setState(() {
          _hasPendingAssetReport = false;
          _assetReportStatus = 'Report ready';
        });

        // Clear the stored token since report is ready
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        final userPreferences = await storageService.getUserPreferences() ?? {};
        userPreferences.remove('pending_asset_report_token');
        userPreferences.remove('asset_report_created_at');
        await storageService.setUserPreferences(userPreferences);

        // Cancel the periodic timer
        _assetReportCheckTimer?.cancel();
      } else if (response['status'] == 'pending') {
        // Still pending, update the status with time remaining if available
        final int estimatedWaitTime = response['estimated_wait_time'] ?? 0;
        setState(() {
          _assetReportStatus = estimatedWaitTime > 0
              ? 'Analyzing your bank data (est. ${estimatedWaitTime}m remaining)...'
              : 'Analyzing your bank data...';
        });
      } else if (response['exists'] == false) {
        // Report doesn't exist, clear state
        setState(() {
          _hasPendingAssetReport = false;
        });

        // Clear stored preferences
        final storageService =
            Provider.of<StorageService>(context, listen: false);
        final userPreferences = await storageService.getUserPreferences() ?? {};
        userPreferences.remove('pending_asset_report_token');
        userPreferences.remove('asset_report_created_at');
        await storageService.setUserPreferences(userPreferences);

        // Cancel timer
        _assetReportCheckTimer?.cancel();
      }
    } catch (e) {
      _logger.e('Error checking asset report status: $e');
    } finally {
      setState(() {
        _isAssetReportLoading = false;
      });
    }
  }

  // Process and store the asset report data
  Future<void> _processAssetReportData(Map<String, dynamic> reportData) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      // Extract key financial data from the report
      // Note: The exact structure depends on your Plaid implementation
      Map<String, dynamic> financialSummary = {};

      // Extract account data if available
      if (reportData.containsKey('items') && reportData['items'] is List) {
        final items = reportData['items'] as List;
        int totalAccounts = 0;
        double totalBalance = 0.0;

        for (var item in items) {
          if (item is Map<String, dynamic> &&
              item.containsKey('accounts') &&
              item['accounts'] is List) {
            final accounts = item['accounts'] as List;
            totalAccounts += accounts.length;

            for (var account in accounts) {
              if (account is Map<String, dynamic> &&
                  account.containsKey('balances') &&
                  account['balances'] is Map<String, dynamic>) {
                final balances = account['balances'] as Map<String, dynamic>;
                if (balances.containsKey('current') &&
                    balances['current'] is num) {
                  totalBalance += (balances['current'] as num).toDouble();
                }
              }
            }
          }
        }

        financialSummary['total_accounts'] = totalAccounts;
        financialSummary['total_balance'] = totalBalance;
      }

      // Extract summary data if available
      if (reportData.containsKey('report') &&
          reportData['report'] is Map<String, dynamic>) {
        final report = reportData['report'] as Map<String, dynamic>;

        if (report.containsKey('income')) {
          financialSummary['income'] = report['income'];
        }

        if (report.containsKey('cash_flow_analysis')) {
          financialSummary['cash_flow'] = report['cash_flow_analysis'];
        }
      }

      // Store the processed data in user preferences for later use
      final userPreferences = await storageService.getUserPreferences() ?? {};
      userPreferences['financial_summary'] = jsonEncode(financialSummary);
      userPreferences['asset_report_processed_at'] =
          DateTime.now().toIso8601String();
      await storageService.setUserPreferences(userPreferences);

      _logger.i('Stored processed financial summary from asset report');

      // Instead of calling _fetchFinancialData which might not exist,
      // we'll just trigger a UI refresh if needed through setState
      if (mounted) {
        setState(() {
          // Refresh data display with the newly processed financial data
          _currentBalance =
              financialSummary['total_balance'] ?? _currentBalance;
        });
      }
    } catch (e) {
      _logger.e('Error processing asset report data: $e');
      // The error is caught here and doesn't propagate to avoid breaking the app flow
    }
  }

  // Helper method to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  // Helper method to get access token from backend
  Future<String?> _getAccessTokenFromBackend() async {
    try {
      final authService = Provider.of<auth.AuthService>(context, listen: false);

      // Try to get access token from the backend
      try {
        // Use the correct getPlaidAccessToken method that returns a single access token
        return await authService.getPlaidAccessToken();
      } catch (e) {
        _logger.e('Error retrieving Plaid access token: $e');
      }

      _logger.w('No access token found in backend response');
      return null;
    } catch (e) {
      _logger.e('Error getting access token from backend: $e');
      return null;
    }
  }

  // Add new method to load bank account data using the account screen's method
  Future<void> _loadBankAccountFromAPI() async {
    if (!mounted) return;

    try {
      _logger.i('Loading bank accounts from API using account screen method');

      final authService = Provider.of<auth.AuthService>(context, listen: false);
      final token = await authService.getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bank-accounts/plaid-items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          final accountsData = responseData['data'] as List;

          if (accountsData.isNotEmpty) {
            final account = accountsData.first;
            final availableBalance =
                double.tryParse(account['balance_available'] ?? '0') ?? 0.0;
            final currentBalance =
                double.tryParse(account['balance_current'] ?? '0') ?? 0.0;

            // Prefer available balance, fallback to current balance
            final balance =
                availableBalance > 0 ? availableBalance : currentBalance;

            _logger.i('Loaded account balance from API: $balance');

            if (!mounted) return;

            setState(() {
              _currentBalance = balance;
              _balanceLastUpdated = DateTime.now();
            });

            // Trigger animation
            if (_animationController.isAnimating) {
              _animationController.stop();
            }

            _animationController.reset();
            _animationController.forward();

            // Store balance in preferences for future use
            final storageService =
                Provider.of<StorageService>(context, listen: false);
            final userPreferences =
                await storageService.getUserPreferences() ?? {};

            Map<String, dynamic> financialSummary = {};
            if (userPreferences.containsKey('financial_summary')) {
              try {
                financialSummary =
                    jsonDecode(userPreferences['financial_summary']);
              } catch (e) {
                _logger.e('Error parsing stored financial summary: $e');
                financialSummary = {};
              }
            }

            financialSummary['total_balance'] = balance;
            financialSummary['last_updated'] = DateTime.now().toIso8601String();

            userPreferences['financial_summary'] = jsonEncode(financialSummary);
            await storageService.setUserPreferences(userPreferences);
          }
        }
      }
    } catch (e) {
      _logger.e('Error in _loadBankAccountFromAPI: $e');
    }
  }

  void _navigateToBlinkAdvance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            BlinkAdvanceSplashScreen(bankAccountId: _bankAccountId),
      ),
    );
  }
}

// Custom painter for circular progress
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final progressAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      progressAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
