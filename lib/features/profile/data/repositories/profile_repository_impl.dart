import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({ProfileRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ProfileRemoteDataSourceImpl();

  @override
  ResultFuture<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    try {
      final url = await _remoteDataSource.uploadAvatar(
        userId: userId,
        imageBytes: imageBytes,
        fileExtension: fileExtension,
      );
      return Success(url);
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {
    try {
      await _remoteDataSource.removeAvatar(
        userId: userId,
        currentAvatarUrl: currentAvatarUrl,
      );
      return const Success(null);
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  bool get isAppleUser => _remoteDataSource.isAppleUser;

  @override
  ResultFuture<void> deleteAccount({
    required String confirmationEmail,
  }) async {
    try {
      await _remoteDataSource.deleteAccount(
        confirmationEmail: confirmationEmail,
      );
      return const Success(null);
    } on PostgrestException catch (e) {
      return Error(_mapDeleteAccountError(e));
    } catch (e) {
      return const Error(UnknownFailure());
    }
  }

  @override
  ResultFuture<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  }) async {
    try {
      await _remoteDataSource.deleteAppleAccount(
        confirmationEmail: confirmationEmail,
        authorizationCode: authorizationCode,
      );
      return const Success(null);
    } on FunctionException catch (e) {
      String? msg;
      if (e.details is Map) {
        msg = (e.details as Map)['error']?.toString() ??
            (e.details as Map)['message']?.toString();
      } else if (e.details is String && (e.details as String).isNotEmpty) {
        msg = e.details as String;
      }
      msg ??= e.reasonPhrase ?? e.toString();
      return Error(_mapAppleDeleteError(msg));
    } catch (e) {
      final str = e.toString();
      return Error(_mapAppleDeleteError(str));
    }
  }

  Failure _mapAppleDeleteError(String rawMessage) {
    final msg = rawMessage.toUpperCase();
    if (msg.contains('APPLE_AUTHORIZATION_CODE_REQUIRED')) {
      return const ValidationFailure(message: 'APPLE_AUTHORIZATION_CODE_REQUIRED');
    }
    if (msg.contains('APPLE_IDENTITY_NOT_LINKED')) {
      return const ValidationFailure(message: 'APPLE_IDENTITY_NOT_LINKED');
    }
    if (msg.contains('APPLE_IDENTITY_MISMATCH')) {
      return const ValidationFailure(message: 'APPLE_IDENTITY_MISMATCH');
    }
    if (msg.contains('APPLE_TOKEN_EXCHANGE_FAILED')) {
      return const ServerFailure(message: 'APPLE_TOKEN_EXCHANGE_FAILED');
    }
    if (msg.contains('APPLE_TOKEN_REVOKE_FAILED')) {
      return const ServerFailure(message: 'APPLE_TOKEN_REVOKE_FAILED');
    }
    if (msg.contains('APPLE_REVOKE_TOKEN_MISSING')) {
      return const ServerFailure(message: 'APPLE_REVOKE_TOKEN_MISSING');
    }
    if (msg.contains('EMAIL_CONFIRMATION_REQUIRED')) {
      return const ValidationFailure(message: 'EMAIL_CONFIRMATION_REQUIRED');
    }
    if (msg.contains('EMAIL_CONFIRMATION_MISMATCH')) {
      return const ValidationFailure(message: 'EMAIL_CONFIRMATION_MISMATCH');
    }
    return ServerFailure(message: rawMessage);
  }

  Failure _mapDeleteAccountError(PostgrestException e) {
    final msg = e.message.toUpperCase();
    if (msg.contains('EMAIL_CONFIRMATION_REQUIRED')) {
      return const ValidationFailure(message: 'EMAIL_CONFIRMATION_REQUIRED');
    }
    if (msg.contains('EMAIL_CONFIRMATION_MISMATCH')) {
      return const ValidationFailure(message: 'EMAIL_CONFIRMATION_MISMATCH');
    }
    if (msg.contains('PROTECTED_OPERATIONAL_ACCOUNT')) {
      return const PermissionFailure(message: 'PROTECTED_OPERATIONAL_ACCOUNT');
    }
    if (msg.contains('ACCOUNT_NOT_FOUND')) {
      return const ServerFailure(message: 'ACCOUNT_NOT_FOUND');
    }
    if (msg.contains('AUTH_USER_DELETE_FAILED')) {
      return const ServerFailure(message: 'AUTH_USER_DELETE_FAILED');
    }
    return ServerFailure(message: e.message);
  }
}

