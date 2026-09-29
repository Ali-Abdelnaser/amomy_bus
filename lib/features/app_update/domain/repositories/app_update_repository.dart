import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_update_info.dart';

abstract class AppUpdateRepository {
  ResultFuture<AppUpdateInfo> getAppUpdateStatus();
}
