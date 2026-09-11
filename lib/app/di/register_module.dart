import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';

@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  SupabaseClient get supabaseClient {
    if (AppConfig.instance.hasValidSupabaseConfig) {
      return Supabase.instance.client;
    }
    return SupabaseClient(
      AppConfig.instance.supabaseUrl.isNotEmpty
          ? AppConfig.instance.supabaseUrl
          : 'https://placeholder.supabase.co',
      AppConfig.instance.supabaseAnonKey.isNotEmpty
          ? AppConfig.instance.supabaseAnonKey
          : 'placeholder-anon-key',
    );
  }

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn.instance;
}
