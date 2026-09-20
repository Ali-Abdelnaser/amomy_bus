import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../../../../core/error/app_error_mapper.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  final NotificationRepository repository;
  final NotificationService? notificationService;
  final FirebaseMessaging? messaging;

  NotificationPreferencesCubit({
    required this.repository,
    this.notificationService,
    this.messaging,
  }) : super(const NotificationPreferencesInitial());

  FirebaseMessaging? get _safeMessaging {
    if (messaging != null) return messaging;
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPreferences() async {
    emit(const NotificationPreferencesLoading());
    try {
      final prefs = await repository.getPreferences();
      final osStatus = await _checkOsPermissionStatus();
      final isTester = await repository.isNotificationTester();

      emit(
        NotificationPreferencesLoaded(
          preferences: prefs,
          isOsPermissionAuthorized: osStatus.$1,
          isOsPermissionDenied: osStatus.$2,
          isTester: isTester,
        ),
      );
    } catch (e) {
      emit(NotificationPreferencesError(AppErrorMapper.mapToString(e)));
    }
  }

  Future<(bool isAuthorized, bool isDenied)> _checkOsPermissionStatus() async {
    try {
      final messaging = _safeMessaging;
      if (messaging == null) return (true, false);
      final settings = await messaging.getNotificationSettings();
      final isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      final isDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;
      return (isAuthorized, isDenied);
    } catch (_) {
      return (true, false);
    }
  }

  Future<void> refreshOsPermissionStatus() async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    final osStatus = await _checkOsPermissionStatus();
    emit(
      currentState.copyWith(
        isOsPermissionAuthorized: osStatus.$1,
        isOsPermissionDenied: osStatus.$2,
      ),
    );
  }

  Future<void> toggleMaster(bool enabled) async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    final updatedPrefs = currentState.preferences.copyWith(allEnabled: enabled);
    emit(currentState.copyWith(preferences: updatedPrefs, isSaving: true));

    try {
      final saved = await repository.updatePreferences(updatedPrefs);
      emit(currentState.copyWith(preferences: saved, isSaving: false));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationPreferencesCubit] toggleMaster error: $e');
      }
      emit(currentState.copyWith(isSaving: false));
    }
  }

  Future<void> toggleCategory(
    NotificationPreferenceCategory category,
    bool enabled,
  ) async {
    final currentState = state;
    if (currentState is! NotificationPreferencesLoaded) return;

    NotificationPreferences updatedPrefs;
    switch (category) {
      case NotificationPreferenceCategory.serviceUpdates:
        updatedPrefs = currentState.preferences.copyWith(
          serviceUpdates: enabled,
        );
        break;
      case NotificationPreferenceCategory.bookingUpdates:
        updatedPrefs = currentState.preferences.copyWith(
          bookingUpdates: enabled,
        );
        break;
      case NotificationPreferenceCategory.walletUpdates:
        updatedPrefs = currentState.preferences.copyWith(
          walletUpdates: enabled,
        );
        break;
      case NotificationPreferenceCategory.tripUpdates:
        updatedPrefs = currentState.preferences.copyWith(tripUpdates: enabled);
        break;
    }

    emit(currentState.copyWith(preferences: updatedPrefs, isSaving: true));

    try {
      final saved = await repository.updatePreferences(updatedPrefs);
      emit(currentState.copyWith(preferences: saved, isSaving: false));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationPreferencesCubit] toggleCategory error: $e');
      }
      emit(currentState.copyWith(isSaving: false));
    }
  }

  Future<void> requestDevicePermission() async {
    if (notificationService != null) {
      await notificationService!.requestPermission(isManual: true);
    } else {
      await _safeMessaging?.requestPermission();
    }
    await refreshOsPermissionStatus();
  }
}
