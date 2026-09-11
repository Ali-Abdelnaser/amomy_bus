// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../core/network/dio_client.dart' as _i571;
import '../../core/network/interceptors/auth_interceptor.dart' as _i267;
import '../../core/network/network_info.dart' as _i892;
import '../../core/services/connectivity_service.dart' as _i820;
import '../../core/services/secure_storage_service.dart' as _i814;
import '../../core/services/storage_service.dart' as _i54;
import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/complete_profile_usecase.dart'
    as _i1010;
import '../../features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i17;
import '../../features/auth/domain/usecases/get_wallet_preview_usecase.dart'
    as _i442;
import '../../features/auth/domain/usecases/resend_otp_usecase.dart' as _i613;
import '../../features/auth/domain/usecases/send_password_reset_usecase.dart'
    as _i71;
import '../../features/auth/domain/usecases/sign_in_with_email_usecase.dart'
    as _i744;
import '../../features/auth/domain/usecases/sign_in_with_google_usecase.dart'
    as _i673;
import '../../features/auth/domain/usecases/sign_out_usecase.dart' as _i915;
import '../../features/auth/domain/usecases/sign_up_with_email_usecase.dart'
    as _i254;
import '../../features/auth/domain/usecases/update_password_usecase.dart'
    as _i387;
import '../../features/auth/domain/usecases/verify_otp_usecase.dart' as _i503;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/onboarding/data/onboarding_local_data_source.dart'
    as _i657;
import '../../features/splash/data/datasources/splash_local_data_source.dart'
    as _i240;
import '../../features/splash/data/repositories/splash_repository_impl.dart'
    as _i554;
import '../../features/splash/domain/repositories/splash_repository.dart'
    as _i210;
import '../../features/splash/domain/usecases/check_app_status_usecase.dart'
    as _i69;
import '../../features/splash/presentation/bloc/splash_bloc.dart' as _i443;
import '../router/app_router.dart' as _i81;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i116.GoogleSignIn>(() => registerModule.googleSignIn);
    gh.lazySingleton<_i54.StorageService>(
      () => _i54.SharedPreferencesStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i107.AuthRemoteDataSource>(
      () => _i107.AuthRemoteDataSourceImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i814.SecureStorageService>(
      () => _i814.FlutterSecureStorageService(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i820.ConnectivityService>(
      () => _i820.ConnectivityServiceImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i107.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i657.OnboardingLocalDataSource>(
      () => _i657.OnboardingLocalDataSourceImpl(gh<_i54.StorageService>()),
    );
    gh.lazySingleton<_i240.SplashLocalDataSource>(
      () => _i240.SplashLocalDataSourceImpl(
        gh<_i54.StorageService>(),
        gh<_i814.SecureStorageService>(),
      ),
    );
    gh.factory<_i267.AuthInterceptor>(
      () => _i267.AuthInterceptor(gh<_i814.SecureStorageService>()),
    );
    gh.lazySingleton<_i1010.CompleteProfileUseCase>(
      () => _i1010.CompleteProfileUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i17.GetCurrentUserUseCase>(
      () => _i17.GetCurrentUserUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i442.GetWalletPreviewUseCase>(
      () => _i442.GetWalletPreviewUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i613.ResendOtpUseCase>(
      () => _i613.ResendOtpUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i71.SendPasswordResetUseCase>(
      () => _i71.SendPasswordResetUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i744.SignInWithEmailUseCase>(
      () => _i744.SignInWithEmailUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i673.SignInWithGoogleUseCase>(
      () => _i673.SignInWithGoogleUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i915.SignOutUseCase>(
      () => _i915.SignOutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i254.SignUpWithEmailUseCase>(
      () => _i254.SignUpWithEmailUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i387.UpdatePasswordUseCase>(
      () => _i387.UpdatePasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i503.VerifyOtpUseCase>(
      () => _i503.VerifyOtpUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i892.NetworkInfo>(
      () => _i892.NetworkInfoImpl(gh<_i820.ConnectivityService>()),
    );
    gh.lazySingleton<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        getCurrentUserUseCase: gh<_i17.GetCurrentUserUseCase>(),
        signInWithEmailUseCase: gh<_i744.SignInWithEmailUseCase>(),
        signUpWithEmailUseCase: gh<_i254.SignUpWithEmailUseCase>(),
        verifyOtpUseCase: gh<_i503.VerifyOtpUseCase>(),
        resendOtpUseCase: gh<_i613.ResendOtpUseCase>(),
        signInWithGoogleUseCase: gh<_i673.SignInWithGoogleUseCase>(),
        completeProfileUseCase: gh<_i1010.CompleteProfileUseCase>(),
        sendPasswordResetUseCase: gh<_i71.SendPasswordResetUseCase>(),
        updatePasswordUseCase: gh<_i387.UpdatePasswordUseCase>(),
        getWalletPreviewUseCase: gh<_i442.GetWalletPreviewUseCase>(),
        signOutUseCase: gh<_i915.SignOutUseCase>(),
      ),
    );
    gh.lazySingleton<_i571.DioClient>(
      () => _i571.DioClient(gh<_i267.AuthInterceptor>()),
    );
    gh.lazySingleton<_i210.SplashRepository>(
      () => _i554.SplashRepositoryImpl(gh<_i240.SplashLocalDataSource>()),
    );
    gh.factory<_i69.CheckAppStatusUseCase>(
      () => _i69.CheckAppStatusUseCase(gh<_i210.SplashRepository>()),
    );
    gh.lazySingleton<_i81.AppRouter>(
      () => _i81.AppRouter(gh<_i797.AuthBloc>()),
    );
    gh.factory<_i443.SplashBloc>(
      () => _i443.SplashBloc(gh<_i69.CheckAppStatusUseCase>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
