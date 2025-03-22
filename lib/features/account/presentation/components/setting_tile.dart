import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:animate_do/animate_do.dart';

class SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDestructive;

  const SettingTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap != null
            ? () {
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                onTap!();
              }
            : null,
        child: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? (isDarkMode
                            ? Colors.red.withOpacity(0.15)
                            : Colors.red.withOpacity(0.1))
                        : (isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red
                        : (isDarkMode ? Colors.white : Colors.black87),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDestructive
                              ? Colors.red
                              : (isDarkMode ? Colors.white : Colors.black87),
                        ),
                        softWrap: true,
                        maxLines: 2,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                          softWrap: true,
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDestructive
                          ? Colors.red.withOpacity(0.7)
                          : (isDarkMode ? Colors.white60 : Colors.black45),
                      size: 24,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
