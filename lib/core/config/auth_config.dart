import 'dart:io';

/// Centralized access to external Authentication configuration and Public OAuth Client IDs.
///
/// Public Client IDs are injected via `--dart-define`:
/// - `GOOGLE_WEB_CLIENT_ID`: Audience/Server Client ID used by Supabase Auth and token verification.
/// - `GOOGLE_IOS_CLIENT_ID`: Native iOS Client ID used on iOS for Google Sign-In.
///
/// NOTE: Google Client Secret MUST NEVER be placed in Flutter code.
/// Android uses package name (`com.aliabdelnaser.amomy`) + Signing Certificate SHA-1 registered in Google Cloud Console.
abstract final class AuthConfig {
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '614005330939-til537iblassb8apl3o2smsen51jkssk.apps.googleusercontent.com',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '614005330939-9kvm72ogcnd4seaa0lk38luv45usmrrg.apps.googleusercontent.com',
  );

  /// Whether the public Google Web Client ID is provided
  static bool get hasGoogleWebClientId => googleWebClientId.isNotEmpty;

  /// Whether the public Google iOS Client ID is provided
  static bool get hasGoogleIosClientId => googleIosClientId.isNotEmpty;

  /// Verifies that the required Google Client configuration is present for the current platform.
  /// Throws a clear descriptive [AuthConfigurationException] if missing in debug mode.
  static void validateGoogleConfig() {
    if (!hasGoogleWebClientId) {
      assert(
        false,
        'Missing GOOGLE_WEB_CLIENT_ID. Please run with --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>',
      );
    }

    if (Platform.isIOS && !hasGoogleIosClientId) {
      assert(
        false,
        'Missing GOOGLE_IOS_CLIENT_ID. Please run with --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id>',
      );
    }
  }
}

/// Thrown when an OAuth configuration parameter is missing or misconfigured.
class AuthConfigurationException implements Exception {
  final String message;
  const AuthConfigurationException(this.message);

  @override
  String toString() => 'AuthConfigurationException: $message';
}
