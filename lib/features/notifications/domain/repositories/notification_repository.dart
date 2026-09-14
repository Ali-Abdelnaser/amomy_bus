import '../entities/app_notification.dart';

abstract class NotificationRepository {
  /// Fetches paginated in-app notifications for the authenticated passenger.
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  /// Returns count of unread notifications.
  Future<int> getUnreadCount();

  /// Marks a specific notification as read.
  Future<bool> markAsRead(String notificationId);

  /// Marks all unread notifications as read.
  Future<int> markAllAsRead();

  /// Registers/upserts an FCM device token in the backend.
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? installationId,
    String? deviceName,
    String? appVersion,
  });

  /// Deactivates an FCM device token on logout.
  Future<bool> deactivateDeviceToken(String token);

  /// Dispatches a safe developer self-test push notification to the current user.
  Future<bool> sendSelfTestNotification();
}
