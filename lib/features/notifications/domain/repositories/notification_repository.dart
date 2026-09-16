import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';
import '../entities/notification_test_event_result.dart';
import '../entities/self_test_result.dart';

abstract class NotificationRepository {
  /// Fetches paginated in-app notifications for the authenticated passenger.
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  });

  /// Returns count of unread notifications.
  Future<int> getUnreadCount();

  /// Emits whenever the authenticated user's notification rows change.
  ///
  /// Insert events include the inserted notification row so foreground
  /// presentation can be deduplicated against FCM. Update/delete events emit
  /// null and are used only to refresh the inbox and badge.
  Stream<AppNotification?> subscribeToNotificationUpdates();

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
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds});

  /// Checks whether the authenticated user is an authorized QA/test account with Notification Lab access.
  Future<bool> isNotificationTester();

  /// Dispatches a functional test event from the catalog to the tester's account.
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  });

  /// Fetches the authenticated passenger's notification push preferences.
  Future<NotificationPreferences> getPreferences();

  /// Updates and persists the authenticated passenger's notification push preferences.
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  );
}
