import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_preferences.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';
import 'package:amomy_bus/features/notifications/domain/entities/self_test_result.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/pages/notifications_page.dart';
import 'package:amomy_bus/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amomy_bus/core/icons/app_icons.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _MockNotificationRepo implements NotificationRepository {
  List<AppNotification> notifications = [];
  int unread = 0;

  @override
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async => unread;

  @override
  Stream<AppNotification?> subscribeToNotificationUpdates() =>
      const Stream.empty();

  @override
  Future<bool> markAsRead(String notificationId) async {
    unread = 0;
    return true;
  }

  @override
  Future<int> markAllAsRead() async {
    final count = unread;
    unread = 0;
    return count;
  }

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
  late _MockNotificationRepo mockRepo;

  setUpAll(() {
    mockRepo = _MockNotificationRepo();
    if (!getIt.isRegistered<NotificationRepository>()) {
      getIt.registerSingleton<NotificationRepository>(mockRepo);
    }
  });

  Widget createWidgetUnderTest(Locale locale) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const NotificationsPage(),
    );
  }

  testWidgets('renders empty state when there are no notifications', (
    tester,
  ) async {
    mockRepo.notifications = [];
    mockRepo.unread = 0;

    await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('renders notification items with TODAY grouping', (tester) async {
    final now = DateTime.now();
    final earlier = now.subtract(const Duration(days: 2));

    mockRepo.notifications = [
      AppNotification(
        id: 'n1',
        userId: 'u1',
        type: NotificationType.bookingConfirmed,
        titleAr: 'تأكيد الحجز',
        bodyAr: 'تم حجز المقعد بنجاح.',
        titleEn: 'Booking Confirmed',
        bodyEn: 'Seat confirmed successfully.',
        createdAt: now,
      ),
      AppNotification(
        id: 'n2',
        userId: 'u1',
        type: NotificationType.topupApproved,
        titleAr: 'تم الشحن',
        bodyAr: 'تم إضافة الرصيد.',
        titleEn: 'Top-up Approved',
        bodyEn: 'Points added.',
        createdAt: earlier,
      ),
    ];
    mockRepo.unread = 1;

    await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsNWidgets(2));
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Top-up Approved'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);

    // Verify Debug action is NOT present on production NotificationsPage
    expect(find.text('Debug'), findsNothing);
  });

  testWidgets('does not show Mark all as read when unread count is zero', (
    tester,
  ) async {
    mockRepo.notifications = [
      AppNotification(
        id: 'n1',
        userId: 'u1',
        type: NotificationType.bookingConfirmed,
        titleAr: 'تأكيد الحجز',
        bodyAr: 'تم حجز المقعد بنجاح.',
        titleEn: 'Booking Confirmed',
        bodyEn: 'Seat confirmed successfully.',
        readAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ];
    mockRepo.unread = 0;

    await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Mark all as read'), findsNothing);
  });

  testWidgets(
    'renders points_adjusted notification with backend English title/body and wallet icon',
    (tester) async {
      mockRepo.notifications = [
        AppNotification(
          id: 'p1',
          userId: 'u1',
          type: NotificationType.pointsAdjusted,
          titleAr: 'تعديل الرصيد',
          bodyAr: 'تم إضافة 50 نقطة بواسطة الإدارة.',
          titleEn: 'Points Adjusted',
          bodyEn: '50 points were added to your account by admin.',
          createdAt: DateTime.now(),
        ),
      ];
      mockRepo.unread = 1;

      await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsOneWidget);
      expect(find.text('Points Adjusted'), findsOneWidget);
      expect(
        find.text('50 points were added to your account by admin.'),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.wallet), findsOneWidget);
    },
  );

  testWidgets(
    'renders points_adjusted notification with backend Arabic title/body and wallet icon',
    (tester) async {
      mockRepo.notifications = [
        AppNotification(
          id: 'p2',
          userId: 'u1',
          type: NotificationType.pointsAdjusted,
          titleAr: 'تعديل النقاط',
          bodyAr: 'تم خصم 20 نقطة لتسوية الحساب.',
          titleEn: 'Points Adjusted',
          bodyEn: '20 points deducted for account settlement.',
          createdAt: DateTime.now(),
        ),
      ];
      mockRepo.unread = 1;

      await tester.pumpWidget(createWidgetUnderTest(const Locale('ar')));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationTile), findsOneWidget);
      expect(find.text('تعديل النقاط'), findsOneWidget);
      expect(find.text('تم خصم 20 نقطة لتسوية الحساب.'), findsOneWidget);
      expect(find.byIcon(AppIcons.wallet), findsOneWidget);
    },
  );
}
