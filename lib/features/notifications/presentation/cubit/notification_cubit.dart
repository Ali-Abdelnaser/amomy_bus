import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit({required this.repository}) : super(const NotificationInitial());

  Future<void> loadNotifications({bool isRefresh = false}) async {
    final currentState = state;
    if (currentState is NotificationLoaded && isRefresh) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const NotificationLoading());
    }

    try {
      final notifications = await repository.getNotifications();
      final unreadCount = await repository.getUnreadCount();

      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
        isRefreshing: false,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    // Optimistically update local state
    final updatedList = currentState.notifications.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnreadCount = updatedList.where((n) => !n.isRead).length;

    emit(currentState.copyWith(
      notifications: updatedList,
      unreadCount: newUnreadCount,
    ));

    try {
      await repository.markAsRead(notificationId);
    } catch (_) {
      // Revert if needed or silent fail
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final now = DateTime.now();
    final updatedList = currentState.notifications.map((n) {
      return n.isRead ? n : n.copyWith(readAt: now);
    }).toList();

    emit(currentState.copyWith(
      notifications: updatedList,
      unreadCount: 0,
    ));

    try {
      await repository.markAllAsRead();
    } catch (_) {}
  }

  Future<bool> sendSelfTestPush() async {
    try {
      final success = await repository.sendSelfTestNotification();
      if (success) {
        await loadNotifications(isRefresh: true);
      }
      return success;
    } catch (_) {
      return false;
    }
  }
}
