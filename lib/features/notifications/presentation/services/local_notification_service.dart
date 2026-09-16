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
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Local notification service initialized: success (channel: $channelId)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Local notification service initialization error: $e',
        );
      }
    }
  }

  /// Displays a heads-up system notification when app is in foreground.
  Future<bool> showForegroundNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    _lastShowAttempt = DateTime.now();
    final normalizedId = _normalizeNotificationId(id);

    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint('[IOS_LOCAL_NOTIF_DIAG] plugin_initialized=$_isInitialized');
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] notification_id_valid=${_isValidNotificationId(id)}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] title_present=${title.trim().isNotEmpty}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] body_present=${body.trim().isNotEmpty}',
        );
      }

      if (!_isInitialized) {
        _lastShowResult = 'error: not_initialized';
        if (kDebugMode) {
          debugPrint('[NOTIF_PRESENT_DIAG] local_show_error=StateError');
        }
        return false;
      }

      if (kDebugMode) {
        debugPrint('[NOTIF_PRESENT_DIAG] local_show_start');
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

      if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] darwin_present_alert=${iosDetails.presentAlert}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] darwin_present_banner=${iosDetails.presentBanner}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] darwin_present_list=${iosDetails.presentList}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] darwin_present_sound=${iosDetails.presentSound}',
        );
        debugPrint(
          '[IOS_LOCAL_NOTIF_DIAG] darwin_present_badge=${iosDetails.presentBadge}',
        );
      }

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

      _lastShowResult = 'success';
      if (kDebugMode) {
        debugPrint('[NOTIF_PRESENT_DIAG] local_show_success');
      }
      return true;
    } catch (e, st) {
      _lastShowResult = 'error: $e';
      if (kDebugMode) {
        debugPrint('[NOTIF_PRESENT_DIAG] local_show_error=${e.runtimeType}');
        debugPrint(
          '[AMOMY_NOTIF] Local notification show result: ERROR - $e\n$st',
        );
      }
      return false;
    }
  }

  /// Direct debug test for local notifications (isolated from Firebase/Supabase).
  Future<bool> showTestLocalNotification() async {
    return showForegroundNotification(
      id: 999001,
      title: 'AMOMY Bus',
      body: 'Local notification presentation test',
      payload: {'test': 'local_diagnostic', 'screen': 'notifications'},
    );
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Error parsing tap payload: $e');
      }
      NotificationRouter.navigateToDestination(null);
    }
  }
}
