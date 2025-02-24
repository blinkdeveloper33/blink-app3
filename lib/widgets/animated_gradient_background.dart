import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool isDarkMode;

  const AnimatedGradientBackground({
    Key? key,
    required this.child,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _AnimatedGradientBackgroundState createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getLightGradientColors() {
    final now = TimeOfDay.now();
    if (now.hour >= 17 && now.hour < 21) {
      // Evening (5 PM to 8:59 PM)
      return [
        const Color(0xFFF3E5F5), // Very light purple
        const Color(0xFFFCE4EC), // Very light pink
      ];
    } else {
      // Night (9 PM to 4:59 AM) and all other times
      return [
        const Color(0xFFE8EAF6), // Very light blue
        const Color(0xFFEDE7F6), // Very light purple
      ];
    }
  }

  List<Color> _getDarkGradientColors() {
    final now = TimeOfDay.now();
    if (now.hour >= 17 && now.hour < 21) {
      // Evening (5 PM to 8:59 PM)
      return [
        const Color(0xFF2E0249), // Deeper purple
        const Color(0xFF570A57), // Darker pink
      ];
    } else {
      // Night (9 PM to 4:59 AM) and all other times
      return [
        const Color(0xFF03001C), // Very dark blue
        const Color(0xFF301E67), // Slightly lighter blue
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.isDarkMode
        ? _getDarkGradientColors()
        : _getLightGradientColors();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                  stops: [_animation.value, _animation.value + 0.5],
                ),
              ),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
