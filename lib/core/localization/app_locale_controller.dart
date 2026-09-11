import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'localization_helpers.dart';

/// Centralized controller managing app-wide locale switching with persistence.
class AppLocaleController extends ChangeNotifier {
  static final AppLocaleController instance = AppLocaleController._();
  AppLocaleController._();

  Locale _locale = LocalizationHelper.arabicLocale;
  Locale get locale => _locale;

  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(StorageKeys.appLocale);
      if (code != null && code.isNotEmpty) {
        _locale = Locale(code);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    if (_locale.languageCode == 'ar') {
      await setLocale(LocalizationHelper.englishLocale);
    } else {
      await setLocale(LocalizationHelper.arabicLocale);
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.appLocale, newLocale.languageCode);
    } catch (_) {}
  }
}
