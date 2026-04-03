import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  static const List<({String code, String name, String nativeName})>
      supportedLanguages = [
    (code: 'en', name: 'English', nativeName: 'English'),
    (code: 'hi', name: 'Hindi', nativeName: 'हिन्दी'),
    (code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
    (code: 'ta', name: 'Tamil', nativeName: 'தமிழ்'),
    (code: 'te', name: 'Telugu', nativeName: 'తెలుగు'),
    (code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
    (code: 'ur', name: 'Urdu', nativeName: 'اردو'),
    (code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    (code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    (code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
    (code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
  ];
}
