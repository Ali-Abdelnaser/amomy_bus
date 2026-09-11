import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_init_status.dart';
import '../repositories/splash_repository.dart';

@injectable
class CheckAppStatusUseCase {
  final SplashRepository _repository;

  CheckAppStatusUseCase(this._repository);

  ResultFuture<AppInitStatus> call() async {
    return _repository.checkAppStatus();
  }
}
