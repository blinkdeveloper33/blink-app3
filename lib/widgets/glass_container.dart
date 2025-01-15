import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurAmount;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final bool useGradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurAmount = 15.0,
    this.backgroundColor,
    this.borderColor,
    this.gradientColors,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultBackgroundColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.7);
    final defaultBorderColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.8);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? defaultBorderColor,
              width: 1.5,
            ),
            gradient: useGradient && gradientColors != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors!,
                  )
                : null,
            color: useGradient
                ? null
                : (backgroundColor ?? defaultBackgroundColor),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
