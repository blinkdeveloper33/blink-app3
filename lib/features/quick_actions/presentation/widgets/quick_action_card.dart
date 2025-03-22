import 'package:flutter/material.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

/// A base class for quick action cards to maintain consistent behavior and styling
abstract class QuickActionCard extends StatefulWidget {
  final bool isDarkMode;
  final Function(haptics.HapticsType)? onHapticFeedback;

  const QuickActionCard({
    Key? key,
    required this.isDarkMode,
    this.onHapticFeedback,
  }) : super(key: key);
}

abstract class QuickActionCardState<T extends QuickActionCard> extends State<T>
    with SingleTickerProviderStateMixin {
  // Late initialization - will be set in initState
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    // Initialize with proper vsync
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  /// Helper method to perform haptic feedback with the appropriate type
  void performHapticFeedback(haptics.HapticsType type) {
    if (widget.onHapticFeedback != null) {
      widget.onHapticFeedback!(type);
    }
  }

  /// Called when the card is tapped
  void onCardTap(BuildContext context);

  /// Base build method that implements common gesture detection behavior
  Widget buildCardGesture(BuildContext context, Widget child) {
    return GestureDetector(
      onTapDown: (_) {
        performHapticFeedback(haptics.HapticsType.light);
        animationController.forward();
      },
      onTapUp: (_) {
        animationController.reverse();
        performHapticFeedback(haptics.HapticsType.medium);
        onCardTap(context);
      },
      onTapCancel: () {
        animationController.reverse();
      },
      child: child,
    );
  }
}

/// A utility class that provides common styling for quick action cards
class QuickActionCardStyle {
  static BoxDecoration buildGradientDecoration({
    required Color primaryColor,
    required bool isDarkMode,
    double opacity = 0.95,
    double shadowIntensity = 1.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primaryColor.withOpacity(opacity),
          primaryColor.withOpacity(opacity - 0.05),
        ],
        stops: const [0.2, 0.9],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(isDarkMode ? 0.2 : 0.1),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: primaryColor.withOpacity(isDarkMode ? 0.4 : 0.2),
          blurRadius: 12 * shadowIntensity,
          offset: Offset(0, 6 * shadowIntensity),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1),
          blurRadius: 24 * shadowIntensity,
          offset: Offset(0, 12 * shadowIntensity),
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Create a standard icon container for quick action cards
  static Widget buildIconContainer({
    required Widget icon,
    required Color color,
    required bool isDarkMode,
    double size = 40,
    double padding = 12,
  }) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDarkMode ? 0.15 : 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(isDarkMode ? 0.2 : 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: icon,
      ),
    );
  }
}
