import 'package:injectable/injectable.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/storage_service.dart';

abstract class SplashLocalDataSource {
  Future<bool> isAuthenticated();
  Future<bool> isOnboardingCompleted();
}

@LazySingleton(as: SplashLocalDataSource)
class SplashLocalDataSourceImpl implements SplashLocalDataSource {
  final StorageService _storageService;
  final SecureStorageService _secureStorageService;

  SplashLocalDataSourceImpl(
    this._storageService,
    this._secureStorageService,
  );

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorageService.read(StorageKeys.authToken);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return _storageService.getBool(StorageKeys.onboardingCompleted) ?? false;
  }
}
