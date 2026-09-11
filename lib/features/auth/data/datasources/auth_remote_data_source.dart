import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user_model.dart';
import '../models/wallet_preview_model.dart';

abstract class AuthRemoteDataSource {
  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  });

  Future<AppUserModel> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> resendVerificationOtp({
    required String email,
  });

  Future<AppUserModel> signInWithGoogle({
    String? webClientId,
  });

  Future<AppUserModel> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<void> updatePassword({
    required String newPassword,
  });

  Future<AppUserModel?> getCurrentUser();

  Future<WalletPreviewModel?> getWalletPreview(String userId);

  Future<void> signOut();

  Stream<User?> get authStateChanges;
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  static const String redirectUrl = 'com.aliabdelnaser.amomy://login-callback';

  AuthRemoteDataSourceImpl(
    this._supabase,
    this._googleSignIn,
  );

  @override
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) => data.session?.user);
  }

  @override
  Future<AppUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Login failed: user not found.');
    }

    return _fetchFullUserModel(user);
  }

  @override
  Future<AppUserModel> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    final dobFormatted = DateFormat('yyyy-MM-dd').format(dateOfBirth);

    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'gender': gender.trim().toLowerCase(),
        'date_of_birth': dobFormatted,
      },
      emailRedirectTo: redirectUrl,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Registration failed: no user returned.');
    }

    return AppUserModel.fromSupabase(user: user);
  }

  @override
  Future<AppUserModel> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );

    final user = response.user ?? _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Verification failed: user not available.');
    }

    return _fetchFullUserModel(user);
  }

  @override
  Future<void> resendVerificationOtp({
    required String email,
  }) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<AppUserModel> signInWithGoogle({
    String? webClientId,
  }) async {
    if (webClientId != null && webClientId.isNotEmpty) {
      await _googleSignIn.initialize(serverClientId: webClientId);
    }

    final googleAccount = await _googleSignIn.authenticate();
    final googleAuth = googleAccount.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('Failed to retrieve Google ID Token.');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('Google Sign-In failed: no Supabase user session created.');
    }

    return _fetchFullUserModel(user);
  }

  @override
  Future<AppUserModel> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    final dobFormatted = DateFormat('yyyy-MM-dd').format(dateOfBirth);

    // Update public.profiles row
    await _supabase.from('profiles').update({
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'gender': gender.trim().toLowerCase(),
      'date_of_birth': dobFormatted,
    }).eq('id', userId);

    // Also sync to auth user metadata
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'gender': gender.trim().toLowerCase(),
            'date_of_birth': dobFormatted,
          },
        ),
      );
    } catch (_) {
      // Non-critical if metadata sync is restricted
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      return _fetchFullUserModel(currentUser);
    }

    throw const AuthException('Failed to refresh user after completing profile.');
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  @override
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _fetchFullUserModel(user);
  }

  @override
  Future<WalletPreviewModel?> getWalletPreview(String userId) async {
    try {
      final data = await _supabase
          .from('wallets')
          .select('id, user_id, cash_points, subscription_points, held_points')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return WalletPreviewModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if not signed in with Google
    }
    await _supabase.auth.signOut();
  }

  Future<AppUserModel> _fetchFullUserModel(User user) async {
    Map<String, dynamic>? profileData;
    List<String>? roles;

    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      profileData = profileResponse;
    } catch (_) {
      // Profile may not exist if trigger hasn't finished or in offline mode
    }

    try {
      final rolesResponse = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id);

      roles = rolesResponse
          .map((r) => r['role']?.toString())
          .whereType<String>()
          .toList();
    } catch (_) {
      // Default to passenger
    }

    return AppUserModel.fromSupabase(
      user: user,
      profileData: profileData,
      roleStrings: roles,
    );
  }
}
