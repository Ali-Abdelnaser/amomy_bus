import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/entities/self_test_result.dart';
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
  Stream<AppNotification?> subscribeToNotificationUpdates() {
    return remoteDataSource.subscribeToNotificationUpdates();
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
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds}) {
    return remoteDataSource.sendSelfTestNotification(
      delaySeconds: delaySeconds,
    );
  }

  @override
  Future<bool> isNotificationTester() {
    return remoteDataSource.isNotificationTester();
  }

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) {
    return remoteDataSource.sendTestEvent(
      eventType: eventType,
      forceDelivery: forceDelivery,
      customData: customData,
      delaySeconds: delaySeconds,
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() {
    return remoteDataSource.getPreferences();
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) {
    return remoteDataSource.updatePreferences(preferences);
  }
}
