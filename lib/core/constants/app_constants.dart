class AppConstants {
  const AppConstants._();

  static const String appName = 'Amomy Bus';
  static const String appVersion = '1.0.0';

  // Duration constants
  static const Duration splashDuration = Duration(milliseconds: 1500);
  static const Duration seatHoldDuration = Duration(minutes: 5);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Localization
  static const String defaultLocale = 'ar';
  static const String fallbackLocale = 'en';
}
