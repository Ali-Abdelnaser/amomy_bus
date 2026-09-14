import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/pages/notifications_page.dart';
import 'package:amomy_bus/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockNotificationRepo implements NotificationRepository {
  List<AppNotification> notifications = [];
  int unread = 0;

  @override
  Future<List<AppNotification>> getNotifications({int limit = 50, int offset = 0}) async {
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async => unread;

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
  }) async =>
      true;

  @override
  Future<bool> deactivateDeviceToken(String token) async => true;

  @override
  Future<bool> sendSelfTestNotification() async => true;
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
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const NotificationsPage(),
    );
  }

  testWidgets('renders empty state when there are no notifications', (tester) async {
    mockRepo.notifications = [];
    mockRepo.unread = 0;

    await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('renders notification items and unread count', (tester) async {
    mockRepo.notifications = [
      AppNotification(
        id: 'n1',
        userId: 'u1',
        type: NotificationType.bookingConfirmed,
        titleAr: 'تأكيد الحجز',
        bodyAr: 'تم حجز المقعد بنجاح.',
        titleEn: 'Booking Confirmed',
        bodyEn: 'Seat confirmed successfully.',
        createdAt: DateTime.now(),
      ),
    ];
    mockRepo.unread = 1;

    await tester.pumpWidget(createWidgetUnderTest(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationTile), findsOneWidget);
    expect(find.text('Booking Confirmed'), findsOneWidget);
    expect(find.text('Seat confirmed successfully.'), findsOneWidget);
    expect(find.text('Mark all as read'), findsOneWidget);
  });
}
