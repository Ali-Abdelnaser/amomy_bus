import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../entities/user_access_status.dart';
import '../entities/wallet_preview.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  ResultFuture<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email, password and full name (phone, gender, dob optional at registration)
  ResultFuture<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  });

  /// Verify 6-digit email OTP (signup or recovery)
  ResultFuture<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  });

  /// Resend verification OTP to email
  ResultFuture<void> resendVerificationOtp({required String email});

  /// Native Google Sign-In with Google ID Token exchange
  ResultFuture<AppUser> signInWithGoogle({String? webClientId});

  /// Native Apple Sign-In with Apple ID Token exchange
  ResultFuture<AppUser> signInWithApple();

  /// Complete missing profile fields (for Google authenticated users)
  ResultFuture<AppUser> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  });

  /// Initiate password reset email
  ResultFuture<void> sendPasswordResetEmail({required String email});

  /// Update password (when in recovery session)
  ResultFuture<void> updatePassword({required String newPassword});

  /// Retrieve current authenticated user with profile and roles
  ResultFuture<AppUser?> getCurrentUser();

  /// Retrieve user wallet points (read-only verification)
  ResultFuture<WalletPreview?> getWalletPreview(String userId);

  /// Silently attempt to claim active welcome gift campaign
  ResultFuture<bool> claimActiveWelcomeGift({required String deviceIdentifier});

  /// Check pre-auth device access (works unauthenticated)
  ResultFuture<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  });

  /// Register installation after auth
  ResultFuture<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  });

  /// Get current user access status (banned/blocked check)
  ResultFuture<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  });

  /// Record user activity event
  ResultFuture<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  });

  /// Sign out current user session
  ResultFuture<void> signOut();

  /// Stream of user auth changes
  Stream<AppUser?> get authUserStream;
}
