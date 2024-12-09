import 'package:flutter/material.dart';

class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();

  factory ThemeManager() {
    return _instance;
  }

  ThemeManager._internal();

  ThemeData _currentTheme = _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    primaryColor: Color(0xFF2196F3),
    scaffoldBackgroundColor: Color(0xFFF5F7FF),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF2196F3),
      secondary: Color(0xFF1A237E),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    primaryColor: Color(0xFF1565C0),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1A237E),
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1565C0),
      secondary: Color(0xFF1A237E),
    ),
  );

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    _currentTheme = _currentTheme == _lightTheme ? _darkTheme : _lightTheme;
  }
}
