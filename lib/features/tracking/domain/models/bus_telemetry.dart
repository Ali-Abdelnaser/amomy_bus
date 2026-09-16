import 'package:equatable/equatable.dart';

/// Live physical bus location telemetry ingested from external GPS hardware tracker.
class BusTelemetry extends Equatable {
  final double latitude;
  final double longitude;
  final int heading;
  final double speedKmh;
  final DateTime gpsRecordedAt;
  final bool isStale;
  final int ageSeconds;
  final String? activeTripId;
  final String? serviceRunTime;
  final String? serviceState;
  final String? progressState;
  final String? currentStopId;
  final String? nextStopId;
  final int? currentStopOrder;
  final int? nextStopOrder;
  final String? source;

  const BusTelemetry({
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.speedKmh = 0.0,
    required this.gpsRecordedAt,
    this.isStale = false,
    this.ageSeconds = 0,
    this.activeTripId,
    this.serviceRunTime,
    this.serviceState,
    this.progressState,
    this.currentStopId,
    this.nextStopId,
    this.currentStopOrder,
    this.nextStopOrder,
    this.source,
  });

  bool get isMoving => speedKmh > 2.0;

  bool get hasValidCoordinates =>
      !latitude.isNaN &&
      !longitude.isNaN &&
      !latitude.isInfinite &&
      !longitude.isInfinite &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;

  BusTelemetry copyWith({
    double? latitude,
    double? longitude,
    int? heading,
    double? speedKmh,
    DateTime? gpsRecordedAt,
    bool? isStale,
    int? ageSeconds,
    String? activeTripId,
    String? serviceRunTime,
    String? serviceState,
    String? progressState,
    String? currentStopId,
    String? nextStopId,
    int? currentStopOrder,
    int? nextStopOrder,
    String? source,
  }) {
    return BusTelemetry(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      gpsRecordedAt: gpsRecordedAt ?? this.gpsRecordedAt,
      isStale: isStale ?? this.isStale,
      ageSeconds: ageSeconds ?? this.ageSeconds,
      activeTripId: activeTripId ?? this.activeTripId,
      serviceRunTime: serviceRunTime ?? this.serviceRunTime,
      serviceState: serviceState ?? this.serviceState,
      progressState: progressState ?? this.progressState,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
      currentStopOrder: currentStopOrder ?? this.currentStopOrder,
      nextStopOrder: nextStopOrder ?? this.nextStopOrder,
      source: source ?? this.source,
    );
  }

  factory BusTelemetry.fromJson(Map<String, dynamic> json) {
    final recordedAtRaw = json['gps_recorded_at'] ?? json['recorded_at'];
    final recordedAt = recordedAtRaw != null
        ? DateTime.tryParse(recordedAtRaw.toString())?.toUtc() ??
              DateTime.now().toUtc()
        : DateTime.now().toUtc();

    final age =
        (json['age_seconds'] as num?)?.toInt() ??
        DateTime.now().toUtc().difference(recordedAt).inSeconds;

    return BusTelemetry(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      heading: (json['heading'] as num?)?.toInt() ?? 0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      gpsRecordedAt: recordedAt,
      isStale: (json['is_stale'] as bool?) ?? (age > 120),
      ageSeconds: age,
      activeTripId: json['active_trip_id'] as String?,
      serviceRunTime: json['service_run_time'] as String?,
      serviceState: json['service_state'] as String?,
      progressState: json['progress_state'] as String?,
      currentStopId: json['current_stop_id'] as String?,
      nextStopId: json['next_stop_id'] as String?,
      currentStopOrder: (json['current_stop_order'] as num?)?.toInt(),
      nextStopOrder: (json['next_stop_order'] as num?)?.toInt(),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'speed_kmh': speedKmh,
    'gps_recorded_at': gpsRecordedAt.toIso8601String(),
    'is_stale': isStale,
    'age_seconds': ageSeconds,
    'active_trip_id': activeTripId,
    'service_run_time': serviceRunTime,
    'service_state': serviceState,
    'progress_state': progressState,
    'current_stop_id': currentStopId,
    'next_stop_id': nextStopId,
    'current_stop_order': currentStopOrder,
    'next_stop_order': nextStopOrder,
    'source': source,
  };

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    heading,
    speedKmh,
    gpsRecordedAt,
    isStale,
    ageSeconds,
    activeTripId,
    serviceRunTime,
    serviceState,
    progressState,
    currentStopId,
    nextStopId,
    currentStopOrder,
    nextStopOrder,
    source,
  ];
}
