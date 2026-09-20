import 'dart:math' as math;
import '../models/bus_stop_model.dart';
import '../models/bus_telemetry.dart';
import '../models/live_tracking_status.dart';
import '../models/stop_progression.dart';

/// Route-aware progression engine with monotonic forward progression
/// and hysteresis thresholds to prevent rapid state flickering.
class StopProgressionEngine {
  /// Proximity radius in meters to consider the bus "At Stop".
  final double arrivalRadiusMeters;

  /// Departure radius in meters to confirm the bus has "Departed Stop" (Hysteresis).
  final double departureRadiusMeters;

  /// Window radius in meters to declare the bus "Approaching" the next stop.
  final double approachRadiusMeters;

  int _lastConfirmedIndex = 0;
  String? _lastRouteId;
  TrackingDirection? _lastDirection;

  StopProgressionEngine({
    this.arrivalRadiusMeters = 80.0,
    this.departureRadiusMeters = 130.0,
    this.approachRadiusMeters = 500.0,
  }) : assert(
         departureRadiusMeters > arrivalRadiusMeters,
         'departureRadiusMeters must exceed arrivalRadiusMeters for hysteresis',
       );

  /// Reset the engine monotonic memory (called upon service run or route change).
  void reset() {
    _lastConfirmedIndex = 0;
    _lastRouteId = null;
    _lastDirection = null;
  }

  /// Calculates authoritative progress along ordered route stops.
  StopProgression evaluate({
    required List<BusStopModel> orderedStops,
    required BusTelemetry? telemetry,
    required String? routeId,
    required TrackingDirection direction,
  }) {
    if (orderedStops.isEmpty) {
      const fallbackStop = BusStopModel(
        id: 'placeholder',
        routeStopId: 'placeholder',
        stopOrder: 1,
        nameAr: 'المحطة غير محددة',
        nameEn: 'Stop Unspecified',
        localityAr: '',
        localityEn: '',
      );
      return const StopProgression(
        currentStop: fallbackStop,
        nextStop: fallbackStop,
        status: ApproachStatus.atStop,
        isCoordinatesPending: true,
      );
    }

    // Reset progression if route or direction shifted
    if (routeId != _lastRouteId || direction != _lastDirection) {
      _lastRouteId = routeId;
      _lastDirection = direction;
      _lastConfirmedIndex = 0;
    }

    // If only one stop exists
    if (orderedStops.length == 1) {
      return StopProgression(
        currentStop: orderedStops.first,
        nextStop: orderedStops.first,
        status: ApproachStatus.atStop,
        isCoordinatesPending: !orderedStops.first.hasCoordinates,
      );
    }

    // Check if stops have coordinates
    final stopsWithCoords = orderedStops
        .where((s) => s.hasCoordinates)
        .toList();
    if (stopsWithCoords.isEmpty || telemetry == null) {
      // Graceful fallback when coordinates are pending
      final current = orderedStops.first;
      final next = orderedStops.length > 1 ? orderedStops[1] : current;
      return StopProgression(
        currentStop: current,
        nextStop: next,
        status: ApproachStatus.atStop,
        isCoordinatesPending: true,
      );
    }

    // We have coordinates and live telemetry!
    final busLat = telemetry.latitude;
    final busLng = telemetry.longitude;

    // Evaluate progression forward from last confirmed stop index
    var currentIndex = _lastConfirmedIndex;
    if (currentIndex >= orderedStops.length) {
      currentIndex = orderedStops.length - 1;
    }

    final currentStop = orderedStops[currentIndex];
    final nextIndex = math.min(currentIndex + 1, orderedStops.length - 1);
    final nextStop = orderedStops[nextIndex];

    final distToCurrent = currentStop.hasCoordinates
        ? haversineDistanceMeters(
            busLat,
            busLng,
            currentStop.latitude!,
            currentStop.longitude!,
          )
        : null;

    final distToNext = nextStop.hasCoordinates
        ? haversineDistanceMeters(
            busLat,
            busLng,
            nextStop.latitude!,
            nextStop.longitude!,
          )
        : null;

    // State evaluation with hysteresis
    ApproachStatus status;

    if (distToNext != null && distToNext <= arrivalRadiusMeters) {
      // Arrived at next stop! Advance forward
      _lastConfirmedIndex = nextIndex;
      final newNextIndex = math.min(nextIndex + 1, orderedStops.length - 1);
      return StopProgression(
        currentStop: nextStop,
        nextStop: orderedStops[newNextIndex],
        status: ApproachStatus.atStop,
        distanceToCurrentMeters: distToNext,
        distanceToNextMeters: orderedStops[newNextIndex].hasCoordinates
            ? haversineDistanceMeters(
                busLat,
                busLng,
                orderedStops[newNextIndex].latitude!,
                orderedStops[newNextIndex].longitude!,
              )
            : null,
      );
    } else if (distToCurrent != null && distToCurrent <= arrivalRadiusMeters) {
      // Still inside current stop arrival radius
      status = ApproachStatus.atStop;
    } else if (distToCurrent != null && distToCurrent > departureRadiusMeters) {
      // Left departure radius of current stop
      if (distToNext != null && distToNext <= approachRadiusMeters) {
        status = ApproachStatus.approaching;
      } else {
        status = ApproachStatus.departed;
      }
    } else {
      // In hysteresis zone between arrivalRadius and departureRadius
      status = ApproachStatus.atStop;
    }

    return StopProgression(
      currentStop: currentStop,
      nextStop: nextStop,
      status: status,
      distanceToCurrentMeters: distToCurrent,
      distanceToNextMeters: distToNext,
    );
  }

  /// Calculates geodesic distance between two GPS coordinates using Haversine formula in meters.
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
