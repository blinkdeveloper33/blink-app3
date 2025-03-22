import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/utils/temp_localizations.dart';
import 'package:blink_app/services/auth_service.dart';
import 'package:blink_app/features/account/presentation/help_support_screen.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;

class ActionButtons extends StatelessWidget {
  const ActionButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.support_outlined,
            title: localizations.helpAndSupport,
            subtitle: localizations.getHelpWithAccount,
            onTap: () {
              haptics.Haptics.vibrate(haptics.HapticsType.light);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            context: context,
            icon: Icons.logout,
            title: localizations.logOut,
            subtitle: localizations.signOutOfAccount,
            isDestructive: true,
            onTap: () async {
              haptics.Haptics.vibrate(haptics.HapticsType.heavy);
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: isDestructive
              ? (isDarkMode
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.05))
              : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDestructive
                ? (isDarkMode
                    ? Colors.red.withOpacity(0.2)
                    : Colors.red.withOpacity(0.1))
                : (isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
          ),
          boxShadow: !isDarkMode && !isDestructive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
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
                            : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: isDestructive
                        ? Colors.red
                        : (isDarkMode ? Colors.white : Colors.black87),
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
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
