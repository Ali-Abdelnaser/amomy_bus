import 'package:injectable/injectable.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/services/storage_service.dart';

abstract class OnboardingLocalDataSource {
  Future<bool> isOnboardingCompleted();
  Future<bool> setOnboardingCompleted();
  Future<bool> resetOnboarding();
}

@LazySingleton(as: OnboardingLocalDataSource)
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final StorageService _storageService;

  OnboardingLocalDataSourceImpl(this._storageService);

  @override
  Future<bool> isOnboardingCompleted() async {
    return _storageService.getBool(StorageKeys.onboardingCompleted) ?? false;
  }

  @override
  Future<bool> setOnboardingCompleted() async {
    return _storageService.setBool(StorageKeys.onboardingCompleted, true);
  }

  @override
  Future<bool> resetOnboarding() async {
    return _storageService.remove(StorageKeys.onboardingCompleted);
  }
}
