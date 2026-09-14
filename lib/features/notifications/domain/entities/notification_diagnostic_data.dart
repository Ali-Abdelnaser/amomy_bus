class NotificationDiagnosticData {
  final bool firebaseInitialized;
  final String notificationPermission;
  final String androidPostNotifications;
  final bool fcmTokenAvailable;
  final int fcmTokenLength;
  final String fcmTokenSuffix;
  final String tokenRegisteredInSupabase;
  final String activeTokenRow;
  final bool localNotificationServiceInitialized;
  final String androidNotificationChannel;
  final String channelId;
  final bool foregroundListenerAttached;
  final bool backgroundHandlerRegistered;
  final String lastForegroundFcmMessage;
  final String lastLocalNotificationShowAttempt;
  final String lastLocalNotificationResult;
  final String lastSelfTestRequest;
  final String lastSelfTestBackendResult;
  final String lastFcmProviderResult;
  final String lastInboxRefresh;
  final String unreadCount;
  final String currentLifecycle;

  const NotificationDiagnosticData({
    required this.firebaseInitialized,
    required this.notificationPermission,
    required this.androidPostNotifications,
    required this.fcmTokenAvailable,
    required this.fcmTokenLength,
    required this.fcmTokenSuffix,
    required this.tokenRegisteredInSupabase,
    required this.activeTokenRow,
    required this.localNotificationServiceInitialized,
    required this.androidNotificationChannel,
    required this.channelId,
    required this.foregroundListenerAttached,
    required this.backgroundHandlerRegistered,
    required this.lastForegroundFcmMessage,
    required this.lastLocalNotificationShowAttempt,
    required this.lastLocalNotificationResult,
    required this.lastSelfTestRequest,
    required this.lastSelfTestBackendResult,
    required this.lastFcmProviderResult,
    required this.lastInboxRefresh,
    required this.unreadCount,
    required this.currentLifecycle,
  });
}
