import 'package:flutter/material.dart';
export '../extensions/context_extensions.dart';

class LocalizationHelper {
  const LocalizationHelper._();

  static const Locale arabicLocale = Locale('ar');
  static const Locale englishLocale = Locale('en');

  static const List<Locale> supportedLocales = [
    arabicLocale,
    englishLocale,
  ];
}
