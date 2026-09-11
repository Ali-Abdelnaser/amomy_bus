class StorageKeys {
  const StorageKeys._();

  // Secure storage keys
  static const String authToken = 'amomy_auth_token';
  static const String refreshToken = 'amomy_refresh_token';
  static const String userId = 'amomy_user_id';
  static const String nfcToken = 'amomy_nfc_card_token';

  // Shared preferences keys
  static const String appThemeMode = 'amomy_theme_mode';
  static const String appLocale = 'amomy_locale';
  static const String onboardingCompleted = 'amomy_onboarding_completed';
  static const String fcmDeviceToken = 'amomy_fcm_token';
}
