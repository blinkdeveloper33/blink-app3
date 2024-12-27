import 'dart:math';
import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      )..repeat(reverse: true);
    });

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Stagger the animations
    for (var i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _dotControllers[i].forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedBuilder(
              animation: _dotAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -4 * _dotAnimations[index].value),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
