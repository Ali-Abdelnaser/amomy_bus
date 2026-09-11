import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SendPasswordResetUseCase {
  final AuthRepository _repository;

  const SendPasswordResetUseCase(this._repository);

  ResultFuture<void> call({
    required String email,
  }) {
    return _repository.sendPasswordResetEmail(
      email: email,
    );
  }
}
