import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  ResultFuture<void> call() {
    return _repository.signOut();
  }
}
