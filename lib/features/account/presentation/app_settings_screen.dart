import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blink_app/providers/theme_provider.dart';
import 'package:blink_app/providers/locale_provider.dart';
import 'package:haptic_feedback/haptic_feedback.dart' as haptics;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:ui';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late String _selectedLanguage;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = Provider.of<LocaleProvider>(context, listen: false)
            .locale
            ?.languageCode ??
        'en';
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          haptics.Haptics.vibrate(haptics.HapticsType.light);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 20,
          height: 20,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white.withOpacity(0.9),
              size: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isDarkMode ? Colors.white : Colors.black87,
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
                        color: isDarkMode ? Colors.white : Colors.black87,
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
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.selectLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('EN'),
              ),
              title: Text(localizations.english),
              trailing: _selectedLanguage == 'en'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () async {
                setState(() => _selectedLanguage = 'en');
                await Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale('en');
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Text('ES'),
              ),
              title: Text(localizations.spanish),
              trailing: _selectedLanguage == 'es'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () async {
                setState(() => _selectedLanguage = 'es');
                await Provider.of<LocaleProvider>(context, listen: false)
                    .setLocale('es');
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                if (mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;

    return Container(
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
            child: Text(
              localizations.general.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: isDarkMode ? Colors.white60 : Colors.grey[700],
              ),
            ),
          ),
          _buildSettingTile(
            icon: Icons.language,
            title: localizations.language,
            subtitle: _selectedLanguage == 'en'
                ? localizations.english
                : localizations.spanish,
            onTap: _showLanguageSelector,
            trailing: Icon(
              Icons.chevron_right,
              color: isDarkMode ? Colors.white60 : Colors.black45,
            ),
          ),
          _buildSettingTile(
            icon: Icons.dark_mode_outlined,
            title: localizations.darkMode,
            subtitle: localizations.toggleDarkMode,
            trailing: Switch.adaptive(
              value: isDarkMode,
              activeColor: Colors.blue,
              onChanged: (value) {
                haptics.Haptics.vibrate(haptics.HapticsType.light);
                Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final localizations = AppLocalizations.of(context)!;
    final appBarOpacity = (_scrollOffset / 100).clamp(0.0, 0.8);

    return Scaffold(
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor:
            (isDarkMode ? const Color(0xFF1A237E) : const Color(0xFF1A237E))
                .withOpacity(appBarOpacity),
        elevation: appBarOpacity > 0 ? 1 : 0,
        leadingWidth: 56,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: appBarOpacity * 10,
              sigmaY: appBarOpacity * 10,
            ),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _buildBackButton(),
        ),
        title: Text(
          localizations.appSettings,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Enhanced background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.2, 0.5, 1.0],
                  colors: [
                    const Color(0xFF1A237E).withOpacity(0.95),
                    const Color(0xFF0D47A1).withOpacity(0.8),
                    isDarkMode
                        ? const Color(0xFF121212).withOpacity(0.95)
                        : const Color(0xFFF5F5F7).withOpacity(0.95),
                    isDarkMode
                        ? const Color(0xFF121212)
                        : const Color(0xFFF5F5F7),
                  ],
                ),
              ),
            ),
          ),
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: CustomPaint(
                painter: PatternPainter(),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = 20.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(i, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
