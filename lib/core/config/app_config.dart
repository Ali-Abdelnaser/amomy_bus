import 'environment.dart';

class AppConfig {
  final EnvironmentType environment;
  final String appTitle;
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String cartoBasemapKey;
  final String stadiaMapsApiKey;
  final bool enableLogging;

  const AppConfig({
    required this.environment,
    required this.appTitle,
    required this.apiBaseUrl,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.cartoBasemapKey = '',
    this.stadiaMapsApiKey = '',
    this.enableLogging = true,
  });

  bool get hasValidSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool get hasCartoBasemapKey => cartoBasemapKey.isNotEmpty;

  bool get hasStadiaMapsApiKey => stadiaMapsApiKey.isNotEmpty;

  static late final AppConfig instance;

  static void init(AppConfig config) {
    instance = config;
  }
}
