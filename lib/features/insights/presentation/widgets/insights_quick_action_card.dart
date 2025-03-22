import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:blink_app/features/insights/presentation/financial_insights_screen.dart';
import 'package:blink_app/features/quick_actions/presentation/widgets/quick_action_card.dart';
import 'package:blink_app/core/utils/responsive_utils.dart';

class InsightsQuickActionCard extends QuickActionCard {
  const InsightsQuickActionCard({
    Key? key,
    required bool isDarkMode,
    Function(haptics.HapticsType)? onHapticFeedback,
  }) : super(
          key: key,
          isDarkMode: isDarkMode,
          onHapticFeedback: onHapticFeedback,
        );

  @override
  State<InsightsQuickActionCard> createState() =>
      _InsightsQuickActionCardState();
}

class _InsightsQuickActionCardState
    extends QuickActionCardState<InsightsQuickActionCard> {
  @override
  void onCardTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FinancialInsightsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const insightsBlue = Color.fromRGBO(55, 168, 222, 1.0);
    final deviceMultiplier = ResponsiveUtils.getElementSizeMultiplier(context);

    return buildCardGesture(
      context,
      Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20 * deviceMultiplier),
        child: Container(
          clipBehavior: Clip.antiAlias,
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
            borderRadius: BorderRadius.circular(20 * deviceMultiplier),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: insightsBlue.withOpacity(0.4),
                blurRadius: 12 * deviceMultiplier,
                offset: Offset(0, 6 * deviceMultiplier),
                spreadRadius: -2 * deviceMultiplier,
              ),
              BoxShadow(
                color: insightsBlue.withOpacity(0.2),
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
                        // Modern icon container with refined styling - matching Repay card
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
                            AnimatedEmojis.crystalBall,
                            size: 28,
                            repeat: true,
                          ),
                        ),
                        // Forward button styling matching Repay card
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
                    // Professional title with consistent styling matching Repay card
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
                            text: 'Insights',
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
}
