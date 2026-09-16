import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_diagnostic_data.dart';
import '../../domain/entities/self_test_result.dart';
import '../../domain/repositories/notification_repository.dart';
import '../widgets/notification_permission_sheet.dart';
import 'local_notification_service.dart';
import 'notification_payload_parser.dart';
import 'notification_router.dart';

/// Top-level background message handler required by Firebase Messaging.
/// Background & terminated pushes are displayed natively by the OS/FCM system tray.
/// Does NOT spawn duplicate local notifications.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or mock test environment
  }
}

class NotificationService with WidgetsBindingObserver {
  /// TEMPORARY DIAGNOSTIC SWITCH FOR IOS CRASH INVESTIGATION
  /// Set to true to isolate iOS push startup completely (skips permission prompt, APNs check, getToken, backend sync).
  /// If Home stays alive with this true, push startup area is definitively confirmed.
  /// Set to false to run normal startup with focused [IOS_PUSH_DIAG] logging.
  static const bool debugDisableIosPushStartup =
      false; // Set to false for normal startup

  final NotificationRepository repository;
  final FirebaseMessaging _messaging;
  final LocalNotificationService _localNotifications;
  final SharedPreferences? _prefs;

  static const String promptShownKey = 'amomy_notification_prompt_shown';

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  // Deduplication cache to prevent duplicate visual presentations across
  // FCM and notifications-table realtime for the same logical event.
  final Set<String> _processedMessageKeys = <String>{};
  final List<String> _processedMessageKeyOrder = <String>[];
  static const int _maxDedupeCacheSize = 200;

  String? _lastKnownToken;
  bool _initialized = false;
  bool _firebaseInitialized = false;

  // Diagnostics tracking
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;
  DateTime? _lastForegroundFcmTime;
  DateTime? _lastSelfTestTime;
  String? _lastSelfTestBackendResult;
  String? _lastFcmProviderResult;
  DateTime? _lastInboxRefreshTime;
  String _lastRegistrationStatus = 'unknown';
  int? _lastUnreadCount;

  NotificationService({
    required this.repository,
    FirebaseMessaging? messaging,
    LocalNotificationService? localNotifications,
    SharedPreferences? preferences,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications = localNotifications ?? LocalNotificationService(),
       _prefs = preferences {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentLifecycleState = state;
  }

  /// Stream of foreground FCM messages received for active in-app listeners / inbox refresh.
  Stream<RemoteMessage> get onForegroundNotification =>
      _foregroundMessageController.stream;

  LocalNotificationService get localNotifications => _localNotifications;

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'none';
    final len = token.length;
    final suffix = len > 6 ? token.substring(len - 6) : token;
    return 'len:$len (...$suffix)';
  }

  /// Initializes listeners for tokens, foreground notifications, and background taps.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Verify Firebase App Initialization
      try {
        _firebaseInitialized = Firebase.apps.isNotEmpty;
      } catch (_) {
        _firebaseInitialized = false;
      }
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Firebase initialized: $_firebaseInitialized');
      }

      // 2. Initialize local notification service & Android channel
      await _localNotifications.initialize();

      // 3. Foreground FCM display is routed through this service's local
      // notification path so it can be deduplicated against realtime rows.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      await _logIosLocalNotificationSettings();

      // 4. Check for initial cold-start notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint(
            '[AMOMY_NOTIF] Cold start from FCM notification: ${initialMessage.messageId}',
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationRouter.navigateToDestination(initialMessage.data);
        });
      }

      // 5. Listen to notification taps when app is opened from background
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        if (kDebugMode) {
          debugPrint(
            '[AMOMY_NOTIF] App opened from background notification: ${message.messageId}',
          );
        }
        NotificationRouter.navigateToDestination(message.data);
      });

      // 6. Listen to foreground notifications
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen((
        message,
      ) async {
        await handleForegroundMessage(message);
      });

      // 7. Listen to token refresh events
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        _lastKnownToken = newToken;
        if (kDebugMode) {
          debugPrint(
            '[AMOMY_NOTIF] FCM token refreshed: ${_maskToken(newToken)}',
          );
        }
        syncDeviceToken(forcedToken: newToken);
      });

      if (kDebugMode) {
        debugPrint(
          '[AMOMY_NOTIF] Foreground listener attached: true | Background handler registered: true',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Initialization error: $e');
      }
    }
  }

  /// Processes a message received while the app is in the foreground.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    _lastForegroundFcmTime = DateTime.now();
    final dedupeKey = _extractDedupeKey(message);
    final parsedPayload = NotificationPayloadParser.fromApnsPayload(
      message.data,
    );

    final hasNotificationPayload = message.notification != null;
    final hasTitle =
        (message.notification?.title?.isNotEmpty ?? false) ||
        (parsedPayload.title?.isNotEmpty ?? false) ||
        (message.data['title']?.isNotEmpty ?? false) ||
        (message.data['title_en']?.isNotEmpty ?? false) ||
        (message.data['title_ar']?.isNotEmpty ?? false);
    final hasBody =
        (message.notification?.body?.isNotEmpty ?? false) ||
        (parsedPayload.body?.isNotEmpty ?? false) ||
        (message.data['body']?.isNotEmpty ?? false) ||
        (message.data['body_en']?.isNotEmpty ?? false) ||
        (message.data['body_ar']?.isNotEmpty ?? false);

    if (kDebugMode) {
      debugPrint(
        '[AMOMY_NOTIF] onMessage received: '
        'messageId=${message.messageId ?? "none"}, '
        'has_notification_payload=$hasNotificationPayload, '
        'has_title=$hasTitle, '
        'has_body=$hasBody, '
        'data_keys=${message.data.keys.toList()}',
      );
    }

    // Deduplication check
    final dedupeHit = _hasPresented(dedupeKey);
    if (dedupeHit) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Skipping duplicate foreground message');
      }
      return;
    }

    // Notify stream subscribers for in-app inbox sync
    _foregroundMessageController.add(message);

    final title =
        message.notification?.title ??
        parsedPayload.title ??
        message.data['title'] ??
        message.data['title_en'] ??
        message.data['title_ar'] ??
        'AMOMY';
    final body =
        message.notification?.body ??
        parsedPayload.body ??
        message.data['body'] ??
        message.data['body_en'] ??
        message.data['body_ar'] ??
        '';

    await _localNotifications.showForegroundNotification(
      id: _notificationIdFromKey(dedupeKey),
      title: title,
      body: body,
      payload: parsedPayload.data.isNotEmpty
          ? parsedPayload.data
          : message.data,
    );
    _rememberPresented(dedupeKey);
  }

  String? _extractDedupeKey(RemoteMessage message) {
    if (message.data.containsKey('notification_id') &&
        message.data['notification_id'] != null) {
      return message.data['notification_id'].toString();
    }
    if (message.data.containsKey('id') && message.data['id'] != null) {
      return message.data['id'].toString();
    }
    if (message.data.containsKey('dedupe_key') &&
        message.data['dedupe_key'] != null) {
      return message.data['dedupe_key'].toString();
    }
    if (message.messageId != null && message.messageId!.isNotEmpty) {
      return message.messageId;
    }
    return null;
  }

  String? _extractNotificationDedupeKey(AppNotification notification) {
    if (notification.id.trim().isNotEmpty) return notification.id.trim();
    final payloadNotificationId = notification.data['notification_id'];
    if (payloadNotificationId != null &&
        payloadNotificationId.toString().trim().isNotEmpty) {
      return payloadNotificationId.toString().trim();
    }
    if (notification.dedupeKey != null &&
        notification.dedupeKey!.trim().isNotEmpty) {
      return notification.dedupeKey!.trim();
    }
    return null;
  }

  bool _hasPresented(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    return _processedMessageKeys.contains(key.trim());
  }

  void _rememberPresented(String? key) {
    if (key == null || key.trim().isEmpty) return;
    final normalized = key.trim();
    if (_processedMessageKeys.contains(normalized)) return;

    _processedMessageKeys.add(normalized);
    _processedMessageKeyOrder.add(normalized);
    while (_processedMessageKeyOrder.length > _maxDedupeCacheSize) {
      final oldest = _processedMessageKeyOrder.removeAt(0);
      _processedMessageKeys.remove(oldest);
    }
  }

  int _notificationIdFromKey(String? key) {
    if (key != null && key.trim().isNotEmpty) {
      return key.trim().hashCode & 0x7FFFFFFF;
    }
    return DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
  }

  bool get _isForeground =>
      _currentLifecycleState == AppLifecycleState.resumed ||
      _currentLifecycleState == AppLifecycleState.inactive;

  Future<void> _logIosLocalNotificationSettings() async {
    if (!kDebugMode || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final settings = await _messaging.getNotificationSettings();
      debugPrint(
        '[IOS_LOCAL_NOTIF_DIAG] authorization=${settings.authorizationStatus.name}',
      );
      debugPrint('[IOS_LOCAL_NOTIF_DIAG] alert_setting=${settings.alert.name}');
      debugPrint('[IOS_LOCAL_NOTIF_DIAG] sound_setting=${settings.sound.name}');
      debugPrint('[IOS_LOCAL_NOTIF_DIAG] badge_setting=${settings.badge.name}');
      debugPrint(
        '[IOS_LOCAL_NOTIF_DIAG] notification_center_setting=${settings.notificationCenter.name}',
      );
      debugPrint(
        '[IOS_LOCAL_NOTIF_DIAG] lock_screen_setting=${settings.lockScreen.name}',
      );
      debugPrint(
        '[IOS_LOCAL_NOTIF_DIAG] plugin_initialized=${_localNotifications.isInitialized}',
      );
    } catch (e) {
      debugPrint(
        '[IOS_LOCAL_NOTIF_DIAG] notification_settings_error=${e.runtimeType}',
      );
    }
  }

  Future<bool> presentForegroundNotificationRow(
    AppNotification notification,
  ) async {
    if (kDebugMode) {
      debugPrint('[NOTIF_PRESENT_DIAG] realtime_insert_received');
      debugPrint(
        '[NOTIF_PRESENT_DIAG] lifecycle=${_currentLifecycleState.name}',
      );
    }

    if (!_isForeground) return false;
    if (notification.isRead) return false;

    final dedupeKey = _extractNotificationDedupeKey(notification);
    final dedupeHit = _hasPresented(dedupeKey);
    if (kDebugMode) {
      debugPrint('[NOTIF_PRESENT_DIAG] dedupe_hit=$dedupeHit');
    }
    if (dedupeHit) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Skipping duplicate realtime notification');
      }
      return false;
    }

    final title = notification.titleEn.isNotEmpty
        ? notification.titleEn
        : (notification.titleAr.isNotEmpty ? notification.titleAr : 'AMOMY');
    final body = notification.bodyEn.isNotEmpty
        ? notification.bodyEn
        : notification.bodyAr;

    await _logIosLocalNotificationSettings();

    final payload = <String, dynamic>{
      ...notification.data,
      'notification_id': notification.id,
      'type': notification.type.toDbString(),
      if (notification.entityType != null)
        'entity_type': notification.entityType,
      if (notification.entityId != null) 'entity_id': notification.entityId,
    };

    final shown = await _localNotifications.showForegroundNotification(
      id: _notificationIdFromKey(dedupeKey),
      title: title,
      body: body,
      payload: payload,
    );
    _rememberPresented(dedupeKey);
    return shown;
  }

  /// Checks if the pre-permission bottom sheet should be presented to the passenger.
  /// Returns true only when:
  /// 1. The sheet has not yet been shown/dismissed (per SharedPreferences).
  /// 2. The OS permission is not yet authorized.
  Future<bool> shouldShowPermissionPrompt() async {
    if (kDebugMode) {
      debugPrint('[IOS_PUSH_DIAG] 03 notification permission check start');
    }

    if (defaultTargetPlatform == TargetPlatform.iOS &&
        debugDisableIosPushStartup) {
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] debugDisableIosPushStartup is true; skipping permission prompt',
        );
      }
      return false;
    }

    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(promptShownKey) ?? false;
      if (hasSeen) return false;

      final settings = await _messaging.getNotificationSettings();
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] 04 current permission = ${settings.authorizationStatus.name}',
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Already authorized on device, sync token safely and mark as shown
        await syncDeviceToken();
        await prefs.setBool(promptShownKey, true);
        return false;
      }

      // On iOS: Explicit OS-level denial cannot be prompted again via standard requestPermission
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          settings.authorizationStatus == AuthorizationStatus.denied) {
        await prefs.setBool(promptShownKey, true);
        return false;
      }

      // On Android / notDetermined: Has not seen prompt yet -> show pre-permission sheet
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] 03 notification permission check error: ${e.runtimeType}',
        );
      }
      return false;
    }
  }

  /// Marks the pre-permission prompt as shown in persistent storage.
  Future<void> markPermissionPromptShown() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(promptShownKey, true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] markPermissionPromptShown error: $e');
      }
    }
  }

  /// Evaluates and mounts the NotificationPermissionSheet if not yet shown or granted.
  Future<void> promptPermissionIfNeeded(BuildContext context) async {
    final shouldShow = await shouldShowPermissionPrompt();
    if (!shouldShow) return;

    // Immediately mark as shown to prevent duplicate triggers on rapid navigation
    await markPermissionPromptShown();

    if (!context.mounted) return;

    final accepted = await NotificationPermissionSheet.show(context);
    if (accepted == true) {
      await requestPermission(isManual: true);
    }
  }

  /// Requests notification permission with platform-appropriate parameters.
  Future<NotificationSettings?> requestPermission({
    bool isManual = false,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        debugDisableIosPushStartup) {
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] debugDisableIosPushStartup is true; skipping requestPermission',
        );
      }
      return null;
    }

    try {
      if (kDebugMode) {
        debugPrint('[IOS_PUSH_DIAG] 05 permission request start');
      }

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] 06 permission request returned = ${settings.authorizationStatus.name}',
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await syncDeviceToken();
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] 05 permission request error: ${e.runtimeType}',
        );
      }
      return null;
    }
  }

  /// Helper to verify APNs token readiness on iOS before attempting getToken.
  /// Bounded retry: attempts up to 3 times with 500ms intervals, then stops quietly.
  Future<bool> _isApnsReadyOnIos() async {
    if (kDebugMode) {
      debugPrint('[IOS_PUSH_DIAG] 07 getAPNSToken start');
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        final hasApns = apnsToken != null && apnsToken.trim().isNotEmpty;
        if (kDebugMode) {
          debugPrint(
            '[IOS_PUSH_DIAG] 08 APNs token available = $hasApns (attempt $attempt/3)',
          );
        }
        if (hasApns) return true;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[IOS_PUSH_DIAG] 07 getAPNSToken error: ${e.runtimeType}');
        }
        return false;
      }

      if (attempt < 3) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[IOS_PUSH_DIAG] APNs token not ready; stopping quietly without calling getToken',
      );
    }
    return false;
  }

  /// Syncs / upserts the current FCM device token into public.user_device_tokens.
  Future<bool> syncDeviceToken({String? forcedToken}) async {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        debugDisableIosPushStartup) {
      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] debugDisableIosPushStartup is true; skipping syncDeviceToken',
        );
      }
      return false;
    }

    try {
      // On iOS: verify APNs readiness first to prevent unready getToken crashes
      if (defaultTargetPlatform == TargetPlatform.iOS && forcedToken == null) {
        final apnsReady = await _isApnsReadyOnIos();
        if (!apnsReady) {
          _lastRegistrationStatus = 'apns_not_ready';
          return false;
        }
      }

      if (kDebugMode) {
        debugPrint('[IOS_PUSH_DIAG] 09 getToken start');
      }

      final token = forcedToken ?? await _messaging.getToken();
      final hasToken = token != null && token.trim().isNotEmpty;

      if (kDebugMode) {
        final statusDesc = hasToken ? 'success' : 'null';
        debugPrint('[IOS_PUSH_DIAG] 10 getToken $statusDesc');
      }

      if (!hasToken) {
        _lastRegistrationStatus = 'missing_token';
        return false;
      }
      _lastKnownToken = token;

      if (kDebugMode) {
        debugPrint('[IOS_PUSH_DIAG] 11 backend token sync start');
      }

      final platformStr = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

      final success = await repository.registerDeviceToken(
        token: token,
        platform: platformStr,
      );

      if (kDebugMode) {
        debugPrint(
          '[IOS_PUSH_DIAG] 12 backend token sync ${success ? "success" : "error"}',
        );
      }

      _lastRegistrationStatus = success ? 'success' : 'failure';
      return success;
    } catch (e) {
      _lastRegistrationStatus = 'error: $e';
      if (kDebugMode) {
        debugPrint('[IOS_PUSH_DIAG] syncDeviceToken error: ${e.runtimeType}');
      }
      return false;
    }
  }

  /// Deactivates the current device token in the database upon user logout.
  Future<bool> deactivateCurrentToken() async {
    try {
      final token = _lastKnownToken ?? await _messaging.getToken();
      if (token == null || token.trim().isEmpty) return false;

      final success = await repository.deactivateDeviceToken(token);
      _lastKnownToken = null;
      _lastRegistrationStatus = 'deactivated';
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] deactivateCurrentToken error: $e');
      }
      return false;
    }
  }

  /// Safe developer self-test push execution with diagnostic recording.
  Future<SelfTestResult> executeSelfTest({int? delaySeconds}) async {
    _lastSelfTestTime = DateTime.now();
    try {
      final result = await repository.sendSelfTestNotification(
        delaySeconds: delaySeconds,
      );
      _lastSelfTestBackendResult = result.success
          ? 'success'
          : 'error: ${result.error ?? result.message}';
      _lastFcmProviderResult = result.fcmSuccesses > 0
          ? 'success'
          : (result.totalDevices == 0 ? 'no_devices' : 'failure');
      return result;
    } catch (e) {
      _lastSelfTestBackendResult = 'error: $e';
      _lastFcmProviderResult = 'failure';
      return SelfTestResult.failure(e.toString());
    }
  }

  void recordInboxRefresh({required int count, required int unreadCount}) {
    _lastInboxRefreshTime = DateTime.now();
    _lastUnreadCount = unreadCount;
  }

  /// Generates the complete 22-field diagnostic snapshot for debug status sheet.
  Future<NotificationDiagnosticData> getDiagnostics() async {
    // 1. Firebase init
    bool fbInit = false;
    try {
      fbInit = Firebase.apps.isNotEmpty;
    } catch (_) {
      fbInit = _firebaseInitialized;
    }

    // 2. Permission status
    String permStatus = 'unknown';
    String postNotif = 'notRequired';
    try {
      final settings = await _messaging.getNotificationSettings();
      permStatus = settings.authorizationStatus.name;
      if (defaultTargetPlatform == TargetPlatform.android) {
        postNotif =
            settings.authorizationStatus == AuthorizationStatus.authorized
            ? 'granted'
            : (settings.authorizationStatus == AuthorizationStatus.denied
                  ? 'denied'
                  : 'notDetermined');
      }
    } catch (e) {
      permStatus = 'error: $e';
    }

    // 3. FCM token
    String? token = _lastKnownToken;
    if (token == null) {
      try {
        token = await _messaging.getToken();
        _lastKnownToken = token;
      } catch (_) {}
    }
    final tokenAvail = token != null && token.isNotEmpty;
    final tokenLen = token?.length ?? 0;
    final tokenSuffix = (token != null && token.length > 6)
        ? token.substring(token.length - 6)
        : (token ?? 'none');

    // 4. Token registered in Supabase
    final tokenReg = _lastRegistrationStatus == 'success'
        ? 'true'
        : (_lastRegistrationStatus == 'failure' ? 'false' : 'unknown');

    // 5. Active token row
    final activeRow = tokenAvail && _lastRegistrationStatus == 'success'
        ? 'true'
        : 'unknown';

    // 6. Local notifications
    final localInit = _localNotifications.isInitialized;
    final channelStatus = localInit ? 'created' : 'missing';

    // 7. Last timestamps formatting helper
    String fmtTime(DateTime? dt) => dt != null
        ? dt.toIso8601String().split('T').last.split('.').first
        : 'none';

    return NotificationDiagnosticData(
      firebaseInitialized: fbInit,
      notificationPermission: permStatus,
      androidPostNotifications: postNotif,
      fcmTokenAvailable: tokenAvail,
      fcmTokenLength: tokenLen,
      fcmTokenSuffix: tokenSuffix,
      tokenRegisteredInSupabase: tokenReg,
      activeTokenRow: activeRow,
      localNotificationServiceInitialized: localInit,
      androidNotificationChannel: channelStatus,
      channelId: LocalNotificationService.channelId,
      foregroundListenerAttached: _foregroundMessageSub != null,
      backgroundHandlerRegistered: true,
      lastForegroundFcmMessage: fmtTime(_lastForegroundFcmTime),
      lastLocalNotificationShowAttempt: fmtTime(
        _localNotifications.lastShowAttempt,
      ),
      lastLocalNotificationResult: _localNotifications.lastShowResult ?? 'none',
      lastSelfTestRequest: fmtTime(_lastSelfTestTime),
      lastSelfTestBackendResult: _lastSelfTestBackendResult ?? 'none',
      lastFcmProviderResult: _lastFcmProviderResult ?? 'unknown',
      lastInboxRefresh: fmtTime(_lastInboxRefreshTime),
      unreadCount: _lastUnreadCount != null ? '$_lastUnreadCount' : 'unknown',
      currentLifecycle: _currentLifecycleState.name,
    );
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
    _messageOpenedSub?.cancel();
    _foregroundMessageController.close();
  }
}
