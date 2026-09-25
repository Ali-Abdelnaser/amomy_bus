import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class SignInWithAppleUseCase {
  final AuthRepository _repository;

  const SignInWithAppleUseCase(this._repository);

  ResultFuture<AppUser> call() {
    return _repository.signInWithApple();
  }
}
