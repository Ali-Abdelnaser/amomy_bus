import 'dart:collection';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_telemetry.dart';
import '../models/route_geometry.dart';

/// Clean result holding stop arrival timing information.
class StopTimingInfo {
  final String stopId;
  final int stopOrder;
  final DateTime? actualArrivalTime;
  final DateTime? estimatedArrivalTime;
  final String? scheduledDepartureTime;
  final double? remainingDistanceMeters;
  final bool isPassed;
  final bool isCurrent;
  final bool isNext;
  final bool isQaPreviewOnly;

  const StopTimingInfo({
    required this.stopId,
    required this.stopOrder,
    this.actualArrivalTime,
    this.estimatedArrivalTime,
    this.scheduledDepartureTime,
    this.remainingDistanceMeters,
    this.isPassed = false,
    this.isCurrent = false,
    this.isNext = false,
    this.isQaPreviewOnly = false,
  });

  bool get hasActualArrival => actualArrivalTime != null;
  bool get hasEta => estimatedArrivalTime != null;
}

/// Domain ETA calculation engine for AMOMY Live Tracking.
/// Computes ordered cumulative route distances, applies speed smoothing over telemetry history,
/// handles zero-speed dwell periods without infinite ETAs, and strictly isolates QA stop ETAs.
class StopEtaEngine {
  /// Initial configurable fallback route speed in km/h (within 20–25 km/h range).
  static const double defaultFallbackSpeedKmh = 22.0;

  /// Minimum threshold in km/h to consider the bus actively moving.
  static const double minMovingSpeedThreshold = 2.0;

  /// Maximum realistic speed in km/h to reject GPS telemetry spikes.
  static const double maxRealisticSpeedThreshold = 85.0;

  /// Estimated dwell time per intermediate route stop in seconds.
  static const int stopDwellTimeSeconds = 35;

  /// Duration for which recent moving speed is preserved during short stops (traffic lights, passenger boarding).
  static const Duration shortStopHoldDuration = Duration(minutes: 3);

  final double fallbackSpeedKmh;
  final ListQueue<_SpeedPoint> _speedHistory = ListQueue<_SpeedPoint>();
  DateTime? _lastMovingTime;
  double? _lastSmoothedMovingSpeed;

  StopEtaEngine({this.fallbackSpeedKmh = defaultFallbackSpeedKmh});

  /// Clear telemetry history (e.g. on new service run).
  void reset() {
    _speedHistory.clear();
    _lastMovingTime = null;
    _lastSmoothedMovingSpeed = null;
  }

  /// Ingests a new speed reading into the rolling history window (last 3 to 8 points).
  void recordTelemetrySpeed(double speedKmh, DateTime timestamp) {
    if (speedKmh < 0) return;

    // Ignore obvious GPS telemetry spikes
    if (speedKmh > maxRealisticSpeedThreshold) return;

    if (speedKmh >= minMovingSpeedThreshold) {
      _lastMovingTime = timestamp;
      _speedHistory.addLast(_SpeedPoint(speedKmh, timestamp));
      while (_speedHistory.length > 8) {
        _speedHistory.removeFirst();
      }
      _lastSmoothedMovingSpeed = _computeRawSmoothedSpeed();
    }
  }

  /// Computes the effective smoothed moving speed in km/h.
  /// If the bus is temporarily stopped (speed <= 2 km/h) for under 3 minutes,
  /// recent moving speed is retained so ETAs do not blow up to infinity.
  double getEffectiveSpeedKmh({double? instantSpeedKmh, DateTime? now}) {
    final currentTime = now ?? DateTime.now().toUtc();
    final instant = instantSpeedKmh ?? 0.0;

    // If instant speed is a valid moving speed and not an extreme spike
    if (instant >= minMovingSpeedThreshold &&
        instant <= maxRealisticSpeedThreshold) {
      recordTelemetrySpeed(instant, currentTime);
      return _lastSmoothedMovingSpeed ?? instant;
    }

    // Bus is stopped or moving very slowly (<= 2 km/h)
    if (_lastMovingTime != null && _lastSmoothedMovingSpeed != null) {
      final stopDuration = currentTime.difference(_lastMovingTime!);
      if (stopDuration <= shortStopHoldDuration) {
        // Short stop: retain recent smoothed moving speed
        return _lastSmoothedMovingSpeed!;
      }
    }

    // Insufficient recent movement or prolonged stop: use domain fallback speed
    return fallbackSpeedKmh;
  }

  double _computeRawSmoothedSpeed() {
    if (_speedHistory.isEmpty) return fallbackSpeedKmh;
    if (_speedHistory.length == 1) return _speedHistory.first.speedKmh;

    // Weighted moving average giving more weight to recent telemetry points
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    int index = 1;

    for (final point in _speedHistory) {
      final weight = index.toDouble();
      weightedSum += point.speedKmh * weight;
      totalWeight += weight;
      index++;
    }

    return totalWeight > 0 ? (weightedSum / totalWeight) : fallbackSpeedKmh;
  }

  /// Computes cumulative distance along the stored Google route geometry polyline
  /// from current bus coordinates to the target stop, or falls back to ordered stop geodesics.
  double calculateRemainingRouteDistanceMeters({
    required List<BusStopModel> orderedStops,
    required double busLat,
    required double busLng,
    required int nextStopOrder,
    required int targetStopOrder,
    List<LatLng>? routePolylinePoints,
  }) {
    if (targetStopOrder < nextStopOrder) return 0.0;

    final stopsWithCoords = orderedStops
        .where((s) => s.hasCoordinates)
        .toList();
    if (stopsWithCoords.isEmpty) return 0.0;

    final nextStopIndex = stopsWithCoords.indexWhere(
      (s) => s.stopOrder == nextStopOrder,
    );
    final targetStopIndex = stopsWithCoords.indexWhere(
      (s) => s.stopOrder == targetStopOrder,
    );

    if (nextStopIndex == -1 || targetStopIndex == -1) {
      return 0.0;
    }

    final targetStop = stopsWithCoords[targetStopIndex];

    // If verified or road polyline points exist, calculate distance along the road polyline
    if (routePolylinePoints != null && routePolylinePoints.length >= 2) {
      final busLoc = LatLng(busLat, busLng);
      final targetLoc = LatLng(targetStop.latitude!, targetStop.longitude!);
      final busProj = RouteGeometryEngine.projectBusLocation(
        rawGps: busLoc,
        polyline: routePolylinePoints,
      );
      final stopProj = RouteGeometryEngine.projectBusLocation(
        rawGps: targetLoc,
        polyline: routePolylinePoints,
      );

      final split = RouteGeometryEngine.splitPolylineByBus(
        polyline: routePolylinePoints,
        busLocation: busProj,
      );

      // Sum distance along upcoming polyline up to target stop projection
      double distAlongRoad = 0.0;
      for (int i = 0; i < split.upcoming.length - 1; i++) {
        final p1 = split.upcoming[i];
        final p2 = split.upcoming[i + 1];
        distAlongRoad += RouteGeometryEngine.distanceMeters(p1, p2);
        if (RouteGeometryEngine.distanceMeters(p2, stopProj) < 25.0) {
          break;
        }
      }
      return distAlongRoad;
    }

    // Geodesic fallback along ordered stops
    final nextStop = stopsWithCoords[nextStopIndex];
    double totalDistance = haversineDistanceMeters(
      busLat,
      busLng,
      nextStop.latitude!,
      nextStop.longitude!,
    );

    for (int i = nextStopIndex; i < targetStopIndex; i++) {
      final from = stopsWithCoords[i];
      final to = stopsWithCoords[i + 1];
      totalDistance += haversineDistanceMeters(
        from.latitude!,
        from.longitude!,
        to.latitude!,
        to.longitude!,
      );
    }

    return totalDistance;
  }

  /// Evaluates timing information for all stops along the active route.
  Map<String, StopTimingInfo> computeAllStopTimings({
    required List<BusStopModel> orderedStops,
    required BusTelemetry? telemetry,
    required String? activeRunTime,
    required bool isQaPreview,
    List<LatLng>? routePolylinePoints,
    DateTime? now,
  }) {
    final Map<String, StopTimingInfo> results = {};
    if (orderedStops.isEmpty) return results;

    final currentTime = now ?? DateTime.now().toUtc();
    final effectiveSpeed = getEffectiveSpeedKmh(
      instantSpeedKmh: telemetry?.speedKmh,
      now: currentTime,
    );

    final currentStopOrder = telemetry?.currentStopOrder ?? 1;
    final nextStopOrder =
        telemetry?.nextStopOrder ??
        (currentStopOrder < orderedStops.length
            ? currentStopOrder + 1
            : currentStopOrder);

    final busLat = telemetry?.latitude;
    final busLng = telemetry?.longitude;
    final hasBusLocation = busLat != null && busLng != null;

    // First stop scheduled time
    final scheduledDeparture = _parseRunDepartureTime(
      activeRunTime,
      currentTime,
    );

    for (int i = 0; i < orderedStops.length; i++) {
      final stop = orderedStops[i];
      final isFirstStop = stop.stopOrder == 1;
      final isPassed = stop.stopOrder < currentStopOrder;
      final isCurrent = stop.stopOrder == currentStopOrder;
      final isNext = stop.stopOrder == nextStopOrder;

      // Rule 19: Stops 1-17 QA coordinates strictly isolated from production ETAs
      if (stop.isTemporaryQa && !isQaPreview) {
        results[stop.id] = StopTimingInfo(
          stopId: stop.id,
          stopOrder: stop.stopOrder,
          actualArrivalTime: stop.actualArrivalTime,
          scheduledDepartureTime: isFirstStop ? activeRunTime : null,
          isPassed: isPassed,
          isCurrent: isCurrent,
          isNext: isNext,
          isQaPreviewOnly: true,
        );
        continue;
      }

      final actualTime = stop.actualArrivalTime;
      DateTime? etaTime;
      double? remainingDistMeters;

      if (isFirstStop && currentStopOrder <= 1 && scheduledDeparture != null) {
        // First stop schedule rule (Section 14)
        etaTime = scheduledDeparture;
      } else if (hasBusLocation && stop.stopOrder >= nextStopOrder) {
        // Future stop ahead of the bus: calculate ordered route ETA along road polyline
        remainingDistMeters = calculateRemainingRouteDistanceMeters(
          orderedStops: orderedStops,
          busLat: busLat,
          busLng: busLng,
          nextStopOrder: nextStopOrder,
          targetStopOrder: stop.stopOrder,
          routePolylinePoints: routePolylinePoints,
        );

        if (remainingDistMeters > 0 && effectiveSpeed > 0) {
          final travelHours = (remainingDistMeters / 1000.0) / effectiveSpeed;
          final intermediateStopsCount = math.max(
            0,
            stop.stopOrder - nextStopOrder,
          );
          final dwellSeconds = intermediateStopsCount * stopDwellTimeSeconds;
          final totalSeconds = (travelHours * 3600).round() + dwellSeconds;

          etaTime = currentTime.add(Duration(seconds: totalSeconds));
        }
      }

      results[stop.id] = StopTimingInfo(
        stopId: stop.id,
        stopOrder: stop.stopOrder,
        actualArrivalTime: actualTime,
        estimatedArrivalTime: etaTime,
        scheduledDepartureTime: isFirstStop ? activeRunTime : null,
        remainingDistanceMeters: remainingDistMeters,
        isPassed: isPassed,
        isCurrent: isCurrent,
        isNext: isNext,
        isQaPreviewOnly: stop.isTemporaryQa && isQaPreview,
      );
    }

    return results;
  }

  /// Parses active run string e.g. "08:00", "09:00", "13:00" into a DateTime on current date.
  DateTime? _parseRunDepartureTime(String? runTime, DateTime referenceTime) {
    if (runTime == null || !runTime.contains(':')) return null;
    final parts = runTime.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return DateTime.utc(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
      hour,
      minute,
    );
  }

  /// Human-friendly clock format: "08:27 AM" or "٠٨:٢٧ ص"
  static String formatClockTime(DateTime time, String locale) {
    final local = time.toLocal();
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final isPm = hour >= 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final hourStr = displayHour.toString().padLeft(2, '0');

    if (locale.startsWith('ar')) {
      final period = isPm ? 'م' : 'ص';
      return '$hourStr:$minute $period';
    } else {
      final period = isPm ? 'PM' : 'AM';
      return '$hourStr:$minute $period';
    }
  }

  /// Human-friendly countdown representation: "~6 min" or "6 min away"
  static String formatRemainingMinutes(
    DateTime targetTime,
    String locale, {
    DateTime? now,
  }) {
    final current = now?.toLocal() ?? DateTime.now();
    final diff = targetTime.toLocal().difference(current);
    final minutes = (diff.inSeconds / 60.0).round();

    if (minutes <= 1) {
      return locale.startsWith('ar') ? 'أقل من دقيقة' : '< 1 min';
    }

    if (locale.startsWith('ar')) {
      return '~$minutes د';
    } else {
      return '~$minutes min';
    }
  }

  /// Geodesic distance between two points in meters using Haversine formula.
  static double haversineDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = (lat2 - lat1) * (math.pi / 180.0);
    final dLon = (lon2 - lon1) * (math.pi / 180.0);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }
}

class _SpeedPoint {
  final double speedKmh;
  final DateTime timestamp;

  _SpeedPoint(this.speedKmh, this.timestamp);
}
