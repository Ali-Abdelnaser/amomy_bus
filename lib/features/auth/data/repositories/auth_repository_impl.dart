import 'dart:async';
import 'package:injectable/injectable.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_access_status.dart';
import '../../domain/entities/wallet_preview.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<AppUser?> get authUserStream {
    return _remoteDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) return null;
      try {
        final appUser = await _remoteDataSource.getCurrentUser();
        return appUser?.toEntity();
      } catch (_) {
        return null;
      }
    });
  }

  @override
  ResultFuture<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Success(user.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      final user = await _remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      return Success(user.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    try {
      final user = await _remoteDataSource.verifyEmailOtp(
        email: email,
        token: token,
      );
      return Success(user.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> resendVerificationOtp({required String email}) async {
    try {
      await _remoteDataSource.resendVerificationOtp(email: email);
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<AppUser> signInWithGoogle({String? webClientId}) async {
    try {
      final user = await _remoteDataSource.signInWithGoogle(
        webClientId: webClientId,
      );
      return Success(user.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<AppUser> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    try {
      final user = await _remoteDataSource.completeProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      return Success(user.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _remoteDataSource.sendPasswordResetEmail(email: email);
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> updatePassword({required String newPassword}) async {
    try {
      await _remoteDataSource.updatePassword(newPassword: newPassword);
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<AppUser?> getCurrentUser() async {
    try {
      final user = await _remoteDataSource.getCurrentUser();
      return Success(user?.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<WalletPreview?> getWalletPreview(String userId) async {
    try {
      final wallet = await _remoteDataSource.getWalletPreview(userId);
      return Success(wallet?.toEntity());
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<bool> claimActiveWelcomeGift({
    required String deviceIdentifier,
  }) async {
    try {
      final result = await _remoteDataSource.claimActiveWelcomeGift(
        deviceIdentifier: deviceIdentifier,
      );
      final granted = result?['granted'] == true;
      return Success(granted);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  }) async {
    try {
      final result = await _remoteDataSource.checkDeviceAccess(
        deviceIdentifier: deviceIdentifier,
      );
      return Success(result);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    try {
      await _remoteDataSource.registerUserInstallation(
        deviceIdentifier: deviceIdentifier,
        platform: platform,
        deviceName: deviceName,
        appVersion: appVersion,
      );
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  }) async {
    try {
      final result = await _remoteDataSource.getMyAccessStatus(
        deviceIdentifier: deviceIdentifier,
      );
      return Success(result);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _remoteDataSource.recordUserActivity(
        eventType: eventType,
        deviceIdentifier: deviceIdentifier,
        metadata: metadata,
      );
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }

  @override
  ResultFuture<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
      return const Success(null);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }
}
