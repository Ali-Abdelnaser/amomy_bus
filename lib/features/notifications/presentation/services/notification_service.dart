import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_diagnostic_data.dart';
import '../../domain/entities/self_test_result.dart';
import '../../domain/repositories/notification_repository.dart';
import '../widgets/notification_permission_sheet.dart';
import 'local_notification_service.dart';
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

  // Deduplication cache to prevent duplicate local presentations
  final Set<String> _processedMessageKeys = <String>{};
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
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
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

      // 3. Configure iOS native foreground presentation options (alert, badge, sound)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Check for initial cold-start notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint('[AMOMY_NOTIF] Cold start from FCM notification: ${initialMessage.messageId}');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationRouter.navigateToDestination(initialMessage.data);
        });
      }

      // 5. Listen to notification taps when app is opened from background
      _messageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          debugPrint(
              '[AMOMY_NOTIF] App opened from background notification: ${message.messageId}');
        }
        NotificationRouter.navigateToDestination(message.data);
      });

      // 6. Listen to foreground notifications
      _foregroundMessageSub =
          FirebaseMessaging.onMessage.listen((message) async {
        await handleForegroundMessage(message);
      });

      // 7. Listen to token refresh events
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        _lastKnownToken = newToken;
        if (kDebugMode) {
          debugPrint('[AMOMY_NOTIF] FCM token refreshed: ${_maskToken(newToken)}');
        }
        syncDeviceToken(forcedToken: newToken);
      });

      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Foreground listener attached: true | Background handler registered: true');
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

    final hasNotificationPayload = message.notification != null;
    final hasTitle = (message.notification?.title?.isNotEmpty ?? false) ||
        (message.data['title']?.isNotEmpty ?? false) ||
        (message.data['title_en']?.isNotEmpty ?? false) ||
        (message.data['title_ar']?.isNotEmpty ?? false);
    final hasBody = (message.notification?.body?.isNotEmpty ?? false) ||
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
          'data_keys=${message.data.keys.toList()}');
    }

    // Deduplication check
    if (dedupeKey != null && _processedMessageKeys.contains(dedupeKey)) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] Skipping duplicate foreground message: $dedupeKey');
      }
      return;
    }

    if (dedupeKey != null) {
      if (_processedMessageKeys.length >= _maxDedupeCacheSize) {
        _processedMessageKeys.remove(_processedMessageKeys.first);
      }
      _processedMessageKeys.add(dedupeKey);
    }

    // Notify stream subscribers for in-app inbox sync
    _foregroundMessageController.add(message);

    // On Android: Show heads-up local notification
    // (iOS handles foreground display natively via setForegroundNotificationPresentationOptions)
    if (defaultTargetPlatform == TargetPlatform.android || kIsWeb) {
      final title = message.notification?.title ??
          message.data['title'] ??
          message.data['title_en'] ??
          message.data['title_ar'] ??
          'AMOMY';
      final body = message.notification?.body ??
          message.data['body'] ??
          message.data['body_en'] ??
          message.data['body_ar'] ??
          '';

      final notificationId = dedupeKey != null
          ? (dedupeKey.hashCode & 0x7FFFFFFF)
          : (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);

      await _localNotifications.showForegroundNotification(
        id: notificationId,
        title: title,
        body: body,
        payload: message.data,
      );
    }
  }

  String? _extractDedupeKey(RemoteMessage message) {
    if (message.data.containsKey('dedupe_key') &&
        message.data['dedupe_key'] != null) {
      return message.data['dedupe_key'].toString();
    }
    if (message.messageId != null && message.messageId!.isNotEmpty) {
      return message.messageId;
    }
    if (message.data.containsKey('id') && message.data['id'] != null) {
      return message.data['id'].toString();
    }
    return null;
  }

  /// Checks if the pre-permission bottom sheet should be presented to the passenger.
  /// Returns true only when:
  /// 1. The sheet has not yet been shown/dismissed (per SharedPreferences).
  /// 2. The OS permission is not yet authorized.
  ///
  /// Note: On Android 13+, fresh installs report 'denied' before POST_NOTIFICATIONS is requested.
  /// We do NOT treat 'denied' on Android as proof that the user has already rejected our pre-permission flow.
  Future<bool> shouldShowPermissionPrompt() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(promptShownKey) ?? false;
      if (hasSeen) return false;

      final settings = await _messaging.getNotificationSettings();
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Permission status: ${settings.authorizationStatus.name}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Already authorized on device, sync token and mark as shown
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
        debugPrint('[AMOMY_NOTIF] shouldShowPermissionPrompt error: $e');
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
      final settings = await requestPermission(isManual: true);
      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] Permission requested after pre-sheet. Status: ${settings?.authorizationStatus.name}');
      }
    }
  }

  /// Requests notification permission with platform-appropriate parameters.
  Future<NotificationSettings?> requestPermission({bool isManual = false}) async {
    try {
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
            '[AMOMY_NOTIF] Permission request returned: ${settings.authorizationStatus.name}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await syncDeviceToken();
      }

      return settings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] requestPermission error: $e');
      }
      return null;
    }
  }

  /// Syncs / upserts the current FCM device token into public.user_device_tokens.
  Future<bool> syncDeviceToken({String? forcedToken}) async {
    try {
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] getToken() called...');
      }

      final token = forcedToken ?? await _messaging.getToken();
      final hasToken = token != null && token.trim().isNotEmpty;

      if (kDebugMode) {
        debugPrint(
            '[AMOMY_NOTIF] FCM token available: $hasToken (${_maskToken(token)})');
      }

      if (!hasToken) {
        _lastRegistrationStatus = 'missing_token';
        return false;
      }
      _lastKnownToken = token;

      final platformStr =
          defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

      final success = await repository.registerDeviceToken(
        token: token,
        platform: platformStr,
      );

      _lastRegistrationStatus = success ? 'success' : 'failure';
      return success;
    } catch (e) {
      _lastRegistrationStatus = 'error: $e';
      if (kDebugMode) {
        debugPrint('[AMOMY_NOTIF] syncDeviceToken error: $e');
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
      final result = await repository.sendSelfTestNotification(delaySeconds: delaySeconds);
      _lastSelfTestBackendResult = result.success ? 'success' : 'error: ${result.error ?? result.message}';
      _lastFcmProviderResult = result.fcmSuccesses > 0 ? 'success' : (result.totalDevices == 0 ? 'no_devices' : 'failure');
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
        postNotif = settings.authorizationStatus == AuthorizationStatus.authorized
            ? 'granted'
            : (settings.authorizationStatus == AuthorizationStatus.denied ? 'denied' : 'notDetermined');
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
    final activeRow = tokenAvail && _lastRegistrationStatus == 'success' ? 'true' : 'unknown';

    // 6. Local notifications
    final localInit = _localNotifications.isInitialized;
    final channelStatus = localInit ? 'created' : 'missing';

    // 7. Last timestamps formatting helper
    String fmtTime(DateTime? dt) => dt != null ? dt.toIso8601String().split('T').last.split('.').first : 'none';

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
      lastLocalNotificationShowAttempt: fmtTime(_localNotifications.lastShowAttempt),
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
