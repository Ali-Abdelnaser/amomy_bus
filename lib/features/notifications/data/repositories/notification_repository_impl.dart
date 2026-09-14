import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) {
    return remoteDataSource.getNotifications(limit: limit, offset: offset);
  }

  @override
  Future<int> getUnreadCount() {
    return remoteDataSource.getUnreadCount();
  }

  @override
  Future<bool> markAsRead(String notificationId) {
    return remoteDataSource.markAsRead(notificationId);
  }

  @override
  Future<int> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }

  @override
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? installationId,
    String? deviceName,
    String? appVersion,
  }) {
    return remoteDataSource.registerDeviceToken(
      token: token,
      platform: platform,
      installationId: installationId,
      deviceName: deviceName,
      appVersion: appVersion,
    );
  }

  @override
  Future<bool> deactivateDeviceToken(String token) {
    return remoteDataSource.deactivateDeviceToken(token);
  }

  @override
  Future<bool> sendSelfTestNotification() {
    return remoteDataSource.sendSelfTestNotification();
  }
}
