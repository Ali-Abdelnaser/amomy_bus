import 'package:injectable/injectable.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/app_init_status.dart';
import '../../domain/repositories/splash_repository.dart';
import '../datasources/splash_local_data_source.dart';

@LazySingleton(as: SplashRepository)
class SplashRepositoryImpl implements SplashRepository {
  final SplashLocalDataSource _localDataSource;

  SplashRepositoryImpl(this._localDataSource);

  @override
  ResultFuture<AppInitStatus> checkAppStatus() async {
    try {
      // Minimum duration for splash visual branding
      await Future.delayed(AppConstants.splashDuration);

      final isAuth = await _localDataSource.isAuthenticated();
      final isOnboarding = await _localDataSource.isOnboardingCompleted();

      return Success(
        AppInitStatus(
          isAuthenticated: isAuth,
          isOnboardingCompleted: isOnboarding,
        ),
      );
    } catch (e) {
      return Error(ErrorHandler.handle(e));
    }
  }
}
