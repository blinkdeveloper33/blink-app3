import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Available app icon themes
enum AppIconTheme {
  blue, // Default icon
  white, // White/light theme icon
}

/// A utility class to manage app icon switching on iOS
class AppIconManager {
  /// Channel for communicating with iOS native code
  static const MethodChannel _channel = MethodChannel('com.blink_app/app_icon');

  // Global navigator key for accessing context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Returns whether the current platform supports alternate icons
  static Future<bool> supportsAlternateIcons() async {
    if (!Platform.isIOS) {
      return false;
    }

    try {
      final bool result = await _channel.invokeMethod('supportsAlternateIcons');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking alternate icon support: ${e.message}');
      return false;
    }
  }

  /// Get the current app icon theme
  static Future<AppIconTheme> getCurrentAppIconTheme() async {
    if (!await supportsAlternateIcons()) {
      return AppIconTheme.blue; // Default
    }

    try {
      final String? iconName =
          await _channel.invokeMethod('getAlternateIconName');
      if (iconName == null || iconName.isEmpty) {
        return AppIconTheme.blue;
      } else if (iconName == 'WhiteIcon') {
        return AppIconTheme.white;
      } else {
        return AppIconTheme.blue;
      }
    } on PlatformException catch (e) {
      debugPrint('Error getting current icon: ${e.message}');
      return AppIconTheme.blue;
    }
  }

  /// Change the app icon to the specified theme
  static Future<bool> setAppIconTheme(AppIconTheme theme) async {
    if (!await supportsAlternateIcons()) {
      return false;
    }

    String? iconName;
    switch (theme) {
      case AppIconTheme.blue:
        iconName = null; // Use primary icon
        break;
      case AppIconTheme.white:
        iconName = 'WhiteIcon';
        break;
    }

    try {
      await _channel
          .invokeMethod('setAlternateIconName', {'iconName': iconName});
      return true;
    } on PlatformException catch (e) {
      debugPrint('Error setting app icon: ${e.message}');
      return false;
    }
  }
}
