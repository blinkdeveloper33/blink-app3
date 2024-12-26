import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Onest',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontFamily: 'Onest'),
        bodyMedium: TextStyle(fontFamily: 'Onest'),
        titleLarge: TextStyle(fontFamily: 'Onest'),
        titleMedium: TextStyle(fontFamily: 'Onest'),
        titleSmall: TextStyle(fontFamily: 'Onest'),
      ),
    );
  }
}
