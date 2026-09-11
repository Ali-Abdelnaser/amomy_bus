import '../../../../core/typedefs/typedefs.dart';
import '../entities/app_init_status.dart';

abstract class SplashRepository {
  ResultFuture<AppInitStatus> checkAppStatus();
}
