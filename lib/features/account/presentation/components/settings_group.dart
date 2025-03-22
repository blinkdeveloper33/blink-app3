import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:animate_do/animate_do.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.7)
                    : Theme.of(context).primaryColor.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...children.asMap().entries.map((entry) {
            final index = entry.key;
            final child = entry.value;

            // Apply increasing delay for cascading animation effect
            return FadeInUp(
              delay: Duration(milliseconds: 100 * index),
              duration: const Duration(milliseconds: 400),
              from: 10,
              child: child,
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
