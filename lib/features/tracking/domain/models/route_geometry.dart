import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Decoded road route geometry from backend [public.route_geometries].
class RouteGeometry {
  final String id;
  final String routeId;
  final String direction;
  final int version;
  final String polylineEncoded;
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final String source;
  final bool isVerified;

  const RouteGeometry({
    required this.id,
    required this.routeId,
    required this.direction,
    required this.version,
    required this.polylineEncoded,
    required this.points,
    this.distanceMeters = 0.0,
    this.durationSeconds = 0,
    this.source = 'google_routes',
    this.isVerified = false,
  });

  factory RouteGeometry.fromJson(Map<String, dynamic> json) {
    final encoded = (json['polyline_encoded'] ?? '') as String;
    final points = decodePolyline(encoded);
    return RouteGeometry(
      id: (json['id'] ?? '') as String,
      routeId: (json['route_id'] ?? '') as String,
      direction: (json['direction'] ?? 'OUTBOUND') as String,
      version: (json['version'] as num?)?.toInt() ?? 1,
      polylineEncoded: encoded,
      points: points,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      source: (json['source'] ?? 'google_routes') as String,
      isVerified: (json['is_verified'] as bool?) ?? false,
    );
  }

  /// Decodes a Google Encoded Polyline algorithm string into a list of [LatLng].
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }
}

/// Route quality and proximity diagnostics.
enum StopProximityQuality {
  excellent, // <= 75m
  acceptable, // 75–150m
  reviewNeeded, // > 150m
}

class StopValidationReport {
  final String stopId;
  final int stopOrder;
  final double shortestDistanceMeters;
  final StopProximityQuality quality;

  const StopValidationReport({
    required this.stopId,
    required this.stopOrder,
    required this.shortestDistanceMeters,
    required this.quality,
  });
}

/// Tools to validate road routes against stop locations and project bus onto road.
class RouteGeometryEngine {
  static const double _earthRadiusMeters = 6371000.0;

  /// Haversine distance in meters between two coordinates.
  static double distanceMeters(LatLng p1, LatLng p2) {
    final lat1 = p1.latitude * math.pi / 180.0;
    final lat2 = p2.latitude * math.pi / 180.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Calculates shortest perpendicular or endpoint distance from a coordinate to a polyline.
  static double shortestDistanceToPolyline(
    LatLng point,
    List<LatLng> polyline,
  ) {
    if (polyline.isEmpty) return double.infinity;
    if (polyline.length == 1) return distanceMeters(point, polyline.first);

    double minDistance = double.infinity;
    for (int i = 0; i < polyline.length - 1; i++) {
      final d = _distanceToSegment(point, polyline[i], polyline[i + 1]);
      if (d < minDistance) minDistance = d;
    }
    return minDistance;
  }

  /// Distance from [p] to line segment [v]-[w].
  static double _distanceToSegment(LatLng p, LatLng v, LatLng w) {
    final double l2 = _distSq(v, w);
    if (l2 == 0) return distanceMeters(p, v);

    // Project p onto line segment
    final double t =
        (((p.latitude - v.latitude) * (w.latitude - v.latitude) +
                    (p.longitude - v.longitude) * (w.longitude - v.longitude)) /
                l2)
            .clamp(0.0, 1.0);

    final projection = LatLng(
      v.latitude + t * (w.latitude - v.latitude),
      v.longitude + t * (w.longitude - v.longitude),
    );
    return distanceMeters(p, projection);
  }

  static double _distSq(LatLng p1, LatLng p2) {
    final dLat = p1.latitude - p2.latitude;
    final dLng = p1.longitude - p2.longitude;
    return (dLat * dLat) + (dLng * dLng);
  }

  /// Evaluates each stop's proximity to the road route.
  static List<StopValidationReport> validateStopsProximity({
    required List<LatLng> polyline,
    required List<Map<String, dynamic>> stops,
  }) {
    final List<StopValidationReport> reports = [];
    for (final s in stops) {
      final lat = (s['latitude'] as num?)?.toDouble();
      final lng = (s['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final dist = shortestDistanceToPolyline(LatLng(lat, lng), polyline);
      final StopProximityQuality quality;
      if (dist <= 75.0) {
        quality = StopProximityQuality.excellent;
      } else if (dist <= 150.0) {
        quality = StopProximityQuality.acceptable;
      } else {
        quality = StopProximityQuality.reviewNeeded;
      }

      reports.add(
        StopValidationReport(
          stopId: (s['id'] ?? '') as String,
          stopOrder: (s['stop_order'] as num?)?.toInt() ?? 0,
          shortestDistanceMeters: dist,
          quality: quality,
        ),
      );
    }
    return reports;
  }

  /// Projects GPS coordinate to nearest point on road polyline if within [maxSnapDistanceMeters].
  /// Returns original GPS location if too far (e.g. deviation or off-route).
  static LatLng projectBusLocation({
    required LatLng rawGps,
    required List<LatLng> polyline,
    double maxSnapDistanceMeters = 80.0,
  }) {
    if (polyline.length < 2) return rawGps;

    double minDistance = double.infinity;
    LatLng closestPoint = rawGps;

    for (int i = 0; i < polyline.length - 1; i++) {
      final v = polyline[i];
      final w = polyline[i + 1];
      final l2 = _distSq(v, w);
      if (l2 == 0) continue;

      final t =
          (((rawGps.latitude - v.latitude) * (w.latitude - v.latitude) +
                      (rawGps.longitude - v.longitude) *
                          (w.longitude - v.longitude)) /
                  l2)
              .clamp(0.0, 1.0);

      final projection = LatLng(
        v.latitude + t * (w.latitude - v.latitude),
        v.longitude + t * (w.longitude - v.longitude),
      );

      final d = distanceMeters(rawGps, projection);
      if (d < minDistance) {
        minDistance = d;
        closestPoint = projection;
      }
    }

    if (minDistance <= maxSnapDistanceMeters) {
      return closestPoint;
    }
    // Far from route -> Keep real GPS authoritative
    return rawGps;
  }

  /// Splits road polyline into [passed] and [upcoming] based on bus position.
  static ({List<LatLng> passed, List<LatLng> upcoming}) splitPolylineByBus({
    required List<LatLng> polyline,
    required LatLng busLocation,
  }) {
    if (polyline.length < 2) {
      return (passed: const <LatLng>[], upcoming: polyline);
    }

    int closestSegmentIndex = 0;
    double minDistance = double.infinity;
    LatLng projectionPoint = polyline.first;

    for (int i = 0; i < polyline.length - 1; i++) {
      final v = polyline[i];
      final w = polyline[i + 1];
      final l2 = _distSq(v, w);
      if (l2 == 0) continue;

      final t =
          (((busLocation.latitude - v.latitude) * (w.latitude - v.latitude) +
                      (busLocation.longitude - v.longitude) *
                          (w.longitude - v.longitude)) /
                  l2)
              .clamp(0.0, 1.0);

      final proj = LatLng(
        v.latitude + t * (w.latitude - v.latitude),
        v.longitude + t * (w.longitude - v.longitude),
      );

      final d = distanceMeters(busLocation, proj);
      if (d < minDistance) {
        minDistance = d;
        closestSegmentIndex = i;
        projectionPoint = proj;
      }
    }

    final List<LatLng> passed = [
      ...polyline.sublist(0, closestSegmentIndex + 1),
      projectionPoint,
    ];

    final List<LatLng> upcoming = [
      projectionPoint,
      ...polyline.sublist(closestSegmentIndex + 1),
    ];

    return (passed: passed, upcoming: upcoming);
  }

  /// Calculates remaining distance along road polyline from [fromPoint] to end of route.
  static double remainingPolylineDistanceMeters({
    required List<LatLng> polyline,
    required LatLng fromPoint,
  }) {
    final split = splitPolylineByBus(
      polyline: polyline,
      busLocation: fromPoint,
    );
    double dist = 0.0;
    for (int i = 0; i < split.upcoming.length - 1; i++) {
      dist += distanceMeters(split.upcoming[i], split.upcoming[i + 1]);
    }
    return dist;
  }
}
