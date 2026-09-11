import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class CompleteProfileUseCase {
  final AuthRepository _repository;

  const CompleteProfileUseCase(this._repository);

  ResultFuture<AppUser> call({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) {
    return _repository.completeProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
    );
  }
}
