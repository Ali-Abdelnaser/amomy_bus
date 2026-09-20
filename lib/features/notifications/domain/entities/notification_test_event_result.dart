import 'package:equatable/equatable.dart';

/// Result details from dispatching a simulated event in the Notification Test Lab.
class NotificationTestEventResult extends Equatable {
  final bool success;
  final String eventType;
  final String category;
  final bool preferenceSuppressed;
  final bool forced;
  final int totalDevices;
  final int delivered;
  final int fcmFailures;
  final bool inboxInserted;
  final String? message;
  final String? error;

  const NotificationTestEventResult({
    required this.success,
    required this.eventType,
    required this.category,
    this.preferenceSuppressed = false,
    this.forced = false,
    this.totalDevices = 0,
    this.delivered = 0,
    this.fcmFailures = 0,
    this.inboxInserted = false,
    this.message,
    this.error,
  });

  factory NotificationTestEventResult.fromJson(
    Map<String, dynamic> json, [
    int? statusCode,
  ]) {
    final success = json['success'] == true;
    final eventType = json['event_type']?.toString() ?? 'unknown';
    final category = json['category']?.toString() ?? 'general';
    final preferenceSuppressed = json['preference_suppressed'] == true;
    final forced = json['forced'] == true;
    final totalDevices = (json['total_devices'] as num?)?.toInt() ?? 0;
    final delivered = (json['delivered'] as num?)?.toInt() ?? 0;
    final fcmFailures = (json['fcm_failures'] as num?)?.toInt() ?? 0;
    final inboxInserted = json['notification_inbox_inserted'] == true;
    final message = json['message']?.toString();
    final error = json['error']?.toString();

    return NotificationTestEventResult(
      success: success,
      eventType: eventType,
      category: category,
      preferenceSuppressed: preferenceSuppressed,
      forced: forced,
      totalDevices: totalDevices,
      delivered: delivered,
      fcmFailures: fcmFailures,
      inboxInserted: inboxInserted,
      message: message,
      error: error,
    );
  }

  factory NotificationTestEventResult.failure(
    String error, {
    String eventType = 'unknown',
  }) {
    return NotificationTestEventResult(
      success: false,
      eventType: eventType,
      category: 'unknown',
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    success,
    eventType,
    category,
    preferenceSuppressed,
    forced,
    totalDevices,
    delivered,
    fcmFailures,
    inboxInserted,
    message,
    error,
  ];
}
