import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/fleet_bus.dart';
import 'package:amomy_bus/features/tracking/domain/models/fleet_tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';

class _FakeFleetTrackingRepo implements TrackingRepository {
  FleetTrackingSummary fleetSummary;

  _FakeFleetTrackingRepo({required this.fleetSummary});

  @override
  Future<FleetTrackingSummary> getPassengerFleetTracking() async {
    return fleetSummary;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Passenger Fleet Tracking Integration Tests', () {
    test('1. Fleet mode active when tripId is null or empty', () async {
      final repo = _FakeFleetTrackingRepo(
        fleetSummary: FleetTrackingSummary(
          mapEnabled: true,
          buses: [
            FleetBus(
              busId: 'bus-1',
              internalCode: 'AM-01',
              displayName: 'عمومي 1',
              latitude: 31.04,
              longitude: 31.37,
              isValid: true,
              hasLocation: true,
              gpsRecordedAt: DateTime.now().toUtc(),
            ),
          ],
          routes: const [],
          serverTime: DateTime.now().toUtc(),
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(); // null tripId

      expect(cubit.state.isFleetMode, isTrue);
      expect(cubit.state.hasVisibleFleetBuses, isTrue);
      expect(cubit.state.visibleFleetBuses.length, 1);
      expect(cubit.state.visibleFleetBuses.first.displayName, 'عمومي 1');
      expect(cubit.state.trackingStatus, LiveTrackingStatus.live);
      await cubit.close();
    });

    test('2. Global passenger map disabled sets isMapDisabled and offline status', () async {
      final repo = _FakeFleetTrackingRepo(
        fleetSummary: FleetTrackingSummary(
          mapEnabled: false,
          buses: [
            FleetBus(
              busId: 'bus-1',
              internalCode: 'AM-01',
              displayName: 'عمومي 1',
              latitude: 31.04,
              longitude: 31.37,
              isValid: true,
              hasLocation: true,
            ),
          ],
          routes: const [],
          serverTime: DateTime.now().toUtc(),
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData();

      expect(cubit.state.isFleetMode, isTrue);
      expect(cubit.state.isMapDisabled, isTrue);
      expect(cubit.state.trackingStatus, LiveTrackingStatus.offline);
      await cubit.close();
    });

    test('3. Map enabled but no buses returned results in empty fleet', () async {
      final repo = _FakeFleetTrackingRepo(
        fleetSummary: FleetTrackingSummary(
          mapEnabled: true,
          buses: const [],
          routes: const [],
          serverTime: DateTime.now().toUtc(),
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData();

      expect(cubit.state.isFleetMode, isTrue);
      expect(cubit.state.fleetBuses, isEmpty);
      expect(cubit.state.hasVisibleFleetBuses, isFalse);
      await cubit.close();
    });

    test('4. Map enabled but buses have null/invalid GPS coordinates', () async {
      final repo = _FakeFleetTrackingRepo(
        fleetSummary: FleetTrackingSummary(
          mapEnabled: true,
          buses: [
            FleetBus(
              busId: 'bus-1',
              internalCode: 'AM-01',
              displayName: 'عمومي 1',
              latitude: null,
              longitude: null,
              isValid: false,
              hasLocation: false,
            ),
          ],
          routes: const [],
          serverTime: DateTime.now().toUtc(),
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData();

      expect(cubit.state.isFleetMode, isTrue);
      expect(cubit.state.fleetBuses.length, 1);
      expect(cubit.state.hasVisibleFleetBuses, isFalse);
      await cubit.close();
    });

    test('5. Privacy: FleetBus.label only returns display_name and never plate_number or internal_code', () {
      final busWithDisplayName = FleetBus(
        busId: 'bus-1',
        internalCode: 'AM-01',
        plateNumber: 'ط ر ق 1234',
        displayName: 'عمومي 1',
        isValid: true,
        hasLocation: true,
      );

      final busWithoutDisplayName = FleetBus(
        busId: 'bus-2',
        internalCode: 'AM-02',
        plateNumber: 'س ي د 5678',
        displayName: null,
        isValid: true,
        hasLocation: true,
      );

      final busWithEmptyDisplayName = FleetBus(
        busId: 'bus-3',
        internalCode: 'AM-03',
        plateNumber: 'ع م م 9999',
        displayName: '   ',
        isValid: true,
        hasLocation: true,
      );

      expect(busWithDisplayName.label, 'عمومي 1');
      expect(busWithoutDisplayName.label, isEmpty);
      expect(busWithoutDisplayName.label, isNot(contains('AM-02')));
      expect(busWithoutDisplayName.label, isNot(contains('5678')));
      expect(busWithEmptyDisplayName.label, isEmpty);
      expect(busWithEmptyDisplayName.label, isNot(contains('AM-03')));
    });
  });
}
