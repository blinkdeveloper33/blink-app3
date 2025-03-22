import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:intl/intl.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/core/utils/responsive_utils.dart';
import 'package:blink_app/features/quick_actions/presentation/widgets/quick_action_card.dart';

class BlinkRepayCard extends StatefulWidget {
  final bool isDarkMode;
  final Function(haptics.HapticsType)? onHapticFeedback;
  final Map<String, dynamic>? activeAdvanceData;

  const BlinkRepayCard({
    Key? key,
    required this.isDarkMode,
    this.onHapticFeedback,
    this.activeAdvanceData,
  }) : super(key: key);

  @override
  State<BlinkRepayCard> createState() => _BlinkRepayCardState();
}

class _BlinkRepayCardState extends State<BlinkRepayCard>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isCardFlipped = false;

  // For the repay button pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final NumberFormat currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();

    // Initialize flip controller
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

    // Setup pulse animation for repayment button
    _setupPulseAnimation();

    // If an active advance exists, show the repayment details by flipping the card
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted && hasActiveAdvance && widget.activeAdvanceData != null) {
        if (!_isCardFlipped) {
          _flipCard();
        }
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = TweenSequence<double>([
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
    ]).animate(_pulseController);

    _pulseController.repeat();
  }

  void _flipCard() {
    setState(() {
      _isCardFlipped = !_isCardFlipped;
    });

    if (_isCardFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }

    // Add haptic feedback for the flip
    _performHapticFeedback(haptics.HapticsType.medium);
  }

  void _performHapticFeedback(haptics.HapticsType type) {
    if (widget.onHapticFeedback != null) {
      widget.onHapticFeedback!(type);
    }
  }

  bool get hasActiveAdvance => widget.activeAdvanceData != null;

  // Helper method to get repayment-based color
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

  Widget _buildFrontCard() {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);
    final deviceMultiplier = ResponsiveUtils.getElementSizeMultiplier(context);

    return GestureDetector(
      onTap: () {
        _performHapticFeedback(haptics.HapticsType.medium);
        // Always flip the card regardless of active advance status
        _flipCard();
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
                              turns: _isCardFlipped ? 0.75 : 0.25,
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

  Widget _buildBackCard() {
    const repaymentBlue = Color.fromRGBO(30, 54, 100, 1.0);

    // More robust handling of repayment amount with fallbacks
    final repaymentAmount = hasActiveAdvance
        ? (double.tryParse(widget.activeAdvanceData!['total_repayment_amount']
                    ?.toString() ??
                widget.activeAdvanceData!['amount']?.toString() ??
                '0') ??
            0.0)
        : 0.0;

    // More robust handling of repayment date with fallbacks
    DateTime repaymentDate;
    if (hasActiveAdvance) {
      try {
        // Try multiple date field names that might be present
        final dateStr =
            widget.activeAdvanceData!['repayment_date']?.toString() ??
                widget.activeAdvanceData!['repayment_due_date']?.toString();

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
                              _flipCard();
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
                                  turns: _isCardFlipped ? 0.75 : 0.25,
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
                                    ? _pulseAnimation
                                    : const AlwaysStoppedAnimation(1.0),
                                builder: (context, child) {
                                  // Additional mounted check for animation callback
                                  if (!mounted) return Container();

                                  return Transform.scale(
                                    scale:
                                        isUrgent ? _pulseAnimation.value : 1.0,
                                    child: Center(
                                      child: Container(
                                        // Modern glass button
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 18),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                            width: 0.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26
                                                  .withOpacity(0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          buttonText,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14 * fontSizeMultiplier,
                                            fontFamily: 'Onest',
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
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
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'No active loans',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context, 16),
                              fontFamily: 'Onest',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _performHapticFeedback(haptics.HapticsType.light),
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final showFrontSide = _flipAnimation.value < (math.pi / 2);
          final deviceType = ResponsiveUtils.getDeviceType(context);
          // Adjust perspective based on device size
          final perspectiveValue =
              deviceType == DeviceType.small ? 0.002 : 0.001;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspectiveValue)
              ..rotateX(_flipAnimation.value),
            alignment: Alignment.center,
            child: showFrontSide
                ? _buildFrontCard()
                : Transform(
                    transform: Matrix4.identity()..rotateX(math.pi),
                    alignment: Alignment.center,
                    child: _buildBackCard(),
                  ),
          );
        },
      ),
    );
  }
}
