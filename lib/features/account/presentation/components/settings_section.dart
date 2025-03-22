import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/utils/temp_localizations.dart';
import 'package:blink_app/features/account/presentation/components/settings_group.dart';
import 'package:blink_app/features/account/presentation/components/setting_tile.dart';
import 'package:blink_app/features/account/presentation/personal_information_screen.dart';
import 'package:blink_app/features/account/presentation/security_screen.dart';
import 'package:blink_app/features/notifications/notifications.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:animate_do/animate_do.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const AnimatedEmoji(
                      AnimatedEmojis.pencil,
                      size: 28,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    localizations.settings,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            _buildAccountSettings(context, localizations),
            _buildGeneralSettings(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettings(
      BuildContext context, AppLocalizations localizations) {
    return SettingsGroup(
      title: localizations.account,
      children: [
        SettingTile(
          icon: Icons.person_outline,
          title: localizations.personalInformation,
          subtitle: localizations.managePersonalDetails,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PersonalInformationScreen(),
              ),
            );
          },
        ),
        SettingTile(
          icon: Icons.security_outlined,
          title: localizations.security,
          subtitle: localizations.manageSecuritySettings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecurityScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(
      BuildContext context, AppLocalizations localizations) {
    return SettingsGroup(
      title: localizations.general,
      children: [
        SettingTile(
          icon: Icons.notifications_outlined,
          title: localizations.notifications,
          subtitle: localizations.configureNotifications,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
