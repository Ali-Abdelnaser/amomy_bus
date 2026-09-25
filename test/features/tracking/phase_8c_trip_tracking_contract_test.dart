import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';

class _FakeTripTrackingRepository extends TrackingRepository {
  final List<String> requestedTripIds = [];
  final List<String> subscribedTripIds = [];
  final List<String> cancelledTripIds = [];
  final Map<String, StreamController<void>> controllers = {};
  final List<TrackingSummary> responses;
  int responseIndex = 0;

  _FakeTripTrackingRepository(this.responses);

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    requestedTripIds.add(tripId);
    final index = responseIndex.clamp(0, responses.length - 1);
    responseIndex++;
    return responses[index];
  }

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) {
    subscribedTripIds.add(tripId);
    final controller = StreamController<void>.broadcast(
      onCancel: () => cancelledTripIds.add(tripId),
    );
    controllers[tripId] = controller;
    return controller.stream;
  }

  void emitRevision(String tripId) => controllers[tripId]?.add(null);

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) async => false;

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) async {}

  @override
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {}
}

TrackingSummary _summary({
  required LiveTrackingStatus status,
  String tripId = 'trip-a',
  bool withCoordinates = false,
  List<BusStopModel> stops = const [],
  BusStopModel? currentStop,
  BusStopModel? nextStop,
  BusStopModel? lastPassedStop,
  String etaStatus = 'unavailable',
}) {
  return TrackingSummary.fromJson({
    'tracking_status': switch (status) {
      LiveTrackingStatus.live => 'live',
      LiveTrackingStatus.stale => 'stale',
      LiveTrackingStatus.assignmentPending => 'assignment_pending',
      LiveTrackingStatus.tripNotActive => 'trip_not_active',
      LiveTrackingStatus.outsideTrackingWindow => 'outside_tracking_window',
      LiveTrackingStatus.progressionUnavailable => 'progression_unavailable',
      _ => 'offline',
    },
    'trip_id': tripId,
    'direction': 'return',
    'service_date': '2026-09-16',
    'departure_at': '2026-09-16T13:00:00Z',
    if (withCoordinates) ...{
      'latitude': 31.0379,
      'longitude': 31.3815,
      'heading': 88,
      'gps_recorded_at': '2026-09-16T10:30:00Z',
    },
    'progress_state': status == LiveTrackingStatus.progressionUnavailable
        ? 'progression_unavailable'
        : 'in_transit',
    'eta_status': etaStatus,
    'eta_at': null,
    'ordered_stops': stops.map((s) => s.toJson()).toList(),
    if (currentStop != null) 'current_stop': currentStop.toJson(),
    if (nextStop != null) 'next_stop': nextStop.toJson(),
    if (lastPassedStop != null) 'last_passed_stop': lastPassedStop.toJson(),
    'tracking_window': {
      'next_window_start_time': '13:00',
      'next_window_is_tomorrow': false,
    },
  });
}

BusStopModel _stop(int order, TrackingStopSemanticState state) => BusStopModel(
  id: 'stop-$order',
  routeStopId: 'route-stop-$order',
  stopOrder: order,
  nameAr: 'محطة $order',
  nameEn: 'Stop $order',
  localityAr: 'المنصورة',
  localityEn: 'Mansoura',
  latitude: 31.0 + order / 1000,
  longitude: 31.3 + order / 1000,
  actualArrivalTime: state == TrackingStopSemanticState.passed
      ? DateTime.utc(2026, 9, 16, 10, 32)
      : null,
  semanticState: state,
);

void main() {
  test(
    'A/S. get_my_trip_tracking equivalent uses exact trip_id and refetches on revision',
    () async {
      final repo = _FakeTripTrackingRepository([
        _summary(
          status: LiveTrackingStatus.live,
          tripId: 'trip-123',
          withCoordinates: true,
        ),
        _summary(
          status: LiveTrackingStatus.live,
          tripId: 'trip-123',
          withCoordinates: true,
        ),
      ]);
      final cubit = TrackingCubit(repository: repo);

      await cubit.loadTrackingData(tripId: 'trip-123');
      repo.emitRevision('trip-123');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(repo.requestedTripIds, ['trip-123', 'trip-123']);
      expect(repo.subscribedTripIds, ['trip-123']);
      await cubit.close();
    },
  );

  test(
    'B. passenger tracking repository source has no direct raw operational live feed reads',
    () {
      final source = File(
        'lib/features/tracking/data/datasources/tracking_remote_datasource.dart',
      ).readAsStringSync();

      expect(source.contains('get_my_trip_tracking'), isTrue);
      expect(source.contains('trip_tracking_state'), isTrue);
      expect(source.contains('bus_live_locations'), isFalse);
      expect(source.contains('trip_stop_events'), isFalse);
      expect(source.contains('trip_assignments'), isFalse);
      expect(source.contains('bus_tracking_devices'), isFalse);
      expect(source.contains("from('buses')"), isFalse);
    },
  );

  test(
    'C/D/E/F/G/H/R/U/V. status mapping controls marker state safely',
    () async {
      final repo = _FakeTripTrackingRepository([
        _summary(status: LiveTrackingStatus.live, withCoordinates: true),
        _summary(
          status: LiveTrackingStatus.assignmentPending,
          withCoordinates: true,
        ),
        _summary(status: LiveTrackingStatus.stale, withCoordinates: true),
        _summary(status: LiveTrackingStatus.offline, withCoordinates: true),
        _summary(status: LiveTrackingStatus.outsideTrackingWindow),
        _summary(
          status: LiveTrackingStatus.progressionUnavailable,
          withCoordinates: true,
        ),
      ]);
      final cubit = TrackingCubit(repository: repo);

      await cubit.loadTrackingData(tripId: 'trip-a');
      expect(cubit.state.trackingStatus, LiveTrackingStatus.live);
      expect(cubit.state.latestTelemetry, isNotNull);

      await cubit.loadTrackingData(tripId: 'trip-a', isRefresh: true);
      expect(cubit.state.trackingStatus, LiveTrackingStatus.assignmentPending);
      expect(cubit.state.latestTelemetry, isNull);

      await cubit.loadTrackingData(tripId: 'trip-a', isRefresh: true);
      expect(cubit.state.trackingStatus, LiveTrackingStatus.stale);
      expect(cubit.state.latestTelemetry, isNotNull);
      expect(cubit.state.latestTelemetry!.isStale, isTrue);

      await cubit.loadTrackingData(tripId: 'trip-a', isRefresh: true);
      expect(cubit.state.trackingStatus, LiveTrackingStatus.offline);
      expect(cubit.state.latestTelemetry, isNull);

      await cubit.loadTrackingData(tripId: 'trip-a', isRefresh: true);
      expect(
        cubit.state.trackingStatus,
        LiveTrackingStatus.outsideTrackingWindow,
      );

      await cubit.loadTrackingData(tripId: 'trip-a', isRefresh: true);
      expect(
        cubit.state.trackingStatus,
        LiveTrackingStatus.progressionUnavailable,
      );
      expect(cubit.state.summary!.etaStatus, 'unavailable');
      expect(cubit.state.summary!.etaAt, isNull);
      expect(cubit.state.latestTelemetry, isNotNull);
      expect(cubit.state.progression, isNull);
      await cubit.close();
    },
  );

  test(
    'I/J/K/L/M/N/O/P/Q. ordered stops and semantic states are backend-owned',
    () {
      final stops = [
        _stop(16, TrackingStopSemanticState.passed),
        _stop(15, TrackingStopSemanticState.active),
        _stop(14, TrackingStopSemanticState.next),
        _stop(13, TrackingStopSemanticState.future),
        _stop(12, TrackingStopSemanticState.unknown),
      ];

      final summary = _summary(
        status: LiveTrackingStatus.live,
        withCoordinates: true,
        stops: stops,
        currentStop: stops[1],
        nextStop: stops[2],
        lastPassedStop: stops[0],
      );

      expect(summary.activeDirection, TrackingDirection.returnDirection);
      expect(summary.routeStops.map((s) => s.stopOrder), [16, 15, 14, 13, 12]);
      expect(summary.routeStops.map((s) => s.semanticState), [
        TrackingStopSemanticState.passed,
        TrackingStopSemanticState.active,
        TrackingStopSemanticState.next,
        TrackingStopSemanticState.future,
        TrackingStopSemanticState.unknown,
      ]);
      expect(summary.lastPassedStop!.actualArrivalTime, isNotNull);
      expect(
        summary.routeStops.last.actualArrivalTime,
        isNull,
        reason: 'Unknown/future stops must not fabricate reached time.',
      );
    },
  );

  test(
    'T. changing tracked trip cancels previous invalidation subscription',
    () async {
      final repo = _FakeTripTrackingRepository([
        _summary(status: LiveTrackingStatus.live, tripId: 'trip-a'),
        _summary(status: LiveTrackingStatus.live, tripId: 'trip-b'),
      ]);
      final cubit = TrackingCubit(repository: repo);

      await cubit.loadTrackingData(tripId: 'trip-a');
      await cubit.loadTrackingData(tripId: 'trip-b');

      expect(repo.subscribedTripIds, ['trip-a', 'trip-b']);
      expect(repo.cancelledTripIds, contains('trip-a'));
      await cubit.close();
    },
  );

  test(
    'W/X. passenger tracking source avoids operational identity fields and shares cubit',
    () {
      final trackingFiles = [
        'lib/features/tracking/presentation/widgets/home_live_tracking_card.dart',
        'lib/features/tracking/presentation/screens/live_map_screen.dart',
        'lib/features/tracking/presentation/cubit/tracking_cubit.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');

      expect(trackingFiles.contains('BUS-AMY'), isFalse);
      expect(trackingFiles.contains('plate'), isFalse);
      expect(trackingFiles.contains('driver'), isFalse);
      expect(trackingFiles.contains('device'), isFalse);
      expect(trackingFiles.contains('TrackingCubit'), isTrue);
    },
  );
}
