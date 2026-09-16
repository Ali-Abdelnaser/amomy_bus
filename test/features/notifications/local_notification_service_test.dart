import 'dart:convert';
import 'dart:io';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_preferences.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';
import 'package:amomy_bus/features/notifications/domain/entities/self_test_result.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_state.dart';
import 'package:amomy_bus/features/notifications/presentation/services/local_notification_service.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_service.dart';
import 'package:amomy_bus/features/notifications/presentation/widgets/notification_permission_sheet.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAndroidFlutterLocalNotificationsPlugin extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  AndroidNotificationChannel? createdChannel;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {
    createdChannel = channel;
  }
}

class _FakeLocalNotificationPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  bool initialized = false;
  InitializationSettings? initSettings;
  void Function(NotificationResponse)? onDidReceiveNotificationResponse;
  final androidPlugin = _FakeAndroidFlutterLocalNotificationsPlugin();

  int? lastShownId;
  String? lastShownTitle;
  String? lastShownBody;
  NotificationDetails? lastShownDetails;
  String? lastShownPayload;
  int showCallCount = 0;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initialized = true;
    initSettings = initializationSettings;
    this.onDidReceiveNotificationResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    lastShownId = id;
    lastShownTitle = title;
    lastShownBody = body;
    lastShownDetails = notificationDetails;
    lastShownPayload = payload;
    showCallCount++;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return androidPlugin as T;
    }
    return null;
  }
}

class _ThrowingShowLocalNotificationPlugin
    extends _FakeLocalNotificationPlugin {
  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    showCallCount++;
    throw StateError('show failed');
  }
}

class _FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  bool foregroundPresentationConfigured = false;
  bool alertOption = false;
  bool badgeOption = false;
  bool soundOption = false;
  bool requestPermissionCalled = false;
  int notificationSettingsCallCount = 0;
  AuthorizationStatus authorizationStatus = AuthorizationStatus.notDetermined;

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    notificationSettingsCallCount++;
    return NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      authorizationStatus: authorizationStatus,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool providesAppNotificationSettings = false,
    bool provisional = false,
    bool sound = true,
  }) async {
    requestPermissionCalled = true;
    authorizationStatus = AuthorizationStatus.authorized;
    return getNotificationSettings();
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
    bool provisional = false,
  }) async {
    foregroundPresentationConfigured = true;
    alertOption = alert;
    badgeOption = badge;
    soundOption = sound;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => 'mock-fcm-token';

  @override
  Future<String?> getAPNSToken() async => 'mock-apns-token';
}

class _FakeFirebaseMessagingWithNullApns extends _FakeFirebaseMessaging {
  bool getTokenCalled = false;

  @override
  Future<String?> getAPNSToken() async => null;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    getTokenCalled = true;
    return 'mock-fcm-token';
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  List<AppNotification> notifications = [];
  int unreadCount = 0;
  String? registeredToken;

  @override
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return unreadCount;
  }

  @override
  Stream<AppNotification?> subscribeToNotificationUpdates() =>
      const Stream.empty();

  @override
  Future<bool> markAsRead(String notificationId) async => true;

  @override
  Future<int> markAllAsRead() async => 0;

  @override
  Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? installationId,
    String? deviceName,
    String? appVersion,
  }) async {
    registeredToken = token;
    return true;
  }

  @override
  Future<bool> deactivateDeviceToken(String token) async => true;

  @override
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds}) async =>
      const SelfTestResult(
        success: true,
        requestAccepted: true,
        totalDevices: 1,
        delivered: 1,
        message: 'Self test success',
      );

  @override
  Future<bool> isNotificationTester() async => false;

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) async => const NotificationTestEventResult(
    success: true,
    eventType: 'test',
    category: 'service_updates',
  );

  @override
  Future<NotificationPreferences> getPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async => preferences;
}

void main() {
  group('LocalNotificationService Tests', () {
    late _FakeLocalNotificationPlugin fakePlugin;
    late LocalNotificationService localService;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fakePlugin = _FakeLocalNotificationPlugin();
      localService = LocalNotificationService(plugin: fakePlugin);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'initialize sets up Android channel configuration and initializes plugin',
      () async {
        await localService.initialize();

        expect(localService.isInitialized, isTrue);
        expect(fakePlugin.initialized, isTrue);
        expect(
          fakePlugin.initSettings?.android?.defaultIcon,
          '@drawable/ic_notification',
        );
        expect(
          fakePlugin.androidPlugin.createdChannel?.id,
          'amomy_high_importance',
        );
        expect(
          fakePlugin.androidPlugin.createdChannel?.name,
          'AMOMY Notifications',
        );
        expect(
          fakePlugin.androidPlugin.createdChannel?.description,
          'Booking, wallet, trip, and service updates',
        );
        expect(
          fakePlugin.androidPlugin.createdChannel?.importance,
          Importance.high,
        );
      },
    );

    test(
      'showForegroundNotification displays local notification on Android with payload',
      () async {
        await localService.initialize();

        await localService.showForegroundNotification(
          id: 101,
          title: 'Top-Up Approved',
          body: 'Your 200 PTS top-up has been approved.',
          payload: {'screen': 'wallet', 'type': 'topup_approved'},
        );

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownId, 101);
        expect(fakePlugin.lastShownTitle, 'Top-Up Approved');
        expect(
          fakePlugin.lastShownBody,
          'Your 200 PTS top-up has been approved.',
        );
        expect(
          fakePlugin.lastShownDetails?.android?.channelId,
          'amomy_high_importance',
        );
        expect(
          fakePlugin.lastShownDetails?.android?.importance,
          Importance.high,
        );
        expect(fakePlugin.lastShownDetails?.android?.priority, Priority.high);

        final payloadMap =
            jsonDecode(fakePlugin.lastShownPayload!) as Map<String, dynamic>;
        expect(payloadMap['screen'], 'wallet');
        expect(payloadMap['type'], 'topup_approved');
      },
    );

    test(
      'showForegroundNotification preserves routing payload for NotificationRouter',
      () async {
        await localService.initialize();

        await localService.showForegroundNotification(
          id: 102,
          title: 'Bus Approaching',
          body: 'Bus #101 is 2 stops away',
          payload: {'screen': 'live_tracking', 'trip_id': 'trip-xyz'},
        );

        final payloadMap =
            jsonDecode(fakePlugin.lastShownPayload!) as Map<String, dynamic>;
        final targetRoute = NotificationRouter.resolveRoute(payloadMap);
        expect(targetRoute, '/trips/trip-xyz/tracking');
      },
    );

    test(
      'showForegroundNotification shows local notification on iOS foreground path',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await localService.initialize();

        await localService.showForegroundNotification(
          id: 103,
          title: 'iOS Alert',
          body: 'Handled natively by APNs presentation',
          payload: {'screen': 'home'},
        );

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownDetails?.iOS?.presentAlert, isTrue);
        expect(fakePlugin.lastShownDetails?.iOS?.presentSound, isTrue);
        expect(fakePlugin.lastShownDetails?.iOS?.presentBadge, isTrue);
        expect(fakePlugin.lastShownDetails?.iOS?.presentBanner, isTrue);
        expect(fakePlugin.lastShownDetails?.iOS?.presentList, isTrue);
      },
    );

    test(
      'showForegroundNotification normalizes invalid notification IDs',
      () async {
        await localService.initialize();

        await localService.showForegroundNotification(
          id: -42,
          title: 'ID Test',
          body: 'Negative IDs should be normalized.',
        );

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownId, isNotNull);
        expect(fakePlugin.lastShownId, greaterThanOrEqualTo(0));
        expect(fakePlugin.lastShownId, lessThanOrEqualTo(0x7FFFFFFF));
      },
    );

    test(
      'showTestLocalNotification uses safe direct local test content',
      () async {
        await localService.showTestLocalNotification();

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownId, 999001);
        expect(fakePlugin.lastShownTitle, 'AMOMY Bus');
        expect(
          fakePlugin.lastShownBody,
          'Local notification presentation test',
        );
      },
    );

    test(
      'showForegroundNotification lazily initializes plugin before show',
      () async {
        expect(localService.isInitialized, isFalse);

        await localService.showForegroundNotification(
          id: 104,
          title: 'Lazy Init',
          body: 'Plugin initializes before display.',
          payload: {'type': 'system'},
        );

        expect(localService.isInitialized, isTrue);
        expect(fakePlugin.initialized, isTrue);
        expect(fakePlugin.showCallCount, 1);
      },
    );

    test(
      'showForegroundNotification catches show errors without crashing',
      () async {
        final throwingPlugin = _ThrowingShowLocalNotificationPlugin();
        final throwingService = LocalNotificationService(
          plugin: throwingPlugin,
        );

        final shown = await throwingService.showForegroundNotification(
          id: 105,
          title: 'Failure',
          body: 'This show throws.',
          payload: {'type': 'system'},
        );

        expect(shown, isFalse);
        expect(throwingPlugin.showCallCount, 1);
        expect(throwingService.lastShowResult, startsWith('error:'));
      },
    );

    test('tap payload routes safely, including malformed payloads', () async {
      await localService.initialize();

      expect(
        () => fakePlugin.onDidReceiveNotificationResponse!(
          const NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: '{not-valid-json',
          ),
        ),
        returnsNormally,
      );
    });
  });

  group('NotificationService Foreground & Deduplication Tests', () {
    late _FakeLocalNotificationPlugin fakePlugin;
    late LocalNotificationService localService;
    late _FakeFirebaseMessaging fakeMessaging;
    late _FakeNotificationRepository fakeRepo;
    late NotificationService notificationService;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fakePlugin = _FakeLocalNotificationPlugin();
      localService = LocalNotificationService(plugin: fakePlugin);
      fakeMessaging = _FakeFirebaseMessaging();
      fakeRepo = _FakeNotificationRepository();
      notificationService = NotificationService(
        repository: fakeRepo,
        messaging: fakeMessaging,
        localNotifications: localService,
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      notificationService.dispose();
    });

    test('initialize configures iOS foreground presentation options', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await notificationService.initialize();

      expect(fakeMessaging.foregroundPresentationConfigured, isTrue);
      expect(fakeMessaging.alertOption, isFalse);
      expect(fakeMessaging.badgeOption, isTrue);
      expect(fakeMessaging.soundOption, isFalse);
      expect(fakeMessaging.notificationSettingsCallCount, greaterThan(0));
    });

    test(
      'handleForegroundMessage displays local notification on Android and notifies stream',
      () async {
        await localService.initialize();

        const message = RemoteMessage(
          messageId: 'msg-001',
          notification: RemoteNotification(
            title: 'Booking Confirmed',
            body: 'Seat #12 confirmed for tomorrow',
          ),
          data: {'screen': 'ticket', 'booking_id': 'book-789'},
        );

        RemoteMessage? streamEmittedMessage;
        final sub = notificationService.onForegroundNotification.listen((m) {
          streamEmittedMessage = m;
        });

        await notificationService.handleForegroundMessage(message);

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownTitle, 'Booking Confirmed');
        expect(fakePlugin.lastShownBody, 'Seat #12 confirmed for tomorrow');
        expect(streamEmittedMessage?.messageId, 'msg-001');

        await sub.cancel();
      },
    );

    test(
      'handleForegroundMessage reads simulator APNs alert fields and preserves AMOMY routing data',
      () async {
        await localService.initialize();

        const message = RemoteMessage(
          data: {
            'aps': {
              'alert': {
                'title': 'AMOMY Bus',
                'body': 'This is an iOS simulator notification test.',
              },
              'sound': 'default',
              'badge': 1,
            },
            'type': 'trip_update',
            'notification_id': 'debug-ios-simulator-notification',
            'trip_id': 'debug-trip-001',
            'route': 'live_tracking',
          },
        );

        await notificationService.handleForegroundMessage(message);

        expect(fakePlugin.showCallCount, 1);
        expect(fakePlugin.lastShownTitle, 'AMOMY Bus');
        expect(
          fakePlugin.lastShownBody,
          'This is an iOS simulator notification test.',
        );

        final payloadMap =
            jsonDecode(fakePlugin.lastShownPayload!) as Map<String, dynamic>;
        expect(payloadMap.containsKey('aps'), isFalse);
        expect(
          payloadMap['notification_id'],
          'debug-ios-simulator-notification',
        );
        expect(
          NotificationRouter.resolveRoute(payloadMap),
          '/trips/debug-trip-001/tracking',
        );
      },
    );

    test(
      'handleForegroundMessage deduplicates repeated messages with same notification_id',
      () async {
        await localService.initialize();

        const message = RemoteMessage(
          messageId: 'msg-dup-1',
          notification: RemoteNotification(
            title: 'Special Offer',
            body: 'Get 50 extra points today',
          ),
          data: {'notification_id': 'promo-2026'},
        );

        // First call
        await notificationService.handleForegroundMessage(message);
        expect(fakePlugin.showCallCount, 1);

        // Duplicate call with same dedupe_key
        await notificationService.handleForegroundMessage(message);
        expect(fakePlugin.showCallCount, 1); // Not incremented!
      },
    );

    test(
      'realtime notification arrives then matching FCM still presents once',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final notification = AppNotification(
          id: 'notif-rt-first',
          userId: 'u1',
          type: NotificationType.bookingConfirmed,
          titleAr: 'تم تأكيد الحجز',
          bodyAr: 'رحلتك مؤكدة',
          titleEn: 'Booking Confirmed',
          bodyEn: 'Your 08:00 trip is confirmed. Seat 1.',
          data: const {'booking_id': 'book-1'},
          createdAt: DateTime.now(),
        );

        await notificationService.presentForegroundNotificationRow(
          notification,
        );
        expect(localService.isInitialized, isTrue);
        expect(fakeMessaging.notificationSettingsCallCount, greaterThan(0));
        expect(fakePlugin.showCallCount, 1);

        const message = RemoteMessage(
          messageId: 'different-fcm-id',
          notification: RemoteNotification(
            title: 'Booking Confirmed',
            body: 'Your 08:00 trip is confirmed. Seat 1.',
          ),
          data: {'notification_id': 'notif-rt-first', 'booking_id': 'book-1'},
        );

        await notificationService.handleForegroundMessage(message);

        expect(fakePlugin.showCallCount, 1);
      },
    );

    test(
      'FCM arrives then matching realtime notification still presents once',
      () async {
        await localService.initialize();

        const message = RemoteMessage(
          messageId: 'different-fcm-id',
          notification: RemoteNotification(
            title: 'Booking Cancelled',
            body: 'Your booking was cancelled and 20 Points were refunded.',
          ),
          data: {
            'notification_id': 'notif-fcm-first',
            'type': 'booking_cancelled',
          },
        );

        await notificationService.handleForegroundMessage(message);
        expect(fakePlugin.showCallCount, 1);

        final notification = AppNotification(
          id: 'notif-fcm-first',
          userId: 'u1',
          type: NotificationType.bookingCancelled,
          titleAr: 'تم إلغاء الحجز',
          bodyAr: 'تم رد النقاط',
          titleEn: 'Booking Cancelled',
          bodyEn: 'Your booking was cancelled and 20 Points were refunded.',
          createdAt: DateTime.now(),
        );

        await notificationService.presentForegroundNotificationRow(
          notification,
        );

        expect(fakePlugin.showCallCount, 1);
      },
    );

    test(
      'inbox refresh alone does not mark notification as visually presented',
      () async {
        await localService.initialize();

        final notification = AppNotification(
          id: 'notif-inbox-only',
          userId: 'u1',
          type: NotificationType.bookingConfirmed,
          titleAr: 'تم تأكيد الحجز',
          bodyAr: 'تم تأكيد رحلتك',
          titleEn: 'Booking Confirmed',
          bodyEn: 'Your trip is confirmed.',
          createdAt: DateTime.now(),
        );
        fakeRepo.notifications = [notification];
        fakeRepo.unreadCount = 1;

        final cubit = NotificationCubit(repository: fakeRepo);
        await cubit.loadNotifications();

        await notificationService.handleForegroundMessage(
          const RemoteMessage(
            notification: RemoteNotification(
              title: 'Booking Confirmed',
              body: 'Your trip is confirmed.',
            ),
            data: {'notification_id': 'notif-inbox-only'},
          ),
        );

        expect(fakePlugin.showCallCount, 1);
        await cubit.close();
      },
    );

    test('different notification IDs both present', () async {
      await localService.initialize();

      await notificationService.handleForegroundMessage(
        const RemoteMessage(
          notification: RemoteNotification(title: 'One', body: 'First'),
          data: {'notification_id': 'notif-1'},
        ),
      );
      await notificationService.handleForegroundMessage(
        const RemoteMessage(
          notification: RemoteNotification(title: 'Two', body: 'Second'),
          data: {'notification_id': 'notif-2'},
        ),
      );

      expect(fakePlugin.showCallCount, 2);
    });

    test('missing notification_id is handled safely', () async {
      await localService.initialize();

      await notificationService.handleForegroundMessage(
        const RemoteMessage(
          notification: RemoteNotification(
            title: 'AMOMY Bus',
            body: 'Notification without a persistent id.',
          ),
          data: {'type': 'system'},
        ),
      );

      expect(fakePlugin.showCallCount, 1);
      expect(fakePlugin.lastShownTitle, 'AMOMY Bus');
    });

    test(
      'background lifecycle does not generate client-side local banner',
      () async {
        await localService.initialize();
        notificationService.didChangeAppLifecycleState(
          AppLifecycleState.paused,
        );

        final notification = AppNotification(
          id: 'notif-background',
          userId: 'u1',
          type: NotificationType.system,
          titleAr: 'تنبيه',
          bodyAr: 'مرحبا',
          titleEn: 'Background',
          bodyEn: 'Should rely on APNs/FCM system delivery.',
          createdAt: DateTime.now(),
        );

        final shown = await notificationService
            .presentForegroundNotificationRow(notification);

        expect(shown, isFalse);
        expect(fakePlugin.showCallCount, 0);
      },
    );

    test('realtime local show error returns false without crashing', () async {
      final throwingPlugin = _ThrowingShowLocalNotificationPlugin();
      final throwingLocalService = LocalNotificationService(
        plugin: throwingPlugin,
      );
      final throwingNotificationService = NotificationService(
        repository: fakeRepo,
        messaging: fakeMessaging,
        localNotifications: throwingLocalService,
      );

      final notification = AppNotification(
        id: 'notif-show-error',
        userId: 'u1',
        type: NotificationType.system,
        titleAr: 'تنبيه',
        bodyAr: 'مرحبا',
        titleEn: 'Alert',
        bodyEn: 'Hello',
        createdAt: DateTime.now(),
      );

      final shown = await throwingNotificationService
          .presentForegroundNotificationRow(notification);

      expect(shown, isFalse);
      expect(throwingPlugin.showCallCount, 1);
      throwingNotificationService.dispose();
    });

    test(
      'inbox reloads automatically when foreground message is received by NotificationCubit',
      () async {
        await localService.initialize();

        fakeRepo.notifications = [
          AppNotification(
            id: 'notif-initial',
            userId: 'u1',
            type: NotificationType.system,
            titleAr: 'تنبيه',
            bodyAr: 'مرحبا',
            titleEn: 'Alert',
            bodyEn: 'Hello',
            createdAt: DateTime.now(),
          ),
        ];
        fakeRepo.unreadCount = 1;

        final cubit = NotificationCubit(
          repository: fakeRepo,
          notificationService: notificationService,
        );

        await cubit.loadNotifications();
        expect((cubit.state as NotificationLoaded).notifications.length, 1);

        // Add new notification in repo (simulating backend insertion)
        fakeRepo.notifications = [
          AppNotification(
            id: 'notif-new',
            userId: 'u1',
            type: NotificationType.topupApproved,
            titleAr: 'تم شحن الرصيد',
            bodyAr: 'تم شحن 500 نقطة',
            titleEn: 'Top-Up Approved',
            bodyEn: '500 PTS added',
            createdAt: DateTime.now(),
          ),
          ...fakeRepo.notifications,
        ];
        fakeRepo.unreadCount = 2;

        // Simulate incoming foreground FCM push
        const message = RemoteMessage(
          messageId: 'msg-topup-500',
          notification: RemoteNotification(
            title: 'Top-Up Approved',
            body: '500 PTS added',
          ),
          data: {'screen': 'wallet', 'type': 'topup_approved'},
        );

        await notificationService.handleForegroundMessage(message);
        await pumpEventQueue();

        final updatedState = cubit.state as NotificationLoaded;
        expect(updatedState.notifications.length, 2);
        expect(updatedState.unreadCount, 2);
        expect(updatedState.notifications.first.id, 'notif-new');

        await cubit.close();
      },
    );

    test(
      'firebaseMessagingBackgroundHandler handles background without local notification duplicate',
      () async {
        const bgMessage = RemoteMessage(
          messageId: 'bg-msg-001',
          notification: RemoteNotification(
            title: 'Trip Starting',
            body: 'Bus is departing in 15 mins',
          ),
        );

        await firebaseMessagingBackgroundHandler(bgMessage);
        expect(fakePlugin.showCallCount, 0);
      },
    );
  });

  group('iOS AppDelegate Notification Wiring', () {
    test('AppDelegate assigns UNUserNotificationCenter delegate', () {
      final appDelegate = File(
        'ios/Runner/AppDelegate.swift',
      ).readAsStringSync();

      expect(appDelegate, contains('import UserNotifications'));
      expect(
        appDelegate,
        contains('UNUserNotificationCenter.current().delegate = self'),
      );
    });
  });

  group('Notification Permission Flow & Sheet Tests', () {
    late _FakeLocalNotificationPlugin fakePlugin;
    late LocalNotificationService localService;
    late _FakeFirebaseMessaging fakeMessaging;
    late _FakeNotificationRepository fakeRepo;
    late NotificationService notificationService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakePlugin = _FakeLocalNotificationPlugin();
      localService = LocalNotificationService(plugin: fakePlugin);
      fakeMessaging = _FakeFirebaseMessaging();
      fakeRepo = _FakeNotificationRepository();
      notificationService = NotificationService(
        repository: fakeRepo,
        messaging: fakeMessaging,
        localNotifications: localService,
      );
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      notificationService.dispose();
    });

    test(
      'Android fresh install (status denied + prompt_shown false) SHOULD show permission sheet',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        fakeMessaging.authorizationStatus = AuthorizationStatus.denied;
        final shouldShow = await notificationService
            .shouldShowPermissionPrompt();
        expect(shouldShow, isTrue);
      },
    );

    test(
      'Android fresh install (status notDetermined + prompt_shown false) SHOULD show permission sheet',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        fakeMessaging.authorizationStatus = AuthorizationStatus.notDetermined;
        final shouldShow = await notificationService
            .shouldShowPermissionPrompt();
        expect(shouldShow, isTrue);
      },
    );

    test('Android already authorized => sheet should NOT show', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fakeMessaging.authorizationStatus = AuthorizationStatus.authorized;
      final shouldShow = await notificationService.shouldShowPermissionPrompt();
      expect(shouldShow, isFalse);
    });

    test(
      'Android prompt previously shown => sheet should NOT repeat',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        fakeMessaging.authorizationStatus = AuthorizationStatus.denied;

        // First check: should show
        expect(await notificationService.shouldShowPermissionPrompt(), isTrue);

        // Mark shown
        await notificationService.markPermissionPromptShown();

        // Subsequent check: must not show again
        expect(await notificationService.shouldShowPermissionPrompt(), isFalse);
      },
    );

    test('iOS already denied at OS level => sheet should NOT show', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      fakeMessaging.authorizationStatus = AuthorizationStatus.denied;
      final shouldShow = await notificationService.shouldShowPermissionPrompt();
      expect(shouldShow, isFalse);
    });

    test(
      'Enable Now => requestPermission is called and token synced',
      () async {
        final settings = await notificationService.requestPermission(
          isManual: true,
        );
        expect(fakeMessaging.requestPermissionCalled, isTrue);
        expect(settings?.authorizationStatus, AuthorizationStatus.authorized);
      },
    );

    test(
      'iOS push startup diagnostic normal path syncs token when APNs is ready',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        fakeMessaging.authorizationStatus = AuthorizationStatus.authorized;

        final success = await notificationService.syncDeviceToken();
        expect(success, isTrue);
        expect(fakeRepo.registeredToken, 'mock-fcm-token');
      },
    );

    test(
      'iOS push startup diagnostic: APNs null => stops quietly without calling getToken',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        fakeMessaging.authorizationStatus = AuthorizationStatus.authorized;

        final fakeNoApns = _FakeFirebaseMessagingWithNullApns();
        final serviceWithNoApns = NotificationService(
          repository: fakeRepo,
          messaging: fakeNoApns,
          localNotifications: localService,
        );

        final success = await serviceWithNoApns.syncDeviceToken();
        expect(success, isFalse);
        expect(fakeNoApns.getTokenCalled, isFalse);
        serviceWithNoApns.dispose();
      },
    );

    testWidgets(
      'NotificationPermissionSheet renders UI elements and responds to tap',
      (tester) async {
        bool enabledTapped = false;
        bool laterTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationPermissionSheet(
                onEnablePressed: () => enabledTapped = true,
                onLaterPressed: () => laterTapped = true,
              ),
            ),
          ),
        );

        expect(find.text('Enable Notifications'), findsOneWidget);
        expect(find.text('Enable Now'), findsOneWidget);
        expect(find.text('Maybe Later'), findsOneWidget);

        await tester.tap(find.text('Enable Now'));
        await tester.pump();
        expect(enabledTapped, isTrue);

        await tester.tap(find.text('Maybe Later'));
        await tester.pump();
        expect(laterTapped, isTrue);
      },
    );
  });
}
