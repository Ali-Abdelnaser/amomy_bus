import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw StateError('AppLocalizations not found in current context');
    }
    return localizations;
  }

  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
}

class LocalizationHelper {
  const LocalizationHelper._();

  static const Locale arabicLocale = Locale('ar');
  static const Locale englishLocale = Locale('en');

  static const List<Locale> supportedLocales = [
    arabicLocale,
    englishLocale,
  ];
}
