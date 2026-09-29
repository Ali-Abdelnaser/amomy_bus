import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_update_info.dart';
import '../repositories/app_update_repository.dart';

@injectable
class CheckAppUpdateUseCase {
  final AppUpdateRepository _repository;

  const CheckAppUpdateUseCase(this._repository);

  ResultFuture<AppUpdateInfo> call() async {
    return _repository.getAppUpdateStatus();
  }
}
