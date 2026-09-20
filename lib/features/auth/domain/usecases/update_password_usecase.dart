import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class UpdatePasswordUseCase {
  final AuthRepository _repository;

  const UpdatePasswordUseCase(this._repository);

  ResultFuture<void> call({required String newPassword}) {
    return _repository.updatePassword(newPassword: newPassword);
  }
}
