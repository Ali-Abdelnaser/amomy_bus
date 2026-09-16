import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/bus_telemetry.dart';
import '../../domain/models/route_geometry.dart';
import '../../domain/models/tracking_summary.dart';

abstract class TrackingRemoteDataSource {
  Future<TrackingSummary> getLiveTrackingSummary({bool includeQa = false});
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  });
  Stream<BusTelemetry> subscribeToBusLiveLocation();
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
  Future<TrackingSummary> getLiveTrackingSummary({
    bool includeQa = false,
  }) async {
    try {
      final response = await _client.rpc(
        'get_live_bus_tracking_summary',
        params: includeQa ? {'p_include_qa': true} : {},
      );
      if (response == null) {
        throw Exception('Tracking summary returned null');
      }
      final data = response is Map<String, dynamic>
          ? response
          : Map<String, dynamic>.from(response as Map);
      return TrackingSummary.fromJson(data);
    } catch (e, stack) {
      debugPrint(
        '[TrackingRemoteDataSource] getLiveTrackingSummary error: $e\n$stack',
      );
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
    } catch (e) {
      debugPrint('[TrackingRemoteDataSource] getActiveRouteGeometry error: $e');
      return null;
    }
  }

  @override
  Stream<BusTelemetry> subscribeToBusLiveLocation() {
    debugPrint('[REALTIME_DIAG] bus_live_locations subscribe start');
    return _client
        .from('bus_live_locations')
        .stream(primaryKey: ['bus_id'])
        .where((rows) => rows.isNotEmpty)
        .map((rows) {
          debugPrint('[REALTIME_DIAG] bus_live_locations event');
          // Sort by gps_recorded_at descending to get latest
          final sorted = List<Map<String, dynamic>>.from(rows)
            ..sort((a, b) {
              final aTime =
                  DateTime.tryParse(a['gps_recorded_at']?.toString() ?? '') ??
                  DateTime(1970);
              final bTime =
                  DateTime.tryParse(b['gps_recorded_at']?.toString() ?? '') ??
                  DateTime(1970);
              return bTime.compareTo(aTime);
            });
          return BusTelemetry.fromJson(sorted.first);
        })
        .handleError((error, stackTrace) {
          debugPrint(
            '[REALTIME_DIAG] bus_live_locations error: ${error.runtimeType}',
          );
        });
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
    } catch (e) {
      debugPrint(
        '[TrackingRemoteDataSource] recordApproachNotification error: $e',
      );
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
