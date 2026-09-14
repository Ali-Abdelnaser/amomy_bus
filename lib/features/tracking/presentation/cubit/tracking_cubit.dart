import 'dart:async';
import 'dart:math' as math;
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/bus_telemetry.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/models/stop_progression.dart';
import '../../domain/models/tracking_summary.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../domain/services/stop_eta_engine.dart';
import '../../domain/services/stop_progression_engine.dart';
import 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  final TrackingRepository repository;
  final AuthRepository? authRepository;
  final StopProgressionEngine _progressionEngine;
  final StopEtaEngine _etaEngine;
  final bool? isQaAuthorizedOverride;

  StreamSubscription<BusTelemetry>? _telemetrySubscription;
  Timer? _stalenessTimer;
  Timer? _qaSimulationTimer;
  int _qaStopIndex = 0;

  TrackingCubit({
    required this.repository,
    this.authRepository,
    this.isQaAuthorizedOverride,
    StopProgressionEngine? progressionEngine,
    StopEtaEngine? etaEngine,
  })  : _progressionEngine = progressionEngine ?? StopProgressionEngine(),
        _etaEngine = etaEngine ?? StopEtaEngine(),
        super(const TrackingState());

  Future<bool> _isUserQaAuthorized() async {
    // Release builds strictly cannot enable QA preview
    if (!kDebugMode) return false;
    if (isQaAuthorizedOverride != null) return isQaAuthorizedOverride!;

    try {
      final authRepo = authRepository ??
          (getIt.isRegistered<AuthRepository>() ? getIt<AuthRepository>() : null);
      if (authRepo == null) return false;

      final userResult = await authRepo.getCurrentUser();
      final user = userResult.dataOrNull;
      if (user == null) return false;

      return user.hasAdminPrivileges ||
          user.roles.any((r) =>
              r.isAdmin ||
              r.value.toLowerCase() == 'qa' ||
              r.value.toLowerCase() == 'super_admin');
    } catch (_) {
      return false;
    }
  }

  Future<void> loadTrackingData({bool isRefresh = false}) async {
    if (!isRefresh) {
      emit(state.copyWith(uiStatus: TrackingUiStatus.loading));
    }

    try {
      final isQaAuthorized = await _isUserQaAuthorized();
      final summary = await repository.getTrackingSummary(includeQa: isQaAuthorized);

      // Check if we should activate safe QA Preview mode outside operating hours
      final isOutsideHours = summary.status == LiveTrackingStatus.offline;
      final shouldActivateQaPreview = isOutsideHours && isQaAuthorized;

      final effectiveSummary = shouldActivateQaPreview
          ? summary.copyWith(
              status: LiveTrackingStatus.qaPreview,
              isQaPreviewActive: true,
            )
          : summary;

      final telemetry = effectiveSummary.busLocation;

      final hasBackendProgression =
          effectiveSummary.currentStop != null || effectiveSummary.nextStop != null;
      final progression = hasBackendProgression &&
              effectiveSummary.currentStop != null &&
              effectiveSummary.nextStop != null
          ? StopProgression(
              currentStop: effectiveSummary.currentStop!,
              nextStop: effectiveSummary.nextStop!,
              status: effectiveSummary.progressState == 'at_stop'
                  ? ApproachStatus.atStop
                  : effectiveSummary.progressState == 'approaching'
                      ? ApproachStatus.approaching
                      : ApproachStatus.departed,
            )
          : _progressionEngine.evaluate(
              orderedStops: effectiveSummary.routeStops,
              telemetry: telemetry,
              routeId: effectiveSummary.activeRouteId,
              direction: effectiveSummary.activeDirection,
            );

      // Fetch stored Google road geometry if route is configured
      RouteGeometry? routeGeom;
      if (effectiveSummary.activeRouteId != null) {
        final dir = effectiveSummary.activeDirection == TrackingDirection.returnDirection
            ? 'return'
            : 'outbound';
        routeGeom = await repository.getActiveRouteGeometry(
          routeId: effectiveSummary.activeRouteId!,
          direction: dir,
        );
      }

      if (telemetry != null) {
        _etaEngine.recordTelemetrySpeed(telemetry.speedKmh, telemetry.gpsRecordedAt);
      }
      final effectiveSpeed = _etaEngine.getEffectiveSpeedKmh(
        instantSpeedKmh: telemetry?.speedKmh,
      );
      final timings = _etaEngine.computeAllStopTimings(
        orderedStops: effectiveSummary.routeStops,
        telemetry: telemetry,
        activeRunTime: effectiveSummary.activeRunTime,
        isQaPreview: effectiveSummary.isQaPreviewActive,
        routePolylinePoints: routeGeom?.points,
      );

      emit(state.copyWith(
        uiStatus: TrackingUiStatus.loaded,
        summary: effectiveSummary,
        routeGeometry: routeGeom,
        latestTelemetry: telemetry,
        progression: progression,
        approachAlertsEnabled: effectiveSummary.approachAlertsEnabled,
        stopTimings: timings,
        effectiveSpeedKmh: effectiveSpeed,
        errorMessage: null,
      ));

      if (shouldActivateQaPreview) {
        _startQaSimulation(effectiveSummary);
      } else {
        _qaSimulationTimer?.cancel();
        _checkApproachNotification(
          backendNextStopId: effectiveSummary.nextStopId,
          progression: progression,
        );
        _subscribeToTelemetry();
        _startStalenessWatcher();
      }
    } catch (e) {
      emit(state.copyWith(
        uiStatus: TrackingUiStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _startQaSimulation(TrackingSummary summary) {
    _qaSimulationTimer?.cancel();
    final stops = summary.routeStops.where((s) => s.hasCoordinates).toList();
    if (stops.isEmpty) return;

    if (_qaStopIndex >= stops.length) {
      _qaStopIndex = 0;
    }

    void tick() {
      if (isClosed) return;
      final currentSummary = state.summary;
      if (currentSummary == null ||
          currentSummary.status != LiveTrackingStatus.qaPreview) {
        _qaSimulationTimer?.cancel();
        return;
      }

      final currStop = stops[_qaStopIndex];
      final nextIdx = (_qaStopIndex + 1) % stops.length;
      final nextStop = stops[nextIdx];

      final bearing = _calculateBearing(
        currStop.latitude!,
        currStop.longitude!,
        nextStop.latitude!,
        nextStop.longitude!,
      );

      final telemetry = BusTelemetry(
        latitude: currStop.latitude!,
        longitude: currStop.longitude!,
        heading: bearing.toInt(),
        speedKmh: 34.0,
        gpsRecordedAt: DateTime.now().toUtc(),
        source: 'qa',
        currentStopId: currStop.id,
        nextStopId: nextStop.id,
        serviceState: 'in_service',
        progressState: 'in_transit',
      );

      final progression = StopProgression(
        currentStop: currStop,
        nextStop: nextStop,
        status: ApproachStatus.approaching,
      );

      final updated = currentSummary.copyWith(
        busLocation: telemetry,
        currentStop: currStop,
        nextStop: nextStop,
        currentStopId: currStop.id,
        nextStopId: nextStop.id,
        serviceState: 'in_service',
        progressState: 'in_transit',
      );

      final timings = _etaEngine.computeAllStopTimings(
        orderedStops: currentSummary.routeStops,
        telemetry: telemetry,
        activeRunTime: updated.activeRunTime,
        isQaPreview: true,
        now: telemetry.gpsRecordedAt,
      );

      emit(state.copyWith(
        summary: updated,
        latestTelemetry: telemetry,
        progression: progression,
        stopTimings: timings,
        effectiveSpeedKmh: 34.0,
      ));

      _qaStopIndex = nextIdx;
    }

    // Run first tick immediately to show bus at Stop 1 right away
    tick();
    _qaSimulationTimer = Timer.periodic(
      const Duration(milliseconds: 3500),
      (_) => tick(),
    );
  }

  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final dLon = (endLng - startLng) * (math.pi / 180.0);
    final lat1 = startLat * (math.pi / 180.0);
    final lat2 = endLat * (math.pi / 180.0);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final brng = math.atan2(y, x) * (180.0 / math.pi);
    return (brng + 360.0) % 360.0;
  }

  void _subscribeToTelemetry() {
    _telemetrySubscription?.cancel();
    _telemetrySubscription = repository.subscribeToBusLiveLocation().listen(
      (newTelemetry) {
        _onNewTelemetry(newTelemetry);
      },
      onError: (err) {
        // Stream errors do not break UI; fallback to polling or stale status
      },
    );
  }

  void _onNewTelemetry(BusTelemetry newTelemetry) {
    final currentSummary = state.summary;
    if (currentSummary == null) return;
    if (state.trackingStatus == LiveTrackingStatus.qaPreview) return;

    final hasBackendNext = newTelemetry.nextStopId != null;
    final backendNextStop = hasBackendNext
        ? currentSummary.routeStops.cast<BusStopModel?>().firstWhere(
              (s) => s?.id == newTelemetry.nextStopId,
              orElse: () => null,
            )
        : null;
    final backendCurrentStop = newTelemetry.currentStopId != null
        ? currentSummary.routeStops.cast<BusStopModel?>().firstWhere(
              (s) => s?.id == newTelemetry.currentStopId,
              orElse: () => null,
            )
        : null;

    final progression = (backendCurrentStop != null && backendNextStop != null)
        ? StopProgression(
            currentStop: backendCurrentStop,
            nextStop: backendNextStop,
            status: newTelemetry.progressState == 'at_stop'
                ? ApproachStatus.atStop
                : newTelemetry.progressState == 'approaching'
                    ? ApproachStatus.approaching
                    : ApproachStatus.departed,
          )
        : _progressionEngine.evaluate(
            orderedStops: currentSummary.routeStops,
            telemetry: newTelemetry,
            routeId: currentSummary.activeRouteId,
            direction: currentSummary.activeDirection,
          );

    final updatedSummary = currentSummary.copyWith(
      busLocation: newTelemetry,
      nextStopId: newTelemetry.nextStopId ?? currentSummary.nextStopId,
      currentStopId: newTelemetry.currentStopId ?? currentSummary.currentStopId,
      serviceState: newTelemetry.serviceState ?? currentSummary.serviceState,
      progressState: newTelemetry.progressState ?? currentSummary.progressState,
      activeTripId: newTelemetry.activeTripId ?? currentSummary.activeTripId,
      activeRunTime: newTelemetry.serviceRunTime ?? currentSummary.activeRunTime,
      currentStop: backendCurrentStop ?? currentSummary.currentStop,
      nextStop: backendNextStop ?? currentSummary.nextStop,
    );

    _etaEngine.recordTelemetrySpeed(newTelemetry.speedKmh, newTelemetry.gpsRecordedAt);
    final effectiveSpeed = _etaEngine.getEffectiveSpeedKmh(
      instantSpeedKmh: newTelemetry.speedKmh,
      now: newTelemetry.gpsRecordedAt,
    );
    final timings = _etaEngine.computeAllStopTimings(
      orderedStops: currentSummary.routeStops,
      telemetry: newTelemetry,
      activeRunTime: updatedSummary.activeRunTime,
      isQaPreview: false,
      now: newTelemetry.gpsRecordedAt,
    );

    emit(state.copyWith(
      summary: updatedSummary,
      latestTelemetry: newTelemetry,
      progression: progression,
      stopTimings: timings,
      effectiveSpeedKmh: effectiveSpeed,
    ));

    // Check approach notification trigger using backend nextStopId authority
    _checkApproachNotification(
      backendNextStopId: newTelemetry.nextStopId ?? updatedSummary.nextStopId,
      progression: progression,
    );
  }

  void _checkApproachNotification({
    required String? backendNextStopId,
    StopProgression? progression,
  }) {
    final summary = state.summary;
    if (summary == null ||
        !state.approachAlertsEnabled ||
        state.approachAlertDispatched) {
      return;
    }

    // Never dispatch real approach notifications in QA Preview mode
    if (state.trackingStatus == LiveTrackingStatus.qaPreview) {
      return;
    }

    final targetStop = summary.passengerTargetStop;
    if (targetStop == null) return;

    // Critical: approach notifications must ignore temporary unverified QA coordinates
    if (targetStop.isTemporaryQa) {
      return;
    }

    // Requirement 9: Approach notifications must use BACKEND next_stop_id
    final bool isTriggered = backendNextStopId != null
        ? (backendNextStopId == targetStop.id)
        : (progression != null && progression.isApproachingStop(targetStop.id));

    if (isTriggered) {
      final routeId =
          summary.activeRouteId ?? '11111111-1111-1111-1111-111111111101';
      final runTime = summary.activeRunTime ?? '08:00';
      final stopNameAr = targetStop.nameAr;
      final stopNameEn = targetStop.nameEn;

      repository.recordApproachNotification(
        routeId: routeId,
        targetStopId: targetStop.id,
        serviceRunTime: '$runTime:00',
        titleAr: 'الحافلة تقترب من محطتك! 🚌',
        titleEn: 'Bus is approaching your stop! 🚌',
        bodyAr: 'الحافلة تقترب الآن من محطة $stopNameAr. يرجى التواجد في المحطة.',
        bodyEn: 'The bus is now approaching $stopNameEn. Please be ready at the stop.',
      ).then((dispatched) {
        if (dispatched) {
          emit(state.copyWith(approachAlertDispatched: true));
        }
      }).catchError((_) {});
    }
  }

  void _startStalenessWatcher() {
    _stalenessTimer?.cancel();
    _stalenessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final telemetry = state.latestTelemetry;
      if (telemetry != null && state.trackingStatus != LiveTrackingStatus.qaPreview) {
        final age = DateTime.now()
            .toUtc()
            .difference(telemetry.gpsRecordedAt)
            .inSeconds;
        final isStale = age > 120;
        if (telemetry.isStale != isStale) {
          emit(state.copyWith(
            latestTelemetry: telemetry.copyWith(isStale: isStale, ageSeconds: age),
          ));
        }
      }
    });
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
    // Reload snapshot to update state immediately
    await loadTrackingData(isRefresh: true);
  }

  @override
  Future<void> close() {
    _telemetrySubscription?.cancel();
    _stalenessTimer?.cancel();
    _qaSimulationTimer?.cancel();
    return super.close();
  }
}
