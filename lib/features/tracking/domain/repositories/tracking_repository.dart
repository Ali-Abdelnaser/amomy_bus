import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';

import '../models/bus_telemetry.dart';
import '../models/tracking_summary.dart';

/// Contract for authoritative Live Bus Tracking data and push notification dispatch.
abstract class TrackingRepository {
  /// Fetches authoritative live tracking snapshot from Supabase RPC.
  Future<TrackingSummary> getTrackingSummary({bool includeQa = false});

  /// Fetches active road geometry for the current route and direction from Supabase.
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  });

  /// Subscribes to Supabase Realtime updates on `public:bus_live_locations`.
  Stream<BusTelemetry> subscribeToBusLiveLocation();

  /// Dispatches or records an approach notification with strict backend idempotency.
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  });

  /// Updates passenger approach alerts preference.
  Future<void> updateApproachAlertsPreference(bool enabled);

  /// QA-only isolated telemetry simulation (restricted to admin / QA test users).
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  });
}
