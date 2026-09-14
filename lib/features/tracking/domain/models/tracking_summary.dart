import 'package:equatable/equatable.dart';
import 'bus_stop_model.dart';
import 'bus_telemetry.dart';
import 'live_tracking_status.dart';

/// Complete tracking context and backend contract for AMOMY Live Bus.
class TrackingSummary extends Equatable {
  final LiveTrackingStatus status;
  final bool isInServiceWindow;
  final String serviceWindow; // 'morning' | 'afternoon' | 'offline'
  final String cairoTime;
  final String cairoDate;
  final TrackingDirection activeDirection;
  final String? activeRouteId;
  final String? activeRouteNameAr;
  final String? activeRouteNameEn;
  final String? activeRunTime; // e.g. "08:00", "09:00"

  // Offline next window info
  final String? nextWindowStartTime;
  final bool nextWindowIsTomorrow;
  final String? nextWindowMessageAr;
  final String? nextWindowMessageEn;

  // Telemetry & Route
  final BusTelemetry? busLocation;
  final int stopsCount;
  final int stopsWithCoordsCount;
  final bool hasStopCoordinates;
  // Authoritative Trip & Run Identity
  final String? activeTripId;
  final String serviceState; // 'in_service' | 'between_runs' | 'offline' | 'stale'
  final String progressState; // 'idle' | 'approaching' | 'at_stop' | 'departed' | 'in_transit' | 'between_runs' | 'coordinates_unavailable' | 'offline'
  final BusStopModel? currentStop;
  final BusStopModel? nextStop;
  final String? currentStopId;
  final String? nextStopId;

  final List<BusStopModel> routeStops;
  // Passenger target
  final BusStopModel? passengerTargetStop;
  final String? passengerTargetSource; // 'booking' | 'preference'
  final bool approachAlertsEnabled;
  final bool isQaPreviewActive;

  const TrackingSummary({
    required this.status,
    required this.isInServiceWindow,
    required this.serviceWindow,
    required this.cairoTime,
    required this.cairoDate,
    required this.activeDirection,
    this.activeRouteId,
    this.activeRouteNameAr,
    this.activeRouteNameEn,
    this.activeRunTime,
    this.activeTripId,
    this.serviceState = 'offline',
    this.progressState = 'idle',
    this.currentStop,
    this.nextStop,
    this.currentStopId,
    this.nextStopId,
    this.nextWindowStartTime,
    this.nextWindowIsTomorrow = false,
    this.nextWindowMessageAr,
    this.nextWindowMessageEn,
    this.busLocation,
    this.stopsCount = 34,
    this.stopsWithCoordsCount = 0,
    this.hasStopCoordinates = false,
    this.routeStops = const [],
    this.passengerTargetStop,
    this.passengerTargetSource,
    this.approachAlertsEnabled = true,
    this.isQaPreviewActive = false,
  });

  String localizedActiveRouteName(String locale) {
    if (locale.startsWith('ar')) {
      return activeRouteNameAr ?? 'كوبرى عزت - بوابة توشكى';
    }
    return activeRouteNameEn ?? 'Ezzat Bridge - Toshka Gate';
  }

  String localizedNextWindowMessage(String locale) {
    if (locale.startsWith('ar')) {
      return nextWindowMessageAr ?? 'يستأنف تتبع الحافلة الساعة 08:00 صباحاً';
    }
    return nextWindowMessageEn ?? 'Bus tracking resumes at 08:00 AM';
  }

  TrackingSummary copyWith({
    LiveTrackingStatus? status,
    bool? isInServiceWindow,
    String? serviceWindow,
    String? cairoTime,
    String? cairoDate,
    TrackingDirection? activeDirection,
    String? activeRouteId,
    String? activeRouteNameAr,
    String? activeRouteNameEn,
    String? activeRunTime,
    String? activeTripId,
    String? serviceState,
    String? progressState,
    BusStopModel? currentStop,
    BusStopModel? nextStop,
    String? currentStopId,
    String? nextStopId,
    String? nextWindowStartTime,
    bool? nextWindowIsTomorrow,
    String? nextWindowMessageAr,
    String? nextWindowMessageEn,
    BusTelemetry? busLocation,
    int? stopsCount,
    int? stopsWithCoordsCount,
    bool? hasStopCoordinates,
    List<BusStopModel>? routeStops,
    BusStopModel? passengerTargetStop,
    String? passengerTargetSource,
    bool? approachAlertsEnabled,
    bool? isQaPreviewActive,
  }) {
    return TrackingSummary(
      status: status ?? this.status,
      isInServiceWindow: isInServiceWindow ?? this.isInServiceWindow,
      serviceWindow: serviceWindow ?? this.serviceWindow,
      cairoTime: cairoTime ?? this.cairoTime,
      cairoDate: cairoDate ?? this.cairoDate,
      activeDirection: activeDirection ?? this.activeDirection,
      activeRouteId: activeRouteId ?? this.activeRouteId,
      activeRouteNameAr: activeRouteNameAr ?? this.activeRouteNameAr,
      activeRouteNameEn: activeRouteNameEn ?? this.activeRouteNameEn,
      activeRunTime: activeRunTime ?? this.activeRunTime,
      activeTripId: activeTripId ?? this.activeTripId,
      serviceState: serviceState ?? this.serviceState,
      progressState: progressState ?? this.progressState,
      currentStop: currentStop ?? this.currentStop,
      nextStop: nextStop ?? this.nextStop,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
      nextWindowStartTime: nextWindowStartTime ?? this.nextWindowStartTime,
      nextWindowIsTomorrow: nextWindowIsTomorrow ?? this.nextWindowIsTomorrow,
      nextWindowMessageAr: nextWindowMessageAr ?? this.nextWindowMessageAr,
      nextWindowMessageEn: nextWindowMessageEn ?? this.nextWindowMessageEn,
      busLocation: busLocation ?? this.busLocation,
      stopsCount: stopsCount ?? this.stopsCount,
      stopsWithCoordsCount: stopsWithCoordsCount ?? this.stopsWithCoordsCount,
      hasStopCoordinates: hasStopCoordinates ?? this.hasStopCoordinates,
      routeStops: routeStops ?? this.routeStops,
      passengerTargetStop: passengerTargetStop ?? this.passengerTargetStop,
      passengerTargetSource: passengerTargetSource ?? this.passengerTargetSource,
      approachAlertsEnabled: approachAlertsEnabled ?? this.approachAlertsEnabled,
      isQaPreviewActive: isQaPreviewActive ?? this.isQaPreviewActive,
    );
  }

  factory TrackingSummary.fromJson(Map<String, dynamic> json) {
    final serviceStateStr = (json['service_state'] as String?)?.toLowerCase();
    final statusStr = (json['tracking_status'] as String?)?.toLowerCase() ?? 'offline';
    final isQaPreview = (json['is_qa_preview_active'] as bool?) ?? false;

    final LiveTrackingStatus status;
    if (isQaPreview) {
      status = LiveTrackingStatus.qaPreview;
    } else if (serviceStateStr == 'between_runs') {
      status = LiveTrackingStatus.betweenRuns;
    } else if (statusStr == 'online') {
      status = LiveTrackingStatus.online;
    } else if (statusStr == 'stale') {
      status = LiveTrackingStatus.stale;
    } else {
      status = LiveTrackingStatus.offline;
    }

    final nextWin = json['next_window'] as Map<String, dynamic>?;
    final busLocJson = json['bus_location'] as Map<String, dynamic>?;
    final stopsRaw = json['route_stops'] as List<dynamic>? ?? [];
    final targetRaw = json['passenger_target'] as Map<String, dynamic>?;
    final currentStopRaw = json['current_stop'] as Map<String, dynamic>?;
    final nextStopRaw = json['next_stop'] as Map<String, dynamic>?;

    return TrackingSummary(
      status: status,
      isInServiceWindow: (json['is_in_service_window'] as bool?) ?? false,
      serviceWindow: (json['service_window'] as String?) ?? 'offline',
      cairoTime: (json['cairo_time'] as String?) ?? '',
      cairoDate: (json['cairo_date'] as String?) ?? '',
      activeDirection: TrackingDirection.fromString(json['active_direction'] as String?),
      activeRouteId: json['active_route_id'] as String?,
      activeRouteNameAr: json['active_route_name_ar'] as String?,
      activeRouteNameEn: json['active_route_name_en'] as String?,
      activeRunTime: json['active_run_time'] as String?,
      activeTripId: json['active_trip_id'] as String?,
      serviceState: (json['service_state'] as String?) ?? 'offline',
      progressState: (json['progress_state'] as String?) ?? 'idle',
      currentStop: currentStopRaw != null ? BusStopModel.fromJson(currentStopRaw) : null,
      nextStop: nextStopRaw != null ? BusStopModel.fromJson(nextStopRaw) : null,
      currentStopId: json['current_stop_id'] as String?,
      nextStopId: json['next_stop_id'] as String?,
      nextWindowStartTime: nextWin?['start_time'] as String?,
      nextWindowIsTomorrow: (nextWin?['is_tomorrow'] as bool?) ?? false,
      nextWindowMessageAr: nextWin?['message_ar'] as String?,
      nextWindowMessageEn: nextWin?['message_en'] as String?,
      busLocation: busLocJson != null ? BusTelemetry.fromJson(busLocJson) : null,
      stopsCount: (json['stops_count'] as num?)?.toInt() ?? 34,
      stopsWithCoordsCount: (json['stops_with_coords_count'] as num?)?.toInt() ?? 0,
      hasStopCoordinates: (json['has_stop_coordinates'] as bool?) ?? false,
      routeStops: stopsRaw.map((s) => BusStopModel.fromJson(s as Map<String, dynamic>)).toList(),
      passengerTargetStop: targetRaw != null ? BusStopModel.fromJson(targetRaw) : null,
      passengerTargetSource: targetRaw?['source'] as String?,
      approachAlertsEnabled: (json['approach_alerts_enabled'] as bool?) ?? true,
      isQaPreviewActive: isQaPreview,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isInServiceWindow,
        serviceWindow,
        cairoTime,
        cairoDate,
        activeDirection,
        activeRouteId,
        activeRouteNameAr,
        activeRouteNameEn,
        activeRunTime,
        activeTripId,
        serviceState,
        progressState,
        currentStop,
        nextStop,
        currentStopId,
        nextStopId,
        nextWindowStartTime,
        nextWindowIsTomorrow,
        nextWindowMessageAr,
        nextWindowMessageEn,
        busLocation,
        stopsCount,
        stopsWithCoordsCount,
        hasStopCoordinates,
        routeStops,
        passengerTargetStop,
        passengerTargetSource,
        approachAlertsEnabled,
        isQaPreviewActive,
      ];
}
