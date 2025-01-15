import 'package:flutter/material.dart';
import 'package:animated_emoji/emoji.dart';
import 'package:animated_emoji/emojis.g.dart';

class InsightsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color color;
  final AnimatedEmoji? emoji;
  final bool isDarkMode;
  final VoidCallback? onTap;
  final Widget? trailing;

  const InsightsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
    this.emoji,
    required this.isDarkMode,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? color.withOpacity(0.2) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (emoji != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: emoji!,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontFamily: 'Onest',
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Onest',
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white60 : Colors.black45,
                    fontSize: 12,
                    fontFamily: 'Onest',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
