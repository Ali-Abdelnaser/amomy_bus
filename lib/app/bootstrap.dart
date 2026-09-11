import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/app_config.dart';
import '../core/config/environment.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_bloc_observer.dart';
import 'app.dart';
import 'di/injection.dart';

Future<void> bootstrap({
  EnvironmentType environment = EnvironmentType.dev,
}) async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize App Configuration
      AppConfig.init(
        AppConfig(
          environment: environment,
          appTitle: AppConstants.appName,
          apiBaseUrl: ApiConstants.baseApiUrl,
          // Supabase / Firebase placeholders — wired in backend integration phase
          supabaseUrl: const String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: 'https://vexqglrlwfallmjfhisv.supabase.co',
          ),
          supabaseAnonKey: const String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue:
                'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZleHFnbHJsd2ZhbGxtamZoaXN2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNzg1MDUsImV4cCI6MjEwNDY1NDUwNX0.4uzClpl-IbE6fUtQT0WZV-UciAd1TLj9-P016vee9wM',
          ),
          enableLogging: environment.isDev,
        ),
      );

      // Initialize Supabase before DI if configured
      await _initializeBackendServicesIfConfigured();

      // Set global BLoC observer
      Bloc.observer = const AppBlocObserver();

      // Initialize Dependency Injection
      await configureDependencies();

      runApp(const AmomyApp());
    },
    (error, stackTrace) {
      developer.log(
        'Unhandled exception caught by bootstrap zone',
        error: error,
        stackTrace: stackTrace,
        name: 'BOOTSTRAP',
      );
    },
  );
}

Future<void> _initializeBackendServicesIfConfigured() async {
  final config = AppConfig.instance;
  if (config.hasValidSupabaseConfig) {
    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: config.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      developer.log('Supabase initialized with PKCE flow.', name: 'BOOTSTRAP');
    } catch (e) {
      developer.log('Supabase initialization warning: $e', name: 'BOOTSTRAP');
    }
  } else {
    developer.log('Running with mock/offline backend placeholders (no Supabase keys set).', name: 'BOOTSTRAP');
  }
}
