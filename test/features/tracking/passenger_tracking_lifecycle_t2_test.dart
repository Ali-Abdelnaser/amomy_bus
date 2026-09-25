import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';

class _MockTrackingRepository extends TrackingRepository {
  final List<String> requestedTripIds = [];
  final List<String> subscribedTripIds = [];
  final List<String> cancelledTripIds = [];
  final Map<String, StreamController<void>> controllers = {};
  TrackingSummary Function(String tripId)? responseProvider;

  _MockTrackingRepository({this.responseProvider});

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    requestedTripIds.add(tripId);
    if (responseProvider != null) {
      return responseProvider!(tripId);
    }
    return TrackingSummary.fromJson({
      'trip_id': tripId,
      'tracking_status': 'offline',
      'tracking_phase': 'waiting_assignment',
      'tracking_enabled': false,
    });
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

void main() {
  group('Phase T2 — Passenger Tracking Lifecycle Tests', () {
    test(
      '1. No booking / empty tripId sets error and clears tracking',
      () async {
        final repo = _MockTrackingRepository();
        final cubit = TrackingCubit(repository: repo);

        await cubit.loadTrackingData(tripId: '');

        expect(cubit.state.uiStatus, TrackingUiStatus.error);
        expect(cubit.state.summary, isNull);
        expect(cubit.state.latestTelemetry, isNull);
        expect(cubit.state.errorMessage, contains('requires a booked trip'));
        await cubit.close();
      },
    );

    test(
      '2. waiting_assignment: parses phase, trackingEnabled is false, no bus location',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'assignment_pending',
            'tracking_phase': 'waiting_assignment',
            'tracking_enabled': false,
            'direction': 'outbound',
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-101');

        expect(cubit.state.trackingPhase, TrackingPhase.waitingAssignment);
        expect(cubit.state.trackingEnabled, isFalse);
        expect(cubit.state.isWaitingAssignment, isTrue);
        expect(cubit.state.latestTelemetry, isNull);
        await cubit.close();
      },
    );

    test(
      '3. waiting_start: trip has assignment but driver has not started, no telemetry',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'trip_not_active',
            'tracking_phase': 'waiting_start',
            'tracking_enabled': false,
            'trip_status': 'ready',
            'latitude': 31.0379,
            'longitude': 31.3815,
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-102');

        expect(cubit.state.trackingPhase, TrackingPhase.waitingStart);
        expect(cubit.state.trackingEnabled, isFalse);
        expect(cubit.state.isWaitingStart, isTrue);
        expect(
          cubit.state.latestTelemetry,
          isNull,
        ); // suppressed before driver starts
        await cubit.close();
      },
    );

    test(
      '4. driver-started live state: trackingEnabled is true, telemetry is live',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'live',
            'tracking_phase': 'live',
            'tracking_enabled': true,
            'trip_status': 'started',
            'started_at': '2026-09-20T08:05:00Z',
            'latitude': 31.0379,
            'longitude': 31.3815,
            'heading': 120,
            'gps_recorded_at': '2026-09-20T08:10:00Z',
            'gps_age_seconds': 5,
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-103');

        expect(cubit.state.trackingPhase, TrackingPhase.live);
        expect(cubit.state.trackingEnabled, isTrue);
        expect(cubit.state.isLive, isTrue);
        expect(cubit.state.latestTelemetry, isNotNull);
        expect(cubit.state.latestTelemetry!.latitude, 31.0379);
        expect(cubit.state.latestTelemetry!.longitude, 31.3815);
        expect(cubit.state.latestTelemetry!.isStale, isFalse);
        await cubit.close();
      },
    );

    test('5. gps_stale: tracking is enabled, location marked stale', () async {
      final repo = _MockTrackingRepository(
        responseProvider: (id) => TrackingSummary.fromJson({
          'trip_id': id,
          'tracking_status': 'stale',
          'tracking_phase': 'gps_stale',
          'tracking_enabled': true,
          'trip_status': 'in_progress',
          'latitude': 31.0380,
          'longitude': 31.3820,
          'gps_recorded_at': '2026-09-20T08:00:00Z',
          'gps_age_seconds': 180,
        }),
      );
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-104');

      expect(cubit.state.trackingPhase, TrackingPhase.gpsStale);
      expect(cubit.state.trackingEnabled, isTrue);
      expect(cubit.state.isGpsStale, isTrue);
      expect(cubit.state.latestTelemetry, isNotNull);
      expect(cubit.state.latestTelemetry!.isStale, isTrue);
      expect(cubit.state.summary!.gpsAgeSeconds, 180);
      await cubit.close();
    });

    test(
      '6. gps_offline: tracking enabled but telemetry suppressed (no fake marker)',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'offline',
            'tracking_phase': 'gps_offline',
            'tracking_enabled': true,
            'trip_status': 'in_progress',
            'latitude': 31.0380,
            'longitude': 31.3820,
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-105');

        expect(cubit.state.trackingPhase, TrackingPhase.gpsOffline);
        expect(cubit.state.trackingEnabled, isTrue);
        expect(cubit.state.isGpsOffline, isTrue);
        expect(cubit.state.latestTelemetry, isNull);
        await cubit.close();
      },
    );

    test(
      '7. progression_syncing: location present, stops not yet confident',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'progression_unavailable',
            'tracking_phase': 'progression_syncing',
            'tracking_enabled': true,
            'latitude': 31.0400,
            'longitude': 31.3900,
            'eta_status': 'syncing',
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-106');

        expect(cubit.state.trackingPhase, TrackingPhase.progressionSyncing);
        expect(cubit.state.trackingEnabled, isTrue);
        expect(cubit.state.isProgressionSyncing, isTrue);
        expect(cubit.state.latestTelemetry, isNotNull);
        expect(cubit.state.currentStop, isNull);
        await cubit.close();
      },
    );

    test(
      '8. reassignment_pending: suppresses previous bus telemetry',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'assignment_pending',
            'tracking_phase': 'reassignment_pending',
            'tracking_enabled': false,
            'latitude': 31.0400,
            'longitude': 31.3900,
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-107');

        expect(cubit.state.trackingPhase, TrackingPhase.reassignmentPending);
        expect(cubit.state.trackingEnabled, isFalse);
        expect(cubit.state.isReassignmentPending, isTrue);
        expect(cubit.state.latestTelemetry, isNull); // must not follow old bus
        await cubit.close();
      },
    );

    test(
      '9. completed / cancelled hides tracking and suppresses telemetry',
      () async {
        final repo = _MockTrackingRepository(
          responseProvider: (id) => TrackingSummary.fromJson({
            'trip_id': id,
            'tracking_status': 'offline',
            'tracking_phase': 'completed',
            'tracking_enabled': false,
            'trip_status': 'completed',
            'completed_at': '2026-09-20T09:00:00Z',
          }),
        );
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-108');

        expect(cubit.state.trackingPhase, TrackingPhase.completed);
        expect(cubit.state.trackingEnabled, isFalse);
        expect(cubit.state.isCompleted, isTrue);
        expect(cubit.state.latestTelemetry, isNull);
        await cubit.close();
      },
    );

    test('10. multiple booked trips use exact trip_id requested', () async {
      final repo = _MockTrackingRepository(
        responseProvider: (id) => TrackingSummary.fromJson({
          'trip_id': id,
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
        }),
      );
      final cubit = TrackingCubit(repository: repo);

      await cubit.loadTrackingData(tripId: 'trip-alpha');
      expect(cubit.state.trackedTripId, 'trip-alpha');
      expect(repo.requestedTripIds, contains('trip-alpha'));

      await cubit.loadTrackingData(tripId: 'trip-beta');
      expect(cubit.state.trackedTripId, 'trip-beta');
      expect(repo.requestedTripIds, contains('trip-beta'));
      await cubit.close();
    });

    test(
      '11. realtime trip_tracking_state change triggers RPC refetch',
      () async {
        int fetchCount = 0;
        final repo = _MockTrackingRepository(
          responseProvider: (id) {
            fetchCount++;
            return TrackingSummary.fromJson({
              'trip_id': id,
              'tracking_status': fetchCount == 1 ? 'trip_not_active' : 'live',
              'tracking_phase': fetchCount == 1 ? 'waiting_start' : 'live',
              'tracking_enabled': fetchCount != 1,
            });
          },
        );
        final cubit = TrackingCubit(repository: repo);

        await cubit.loadTrackingData(tripId: 'trip-realtime');
        expect(cubit.state.trackingPhase, TrackingPhase.waitingStart);
        expect(fetchCount, 1);

        // Driver starts trip -> realtime notification arrives
        repo.emitRevision('trip-realtime');
        // Wait for debounce timer (350ms)
        await Future.delayed(const Duration(milliseconds: 450));

        expect(fetchCount, 2);
        expect(cubit.state.trackingPhase, TrackingPhase.live);
        expect(cubit.state.trackingEnabled, isTrue);
        await cubit.close();
      },
    );

    test(
      '12. old time windows do NOT control tracking availability in TrackingSummary / TrackingCubit',
      () {
        // Regardless of current system time or tracking_window values, backend tracking_phase + tracking_enabled rule.
        final summary = TrackingSummary.fromJson({
          'trip_id': 'trip-nowindow',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'tracking_window': {'mode': 'trip_lifecycle'},
        });

        expect(summary.trackingPhase, TrackingPhase.live);
        expect(summary.trackingEnabled, isTrue);
        expect(summary.status, LiveTrackingStatus.live);
      },
    );

    test(
      '13. no bus identity (bus_id, plate, internal code, driver) appears in passenger model',
      () {
        final summary = TrackingSummary.fromJson({
          'trip_id': 'trip-clean',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'bus_id': 'BUS-SECRET-123', // Raw DB field if sent by mistake
          'plate_number': 'ABC 1234',
          'internal_code': 'BUS-42',
          'driver_name': 'Secret Driver',
          'latitude': 31.0379,
          'longitude': 31.3815,
        });

        final summaryStr = summary.toString();
        expect(summaryStr.contains('BUS-SECRET-123'), isFalse);
        expect(summaryStr.contains('ABC 1234'), isFalse);
        expect(summaryStr.contains('BUS-42'), isFalse);
        expect(summaryStr.contains('Secret Driver'), isFalse);

        final telemetryStr = summary.busLocation.toString();
        expect(telemetryStr.contains('BUS-SECRET-123'), isFalse);
        expect(telemetryStr.contains('ABC 1234'), isFalse);
      },
    );
  });
}
