import 'package:equatable/equatable.dart';
import 'app_notification.dart';

enum NotificationPreferenceCategory {
  serviceUpdates('service_updates'),
  bookingUpdates('booking_updates'),
  walletUpdates('wallet_updates'),
  tripUpdates('trip_updates');

  final String key;
  const NotificationPreferenceCategory(this.key);

  static NotificationPreferenceCategory fromKey(String key) {
    switch (key) {
      case 'service_updates':
        return NotificationPreferenceCategory.serviceUpdates;
      case 'booking_updates':
        return NotificationPreferenceCategory.bookingUpdates;
      case 'wallet_updates':
        return NotificationPreferenceCategory.walletUpdates;
      case 'trip_updates':
        return NotificationPreferenceCategory.tripUpdates;
      default:
        return NotificationPreferenceCategory.serviceUpdates;
    }
  }

  /// Maps an event NotificationType to its associated push preference category.
  static NotificationPreferenceCategory fromNotificationType(NotificationType type) {
    switch (type) {
      case NotificationType.system:
      case NotificationType.generalAnnouncement:
      case NotificationType.serviceUpdate:
        return NotificationPreferenceCategory.serviceUpdates;
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingCancelled:
      case NotificationType.seatChanged:
        return NotificationPreferenceCategory.bookingUpdates;
      case NotificationType.topupApproved:
      case NotificationType.topupRejected:
      case NotificationType.walletCredit:
      case NotificationType.walletRefund:
        return NotificationPreferenceCategory.walletUpdates;
      case NotificationType.busApproaching:
      case NotificationType.busArrivedAtBoardingStop:
      case NotificationType.tripUpdate:
      case NotificationType.tripDelayed:
      case NotificationType.nextStopUpdate:
        return NotificationPreferenceCategory.tripUpdates;
      case NotificationType.unknown:
        return NotificationPreferenceCategory.serviceUpdates;
    }
  }

  /// Maps an event type string to its associated push preference category.
  static NotificationPreferenceCategory fromEventTypeString(String? eventType) {
    final type = NotificationType.fromString(eventType);
    return fromNotificationType(type);
  }
}

class NotificationPreferences extends Equatable {
  final bool allEnabled;
  final bool serviceUpdates;
  final bool bookingUpdates;
  final bool walletUpdates;
  final bool tripUpdates;
  final DateTime? updatedAt;

  const NotificationPreferences({
    this.allEnabled = true,
    this.serviceUpdates = true,
    this.bookingUpdates = true,
    this.walletUpdates = true,
    this.tripUpdates = true,
    this.updatedAt,
  });

  /// Evaluates whether push notifications are enabled for a specific category.
  bool isPushEnabledForCategory(NotificationPreferenceCategory category) {
    if (!allEnabled) return false;
    switch (category) {
      case NotificationPreferenceCategory.serviceUpdates:
        return serviceUpdates;
      case NotificationPreferenceCategory.bookingUpdates:
        return bookingUpdates;
      case NotificationPreferenceCategory.walletUpdates:
        return walletUpdates;
      case NotificationPreferenceCategory.tripUpdates:
        return tripUpdates;
    }
  }

  /// Alias for isPushEnabledForCategory
  bool isCategoryEnabled(NotificationPreferenceCategory category) =>
      isPushEnabledForCategory(category);

  /// Evaluates whether push notifications are enabled for an event NotificationType.
  bool isPushEnabledForType(NotificationType type) {
    final category = NotificationPreferenceCategory.fromNotificationType(type);
    return isPushEnabledForCategory(category);
  }

  NotificationPreferences copyWith({
    bool? allEnabled,
    bool? serviceUpdates,
    bool? bookingUpdates,
    bool? walletUpdates,
    bool? tripUpdates,
    DateTime? updatedAt,
  }) {
    return NotificationPreferences(
      allEnabled: allEnabled ?? this.allEnabled,
      serviceUpdates: serviceUpdates ?? this.serviceUpdates,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      walletUpdates: walletUpdates ?? this.walletUpdates,
      tripUpdates: tripUpdates ?? this.tripUpdates,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        allEnabled,
        serviceUpdates,
        bookingUpdates,
        walletUpdates,
        tripUpdates,
        updatedAt,
      ];
}
