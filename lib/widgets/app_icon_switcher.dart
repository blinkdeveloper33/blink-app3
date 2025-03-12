import 'package:flutter/material.dart';
import '../utils/app_icon_manager.dart';

class AppIconSwitcher extends StatefulWidget {
  const AppIconSwitcher({Key? key}) : super(key: key);

  @override
  State<AppIconSwitcher> createState() => _AppIconSwitcherState();
}

class _AppIconSwitcherState extends State<AppIconSwitcher> {
  AppIconTheme _currentTheme = AppIconTheme.blue;
  bool _isSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final isSupported = await AppIconManager.supportsAlternateIcons();
    final currentTheme = await AppIconManager.getCurrentAppIconTheme();

    if (mounted) {
      setState(() {
        _isSupported = isSupported;
        _currentTheme = currentTheme;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeAppIcon(AppIconTheme theme) async {
    if (_currentTheme == theme) return;

    setState(() {
      _isLoading = true;
    });

    final success = await AppIconManager.setAppIconTheme(theme);

    if (mounted) {
      setState(() {
        if (success) {
          _currentTheme = theme;
        }
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'App icon changed to ${theme == AppIconTheme.blue ? "blue" : "white"}'
              : 'Failed to change app icon'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_isSupported) {
      return const SizedBox.shrink(); // Hide if not supported
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'App Icon Style',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIconOption(
              context,
              'Blue',
              AppIconTheme.blue,
              Colors.blue,
            ),
            _buildIconOption(
              context,
              'White',
              AppIconTheme.white,
              Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconOption(
    BuildContext context,
    String label,
    AppIconTheme theme,
    Color color,
  ) {
    final isSelected = _currentTheme == theme;

    return GestureDetector(
      onTap: () => _changeAppIcon(theme),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: color == Colors.white ? Colors.blue : Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
