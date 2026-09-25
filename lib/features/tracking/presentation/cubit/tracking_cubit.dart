import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/models/route_geometry.dart';
import '../../domain/models/stop_progression.dart';
import '../../domain/models/tracking_summary.dart';
import '../../domain/repositories/tracking_repository.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final TrackingRepository repository;

  StreamSubscription<void>? _trackingInvalidationSubscription;
  Timer? _revisionDebounce;
  Timer? _fleetRefreshTimer;
  bool _refreshInFlight = false;
  bool _refreshQueued = false;
  String? _trackedTripId;

  TrackingCubit({required this.repository, bool? isQaAuthorizedOverride})
    : super(const TrackingState());

  Future<void> loadTrackingData({
    String? tripId,
    bool isRefresh = false,
  }) async {
    final normalizedTripId = tripId?.trim();
    if (normalizedTripId != null && normalizedTripId.isNotEmpty) {
      _stopFleetRefresh();
      final tripChanged = _trackedTripId != normalizedTripId;
      _trackedTripId = normalizedTripId;

      if (tripChanged) {
        await _trackingInvalidationSubscription?.cancel();
        _trackingInvalidationSubscription = null;
        emit(
          state.copyWith(
            uiStatus: TrackingUiStatus.loading,
            trackedTripId: normalizedTripId,
            clearTrackingSnapshot: true,
            clearSelectedStop: true,
          ),
        );
      } else if (!isRefresh) {
        emit(state.copyWith(uiStatus: TrackingUiStatus.loading));
      }

      await _fetchTripTracking(
        normalizedTripId,
        silent: isRefresh && !tripChanged,
      );
      _subscribeToTripInvalidation(normalizedTripId);
    } else {
      // Fleet tracking mode: no passenger booking required
      _trackedTripId = null;
      await _trackingInvalidationSubscription?.cancel();
      _trackingInvalidationSubscription = null;

      if (!isRefresh && state.fleetSummary == null) {
        emit(state.copyWith(uiStatus: TrackingUiStatus.loading));
      } else if (isRefresh) {
        emit(state.copyWith(isRefreshingSnapshot: true));
      }

      await _fetchFleetTracking(silent: isRefresh);
      _startFleetRefresh();
    }
  }

  void _startFleetRefresh() {
    _fleetRefreshTimer?.cancel();
    _fleetRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!isClosed && _trackedTripId == null) {
        unawaited(_fetchFleetTracking(silent: true));
      }
    });
  }

  void _stopFleetRefresh() {
    _fleetRefreshTimer?.cancel();
    _fleetRefreshTimer = null;
  }

  Future<void> _fetchFleetTracking({required bool silent}) async {
    if (_refreshInFlight) {
      _refreshQueued = true;
      return;
    }
    _refreshInFlight = true;
    if (!silent) {
      emit(state.copyWith(uiStatus: TrackingUiStatus.loading));
    } else {
      emit(state.copyWith(isRefreshingSnapshot: true));
    }

    try {
      final fleet = await repository.getPassengerFleetTracking();
      if (_trackedTripId != null) return;

      final summary = fleet.toTrackingSummary();
      final routeGeom = fleet.primaryGeometry;
      final telemetry = fleet.busesWithValidLocation.isNotEmpty
          ? fleet.busesWithValidLocation.first.toBusTelemetry()
          : null;

      emit(
        state.copyWith(
          uiStatus: TrackingUiStatus.loaded,
          fleetSummary: fleet,
          summary: summary,
          routeGeometry: routeGeom,
          latestTelemetry: telemetry,
          clearLivePosition: telemetry == null,
          errorMessage: null,
          isRefreshingSnapshot: false,
        ),
      );
    } catch (e) {
      if (state.summary == null && state.fleetSummary == null) {
        emit(
          state.copyWith(
            uiStatus: TrackingUiStatus.error,
            errorMessage: 'TRACKING_LOAD_FAILED',
            isRefreshingSnapshot: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            uiStatus: TrackingUiStatus.loaded,
            isRefreshingSnapshot: false,
          ),
        );
      }
    } finally {
      _refreshInFlight = false;
      if (_refreshQueued && _trackedTripId == null) {
        _refreshQueued = false;
        unawaited(_fetchFleetTracking(silent: true));
      }
    }
  }

  Future<void> refreshTrackedTrip() async {
    final tripId = _trackedTripId;
    if (tripId == null || tripId.isEmpty) return;
    await _fetchTripTracking(tripId, silent: true);
  }

  Future<void> _fetchTripTracking(String tripId, {required bool silent}) async {
    if (_refreshInFlight) {
      _refreshQueued = true;
      return;
    }

    _refreshInFlight = true;
    if (!silent) {
      emit(state.copyWith(uiStatus: TrackingUiStatus.loading));
    } else {
      emit(state.copyWith(isRefreshingSnapshot: true));
    }

    try {
      final summary = await repository.getTripTracking(tripId: tripId);
      if (_trackedTripId != tripId) return;

      final hasUsableTelemetry =
          (summary.trackingEnabled &&
              (summary.trackingPhase == TrackingPhase.live ||
                  summary.trackingPhase == TrackingPhase.gpsStale ||
                  summary.trackingPhase == TrackingPhase.progressionSyncing)) ||
          summary.status == LiveTrackingStatus.live ||
          summary.status == LiveTrackingStatus.online ||
          summary.status == LiveTrackingStatus.qaPreview;

      final isTelemetrySuppressed =
          summary.trackingPhase == TrackingPhase.mapDisabled ||
          summary.trackingPhase == TrackingPhase.busHidden ||
          summary.trackingPhase == TrackingPhase.gpsOffline ||
          summary.trackingPhase == TrackingPhase.reassignmentPending ||
          summary.trackingPhase == TrackingPhase.waitingAssignment ||
          summary.trackingPhase == TrackingPhase.waitingStart ||
          summary.trackingPhase == TrackingPhase.completed ||
          summary.trackingPhase == TrackingPhase.cancelled ||
          summary.trackingPhase == TrackingPhase.serviceDateEnded;

      final telemetry = (!isTelemetrySuppressed && hasUsableTelemetry)
          ? summary.busLocation
          : null;

      final routeGeom = await _loadRouteGeometry(summary);

      emit(
        state.copyWith(
          uiStatus: TrackingUiStatus.loaded,
          trackedTripId: tripId,
          summary: summary,
          routeGeometry: routeGeom,
          latestTelemetry: telemetry,
          clearLivePosition: telemetry == null,
          progression: _backendProgression(summary),
          approachAlertsEnabled: summary.approachAlertsEnabled,
          errorMessage: null,
          isRefreshingSnapshot: false,
          stopTimings: const {},
          effectiveSpeedKmh: 0,
          clearSelectedStop: _shouldClearSelectedStop(summary),
        ),
      );

      if (summary.trackingPhase == TrackingPhase.completed ||
          summary.trackingPhase == TrackingPhase.cancelled ||
          summary.trackingPhase == TrackingPhase.serviceDateEnded) {
        _trackingInvalidationSubscription?.cancel();
        _trackingInvalidationSubscription = null;
        _revisionDebounce?.cancel();
      }

      _checkApproachNotification(summary);
    } catch (e) {
      if (state.summary == null) {
        emit(
          state.copyWith(
            uiStatus: TrackingUiStatus.error,
            errorMessage: 'TRACKING_LOAD_FAILED',
            isRefreshingSnapshot: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            uiStatus: TrackingUiStatus.loaded,
            errorMessage: 'TRACKING_LOAD_FAILED',
            isRefreshingSnapshot: false,
          ),
        );
      }
    } finally {
      _refreshInFlight = false;
      if (_refreshQueued && _trackedTripId == tripId) {
        _refreshQueued = false;
        unawaited(_fetchTripTracking(tripId, silent: true));
      }
    }
  }

  Future<RouteGeometry?> _loadRouteGeometry(TrackingSummary summary) {
    final routeId = summary.activeRouteId;
    if (routeId == null || routeId.isEmpty) {
      return Future.value();
    }
    return repository.getActiveRouteGeometry(
      routeId: routeId,
      direction: summary.activeDirection.toDbString(),
    );
  }

  StopProgression? _backendProgression(TrackingSummary summary) {
    final current = summary.currentStop;
    final next = summary.nextStop;
    if (current == null || next == null) return null;
    return StopProgression(
      currentStop: current,
      nextStop: next,
      status: summary.progressState == 'at_stop'
          ? ApproachStatus.atStop
          : summary.progressState == 'approaching'
          ? ApproachStatus.approaching
          : ApproachStatus.departed,
      isCoordinatesPending:
          !summary.hasStopCoordinates ||
          !current.hasCoordinates ||
          current.isTemporaryQa,
    );
  }

  bool _shouldClearSelectedStop(TrackingSummary summary) {
    final selected = state.selectedStop;
    if (selected == null) return false;
    return !summary.routeStops.any((s) => s.id == selected.id);
  }

  void _subscribeToTripInvalidation(String tripId) {
    if (_trackingInvalidationSubscription != null) return;
    _trackingInvalidationSubscription = repository
        .subscribeToTripTrackingState(tripId: tripId)
        .listen(
          (_) {
            if (_trackedTripId != tripId) return;
            _revisionDebounce?.cancel();
            _revisionDebounce = Timer(const Duration(milliseconds: 350), () {
              if (!isClosed && _trackedTripId == tripId) {
                unawaited(_fetchTripTracking(tripId, silent: true));
              }
            });
          },
          onError: (Object _) {
            // Invalidation errors are transport-level issues. Keep the last
            // canonical snapshot visible instead of fabricating an offline state.
          },
          cancelOnError: false,
        );
  }

  void _checkApproachNotification(TrackingSummary summary) {
    if (!state.approachAlertsEnabled || state.approachAlertDispatched) return;
    final targetStop = summary.passengerTargetStop;
    if (targetStop == null || targetStop.isTemporaryQa) return;
    if (summary.nextStopId != targetStop.id) return;

    final routeId = summary.activeRouteId;
    final runTime = summary.activeRunTime;
    if (routeId == null || runTime == null) return;

    repository
        .recordApproachNotification(
          routeId: routeId,
          targetStopId: targetStop.id,
          serviceRunTime: '$runTime:00',
          titleAr: 'الحافلة تقترب من محطتك!',
          titleEn: 'Bus is approaching your stop!',
          bodyAr:
              'الحافلة تقترب الآن من محطة ${targetStop.nameAr}. يرجى التواجد في المحطة.',
          bodyEn:
              'The bus is now approaching ${targetStop.nameEn}. Please be ready at the stop.',
        )
        .then((dispatched) {
          if (!isClosed && dispatched) {
            emit(state.copyWith(approachAlertDispatched: true));
          }
        })
        .catchError((_) {});
  }

  void toggleFollowBus(bool follow) {
    emit(state.copyWith(followBus: follow));
  }

  void selectStop(BusStopModel? stop) {
    if (stop == null) {
      emit(state.copyWith(clearSelectedStop: true));
    } else {
      emit(state.copyWith(selectedStop: stop));
    }
  }

  Future<void> setApproachAlertsEnabled(bool enabled) async {
    emit(state.copyWith(approachAlertsEnabled: enabled));
    try {
      await repository.updateApproachAlertsPreference(enabled);
    } catch (_) {}
  }

  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {
    await repository.simulateQaLocation(
      busId: busId,
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speedKmh: speedKmh,
    );
    await refreshTrackedTrip();
  }

  @override
  Future<void> close() {
    _stopFleetRefresh();
    _revisionDebounce?.cancel();
    _trackingInvalidationSubscription?.cancel();
    return super.close();
  }
}
