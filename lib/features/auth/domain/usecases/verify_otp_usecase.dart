import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class VerifyOtpUseCase {
  final AuthRepository _repository;

  const VerifyOtpUseCase(this._repository);

  ResultFuture<AppUser> call({
    required String email,
    required String token,
  }) {
    return _repository.verifyEmailOtp(
      email: email,
      token: token,
    );
  }
}
