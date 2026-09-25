import 'package:equatable/equatable.dart';
import 'bus_telemetry.dart';

/// Live fleet bus representation from `get_passenger_fleet_tracking`
class FleetBus extends Equatable {
  final String busId;
  final String internalCode;
  final String? displayName;
  final String? plateNumber;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final int? heading;
  final DateTime? gpsRecordedAt;
  final DateTime? lastSyncedAt;
  final bool isValid;
  final bool hasLocation;
  final String? activeTripId;
  final String? direction;
  final String? serviceState;
  final String? currentStopId;
  final String? nextStopId;

  const FleetBus({
    required this.busId,
    required this.internalCode,
    this.displayName,
    this.plateNumber,
    this.latitude,
    this.longitude,
    this.speedKmh,
    this.heading,
    this.gpsRecordedAt,
    this.lastSyncedAt,
    this.isValid = false,
    this.hasLocation = false,
    this.activeTripId,
    this.direction,
    this.serviceState,
    this.currentStopId,
    this.nextStopId,
  });

  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      !latitude!.isNaN &&
      !longitude!.isNaN &&
      !latitude!.isInfinite &&
      !longitude!.isInfinite &&
      latitude! >= -90.0 &&
      latitude! <= 90.0 &&
      longitude! >= -180.0 &&
      longitude! <= 180.0 &&
      isValid &&
      hasLocation;

  bool get isStale {
    if (gpsRecordedAt == null) return true;
    final age = DateTime.now().toUtc().difference(gpsRecordedAt!).inSeconds;
    return age > 120;
  }

  bool get isOnline => hasValidCoordinates && !isStale;

  /// Safe passenger-facing bus label.
  /// Never exposes plate_number, internal_code, or device IDs.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return '';
  }

  BusTelemetry toBusTelemetry() {
    return BusTelemetry(
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      heading: heading ?? 0,
      speedKmh: speedKmh ?? 0.0,
      gpsRecordedAt: gpsRecordedAt ?? DateTime.now().toUtc(),
      isStale: isStale,
      activeTripId: activeTripId,
      serviceState: serviceState,
      currentStopId: currentStopId,
      nextStopId: nextStopId,
    );
  }

  factory FleetBus.fromJson(Map<String, dynamic> json) {
    final recordedRaw = json['gps_recorded_at'];
    final syncedRaw = json['last_synced_at'];
    return FleetBus(
      busId: json['bus_id']?.toString() ?? '',
      internalCode: json['internal_code']?.toString() ?? '',
      displayName: json['display_name']?.toString(),
      plateNumber: json['plate_number']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toInt(),
      gpsRecordedAt: recordedRaw != null
          ? DateTime.tryParse(recordedRaw.toString())?.toUtc()
          : null,
      lastSyncedAt: syncedRaw != null
          ? DateTime.tryParse(syncedRaw.toString())?.toUtc()
          : null,
      isValid: (json['is_valid'] as bool?) ?? false,
      hasLocation: (json['has_location'] as bool?) ?? false,
      activeTripId: json['active_trip_id']?.toString(),
      direction: json['direction']?.toString(),
      serviceState: json['service_state']?.toString(),
      currentStopId: json['current_stop_id']?.toString(),
      nextStopId: json['next_stop_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bus_id': busId,
    'internal_code': internalCode,
    'display_name': displayName,
    'plate_number': plateNumber,
    'latitude': latitude,
    'longitude': longitude,
    'speed_kmh': speedKmh,
    'heading': heading,
    'gps_recorded_at': gpsRecordedAt?.toIso8601String(),
    'last_synced_at': lastSyncedAt?.toIso8601String(),
    'is_valid': isValid,
    'has_location': hasLocation,
    'active_trip_id': activeTripId,
    'direction': direction,
    'service_state': serviceState,
    'current_stop_id': currentStopId,
    'next_stop_id': nextStopId,
  };

  @override
  List<Object?> get props => [
    busId,
    internalCode,
    displayName,
    plateNumber,
    latitude,
    longitude,
    speedKmh,
    heading,
    gpsRecordedAt,
    lastSyncedAt,
    isValid,
    hasLocation,
    activeTripId,
    direction,
    serviceState,
    currentStopId,
    nextStopId,
  ];
}
