import 'environment.dart';

class AppConfig {
  final EnvironmentType environment;
  final String appTitle;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool enableLogging;

  const AppConfig({
    required this.environment,
    required this.appTitle,
    required this.apiBaseUrl,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.enableLogging = true,
  });

  bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static late final AppConfig instance;

  static void init(AppConfig config) {
    instance = config;
  }
}
