import 'package:equatable/equatable.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/bus_telemetry.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/models/route_geometry.dart';
import '../../domain/models/stop_progression.dart';
import '../../domain/models/tracking_summary.dart';
import '../../domain/services/stop_eta_engine.dart';

enum TrackingUiStatus { initial, loading, loaded, error }

class TrackingState extends Equatable {
  final TrackingUiStatus uiStatus;
  final TrackingSummary? summary;
  final RouteGeometry? routeGeometry;
  final BusTelemetry? latestTelemetry;
  final StopProgression? progression;
  final bool followBus;
  final BusStopModel? selectedStop;
  final bool approachAlertsEnabled;
  final bool approachAlertDispatched;
  final String? errorMessage;
  final Map<String, StopTimingInfo> stopTimings;
  final double effectiveSpeedKmh;
  final String? trackedTripId;
  final bool isRefreshingSnapshot;

  const TrackingState({
    this.uiStatus = TrackingUiStatus.initial,
    this.summary,
    this.routeGeometry,
    this.latestTelemetry,
    this.progression,
    this.followBus = true,
    this.selectedStop,
    this.approachAlertsEnabled = true,
    this.approachAlertDispatched = false,
    this.errorMessage,
    this.stopTimings = const {},
    this.effectiveSpeedKmh = 0.0,
    this.trackedTripId,
    this.isRefreshingSnapshot = false,
  });

  bool get isLoading => uiStatus == TrackingUiStatus.loading;
  bool get isLoaded => uiStatus == TrackingUiStatus.loaded;
  bool get isError => uiStatus == TrackingUiStatus.error;

  LiveTrackingStatus get trackingStatus {
    if (summary == null) return LiveTrackingStatus.offline;
    if (summary!.status == LiveTrackingStatus.qaPreview) {
      return LiveTrackingStatus.qaPreview;
    }
    if (summary!.status == LiveTrackingStatus.assignmentPending ||
        summary!.status == LiveTrackingStatus.tripNotActive ||
        summary!.status == LiveTrackingStatus.outsideTrackingWindow ||
        summary!.status == LiveTrackingStatus.progressionUnavailable) {
      return summary!.status;
    }
    if (summary!.serviceState == 'between_runs') {
      return LiveTrackingStatus.betweenRuns;
    }
    if (summary!.status == LiveTrackingStatus.offline) {
      return LiveTrackingStatus.offline;
    }
    if (latestTelemetry != null && latestTelemetry!.isStale) {
      return LiveTrackingStatus.stale;
    }
    return summary!.status;
  }

  bool get isDeparted =>
      summary?.tripStatus == 'departed' ||
      summary?.startedAt != null ||
      summary?.trackingEnabled == true;

  TrackingPhase get trackingPhase {
    final phase = summary?.trackingPhase ?? TrackingPhase.unknown;
    if (isDeparted &&
        (phase == TrackingPhase.waitingStart ||
            phase == TrackingPhase.waitingAssignment ||
            phase == TrackingPhase.unknown)) {
      return latestTelemetry != null
          ? TrackingPhase.gpsStale
          : TrackingPhase.gpsOffline;
    }
    return phase;
  }

  bool get trackingEnabled {
    if (summary == null) return false;
    if (isDeparted) return true;
    if (summary!.trackingPhase != TrackingPhase.unknown) {
      return summary!.trackingEnabled;
    }
    return summary!.trackingEnabled ||
        trackingStatus == LiveTrackingStatus.live ||
        trackingStatus == LiveTrackingStatus.online ||
        trackingStatus == LiveTrackingStatus.qaPreview ||
        trackingStatus == LiveTrackingStatus.stale ||
        trackingStatus == LiveTrackingStatus.progressionUnavailable;
  }

  bool get isWaitingAssignment =>
      !isDeparted &&
      (trackingPhase == TrackingPhase.waitingAssignment ||
          trackingStatus == LiveTrackingStatus.assignmentPending);
  bool get isWaitingStart =>
      !isDeparted && trackingPhase == TrackingPhase.waitingStart;
  bool get isReassignmentPending =>
      trackingPhase == TrackingPhase.reassignmentPending;
  bool get isGpsOffline => trackingPhase == TrackingPhase.gpsOffline;
  bool get isGpsStale =>
      trackingPhase == TrackingPhase.gpsStale ||
      trackingStatus == LiveTrackingStatus.stale;
  bool get isProgressionSyncing =>
      trackingPhase == TrackingPhase.progressionSyncing ||
      trackingStatus == LiveTrackingStatus.progressionUnavailable;
  bool get isCompleted =>
      trackingPhase == TrackingPhase.completed ||
      summary?.tripStatus == 'completed';
  bool get isCancelled =>
      trackingPhase == TrackingPhase.cancelled ||
      summary?.tripStatus == 'cancelled';
  bool get isServiceDateEnded =>
      trackingPhase == TrackingPhase.serviceDateEnded;

  bool get isOnline => trackingStatus == LiveTrackingStatus.online;
  bool get isLive =>
      trackingPhase == TrackingPhase.live ||
      trackingStatus == LiveTrackingStatus.live ||
      trackingStatus == LiveTrackingStatus.online;
  bool get isBetweenRuns => trackingStatus == LiveTrackingStatus.betweenRuns;
  bool get isStale => isGpsStale;
  bool get isOffline =>
      trackingPhase == TrackingPhase.gpsOffline ||
      trackingStatus == LiveTrackingStatus.offline ||
      trackingStatus == LiveTrackingStatus.tripNotActive ||
      trackingStatus == LiveTrackingStatus.outsideTrackingWindow;
  bool get isAssignmentPending => isWaitingAssignment;
  bool get isProgressionUnavailable => isProgressionSyncing;
  bool get isQaPreview => trackingStatus == LiveTrackingStatus.qaPreview;

  BusStopModel? get currentStop => summary?.currentStop;
  BusStopModel? get nextStop => summary?.nextStop;
  String get serviceState => summary?.serviceState ?? 'offline';
  String get progressState => summary?.progressState ?? 'idle';
  bool get hasStopCoordinates => summary?.hasStopCoordinates ?? false;
  bool get isAtStop =>
      progressState == 'at_stop' || latestTelemetry?.progressState == 'at_stop';

  StopTimingInfo? get currentStopTiming =>
      currentStop != null ? stopTimings[currentStop!.id] : null;
  StopTimingInfo? get nextStopTiming =>
      nextStop != null ? stopTimings[nextStop!.id] : null;
  StopTimingInfo? get selectedStopTiming =>
      selectedStop != null ? stopTimings[selectedStop!.id] : null;

  TrackingState copyWith({
    TrackingUiStatus? uiStatus,
    TrackingSummary? summary,
    RouteGeometry? routeGeometry,
    BusTelemetry? latestTelemetry,
    StopProgression? progression,
    bool? followBus,
    BusStopModel? selectedStop,
    bool? clearSelectedStop,
    bool? approachAlertsEnabled,
    bool? approachAlertDispatched,
    String? errorMessage,
    Map<String, StopTimingInfo>? stopTimings,
    double? effectiveSpeedKmh,
    String? trackedTripId,
    bool? isRefreshingSnapshot,
    bool? clearTrackingSnapshot,
    bool? clearLivePosition,
  }) {
    return TrackingState(
      uiStatus: uiStatus ?? this.uiStatus,
      summary: clearTrackingSnapshot == true ? null : (summary ?? this.summary),
      routeGeometry: clearTrackingSnapshot == true
          ? null
          : (routeGeometry ?? this.routeGeometry),
      latestTelemetry: clearTrackingSnapshot == true
          ? null
          : clearLivePosition == true
          ? null
          : (latestTelemetry ?? this.latestTelemetry),
      progression: clearTrackingSnapshot == true
          ? null
          : (progression ?? this.progression),
      followBus: followBus ?? this.followBus,
      selectedStop: clearSelectedStop == true
          ? null
          : (selectedStop ?? this.selectedStop),
      approachAlertsEnabled:
          approachAlertsEnabled ?? this.approachAlertsEnabled,
      approachAlertDispatched:
          approachAlertDispatched ?? this.approachAlertDispatched,
      errorMessage: errorMessage ?? this.errorMessage,
      stopTimings: clearTrackingSnapshot == true
          ? const {}
          : (stopTimings ?? this.stopTimings),
      effectiveSpeedKmh: effectiveSpeedKmh ?? this.effectiveSpeedKmh,
      trackedTripId: trackedTripId ?? this.trackedTripId,
      isRefreshingSnapshot: isRefreshingSnapshot ?? this.isRefreshingSnapshot,
    );
  }

  @override
  List<Object?> get props => [
    uiStatus,
    summary,
    routeGeometry,
    latestTelemetry,
    progression,
    followBus,
    selectedStop,
    approachAlertsEnabled,
    approachAlertDispatched,
    errorMessage,
    stopTimings,
    effectiveSpeedKmh,
    trackedTripId,
    isRefreshingSnapshot,
  ];
}
