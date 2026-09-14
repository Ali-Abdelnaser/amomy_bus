import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_router.dart';

/// Top-level background message handler required by Firebase Messaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or mock test environment
  }
}

class NotificationService {
  final NotificationRepository repository;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  String? _lastKnownToken;
  bool _initialized = false;

  NotificationService({
    required this.repository,
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  /// Initializes listeners for tokens and incoming FCM messages.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Check for initial cold-start notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[NotificationService] Cold start from FCM notification');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationRouter.navigateToDestination(initialMessage.data);
        });
      }

      // 2. Listen to notification taps when app is in background
      _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[NotificationService] App opened from background notification');
        NotificationRouter.navigateToDestination(message.data);
      });

      // 3. Listen to foreground notifications
      _foregroundMessageSub = FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[NotificationService] Foreground FCM received: ${message.messageId}');
      });

      // 4. Listen to token refresh events
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
        _lastKnownToken = newToken;
        syncDeviceToken(forcedToken: newToken);
      });
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
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

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await syncDeviceToken();
      }

      return settings;
    } catch (e) {
      debugPrint('[NotificationService] requestPermission error: $e');
      return null;
    }
  }

  /// Syncs / upserts the current FCM device token into public.user_device_tokens.
  Future<bool> syncDeviceToken({String? forcedToken}) async {
    try {
      final token = forcedToken ?? await _messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return false;
      }
      _lastKnownToken = token;

      final platformStr = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

      return await repository.registerDeviceToken(
        token: token,
        platform: platformStr,
      );
    } catch (e) {
      debugPrint('[NotificationService] syncDeviceToken error: $e');
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
      return success;
    } catch (e) {
      debugPrint('[NotificationService] deactivateCurrentToken error: $e');
      return false;
    }
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
    _foregroundMessageSub?.cancel();
    _messageOpenedSub?.cancel();
  }
}
