import 'package:equatable/equatable.dart';

class SelfTestResult extends Equatable {
  final bool success;
  final bool requestAccepted;
  final int totalDevices;
  final int delivered;
  final bool fcmSendAttempted;
  final int fcmSuccesses;
  final int fcmFailures;
  final bool notificationInboxInserted;
  final String message;
  final String? error;
  final Map<String, dynamic>? rawResponse;

  const SelfTestResult({
    required this.success,
    this.requestAccepted = false,
    this.totalDevices = 0,
    this.delivered = 0,
    this.fcmSendAttempted = false,
    this.fcmSuccesses = 0,
    this.fcmFailures = 0,
    this.notificationInboxInserted = false,
    required this.message,
    this.error,
    this.rawResponse,
  });

  factory SelfTestResult.fromJson(Map<String, dynamic> json, int statusCode) {
    final success = json['success'] == true;
    final totalDevices = (json['total_devices'] as num?)?.toInt() ?? 0;
    final delivered = (json['delivered'] as num?)?.toInt() ?? 0;
    final fcmSuccesses = (json['fcm_successes'] as num?)?.toInt() ?? delivered;
    final fcmFailures =
        (json['fcm_failures'] as num?)?.toInt() ?? (totalDevices - delivered);
    final fcmAttempted = json['fcm_send_attempted'] == true || totalDevices > 0;
    final inboxInserted =
        json['notification_inbox_inserted'] == true ||
        json['inbox_inserted'] == true;
    final message =
        json['message']?.toString() ?? (success ? 'Push sent' : 'Push failed');
    final error = json['error']?.toString();

    return SelfTestResult(
      success: success,
      requestAccepted: statusCode >= 200 && statusCode < 300,
      totalDevices: totalDevices,
      delivered: delivered,
      fcmSendAttempted: fcmAttempted,
      fcmSuccesses: fcmSuccesses,
      fcmFailures: fcmFailures,
      notificationInboxInserted: inboxInserted,
      message: message,
      error: error,
      rawResponse: json,
    );
  }

  factory SelfTestResult.failure(String error) {
    return SelfTestResult(
      success: false,
      requestAccepted: false,
      message: error,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    success,
    requestAccepted,
    totalDevices,
    delivered,
    fcmSendAttempted,
    fcmSuccesses,
    fcmFailures,
    notificationInboxInserted,
    message,
    error,
  ];
}
