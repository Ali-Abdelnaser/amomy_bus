import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_router.dart';

/// Service managing local foreground system notifications and tap routing.
class LocalNotificationService {
  static const String channelId = 'amomy_high_importance';
  static const String channelName = 'AMOMY Notifications';
  static const String channelDescription =
      'Booking, wallet, trip, and service updates';
  static const int _maxNotificationId = 0x7FFFFFFF;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;

  /// Initializes the local notifications plugin and creates the Android high importance channel.
  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse:
            onNotificationTap ??
            (response) {
              _handleNotificationTap(response.payload);
            },
      );

      // Create high-importance Android Notification Channel
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        if (androidImplementation != null) {
          const channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );
          await androidImplementation.createNotificationChannel(channel);
        }
      }

      _isInitialized = true;
    } catch (_) {}
  }

  /// Displays a heads-up system notification when app is in foreground.
  Future<bool> showForegroundNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final normalizedId = _normalizeNotificationId(id);

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (!_isInitialized) {
        return false;
      }

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payloadString = payload != null ? jsonEncode(payload) : null;

      await _plugin.show(
        normalizedId,
        title,
        body,
        notificationDetails,
        payload: payloadString,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isValidNotificationId(int id) => id >= 0 && id <= _maxNotificationId;

  int _normalizeNotificationId(int id) {
    if (_isValidNotificationId(id)) return id;
    return id.hashCode & _maxNotificationId;
  }

  void _handleNotificationTap(String? payloadString) {
    if (payloadString == null || payloadString.isEmpty) {
      NotificationRouter.navigateToDestination(null);
      return;
    }

    try {
      final decoded = jsonDecode(payloadString);
      if (decoded is Map<String, dynamic>) {
        NotificationRouter.navigateToDestination(decoded);
      } else {
        NotificationRouter.navigateToDestination(null);
      }
    } catch (_) {
      NotificationRouter.navigateToDestination(null);
    }
  }
}
