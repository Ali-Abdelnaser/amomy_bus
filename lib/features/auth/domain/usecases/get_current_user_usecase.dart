import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

@lazySingleton
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  ResultFuture<AppUser?> call() {
    return _repository.getCurrentUser();
  }

  Stream<AppUser?> get userStream => _repository.authUserStream;
}
