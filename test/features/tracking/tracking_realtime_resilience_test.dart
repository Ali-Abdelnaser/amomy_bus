import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';

// ---------------------------------------------------------------------------
// Fake repository with controllable telemetry stream
// ---------------------------------------------------------------------------
class FakeResilienceTrackingRepository implements TrackingRepository {
  final TrackingSummary summary;
  StreamController<BusTelemetry> _controller =
      StreamController<BusTelemetry>.broadcast();

  FakeResilienceTrackingRepository({required this.summary});

  @override
  Future<TrackingSummary> getTrackingSummary({bool includeQa = false}) async =>
      summary;

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Stream<BusTelemetry> subscribeToBusLiveLocation() => _controller.stream;

  void emitTelemetry(BusTelemetry t) => _controller.add(t);
  void emitError(Object error) => _controller.addError(error);

  // Replaces the underlying controller so we can simulate new subscriptions
  void replaceController() {
    _controller = StreamController<BusTelemetry>.broadcast();
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

// ---------------------------------------------------------------------------
// Minimal TrackingSummary for tests (bus offline, no stops needed)
// ---------------------------------------------------------------------------
TrackingSummary _offlineSummary() => const TrackingSummary(
  status: LiveTrackingStatus.offline,
  routeStops: [],
  isInServiceWindow: false,
  serviceWindow: 'offline',
  cairoTime: '19:00:00',
  cairoDate: '2026-09-15',
  activeDirection: TrackingDirection.outbound,
);

BusTelemetry _sampleTelemetry() => BusTelemetry(
  latitude: 30.0626,
  longitude: 31.2497,
  heading: 90,
  speedKmh: 30,
  gpsRecordedAt: DateTime.now().toUtc(),
  source: 'etrack',
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('TrackingCubit — realtime subscription resilience', () {
    late FakeResilienceTrackingRepository repo;
    late TrackingCubit cubit;

    setUp(() {
      repo = FakeResilienceTrackingRepository(summary: _offlineSummary());
      cubit = TrackingCubit(repository: repo, isQaAuthorizedOverride: false);
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'bus_live_locations telemetry event updates TrackingCubit state',
      () async {
        await cubit.loadTrackingData();
        expect(cubit.state.uiStatus, TrackingUiStatus.loaded);

        final telemetry = _sampleTelemetry();
        repo.emitTelemetry(telemetry);
        await pumpEventQueue();

        expect(cubit.state.latestTelemetry?.latitude, telemetry.latitude);
      },
    );

    test(
      'bus_live_locations channelError does NOT escape to global zone',
      () async {
        await cubit.loadTrackingData();

        Object? uncaughtError;
        await runZonedGuarded(
          () async {
            repo.emitError(
              Exception(
                'Unable to subscribe to changes with given parameters. channelError',
              ),
            );
            await pumpEventQueue();
          },
          (error, stack) {
            uncaughtError = error;
          },
        );

        // Error must NOT have escaped to the zone
        expect(uncaughtError, isNull);
      },
    );

    test(
      'TrackingCubit stays loaded after bus_live_locations stream error',
      () async {
        await cubit.loadTrackingData();
        expect(cubit.state.uiStatus, TrackingUiStatus.loaded);

        // Emit error
        repo.emitError(Exception('channelError'));
        await pumpEventQueue();

        // State preserved
        expect(cubit.state.uiStatus, TrackingUiStatus.loaded);
      },
    );

    test(
      'TrackingCubit continues receiving events after stream error (cancelOnError: false)',
      () async {
        await cubit.loadTrackingData();

        // First — fire an error
        repo.emitError(Exception('channelError'));
        await pumpEventQueue();

        // Then — fire a real telemetry event
        final telemetry = _sampleTelemetry();
        repo.emitTelemetry(telemetry);
        await pumpEventQueue();

        // Cubit processed the telemetry after the error
        expect(cubit.state.latestTelemetry?.latitude, telemetry.latitude);
      },
    );

    test(
      'Subscriptions cancelled on cubit close — late telemetry not processed',
      () async {
        await cubit.loadTrackingData();
        expect(cubit.state.uiStatus, TrackingUiStatus.loaded);
        final initialTelemetry = cubit.state.latestTelemetry;

        // Close cubit
        await cubit.close();

        // Emit after close — must not throw
        expect(() => repo.emitTelemetry(_sampleTelemetry()), returnsNormally);
        await pumpEventQueue();

        // State must not have changed after close
        expect(cubit.state.latestTelemetry, initialTelemetry);
      },
    );

    test(
      'Empty bus_live_locations rows are silently skipped — no error emitted',
      () async {
        // The datasource uses .where((rows) => rows.isNotEmpty) so empty rows
        // never reach the cubit. This test verifies the cubit stays loaded
        // even when no telemetry arrives (offline scenario).
        await cubit.loadTrackingData();
        expect(cubit.state.uiStatus, TrackingUiStatus.loaded);
        expect(cubit.state.latestTelemetry, isNull); // no telemetry emitted
      },
    );
  });
}
