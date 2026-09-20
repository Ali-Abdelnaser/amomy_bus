import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/domain/usecases/booking_usecases.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/notifications/presentation/services/local_notification_service.dart';
import '../../features/notifications/presentation/services/notification_service.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/tracking/data/datasources/tracking_remote_datasource.dart';
import '../../features/tracking/data/repositories/tracking_repository_impl.dart';
import '../../features/tracking/domain/repositories/tracking_repository.dart';
import '../../features/tracking/presentation/cubit/tracking_cubit.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  await getIt.init();

  // Register notification dependencies
  if (!getIt.isRegistered<NotificationRemoteDataSource>()) {
    getIt.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<NotificationRepository>()) {
    getIt.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(
        remoteDataSource: getIt<NotificationRemoteDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<LocalNotificationService>()) {
    getIt.registerLazySingleton<LocalNotificationService>(
      () => LocalNotificationService(),
    );
  }
  if (!getIt.isRegistered<NotificationService>()) {
    getIt.registerLazySingleton<NotificationService>(
      () => NotificationService(
        repository: getIt<NotificationRepository>(),
        localNotifications: getIt<LocalNotificationService>(),
      ),
    );
  }
  if (!getIt.isRegistered<NotificationCubit>()) {
    getIt.registerFactory<NotificationCubit>(
      () => NotificationCubit(
        repository: getIt<NotificationRepository>(),
        notificationService: getIt.isRegistered<NotificationService>()
            ? getIt<NotificationService>()
            : null,
      ),
    );
  }

  // Register tracking dependencies
  if (!getIt.isRegistered<TrackingRemoteDataSource>()) {
    getIt.registerLazySingleton<TrackingRemoteDataSource>(
      () => TrackingRemoteDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<TrackingRepository>()) {
    getIt.registerLazySingleton<TrackingRepository>(
      () => TrackingRepositoryImpl(
        remoteDataSource: getIt<TrackingRemoteDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<TrackingCubit>()) {
    getIt.registerFactory<TrackingCubit>(
      () => TrackingCubit(repository: getIt<TrackingRepository>()),
    );
  }

  // Register profile dependencies
  if (!getIt.isRegistered<ProfileRemoteDataSource>()) {
    getIt.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(),
    );
  }
  if (!getIt.isRegistered<ProfileRepository>()) {
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        remoteDataSource: getIt<ProfileRemoteDataSource>(),
      ),
    );
  }
  if (!getIt.isRegistered<ProfileBloc>()) {
    getIt.registerFactory<ProfileBloc>(
      () => ProfileBloc(repository: getIt<ProfileRepository>()),
    );
  }

  // Register Round Trip booking dependencies
  if (getIt.isRegistered<BookingRepository>()) {
    final bookingRepo = getIt<BookingRepository>();
    if (!getIt.isRegistered<CreateRoundTripBundleHoldUseCase>()) {
      getIt.registerLazySingleton<CreateRoundTripBundleHoldUseCase>(
        () => CreateRoundTripBundleHoldUseCase(bookingRepo),
      );
    }
    if (!getIt.isRegistered<SetRoundTripReturnSeatUseCase>()) {
      getIt.registerLazySingleton<SetRoundTripReturnSeatUseCase>(
        () => SetRoundTripReturnSeatUseCase(bookingRepo),
      );
    }
    if (!getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()) {
      getIt.registerLazySingleton<ReleaseRoundTripBundleHoldUseCase>(
        () => ReleaseRoundTripBundleHoldUseCase(bookingRepo),
      );
    }
    if (!getIt.isRegistered<ConfirmRoundTripBundleUseCase>()) {
      getIt.registerLazySingleton<ConfirmRoundTripBundleUseCase>(
        () => ConfirmRoundTripBundleUseCase(bookingRepo),
      );
    }
    if (!getIt.isRegistered<GetRoundTripReturnOptionsUseCase>()) {
      getIt.registerLazySingleton<GetRoundTripReturnOptionsUseCase>(
        () => GetRoundTripReturnOptionsUseCase(bookingRepo),
      );
    }
  }
}
