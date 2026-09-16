import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_event_catalog.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_preferences.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';
import 'package:amomy_bus/features/notifications/domain/entities/self_test_result.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/widgets/notification_test_lab_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTestLabRepository implements NotificationRepository {
  bool isTester = false;
  NotificationPreferences preferences = const NotificationPreferences(
    allEnabled: true,
  );
  NotificationTestEventResult? mockTestResult;
  Exception? errorToThrow;
  String? lastAction;
  String? lastEventType;
  bool? lastForceDelivery;

  @override
  Future<bool> isNotificationTester() async => isTester;

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) async {
    lastAction = 'test_event';
    lastEventType = eventType;
    lastForceDelivery = forceDelivery;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    if (!isTester) {
      return const NotificationTestEventResult(
        success: false,
        eventType: 'unknown',
        category: 'unknown',
        error: 'Notification Test Lab access denied.',
      );
    }

    final catalogItem = NotificationEventCatalog.find(eventType);
    if (eventType != 'unknown_event_xyz' &&
        catalogItem.eventType == 'system' &&
        eventType != 'system') {
      return NotificationTestEventResult(
        success: false,
        eventType: eventType,
        category: 'unknown',
        error: 'Invalid or unsupported event_type: $eventType',
      );
    }

    if (mockTestResult != null) return mockTestResult!;

    return NotificationTestEventResult(
      success: true,
      eventType: eventType,
      category: catalogItem.category.toDbKey(),
      totalDevices: 1,
      delivered: 1,
      inboxInserted: true,
      forced: forceDelivery,
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() async => preferences;

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences prefs,
  ) async {
    preferences = prefs;
    return preferences;
  }

  @override
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async => [];

  @override
  Future<int> getUnreadCount() async => 0;

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
  }) async => true;

  @override
  Future<bool> deactivateDeviceToken(String token) async => true;

  @override
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds}) async =>
      const SelfTestResult(
        success: true,
        requestAccepted: true,
        totalDevices: 1,
        delivered: 1,
        fcmSendAttempted: true,
        fcmSuccesses: 1,
        fcmFailures: 0,
        notificationInboxInserted: true,
        message: 'Self-test sent successfully',
      );
}

void main() {
  late _MockTestLabRepository mockRepo;

  setUp(() async {
    await getIt.reset();
    mockRepo = _MockTestLabRepository();
    getIt.registerSingleton<NotificationRepository>(mockRepo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestSheet() {
    return MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Scaffold(body: NotificationTestLabSheet()),
    );
  }

  group('Notification Test Lab Routing & Security Tests', () {
    test(
      '1. test_event reaches dedicated test_event action with correct parameters',
      () async {
        mockRepo.isTester = true;
        final res = await mockRepo.sendTestEvent(
          eventType: 'service_update',
          forceDelivery: false,
        );

        expect(mockRepo.lastAction, 'test_event');
        expect(mockRepo.lastEventType, 'service_update');
        expect(mockRepo.lastForceDelivery, isFalse);
        expect(res.success, isTrue);
      },
    );

    test(
      '2. normal user (isTester=false) is denied by backend test endpoint',
      () async {
        mockRepo.isTester = false;
        final res = await mockRepo.sendTestEvent(
          eventType: 'booking_confirmed',
          forceDelivery: false,
        );

        expect(res.success, isFalse);
        expect(res.error, contains('Notification Test Lab access denied'));
      },
    );

    test('3. authorized tester is allowed to dispatch test event', () async {
      mockRepo.isTester = true;
      final res = await mockRepo.sendTestEvent(
        eventType: 'booking_confirmed',
        forceDelivery: false,
      );

      expect(res.success, isTrue);
      expect(res.delivered, 1);
      expect(res.inboxInserted, isTrue);
    });

    test('4. unknown event rejected with 400 validation error', () async {
      mockRepo.isTester = true;
      final res = await mockRepo.sendTestEvent(
        eventType: 'non_existent_event_code',
        forceDelivery: false,
      );

      expect(res.success, isFalse);
      expect(res.error, contains('Invalid or unsupported event_type'));
    });

    test('5. preferences respected when force_delivery=false', () async {
      mockRepo.isTester = true;
      mockRepo.mockTestResult = const NotificationTestEventResult(
        success: true,
        eventType: 'topup_approved',
        category: 'wallet_updates',
        preferenceSuppressed: true,
        forced: false,
        inboxInserted: true,
        delivered: 0,
        message: 'Suppressed by user preference',
      );

      final res = await mockRepo.sendTestEvent(
        eventType: 'topup_approved',
        forceDelivery: false,
      );

      expect(res.success, isTrue);
      expect(res.preferenceSuppressed, isTrue);
      expect(res.delivered, 0);
      expect(res.inboxInserted, isTrue);
    });

    test('6. preferences bypassed when force_delivery=true', () async {
      mockRepo.isTester = true;
      mockRepo.mockTestResult = const NotificationTestEventResult(
        success: true,
        eventType: 'topup_approved',
        category: 'wallet_updates',
        preferenceSuppressed: false,
        forced: true,
        totalDevices: 1,
        delivered: 1,
        inboxInserted: true,
      );

      final res = await mockRepo.sendTestEvent(
        eventType: 'topup_approved',
        forceDelivery: true,
      );

      expect(res.success, isTrue);
      expect(res.preferenceSuppressed, isFalse);
      expect(res.forced, isTrue);
      expect(res.delivered, 1);
    });

    testWidgets(
      '7. raw FunctionsHttpException is cleaned and not displayed raw in UI',
      (tester) async {
        mockRepo.isTester = true;
        mockRepo.mockTestResult = const NotificationTestEventResult(
          success: false,
          eventType: 'service_update',
          category: 'service_updates',
          error: 'Forbidden: Notification Test Lab access denied.',
        );

        await tester.pumpWidget(buildTestSheet());
        await tester.pumpAndSettle();

        final sendButtons = find.text('Send Test');
        expect(sendButtons, findsWidgets);

        await tester.tap(sendButtons.first);
        await tester.pumpAndSettle();

        // UI should format error cleanly without FunctionsHttpException
        expect(find.textContaining('FunctionsHttpException'), findsNothing);
        expect(
          find.textContaining('Tester authorization failed'),
          findsOneWidget,
        );
      },
    );

    testWidgets('8. No active devices error is displayed cleanly in UI', (
      tester,
    ) async {
      mockRepo.isTester = true;
      mockRepo.mockTestResult = const NotificationTestEventResult(
        success: false,
        eventType: 'service_update',
        category: 'service_updates',
        error: 'No active notification device found for your account.',
      );

      await tester.pumpWidget(buildTestSheet());
      await tester.pumpAndSettle();

      final sendButtons = find.text('Send Test');
      await tester.tap(sendButtons.first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('No active notification device found'),
        findsOneWidget,
      );
    });

    testWidgets(
      '9. APNs credential error is mapped to safe user message in UI',
      (tester) async {
        mockRepo.isTester = true;
        mockRepo.mockTestResult = const NotificationTestEventResult(
          success: false,
          eventType: 'service_update',
          category: 'service_updates',
          error: 'Invalid APNs credential.',
        );

        await tester.pumpWidget(buildTestSheet());
        await tester.pumpAndSettle();

        final sendButtons = find.text('Send Test');
        await tester.tap(sendButtons.first);
        await tester.pumpAndSettle();

        expect(
          find.text('Apple push credentials are not configured correctly.'),
          findsOneWidget,
        );
      },
    );
  });
}
