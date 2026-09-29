import 'package:injectable/injectable.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_datasource.dart';

@LazySingleton(as: AppUpdateRepository)
class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource _remoteDataSource;

  AppUpdateRepositoryImpl(this._remoteDataSource);

  @override
  ResultFuture<AppUpdateInfo> getAppUpdateStatus() async {
    try {
      final model = await _remoteDataSource.getAppUpdateStatus();
      return Success(model);
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }
}
