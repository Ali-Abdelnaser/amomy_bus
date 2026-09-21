import 'package:equatable/equatable.dart';
import 'bus_stop_model.dart';
import 'bus_telemetry.dart';
import 'live_tracking_status.dart';

/// Complete tracking context and backend contract for AMOMY Live Bus.
class TrackingSummary extends Equatable {
  final LiveTrackingStatus status;
  final TrackingPhase trackingPhase;
  final bool trackingEnabled;
  final String? tripStatus;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? gpsAgeSeconds;
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
  final String
  serviceState; // 'in_service' | 'between_runs' | 'offline' | 'stale'
  final String
  progressState; // 'idle' | 'approaching' | 'at_stop' | 'departed' | 'in_transit' | 'between_runs' | 'coordinates_unavailable' | 'offline'
  final BusStopModel? currentStop;
  final BusStopModel? nextStop;
  final BusStopModel? lastPassedStop;
  final String? currentStopId;
  final String? nextStopId;
  final String etaStatus;
  final DateTime? etaAt;
  final DateTime? departureAt;
  final Map<String, dynamic>? trackingWindow;

  final List<BusStopModel> routeStops;
  // Passenger target
  final BusStopModel? passengerTargetStop;
  final String? passengerTargetSource; // 'booking' | 'preference'
  final bool approachAlertsEnabled;
  final bool isQaPreviewActive;

  const TrackingSummary({
    required this.status,
    this.trackingPhase = TrackingPhase.unknown,
    this.trackingEnabled = false,
    this.tripStatus,
    this.startedAt,
    this.completedAt,
    this.gpsAgeSeconds,
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
    this.lastPassedStop,
    this.currentStopId,
    this.nextStopId,
    this.etaStatus = 'unavailable',
    this.etaAt,
    this.departureAt,
    this.trackingWindow,
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
      return activeRouteNameAr?.trim().isNotEmpty == true
          ? activeRouteNameAr!
          : (activeRouteNameEn?.trim().isNotEmpty == true
                ? activeRouteNameEn!
                : 'كوبرى عزت - بوابة توشكى');
    }
    return activeRouteNameEn?.trim().isNotEmpty == true
        ? activeRouteNameEn!
        : (activeRouteNameAr?.trim().isNotEmpty == true
              ? activeRouteNameAr!
              : 'Ezzat Bridge - Toshka Gate');
  }

  String localizedNextWindowMessage(String locale) {
    if (locale.startsWith('ar')) {
      return nextWindowMessageAr ?? 'يستأنف تتبع الحافلة الساعة 08:00 صباحاً';
    }
    return nextWindowMessageEn ?? 'Bus tracking resumes at 08:00 AM';
  }

  TrackingSummary copyWith({
    LiveTrackingStatus? status,
    TrackingPhase? trackingPhase,
    bool? trackingEnabled,
    String? tripStatus,
    DateTime? startedAt,
    DateTime? completedAt,
    int? gpsAgeSeconds,
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
    BusStopModel? lastPassedStop,
    String? currentStopId,
    String? nextStopId,
    String? etaStatus,
    DateTime? etaAt,
    DateTime? departureAt,
    Map<String, dynamic>? trackingWindow,
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
      trackingPhase: trackingPhase ?? this.trackingPhase,
      trackingEnabled: trackingEnabled ?? this.trackingEnabled,
      tripStatus: tripStatus ?? this.tripStatus,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      gpsAgeSeconds: gpsAgeSeconds ?? this.gpsAgeSeconds,
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
      lastPassedStop: lastPassedStop ?? this.lastPassedStop,
      currentStopId: currentStopId ?? this.currentStopId,
      nextStopId: nextStopId ?? this.nextStopId,
      etaStatus: etaStatus ?? this.etaStatus,
      etaAt: etaAt ?? this.etaAt,
      departureAt: departureAt ?? this.departureAt,
      trackingWindow: trackingWindow ?? this.trackingWindow,
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
      passengerTargetSource:
          passengerTargetSource ?? this.passengerTargetSource,
      approachAlertsEnabled:
          approachAlertsEnabled ?? this.approachAlertsEnabled,
      isQaPreviewActive: isQaPreviewActive ?? this.isQaPreviewActive,
    );
  }

  factory TrackingSummary.fromJson(Map<String, dynamic> json) {
    final serviceStateStr = (json['service_state'] as String?)?.toLowerCase();
    final phaseStr = (json['tracking_phase'] as String?)?.toLowerCase();
    final statusStr =
        (json['tracking_status'] as String?)?.toLowerCase() ?? 'offline';
    final startedAt = json['started_at'] != null
        ? DateTime.tryParse(json['started_at'].toString())
        : null;
    final completedAt = json['completed_at'] != null
        ? DateTime.tryParse(json['completed_at'].toString())
        : null;
    final gpsAgeSeconds = (json['gps_age_seconds'] as num?)?.toInt();
    final tripStatus = (json['trip_status'] as String?)?.toLowerCase();
    final isDeparted = tripStatus == 'departed' || startedAt != null;

    TrackingPhase trackingPhase;
    if (phaseStr != null) {
      trackingPhase = TrackingPhase.fromString(phaseStr);
    } else if (statusStr == 'live' || statusStr == 'online') {
      trackingPhase = TrackingPhase.live;
    } else if (statusStr == 'stale') {
      trackingPhase = TrackingPhase.gpsStale;
    } else if (statusStr == 'progression_unavailable') {
      trackingPhase = TrackingPhase.progressionSyncing;
    } else if (statusStr == 'assignment_pending') {
      trackingPhase = isDeparted
          ? TrackingPhase.reassignmentPending
          : TrackingPhase.waitingAssignment;
    } else if (statusStr == 'trip_not_active') {
      trackingPhase = isDeparted
          ? TrackingPhase.gpsOffline
          : TrackingPhase.waitingStart;
    } else {
      trackingPhase = isDeparted
          ? TrackingPhase.gpsOffline
          : TrackingPhase.unknown;
    }

    // Crucial rule: If the trip has departed, it can NEVER be waiting_start or waiting_assignment
    if (isDeparted) {
      if (trackingPhase == TrackingPhase.waitingStart ||
          trackingPhase == TrackingPhase.waitingAssignment ||
          trackingPhase == TrackingPhase.unknown) {
        final hasCoords = json['latitude'] != null && json['longitude'] != null;
        trackingPhase = hasCoords
            ? TrackingPhase.gpsStale
            : TrackingPhase.gpsOffline;
      }
    }

    final trackingEnabled =
        isDeparted ||
        (json['tracking_enabled'] as bool? ?? false) ||
        (trackingPhase == TrackingPhase.live ||
            trackingPhase == TrackingPhase.gpsStale ||
            trackingPhase == TrackingPhase.gpsOffline ||
            trackingPhase == TrackingPhase.progressionSyncing ||
            statusStr == 'live' ||
            statusStr == 'online' ||
            statusStr == 'stale' ||
            statusStr == 'progression_unavailable');
    final isQaPreview = (json['is_qa_preview_active'] as bool?) ?? false;

    final LiveTrackingStatus status;
    if (isQaPreview) {
      status = LiveTrackingStatus.qaPreview;
    } else if (statusStr == 'live') {
      status = LiveTrackingStatus.live;
    } else if (serviceStateStr == 'between_runs') {
      status = LiveTrackingStatus.betweenRuns;
    } else if (statusStr == 'online') {
      status = LiveTrackingStatus.online;
    } else if (statusStr == 'stale') {
      status = LiveTrackingStatus.stale;
    } else if (statusStr == 'assignment_pending') {
      status = LiveTrackingStatus.assignmentPending;
    } else if (statusStr == 'trip_not_active') {
      status = LiveTrackingStatus.tripNotActive;
    } else if (statusStr == 'outside_tracking_window') {
      status = LiveTrackingStatus.outsideTrackingWindow;
    } else if (statusStr == 'progression_unavailable') {
      status = LiveTrackingStatus.progressionUnavailable;
    } else {
      status = LiveTrackingStatus.offline;
    }

    final nextWin = json['next_window'] as Map<String, dynamic>?;
    final busLocJson =
        json['bus_location'] as Map<String, dynamic>? ??
        (json['latitude'] != null && json['longitude'] != null
            ? {
                'latitude': json['latitude'],
                'longitude': json['longitude'],
                'heading': json['heading'],
                'gps_recorded_at': json['gps_recorded_at'],
                'is_stale':
                    trackingPhase == TrackingPhase.gpsStale ||
                    status == LiveTrackingStatus.stale,
                'age_seconds': gpsAgeSeconds ?? 0,
                'active_trip_id': json['trip_id'],
                'progress_state': json['progress_state'],
                'current_stop_id': json['current_stop_id'],
                'next_stop_id': json['next_stop_id'],
              }
            : null);
    final stopsRaw =
        json['ordered_stops'] as List<dynamic>? ??
        json['route_stops'] as List<dynamic>? ??
        [];
    final targetRaw = json['passenger_target'] as Map<String, dynamic>?;
    final currentStopRaw = json['current_stop'] as Map<String, dynamic>?;
    final nextStopRaw = json['next_stop'] as Map<String, dynamic>?;
    final lastPassedStopRaw = json['last_passed_stop'] as Map<String, dynamic>?;
    final trackingWindowRaw = json['tracking_window'] as Map<String, dynamic>?;
    final departureAtRaw = json['departure_at'];
    final etaAtRaw = json['eta_at'];
    final routeStops = stopsRaw
        .map((s) => BusStopModel.fromJson(s as Map<String, dynamic>))
        .toList();
    final currentStop = currentStopRaw != null
        ? BusStopModel.fromJson(currentStopRaw)
        : routeStops.cast<BusStopModel?>().firstWhere(
            (s) => s?.semanticState == TrackingStopSemanticState.active,
            orElse: () => null,
          );
    final nextStop = nextStopRaw != null
        ? BusStopModel.fromJson(nextStopRaw)
        : routeStops.cast<BusStopModel?>().firstWhere(
            (s) => s?.semanticState == TrackingStopSemanticState.next,
            orElse: () => null,
          );

    return TrackingSummary(
      status: status,
      trackingPhase: trackingPhase,
      trackingEnabled: trackingEnabled,
      tripStatus: tripStatus,
      startedAt: startedAt,
      completedAt: completedAt,
      gpsAgeSeconds: gpsAgeSeconds,
      isInServiceWindow:
          isDeparted ||
          ((json['is_in_service_window'] as bool?) ??
              trackingEnabled ||
                  status == LiveTrackingStatus.live ||
                  status == LiveTrackingStatus.online ||
                  status == LiveTrackingStatus.stale),
      serviceWindow:
          (json['service_window'] as String?) ??
          trackingWindowRaw?['service_window'] as String? ??
          'offline',
      cairoTime: (json['cairo_time'] as String?) ?? '',
      cairoDate: (json['cairo_date'] as String?) ?? '',
      activeDirection: TrackingDirection.fromString(
        json['direction'] as String? ?? json['active_direction'] as String?,
      ),
      activeRouteId:
          json['route_id'] as String? ?? json['active_route_id'] as String?,
      activeRouteNameAr: json['active_route_name_ar'] as String?,
      activeRouteNameEn: json['active_route_name_en'] as String?,
      activeRunTime: json['active_run_time'] as String?,
      activeTripId:
          json['trip_id'] as String? ?? json['active_trip_id'] as String?,
      serviceState:
          (json['service_state'] as String?) ??
          (status == LiveTrackingStatus.live ||
                  trackingPhase == TrackingPhase.live
              ? 'in_service'
              : statusStr),
      progressState: (json['progress_state'] as String?) ?? 'idle',
      currentStop: currentStop,
      nextStop: nextStop,
      lastPassedStop: lastPassedStopRaw != null
          ? BusStopModel.fromJson(lastPassedStopRaw)
          : routeStops.cast<BusStopModel?>().lastWhere(
              (s) => s?.semanticState == TrackingStopSemanticState.passed,
              orElse: () => null,
            ),
      currentStopId: json['current_stop_id'] as String? ?? currentStop?.id,
      nextStopId: json['next_stop_id'] as String? ?? nextStop?.id,
      etaStatus: (json['eta_status'] as String?) ?? 'unavailable',
      etaAt: etaAtRaw != null ? DateTime.tryParse(etaAtRaw.toString()) : null,
      departureAt: departureAtRaw != null
          ? DateTime.tryParse(departureAtRaw.toString())
          : null,
      trackingWindow: trackingWindowRaw,
      nextWindowStartTime:
          nextWin?['start_time'] as String? ??
          trackingWindowRaw?['next_window_start_time'] as String?,
      nextWindowIsTomorrow:
          (nextWin?['is_tomorrow'] as bool?) ??
          (trackingWindowRaw?['next_window_is_tomorrow'] as bool?) ??
          false,
      nextWindowMessageAr:
          nextWin?['message_ar'] as String? ??
          trackingWindowRaw?['message_ar'] as String?,
      nextWindowMessageEn:
          nextWin?['message_en'] as String? ??
          trackingWindowRaw?['message_en'] as String?,
      busLocation: busLocJson != null
          ? BusTelemetry.fromJson(busLocJson)
          : null,
      stopsCount: (json['stops_count'] as num?)?.toInt() ?? routeStops.length,
      stopsWithCoordsCount:
          (json['stops_with_coords_count'] as num?)?.toInt() ?? 0,
      hasStopCoordinates: (json['has_stop_coordinates'] as bool?) ?? false,
      routeStops: routeStops,
      passengerTargetStop: targetRaw != null
          ? BusStopModel.fromJson(targetRaw)
          : null,
      passengerTargetSource: targetRaw?['source'] as String?,
      approachAlertsEnabled: (json['approach_alerts_enabled'] as bool?) ?? true,
      isQaPreviewActive: isQaPreview,
    );
  }

  @override
  List<Object?> get props => [
    status,
    trackingPhase,
    trackingEnabled,
    tripStatus,
    startedAt,
    completedAt,
    gpsAgeSeconds,
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
    lastPassedStop,
    currentStopId,
    nextStopId,
    etaStatus,
    etaAt,
    departureAt,
    trackingWindow,
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

  @override
  String toString() {
    return 'TrackingSummary('
        'status: ${status.name}, '
        'phase: ${trackingPhase.name}, '
        'enabled: $trackingEnabled, '
        'tripStatus: ${tripStatus ?? 'none'}, '
        'serviceState: $serviceState, '
        'progressState: $progressState, '
        'direction: ${activeDirection.name}, '
        'runTime: ${activeRunTime ?? 'none'}, '
        'currentStop: ${currentStop?.stopOrder ?? 'none'}, '
        'nextStop: ${nextStop?.stopOrder ?? 'none'}, '
        'stopsCount: $stopsCount)';
  }
}
