import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_preferences.dart';
import 'package:amomy_bus/features/notifications/domain/entities/notification_test_event_result.dart';
import 'package:amomy_bus/features/notifications/domain/entities/self_test_result.dart';
import 'package:amomy_bus/features/notifications/domain/repositories/notification_repository.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:amomy_bus/features/notifications/presentation/cubit/notification_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeNotificationRepository implements NotificationRepository {
  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool selfTestSuccess = true;
  String? registeredToken;
  String? deactivatedToken;

  @override
  Future<List<AppNotification>> getNotifications({int limit = 50, int offset = 0}) async {
    return notifications;
  }

  @override
  Future<int> getUnreadCount() async {
    return unreadCount;
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    notifications = notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();
    unreadCount = notifications.where((n) => !n.isRead).length;
    return true;
  }

  @override
  Future<int> markAllAsRead() async {
    final count = notifications.where((n) => !n.isRead).length;
    notifications = notifications.map((n) => n.copyWith(readAt: DateTime.now())).toList();
    unreadCount = 0;
    return count;
  }

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
  Future<bool> deactivateDeviceToken(String token) async {
    deactivatedToken = token;
    return true;
  }

  @override
  Future<SelfTestResult> sendSelfTestNotification({int? delaySeconds}) async {
    if (selfTestSuccess) {
      final newNotif = AppNotification(
        id: 'test-1',
        userId: 'u1',
        type: NotificationType.system,
        titleAr: 'اختبار',
        bodyAr: 'نجح الاختبار',
        titleEn: 'Test',
        bodyEn: 'Test succeeded',
        createdAt: DateTime.now(),
      );
      notifications = [newNotif, ...notifications];
      unreadCount++;
      return const SelfTestResult(
        success: true,
        requestAccepted: true,
        totalDevices: 1,
        delivered: 1,
        message: 'Delivered',
      );
    }
    return SelfTestResult.failure('Failed');
  }

  @override
  Future<bool> isNotificationTester() async => false;

  @override
  Future<NotificationTestEventResult> sendTestEvent({
    required String eventType,
    bool forceDelivery = false,
    Map<String, dynamic>? customData,
    int? delaySeconds,
  }) async {
    return const NotificationTestEventResult(
      success: true,
      eventType: 'test',
      category: 'service_updates',
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    return const NotificationPreferences();
  }

  @override
  Future<NotificationPreferences> updatePreferences(NotificationPreferences preferences) async {
    return preferences;
  }
}

void main() {
  late _FakeNotificationRepository fakeRepo;
  late NotificationCubit cubit;

  setUp(() {
    fakeRepo = _FakeNotificationRepository();
    cubit = NotificationCubit(repository: fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is NotificationInitial', () {
    expect(cubit.state, const NotificationInitial());
  });

  test('loadNotifications emits loading then loaded with notifications', () async {
    final notif = AppNotification(
      id: 'n1',
      userId: 'u1',
      type: NotificationType.system,
      titleAr: 'تنبيه',
      bodyAr: 'مرحبا',
      titleEn: 'Alert',
      bodyEn: 'Hello',
      createdAt: DateTime.now(),
    );
    fakeRepo.notifications = [notif];
    fakeRepo.unreadCount = 1;

    expectLater(
      cubit.stream,
      emitsInOrder([
        const NotificationLoading(),
        NotificationLoaded(
          notifications: [notif],
          unreadCount: 1,
          isRefreshing: false,
        ),
      ]),
    );

    await cubit.loadNotifications();
  });

  test('markAsRead updates state optimistically', () async {
    final notif = AppNotification(
      id: 'n1',
      userId: 'u1',
      type: NotificationType.system,
      titleAr: 'تنبيه',
      bodyAr: 'مرحبا',
      titleEn: 'Alert',
      bodyEn: 'Hello',
      createdAt: DateTime.now(),
    );
    fakeRepo.notifications = [notif];
    fakeRepo.unreadCount = 1;

    await cubit.loadNotifications();
    expect(cubit.state, isA<NotificationLoaded>());

    await cubit.markAsRead('n1');

    final state = cubit.state as NotificationLoaded;
    expect(state.notifications.first.isRead, isTrue);
    expect(state.unreadCount, 0);
  });

  test('markAllAsRead marks all notifications as read', () async {
    final notif1 = AppNotification(
      id: 'n1',
      userId: 'u1',
      type: NotificationType.system,
      titleAr: 'تنبيه 1',
      bodyAr: 'مرحبا 1',
      titleEn: 'Alert 1',
      bodyEn: 'Hello 1',
      createdAt: DateTime.now(),
    );
    final notif2 = AppNotification(
      id: 'n2',
      userId: 'u1',
      type: NotificationType.bookingConfirmed,
      titleAr: 'تنبيه 2',
      bodyAr: 'مرحبا 2',
      titleEn: 'Alert 2',
      bodyEn: 'Hello 2',
      createdAt: DateTime.now(),
    );

    fakeRepo.notifications = [notif1, notif2];
    fakeRepo.unreadCount = 2;

    await cubit.loadNotifications();
    await cubit.markAllAsRead();

    final state = cubit.state as NotificationLoaded;
    expect(state.unreadCount, 0);
    expect(state.notifications.every((n) => n.isRead), isTrue);
  });

  test('sendSelfTestPush reloads notifications on success', () async {
    final res = await cubit.sendSelfTestPush();
    expect(res.success, isTrue);

    final state = cubit.state as NotificationLoaded;
    expect(state.notifications, isNotEmpty);
    expect(state.notifications.first.titleEn, 'Test');
  });
}
