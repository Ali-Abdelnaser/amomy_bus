import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class ResendOtpUseCase {
  final AuthRepository _repository;

  const ResendOtpUseCase(this._repository);

  ResultFuture<void> call({
    required String email,
  }) {
    return _repository.resendVerificationOtp(
      email: email,
    );
  }
}
