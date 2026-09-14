import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/cubit/notification_cubit.dart';
import '../../features/notifications/presentation/services/local_notification_service.dart';
import '../../features/notifications/presentation/services/notification_service.dart';
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
}
