import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_router.dart';

/// Service managing local Android system notifications for foreground push presentation.
class LocalNotificationService {
  static const String channelId = 'amomy_high_importance';
  static const String channelName = 'AMOMY Notifications';
  static const String channelDescription =
      'Booking, wallet, trip, and service updates';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;
  DateTime? _lastShowAttempt;
  String? _lastShowResult;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;
  DateTime? get lastShowAttempt => _lastShowAttempt;
  String? get lastShowResult => _lastShowResult;

  /// Initializes the local notifications plugin and creates the Android high importance channel.
  Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    if (_isInitialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');
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
        onDidReceiveNotificationResponse: onNotificationTap ??
            (response) {
              _handleNotificationTap(response.payload);
            },
      );

      // Create high-importance Android Notification Channel
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImplementation = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

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
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Local notification service initialized: success (channel: $channelId)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Local notification service initialization error: $e');
      }
    }
  }

  /// Displays a heads-up system notification on Android when app is in foreground.
  Future<bool> showForegroundNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    _lastShowAttempt = DateTime.now();

    // Only display local notifications on Android (iOS uses native presentation options)
    if (defaultTargetPlatform != TargetPlatform.android && !kIsWeb) {
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Skipping local notification show on non-Android platform: $defaultTargetPlatform');
      }
      _lastShowResult = 'skipped_non_android';
      return true;
    }

    try {
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Local notification show called: id=$id, channelId=$channelId, title="$title"');
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

      const notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final payloadString = payload != null ? jsonEncode(payload) : null;

      await _plugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payloadString,
      );

      _lastShowResult = 'success';
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Local notification show result: success for #$id');
      }
      return true;
    } catch (e, st) {
      _lastShowResult = 'error: $e';
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Local notification show result: ERROR - $e\n$st');
      }
      return false;
    }
  }

  /// Direct debug test for local notifications (isolated from Firebase/Supabase).
  Future<bool> showTestLocalNotification() async {
    return showForegroundNotification(
      id: 999001,
      title: 'AMOMY Local Test',
      body: 'Local notifications are working.',
      payload: {'test': 'local_diagnostic', 'screen': 'notifications'},
    );
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Error parsing tap payload: $e');
      }
      NotificationRouter.navigateToDestination(null);
    }
  }
}
