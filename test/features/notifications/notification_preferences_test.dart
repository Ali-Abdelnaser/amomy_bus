import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_event_catalog.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_preferences.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';
import 'package:amomy_bus/features/notifications/domain/entities/self_test_result.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:amomy_bus/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:amomy_bus/features/notifications/presentation/widgets/notification_test_lab_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockNotificationPreferencesRepo implements NotificationRepository {
  NotificationPreferences preferences = const NotificationPreferences(
    allEnabled: true,
    serviceUpdates: true,
    bookingUpdates: true,
    walletUpdates: true,
    tripUpdates: true,
  );
  int updateCount = 0;
  bool isTesterValue = false;
  String? lastTestEventType;
  bool? lastTestForceDelivery;

  @override
  Future<NotificationPreferences> getPreferences() async => preferences;

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences prefs) async {
    updateCount++;
    preferences = prefs;
    return preferences;
  }

  @override
  Future<bool> isNotificationTester() async => isTesterValue;

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) async {
    lastTestEventType = eventType;
    lastTestForceDelivery = forceDelivery;

    final catalogItem = NotificationEventCatalog.find(eventType);
    final categoryKey = catalogItem.category;

    if (!forceDelivery && !preferences.isCategoryEnabled(
        NotificationPreferenceCategory.fromEventTypeString(eventType))) {
      return NotificationTestEventResult(
        success: true,
        eventType: eventType,
        category: categoryKey.toDbKey(),
        preferenceSuppressed: true,
        forced: false,
        inboxInserted: true,
        message: 'Suppressed by preferences',
      );
    }

    return NotificationTestEventResult(
      success: true,
      eventType: eventType,
      category: categoryKey.toDbKey(),
      preferenceSuppressed: false,
      forced: forceDelivery,
      totalDevices: 1,
      delivered: 1,
      inboxInserted: true,
      message: 'Delivered',
    );
  }

  @override
  Future<List<AppNotification>> getNotifications({int limit = 50, int offset = 0}) async => [];

  @override
  Future<int> getUnreadCount() async => 0;

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
        message: 'Dispatched',
      );
}

void main() {
  group('Event to Category Mapping', () {
    test('maps notification types to correct preference categories', () {
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.system),
        NotificationPreferenceCategory.serviceUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.generalAnnouncement),
        NotificationPreferenceCategory.serviceUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.serviceUpdate),
        NotificationPreferenceCategory.serviceUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.bookingConfirmed),
        NotificationPreferenceCategory.bookingUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.bookingCancelled),
        NotificationPreferenceCategory.bookingUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.seatChanged),
        NotificationPreferenceCategory.bookingUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.topupApproved),
        NotificationPreferenceCategory.walletUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.topupRejected),
        NotificationPreferenceCategory.walletUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.walletCredit),
        NotificationPreferenceCategory.walletUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.walletRefund),
        NotificationPreferenceCategory.walletUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.busApproaching),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.busArrivedAtBoardingStop),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.tripUpdate),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.tripDelayed),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.nextStopUpdate),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromNotificationType(NotificationType.unknown),
        NotificationPreferenceCategory.serviceUpdates,
      );
    });

    test('maps event string keys to correct preference categories', () {
      expect(
        NotificationPreferenceCategory.fromEventTypeString('booking_confirmed'),
        NotificationPreferenceCategory.bookingUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromEventTypeString('topup_approved'),
        NotificationPreferenceCategory.walletUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromEventTypeString('bus_approaching'),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromEventTypeString('bus_arrived_at_boarding_stop'),
        NotificationPreferenceCategory.tripUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromEventTypeString('system'),
        NotificationPreferenceCategory.serviceUpdates,
      );
      expect(
        NotificationPreferenceCategory.fromEventTypeString('unrecognized_event'),
        NotificationPreferenceCategory.serviceUpdates,
      );
    });

    test('NotificationPreferences.isCategoryEnabled handles master toggle logic', () {
      const allOn = NotificationPreferences(
        allEnabled: true,
        serviceUpdates: true,
        bookingUpdates: false,
        walletUpdates: true,
        tripUpdates: true,
      );
      expect(allOn.isCategoryEnabled(NotificationPreferenceCategory.serviceUpdates), isTrue);
      expect(allOn.isCategoryEnabled(NotificationPreferenceCategory.bookingUpdates), isFalse);

      // When master is off, isCategoryEnabled returns false logically
      final masterOff = allOn.copyWith(allEnabled: false);
      expect(masterOff.isCategoryEnabled(NotificationPreferenceCategory.serviceUpdates), isFalse);
      expect(masterOff.isCategoryEnabled(NotificationPreferenceCategory.walletUpdates), isFalse);

      // But individual stored properties are preserved
      expect(masterOff.serviceUpdates, isTrue);
      expect(masterOff.bookingUpdates, isFalse);
      expect(masterOff.walletUpdates, isTrue);
    });
  });

  group('NotificationPreferencesCubit', () {
    late _MockNotificationPreferencesRepo mockRepo;
    late NotificationPreferencesCubit cubit;

    setUp(() {
      mockRepo = _MockNotificationPreferencesRepo();
      cubit = NotificationPreferencesCubit(repository: mockRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is NotificationPreferencesInitial', () {
      expect(cubit.state, const NotificationPreferencesInitial());
    });

    test('loadPreferences loads preferences and isTester flag', () async {
      mockRepo.isTesterValue = true;
      await cubit.loadPreferences();

      expect(cubit.state, isA<NotificationPreferencesLoaded>());
      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.allEnabled, isTrue);
      expect(loaded.preferences.bookingUpdates, isTrue);
      expect(loaded.isTester, isTrue);
    });

    test('toggleMaster retains child preferences and updates repository', () async {
      await cubit.loadPreferences();
      expect((cubit.state as NotificationPreferencesLoaded).preferences.allEnabled, isTrue);

      // Toggle off
      await cubit.toggleMaster(false);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.allEnabled, isFalse);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.bookingUpdates, isTrue);
      expect(mockRepo.preferences.allEnabled, isFalse);

      // Toggle back on
      await cubit.toggleMaster(true);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.allEnabled, isTrue);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.bookingUpdates, isTrue);
    });

    test('toggleCategory updates individual category preference', () async {
      await cubit.loadPreferences();

      await cubit.toggleCategory(NotificationPreferenceCategory.walletUpdates, false);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.walletUpdates, isFalse);
      expect(mockRepo.preferences.walletUpdates, isFalse);

      await cubit.toggleCategory(NotificationPreferenceCategory.walletUpdates, true);
      expect((cubit.state as NotificationPreferencesLoaded).preferences.walletUpdates, isTrue);
      expect(mockRepo.preferences.walletUpdates, isTrue);
    });
  });

  group('NotificationSettingsPage & Notification Test Lab Tests', () {
    late _MockNotificationPreferencesRepo mockRepo;

    setUpAll(() {
      mockRepo = _MockNotificationPreferencesRepo();
      if (getIt.isRegistered<NotificationRepository>()) {
        getIt.unregister<NotificationRepository>();
      }
      getIt.registerSingleton<NotificationRepository>(mockRepo);
    });

    Widget createWidgetUnderTest(Locale locale) {
      return MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const NotificationSettingsPage(),
      );
    }

    testWidgets('normal passenger (isTester=false) does NOT see Test Lab icon', (tester) async {
      mockRepo.isTesterValue = false;
      mockRepo.preferences = const NotificationPreferences(allEnabled: true);

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_test_lab_button')), findsNothing);
    });

    testWidgets('authorized tester (isTester=true) SEES Test Lab icon in AppBar', (tester) async {
      mockRepo.isTesterValue = true;
      mockRepo.preferences = const NotificationPreferences(allEnabled: true);

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notification_test_lab_button')), findsOneWidget);
    });

    testWidgets('tapping Test Lab icon opens NotificationTestLabSheet with events', (tester) async {
      mockRepo.isTesterValue = true;
      mockRepo.preferences = const NotificationPreferences(allEnabled: true);

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      // Tap Test Lab button
      await tester.tap(find.byKey(const Key('notification_test_lab_button')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTestLabSheet), findsOneWidget);
      expect(find.text('Notification Test Lab'), findsOneWidget);
      expect(find.text('Respect Preferences'), findsOneWidget);
      expect(find.text('Force Test Delivery'), findsOneWidget);
      expect(find.text('All (15)'), findsOneWidget);
    });

    testWidgets('sending test event in Respect Preferences mode handles preference suppression', (tester) async {
      mockRepo.isTesterValue = true;
      // Disable wallet updates
      mockRepo.preferences = const NotificationPreferences(
        allEnabled: true,
        walletUpdates: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_test_lab_button')));
      await tester.pumpAndSettle();

      // Filter to wallet
      await tester.tap(find.text('Wallet (4)'));
      await tester.pumpAndSettle();

      // Find topup_approved Send Test button
      final sendButtons = find.text('Send Test');
      expect(sendButtons, findsWidgets);

      await tester.tap(sendButtons.first);
      await tester.pumpAndSettle();

      expect(mockRepo.lastTestEventType, 'topup_approved');
      expect(mockRepo.lastTestForceDelivery, isFalse);
      expect(find.textContaining('Push suppressed by user preference toggle'), findsOneWidget);
    });

    testWidgets('switching to Force Test Delivery mode sends test with forced=true', (tester) async {
      mockRepo.isTesterValue = true;
      mockRepo.preferences = const NotificationPreferences(
        allEnabled: true,
        walletUpdates: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('notification_test_lab_button')));
      await tester.pumpAndSettle();

      // Tap Force Test Delivery mode
      await tester.tap(find.text('Force Test Delivery'));
      await tester.pumpAndSettle();

      // Filter to wallet
      await tester.tap(find.text('Wallet (4)'));
      await tester.pumpAndSettle();

      final sendButtons = find.text('Send Test');
      await tester.tap(sendButtons.first);
      await tester.pumpAndSettle();

      expect(mockRepo.lastTestForceDelivery, isTrue);
      expect(find.textContaining('Delivered (1/1 devices)'), findsOneWidget);
    });
  });
}
