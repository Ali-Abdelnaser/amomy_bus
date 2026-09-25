import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/fleet_tracking_summary.dart';
import '../../domain/models/route_geometry.dart';
import '../../domain/models/tracking_summary.dart';

abstract class TrackingRemoteDataSource {
  Future<TrackingSummary> getTripTracking({required String tripId});
  Future<FleetTrackingSummary> getPassengerFleetTracking();
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  });
  Stream<void> subscribeToTripTrackingState({required String tripId});
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  });
  Future<void> updateApproachAlertsPreference(bool enabled);
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  });
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final SupabaseClient _client;

  TrackingRemoteDataSourceImpl({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<FleetTrackingSummary> getPassengerFleetTracking() async {
    try {
      final response = await _client.rpc('get_passenger_fleet_tracking');
      if (response == null) {
        throw Exception('Fleet tracking returned null');
      }
      final data = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      return FleetTrackingSummary.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    try {
      final response = await _client.rpc(
        'get_my_trip_tracking',
        params: {'p_trip_id': tripId},
      );
      if (response == null) {
        throw Exception('Trip tracking returned null');
      }
      final data = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      return TrackingSummary.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async {
    try {
      final data = await _client
          .from('route_geometries')
          .select()
          .eq('route_id', routeId)
          .eq('direction', direction.toLowerCase())
          .eq('is_active', true)
          .order('version', ascending: false)
          .maybeSingle();

      if (data == null) return null;
      return RouteGeometry.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) {
    return _client
        .from('trip_tracking_state')
        .stream(primaryKey: ['trip_id'])
        .eq('trip_id', tripId)
        .where((rows) => rows.isNotEmpty)
        .map((_) {})
        .handleError((_) {});
  }

  @override
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) async {
    try {
      final response = await _client.rpc(
        'record_approach_notification',
        params: {
          'p_route_id': routeId,
          'p_target_stop_id': targetStopId,
          'p_service_run_time': serviceRunTime,
          'p_title_ar': titleAr,
          'p_title_en': titleEn,
          'p_body_ar': bodyAr,
          'p_body_en': bodyEn,
        },
      );

      if (response != null && response is Map) {
        return (response['dispatched'] as bool?) ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('passenger_trip_preferences').upsert({
      'user_id': userId,
      'approach_alerts_enabled': enabled,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {
    await _client.rpc(
      'qa_simulate_bus_location',
      params: {
        'p_bus_id': busId,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_heading': heading,
        'p_speed_kmh': speedKmh,
      },
    );
  }
}
