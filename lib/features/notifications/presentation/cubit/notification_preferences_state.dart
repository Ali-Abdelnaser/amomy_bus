import 'package:equatable/equatable.dart';
import '../../domain/entities/notification_preferences.dart';

abstract class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState();

  @override
  List<Object?> get props => [];
}

class NotificationPreferencesInitial extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

class NotificationPreferencesLoading extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

class NotificationPreferencesLoaded extends NotificationPreferencesState {
  final NotificationPreferences preferences;
  final bool isSaving;
  final bool isOsPermissionAuthorized;
  final bool isOsPermissionDenied;
  final bool isTester;
  final String? errorMessage;

  const NotificationPreferencesLoaded({
    required this.preferences,
    this.isSaving = false,
    this.isOsPermissionAuthorized = true,
    this.isOsPermissionDenied = false,
    this.isTester = false,
    this.errorMessage,
  });

  NotificationPreferencesLoaded copyWith({
    NotificationPreferences? preferences,
    bool? isSaving,
    bool? isOsPermissionAuthorized,
    bool? isOsPermissionDenied,
    bool? isTester,
    String? errorMessage,
  }) {
    return NotificationPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      isSaving: isSaving ?? this.isSaving,
      isOsPermissionAuthorized:
          isOsPermissionAuthorized ?? this.isOsPermissionAuthorized,
      isOsPermissionDenied: isOsPermissionDenied ?? this.isOsPermissionDenied,
      isTester: isTester ?? this.isTester,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        preferences,
        isSaving,
        isOsPermissionAuthorized,
        isOsPermissionDenied,
        isTester,
        errorMessage,
      ];
}

class NotificationPreferencesError extends NotificationPreferencesState {
  final String message;

  const NotificationPreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}
