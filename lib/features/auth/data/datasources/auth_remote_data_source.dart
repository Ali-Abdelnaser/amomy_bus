import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/auth_config.dart';
import '../../domain/entities/user_access_status.dart';
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
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  });

  Future<AppUserModel> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> resendVerificationOtp({required String email});

  Future<AppUserModel> signInWithGoogle({String? webClientId});

  Future<AppUserModel> signInWithApple();

  Future<AppUserModel> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> updatePassword({required String newPassword});

  Future<AppUserModel?> getCurrentUser();

  Future<WalletPreviewModel?> getWalletPreview(String userId);

  Future<Map<String, dynamic>?> claimActiveWelcomeGift({
    required String deviceIdentifier,
  });

  Future<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  });

  Future<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  });

  Future<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  });

  Future<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  });

  Future<void> signOut();

  Stream<User?> get authStateChanges;
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  static const String redirectUrl = 'com.aliabdelnaser.amomy://login-callback';

  AuthRemoteDataSourceImpl(this._supabase, this._googleSignIn);

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
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    final Map<String, dynamic> metadata = {'full_name': fullName.trim()};
    if (phone != null && phone.trim().isNotEmpty) {
      metadata['phone'] = phone.trim();
    }
    if (gender != null && gender.trim().isNotEmpty) {
      metadata['gender'] = gender.trim().toLowerCase();
    }
    if (dateOfBirth != null) {
      metadata['date_of_birth'] = DateFormat('yyyy-MM-dd').format(dateOfBirth);
    }

    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
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
  Future<void> resendVerificationOtp({required String email}) async {
    await _supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: redirectUrl,
    );
  }

  @override
  Future<AppUserModel> signInWithGoogle({String? webClientId}) async {
    final effectiveWebClientId = (webClientId != null && webClientId.isNotEmpty)
        ? webClientId
        : AuthConfig.googleWebClientId;

    if (effectiveWebClientId.isEmpty) {
      developer.log('Missing GOOGLE_WEB_CLIENT_ID configuration', name: 'AUTH');
      throw const AuthConfigurationException(
        'Missing GOOGLE_WEB_CLIENT_ID. Please run the app with --dart-define=GOOGLE_WEB_CLIENT_ID=<your-web-client-id>',
      );
    }

    if (Platform.isIOS && !AuthConfig.hasGoogleIosClientId) {
      developer.log('Missing GOOGLE_IOS_CLIENT_ID configuration', name: 'AUTH');
      throw const AuthConfigurationException(
        'Missing GOOGLE_IOS_CLIENT_ID. Please run the app with --dart-define=GOOGLE_IOS_CLIENT_ID=<your-ios-client-id>',
      );
    }

    // Attempt native Google authentication
    final GoogleSignInAccount googleAccount;
    try {
      developer.log('Initiating native Google authentication...', name: 'AUTH');
      googleAccount = await _googleSignIn.authenticate();
      developer.log(
        'Google account selected successfully: ${googleAccount.email}',
        name: 'AUTH',
      );
    } catch (e, st) {
      developer.log(
        'Google native authentication failed or was cancelled: $e',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      // Re-throw so ErrorHandler maps user cancellation or PlatformException
      rethrow;
    }

    final googleAuth = googleAccount.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      developer.log(
        'Failed to retrieve Google ID Token (idToken is null or empty)',
        name: 'AUTH',
      );
      throw const AuthException('Failed to retrieve Google ID Token.');
    }

    developer.log(
      'Exchanging Google ID token with Supabase (token length: ${idToken.length})...',
      name: 'AUTH',
    );
    final AuthResponse response;
    try {
      response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e, st) {
      developer.log(
        'Supabase signInWithIdToken threw exception: $e',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }

    final user = response.user;
    if (user == null) {
      developer.log(
        'Supabase returned null user session after Google ID token exchange',
        name: 'AUTH',
      );
      throw const AuthException(
        'Google Sign-In failed: no Supabase user session created.',
      );
    }

    developer.log(
      'Supabase user session authenticated: ${user.id} (${user.email})',
      name: 'AUTH',
    );
    return _fetchFullUserModel(user);
  }

  @override
  Future<AppUserModel> signInWithApple() async {
    developer.log('Initiating native Apple authentication...', name: 'AUTH');

    // A. Generate raw nonce
    final rawNonce = _supabase.auth.generateRawNonce();

    // B. SHA-256 hash it
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    // C. Request Apple credential
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      developer.log('Apple ID credential received successfully', name: 'AUTH');
    } catch (e, st) {
      developer.log(
        'Apple native authentication failed or was cancelled: $e',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }

    // D. Validate identityToken
    final idToken = credential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      developer.log(
        'Failed to retrieve Apple identityToken (null or empty)',
        name: 'AUTH',
      );
      throw const AuthException('Failed to retrieve Apple Identity Token.');
    }

    // E. Sign into Supabase with idToken and rawNonce
    developer.log('Exchanging Apple ID token with Supabase...', name: 'AUTH');
    final AuthResponse response;
    try {
      response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } catch (e, st) {
      developer.log(
        'Supabase signInWithIdToken threw exception for Apple: $e',
        name: 'AUTH',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }

    // F. Validate response.user is not null
    final user = response.user;
    if (user == null) {
      developer.log(
        'Supabase returned null user session after Apple ID token exchange',
        name: 'AUTH',
      );
      throw const AuthException(
        'Apple Sign-In failed: no Supabase user session created.',
      );
    }

    developer.log(
      'Supabase user session authenticated with Apple: ${user.id} (${user.email})',
      name: 'AUTH',
    );

    // Apple Name Handling:
    // Apple only returns givenName/familyName during the FIRST authorization.
    final givenName = credential.givenName?.trim();
    final familyName = credential.familyName?.trim();
    final nameParts = [
      if (givenName != null && givenName.isNotEmpty) givenName,
      if (familyName != null && familyName.isNotEmpty) familyName,
    ];
    final fullName = nameParts.join(' ').trim();

    if (fullName.isNotEmpty) {
      developer.log(
        'Updating auth metadata and profile with Apple name info: $fullName',
        name: 'AUTH',
      );

      try {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': fullName,
              if (givenName != null && givenName.isNotEmpty)
                'given_name': givenName,
              if (familyName != null && familyName.isNotEmpty)
                'family_name': familyName,
            },
          ),
        );
      } catch (e) {
        developer.log(
          'Non-critical: failed to update auth metadata for Apple name: $e',
          name: 'AUTH',
        );
      }

      // Safely persist full_name into public.profiles ONLY when appropriate.
      // Do NOT overwrite an existing meaningful public.profiles.full_name with null, empty, or partial bad data.
      try {
        final currentProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();

        final existingName = (currentProfile?['full_name'] as String?)?.trim();
        if (existingName == null || existingName.isEmpty) {
          await _supabase
              .from('profiles')
              .update({'full_name': fullName})
              .eq('id', user.id);
        }
      } catch (e) {
        developer.log(
          'Non-critical: failed to persist full_name to profiles: $e',
          name: 'AUTH',
        );
      }
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
    await _supabase
        .from('profiles')
        .update({
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'gender': gender.trim().toLowerCase(),
          'date_of_birth': dobFormatted,
        })
        .eq('id', userId);

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

    throw const AuthException(
      'Failed to refresh user after completing profile.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: redirectUrl,
    );
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
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
          .select('id, user_id, cached_available_balance, cached_held_balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      final cachedAvailable =
          (data['cached_available_balance'] as num?)?.toInt() ?? 0;
      final cachedHeld = (data['cached_held_balance'] as num?)?.toInt() ?? 0;

      int cashPoints = cachedAvailable + cachedHeld;
      int subscriptionPoints = 0;

      try {
        final batches = await _supabase
            .from('point_batches')
            .select('source_type, remaining_amount')
            .eq('user_id', userId)
            .gt('remaining_amount', 0);

        if (batches.isNotEmpty) {
          int batchCash = 0;
          int batchSub = 0;
          for (final b in batches) {
            final st = b['source_type'] as String?;
            final amt = (b['remaining_amount'] as num?)?.toInt() ?? 0;
            if (st == 'subscription') {
              batchSub += amt;
            } else {
              batchCash += amt;
            }
          }
          cashPoints = batchCash;
          subscriptionPoints = batchSub;
        }
      } catch (_) {
        // Fallback: cached_available_balance + cached_held_balance serves as total points
      }

      return WalletPreviewModel(
        id: data['id'] as String? ?? '',
        userId: data['user_id'] as String? ?? userId,
        cashPoints: cashPoints,
        subscriptionPoints: subscriptionPoints,
        heldPoints: cachedHeld,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> claimActiveWelcomeGift({
    required String deviceIdentifier,
  }) async {
    final response = await _supabase.rpc(
      'claim_active_welcome_gift',
      params: {'p_device_identifier': deviceIdentifier.trim()},
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return null;
  }

  @override
  Future<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  }) async {
    final response = await _supabase.rpc(
      'check_device_access',
      params: {'p_device_identifier': deviceIdentifier.trim()},
    );

    if (response is Map) {
      return DeviceAccessResult.fromJson(Map<String, dynamic>.from(response));
    }
    return const DeviceAccessResult(allowed: true, isBlocked: false);
  }

  @override
  Future<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    await _supabase.rpc(
      'register_user_installation',
      params: {
        'p_device_identifier': deviceIdentifier.trim(),
        'p_platform': platform.trim(),
        if (deviceName != null && deviceName.trim().isNotEmpty)
          'p_device_name': deviceName.trim(),
        if (appVersion != null && appVersion.trim().isNotEmpty)
          'p_app_version': appVersion.trim(),
      },
    );
  }

  @override
  Future<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  }) async {
    final response = await _supabase.rpc(
      'get_my_access_status',
      params: {'p_device_identifier': deviceIdentifier.trim()},
    );

    if (response is Map) {
      return UserAccessStatus.fromJson(Map<String, dynamic>.from(response));
    }
    return const UserAccessStatus(allowed: true, accountStatus: 'active');
  }

  @override
  Future<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  }) async {
    await _supabase.rpc(
      'record_user_activity',
      params: {
        'p_event_type': eventType.trim(),
        'p_device_identifier': deviceIdentifier.trim(),
        if (metadata != null && metadata.isNotEmpty) 'p_metadata': metadata,
      },
    );
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

    final model = AppUserModel.fromSupabase(
      user: user,
      profileData: profileData,
      roleStrings: roles,
    );

    // If profile row exists but has no avatar_url and user has an avatar from provider metadata, persist it
    if (profileData != null &&
        (profileData['avatar_url'] as String?) == null &&
        model.avatarUrl != null) {
      try {
        await _supabase
            .from('profiles')
            .update({'avatar_url': model.avatarUrl})
            .eq('id', user.id);
      } catch (_) {
        // Non-critical background update
      }
    }

    return model;
  }
}
