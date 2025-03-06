import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  final SharedPreferences _prefs;
  Locale? _locale;

  LocaleProvider(this._prefs) {
    final String? savedLocale = _prefs.getString(_localeKey);
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }
  }

  Locale? get locale => _locale;

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await _prefs.setString(_localeKey, languageCode);
    notifyListeners();
  }
}
