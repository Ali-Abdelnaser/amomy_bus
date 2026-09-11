import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  const SignUpWithEmailUseCase(this._repository);

  ResultFuture<AppUser> call({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
  }
}
