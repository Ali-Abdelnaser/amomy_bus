import '../../domain/entities/notification_preferences.dart';

class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    super.allEnabled = true,
    super.serviceUpdates = true,
    super.bookingUpdates = true,
    super.walletUpdates = true,
    super.tripUpdates = true,
    super.updatedAt,
  });

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      allEnabled: json['all_enabled'] as bool? ?? true,
      serviceUpdates: json['service_updates'] as bool? ?? true,
      bookingUpdates: json['booking_updates'] as bool? ?? true,
      walletUpdates: json['wallet_updates'] as bool? ?? true,
      tripUpdates: json['trip_updates'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all_enabled': allEnabled,
      'service_updates': serviceUpdates,
      'booking_updates': bookingUpdates,
      'wallet_updates': walletUpdates,
      'trip_updates': tripUpdates,
    };
  }

  factory NotificationPreferencesModel.fromEntity(NotificationPreferences entity) {
    return NotificationPreferencesModel(
      allEnabled: entity.allEnabled,
      serviceUpdates: entity.serviceUpdates,
      bookingUpdates: entity.bookingUpdates,
      walletUpdates: entity.walletUpdates,
      tripUpdates: entity.tripUpdates,
      updatedAt: entity.updatedAt,
    );
  }
}
