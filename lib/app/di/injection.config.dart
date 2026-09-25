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

import '../../core/network/dio_client.dart' as _i572;
import '../../core/network/interceptors/auth_interceptor.dart' as _i267;
import '../../core/network/network_info.dart' as _i892;
import '../../core/services/connectivity_service.dart' as _i820;
import '../../core/services/device_identity_service.dart' as _i925;
import '../../core/services/secure_storage_service.dart' as _i814;
import '../../core/services/storage_service.dart' as _i54;
import '../../features/auth/data/datasources/auth_remote_data_source.dart'
    as _i107;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/claim_welcome_gift_usecase.dart'
    as _i178;
import '../../features/auth/domain/usecases/complete_profile_usecase.dart'
    as _i1010;
import '../../features/auth/domain/usecases/get_current_user_usecase.dart'
    as _i17;
import '../../features/auth/domain/usecases/get_wallet_preview_usecase.dart'
    as _i442;
import '../../features/auth/domain/usecases/resend_otp_usecase.dart' as _i613;
import '../../features/auth/domain/usecases/send_password_reset_usecase.dart'
    as _i71;
import '../../features/auth/domain/usecases/sign_in_with_apple_usecase.dart'
    as _i379;
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
import '../../features/booking/data/datasources/booking_remote_data_source.dart'
    as _i774;
import '../../features/booking/data/repositories/booking_repository_impl.dart'
    as _i265;
import '../../features/booking/domain/repositories/booking_repository.dart'
    as _i912;
import '../../features/booking/domain/usecases/booking_usecases.dart' as _i1015;
import '../../features/booking/presentation/cubit/booking_cubit.dart' as _i329;
import '../../features/home/data/datasources/home_remote_data_source.dart'
    as _i362;
import '../../features/home/data/repositories/home_repository_impl.dart'
    as _i76;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/presentation/cubit/home_cubit.dart' as _i9;
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
import '../../features/topup/data/datasources/topup_remote_data_source.dart'
    as _i130;
import '../../features/topup/data/repositories/topup_repository_impl.dart'
    as _i775;
import '../../features/topup/domain/repositories/topup_repository.dart'
    as _i806;
import '../../features/topup/domain/usecases/create_topup_request_usecase.dart'
    as _i688;
import '../../features/topup/domain/usecases/get_active_payment_methods_usecase.dart'
    as _i170;
import '../../features/topup/domain/usecases/get_my_topup_requests_usecase.dart'
    as _i317;
import '../../features/topup/domain/usecases/get_payment_config_usecase.dart'
    as _i567;
import '../../features/topup/domain/usecases/submit_new_topup_request_usecase.dart'
    as _i920;
import '../../features/topup/domain/usecases/submit_topup_proof_usecase.dart'
    as _i27;
import '../../features/topup/domain/usecases/upload_topup_proof_usecase.dart'
    as _i542;
import '../../features/topup/presentation/cubit/topup_cubit.dart' as _i809;
import '../../features/topup/presentation/cubit/topup_history_cubit.dart'
    as _i1020;
import '../../features/trips/presentation/cubit/passenger_trips_cubit.dart'
    as _i568;
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart'
    as _i224;
import '../../features/wallet/data/repositories/wallet_repository_impl.dart'
    as _i690;
import '../../features/wallet/domain/repositories/wallet_repository.dart'
    as _i571;
import '../../features/wallet/domain/usecases/get_wallet_history_usecase.dart'
    as _i821;
import '../../features/wallet/domain/usecases/get_wallet_summary_usecase.dart'
    as _i280;
import '../../features/wallet/domain/usecases/get_wallet_transactions_usecase.dart'
    as _i831;
import '../../features/wallet/presentation/cubit/wallet_cubit.dart' as _i101;
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
    gh.lazySingleton<_i774.BookingRemoteDataSource>(
      () => _i774.BookingRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i54.StorageService>(
      () => _i54.SharedPreferencesStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i568.PassengerTripsCubit>(
      () => _i568.PassengerTripsCubit(
        gh<_i1015.GetPassengerBookingsUseCase>(),
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.lazySingleton<_i362.HomeRemoteDataSource>(
      () => _i362.HomeRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i224.WalletRemoteDataSource>(
      () => _i224.WalletRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
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
    gh.lazySingleton<_i571.WalletRepository>(
      () => _i690.WalletRepositoryImpl(gh<_i224.WalletRemoteDataSource>()),
    );
    gh.lazySingleton<_i130.TopUpRemoteDataSource>(
      () => _i130.TopUpRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i821.GetWalletHistoryUseCase>(
      () => _i821.GetWalletHistoryUseCase(gh<_i571.WalletRepository>()),
    );
    gh.lazySingleton<_i280.GetWalletSummaryUseCase>(
      () => _i280.GetWalletSummaryUseCase(gh<_i571.WalletRepository>()),
    );
    gh.lazySingleton<_i831.GetWalletTransactionsUseCase>(
      () => _i831.GetWalletTransactionsUseCase(gh<_i571.WalletRepository>()),
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
    gh.lazySingleton<_i806.TopUpRepository>(
      () => _i775.TopUpRepositoryImpl(gh<_i130.TopUpRemoteDataSource>()),
    );
    gh.lazySingleton<_i0.HomeRepository>(
      () => _i76.HomeRepositoryImpl(gh<_i362.HomeRemoteDataSource>()),
    );
    gh.factory<_i9.HomeCubit>(
      () => _i9.HomeCubit(
        gh<_i0.HomeRepository>(),
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.factory<_i101.WalletCubit>(
      () => _i101.WalletCubit(
        gh<_i280.GetWalletSummaryUseCase>(),
        gh<_i831.GetWalletTransactionsUseCase>(),
        gh<_i571.WalletRepository>(),
        gh<_i317.GetMyTopUpRequestsUseCase>(),
        gh<_i821.GetWalletHistoryUseCase>(),
      ),
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
    gh.lazySingleton<_i925.DeviceIdentityService>(
      () => _i925.DeviceIdentityServiceImpl(gh<_i814.SecureStorageService>()),
    );
    gh.lazySingleton<_i688.CreateTopUpRequestUseCase>(
      () => _i688.CreateTopUpRequestUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i170.GetActivePaymentMethodsUseCase>(
      () => _i170.GetActivePaymentMethodsUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i317.GetMyTopUpRequestsUseCase>(
      () => _i317.GetMyTopUpRequestsUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i567.GetPaymentConfigUseCase>(
      () => _i567.GetPaymentConfigUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i920.SubmitNewTopUpRequestUseCase>(
      () => _i920.SubmitNewTopUpRequestUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i27.SubmitTopUpProofUseCase>(
      () => _i27.SubmitTopUpProofUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i542.UploadTopUpProofUseCase>(
      () => _i542.UploadTopUpProofUseCase(gh<_i806.TopUpRepository>()),
    );
    gh.lazySingleton<_i178.ClaimWelcomeGiftUseCase>(
      () => _i178.ClaimWelcomeGiftUseCase(gh<_i787.AuthRepository>()),
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
    gh.lazySingleton<_i379.SignInWithAppleUseCase>(
      () => _i379.SignInWithAppleUseCase(gh<_i787.AuthRepository>()),
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
    gh.lazySingleton<_i572.DioClient>(
      () => _i572.DioClient(gh<_i267.AuthInterceptor>()),
    );
    gh.lazySingleton<_i210.SplashRepository>(
      () => _i554.SplashRepositoryImpl(gh<_i240.SplashLocalDataSource>()),
    );
    gh.lazySingleton<_i912.BookingRepository>(
      () => _i265.BookingRepositoryImpl(
        gh<_i774.BookingRemoteDataSource>(),
        gh<_i892.NetworkInfo>(),
      ),
    );
    gh.factory<_i809.TopUpCubit>(
      () => _i809.TopUpCubit(
        gh<_i567.GetPaymentConfigUseCase>(),
        gh<_i170.GetActivePaymentMethodsUseCase>(),
        gh<_i688.CreateTopUpRequestUseCase>(),
        gh<_i27.SubmitTopUpProofUseCase>(),
        submitNewUseCase: gh<_i920.SubmitNewTopUpRequestUseCase>(),
      ),
    );
    gh.factory<_i1020.TopUpHistoryCubit>(
      () => _i1020.TopUpHistoryCubit(gh<_i317.GetMyTopUpRequestsUseCase>()),
    );
    gh.lazySingleton<_i797.AuthBloc>(
      () => _i797.AuthBloc(
        getCurrentUserUseCase: gh<_i17.GetCurrentUserUseCase>(),
        signInWithEmailUseCase: gh<_i744.SignInWithEmailUseCase>(),
        signUpWithEmailUseCase: gh<_i254.SignUpWithEmailUseCase>(),
        verifyOtpUseCase: gh<_i503.VerifyOtpUseCase>(),
        resendOtpUseCase: gh<_i613.ResendOtpUseCase>(),
        signInWithGoogleUseCase: gh<_i673.SignInWithGoogleUseCase>(),
        signInWithAppleUseCase: gh<_i379.SignInWithAppleUseCase>(),
        completeProfileUseCase: gh<_i1010.CompleteProfileUseCase>(),
        sendPasswordResetUseCase: gh<_i71.SendPasswordResetUseCase>(),
        updatePasswordUseCase: gh<_i387.UpdatePasswordUseCase>(),
        getWalletPreviewUseCase: gh<_i442.GetWalletPreviewUseCase>(),
        claimWelcomeGiftUseCase: gh<_i178.ClaimWelcomeGiftUseCase>(),
        deviceIdentityService: gh<_i925.DeviceIdentityService>(),
        authRepository: gh<_i787.AuthRepository>(),
        signOutUseCase: gh<_i915.SignOutUseCase>(),
      ),
    );
    gh.factory<_i69.CheckAppStatusUseCase>(
      () => _i69.CheckAppStatusUseCase(gh<_i210.SplashRepository>()),
    );
    gh.lazySingleton<_i1015.GetRouteStopsUseCase>(
      () => _i1015.GetRouteStopsUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetAvailableTripsUseCase>(
      () => _i1015.GetAvailableTripsUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetTripSeatMapUseCase>(
      () => _i1015.GetTripSeatMapUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.CreateBookingHoldUseCase>(
      () => _i1015.CreateBookingHoldUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.ReleaseBookingHoldUseCase>(
      () => _i1015.ReleaseBookingHoldUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.ConfirmBookingUseCase>(
      () => _i1015.ConfirmBookingUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetPassengerBookingsUseCase>(
      () => _i1015.GetPassengerBookingsUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetPassengerTodayTripsUseCase>(
      () => _i1015.GetPassengerTodayTripsUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetMyTripPreferencesUseCase>(
      () => _i1015.GetMyTripPreferencesUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.SetMyTripPreferencesUseCase>(
      () => _i1015.SetMyTripPreferencesUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.CancelBookingUseCase>(
      () => _i1015.CancelBookingUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.ChangeBookingSeatUseCase>(
      () => _i1015.ChangeBookingSeatUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetRoundTripReturnOptionsUseCase>(
      () => _i1015.GetRoundTripReturnOptionsUseCase(
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.lazySingleton<_i1015.CreateRoundTripBundleHoldUseCase>(
      () => _i1015.CreateRoundTripBundleHoldUseCase(
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.lazySingleton<_i1015.SetRoundTripReturnSeatUseCase>(
      () => _i1015.SetRoundTripReturnSeatUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.ReleaseRoundTripBundleHoldUseCase>(
      () => _i1015.ReleaseRoundTripBundleHoldUseCase(
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.lazySingleton<_i1015.ConfirmRoundTripBundleUseCase>(
      () => _i1015.ConfirmRoundTripBundleUseCase(gh<_i912.BookingRepository>()),
    );
    gh.lazySingleton<_i1015.GetRoundTripBundleContextUseCase>(
      () => _i1015.GetRoundTripBundleContextUseCase(
        gh<_i912.BookingRepository>(),
      ),
    );
    gh.lazySingleton<_i81.AppRouter>(
      () => _i81.AppRouter(gh<_i797.AuthBloc>()),
    );
    gh.factory<_i443.SplashBloc>(
      () => _i443.SplashBloc(gh<_i69.CheckAppStatusUseCase>()),
    );
    gh.factory<_i329.BookingCubit>(
      () => _i329.BookingCubit(
        getRouteStopsUseCase: gh<_i1015.GetRouteStopsUseCase>(),
        getAvailableTripsUseCase: gh<_i1015.GetAvailableTripsUseCase>(),
        getTripSeatMapUseCase: gh<_i1015.GetTripSeatMapUseCase>(),
        createBookingHoldUseCase: gh<_i1015.CreateBookingHoldUseCase>(),
        releaseBookingHoldUseCase: gh<_i1015.ReleaseBookingHoldUseCase>(),
        confirmBookingUseCase: gh<_i1015.ConfirmBookingUseCase>(),
        getMyTripPreferencesUseCase: gh<_i1015.GetMyTripPreferencesUseCase>(),
        getPassengerBookingsUseCase: gh<_i1015.GetPassengerBookingsUseCase>(),
        getRoundTripReturnOptionsUseCase:
            gh<_i1015.GetRoundTripReturnOptionsUseCase>(),
        createRoundTripBundleHoldUseCase:
            gh<_i1015.CreateRoundTripBundleHoldUseCase>(),
        setRoundTripReturnSeatUseCase:
            gh<_i1015.SetRoundTripReturnSeatUseCase>(),
        releaseRoundTripBundleHoldUseCase:
            gh<_i1015.ReleaseRoundTripBundleHoldUseCase>(),
        confirmRoundTripBundleUseCase:
            gh<_i1015.ConfirmRoundTripBundleUseCase>(),
        bookingRepository: gh<_i912.BookingRepository>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
