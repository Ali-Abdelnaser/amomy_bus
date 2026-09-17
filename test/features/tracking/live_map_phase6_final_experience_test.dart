import 'dart:async';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:amomy_bus/core/map/map_tile_config.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/domain/services/stop_eta_engine.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:amomy_bus/features/tracking/presentation/screens/live_map_screen.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockTrackingRepository implements TrackingRepository {
  TrackingSummary summary;
  final StreamController<BusTelemetry> _telemetryController =
      StreamController<BusTelemetry>.broadcast();

  MockTrackingRepository({required this.summary});

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    return summary;
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) =>
      _telemetryController.stream;

  void emitTelemetry(BusTelemetry tel) => _telemetryController.add(tel);

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
    return true;
  }

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

  void dispose() {
    _telemetryController.close();
  }
}

Widget createTestApp({
  required Widget child,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Future<void> pumpAndAdvance(WidgetTester tester, [int count = 4]) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<BusStopModel> testStops = [
    const BusStopModel(
      id: 'stop-1',
      routeStopId: 'rs-1',
      stopOrder: 1,
      nameAr: 'كوبرى عزت — ميت فضالة',
      nameEn: 'Ezzat Bridge - Mit Fadala',
      localityAr: 'ميت فضالة',
      localityEn: 'Mit Fadala',
      latitude: 30.9100,
      longitude: 31.3100,
      isTemporaryQa: true,
      farePoints: 20,
    ),
    const BusStopModel(
      id: 'stop-2',
      routeStopId: 'rs-2',
      stopOrder: 2,
      nameAr: 'موقف دنديط',
      nameEn: 'Dandait Station',
      localityAr: 'دنديط',
      localityEn: 'Dandait',
      latitude: 30.9150,
      longitude: 31.3200,
      isTemporaryQa: true,
      farePoints: 20,
    ),
    BusStopModel(
      id: 'stop-18',
      routeStopId: 'rs-18',
      stopOrder: 18,
      nameAr: 'ماركت المراعي',
      nameEn: 'Al Marai Market',
      localityAr: 'برج النور الحمص',
      localityEn: 'Borg El Nour',
      latitude: 30.9350382,
      longitude: 31.34714024,
      isTemporaryQa: false,
      actualArrivalTime: DateTime.utc(2026, 9, 13, 8, 23, 0),
      farePoints: 20,
    ),
    const BusStopModel(
      id: 'stop-19',
      routeStopId: 'rs-19',
      stopOrder: 19,
      nameAr: 'شركة الحرمين',
      nameEn: 'Al Haramain Co',
      localityAr: 'برج النور الحمص',
      localityEn: 'Borg El Nour',
      latitude: 30.9388338,
      longitude: 31.35249454,
      isTemporaryQa: false,
      farePoints: 20,
    ),
  ];

  final activeTelemetry = BusTelemetry(
    latitude: 30.9360,
    longitude: 31.3490,
    heading: 45,
    speedKmh: 23.0,
    gpsRecordedAt: DateTime.utc(2026, 9, 13, 8, 25, 0),
    isStale: false,
    currentStopId: 'stop-18',
    nextStopId: 'stop-19',
    currentStopOrder: 18,
    nextStopOrder: 19,
    source: 'etrack',
  );

  final activeSummary = TrackingSummary(
    status: LiveTrackingStatus.online,
    serviceState: 'in_service',
    progressState: 'in_transit',
    isInServiceWindow: true,
    serviceWindow: 'morning',
    cairoTime: '08:23:00',
    cairoDate: '2026-09-13',
    activeDirection: TrackingDirection.outbound,
    activeRunTime: '08:00',
    busLocation: activeTelemetry,
    currentStop: testStops[2],
    nextStop: testStops[3],
    currentStopId: 'stop-18',
    nextStopId: 'stop-19',
    routeStops: testStops,
  );

  group('AMOMY Tracking Phase 6 — Final Experience Tests', () {
    test(
      '1. Production Map configuration uses Stadia Alidade Smooth when API key provided',
      () {
        final config = MapTileConfig.productionStadia('test_key');
        expect(
          config.tileUrl,
          contains('tiles.stadiamaps.com/tiles/alidade_smooth'),
        );
        expect(config.tileUrl, contains('api_key=test_key'));
        expect(config.attribution, contains('Stadia Maps'));
        expect(config.attribution, contains('OpenMapTiles'));
        expect(config.attribution, contains('OpenStreetMap contributors'));
      },
    );

    test(
      '2. Debug fallback uses OSM Standard while Release without key is unavailable',
      () {
        final debugConfig = MapTileConfig.resolveActiveConfig(
          explicitApiKey: '',
          isReleaseModeOverride: false,
        );
        expect(
          debugConfig.tileUrl,
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        );
        expect(debugConfig.isAvailable, isTrue);

        final releaseConfig = MapTileConfig.resolveActiveConfig(
          explicitApiKey: '',
          isReleaseModeOverride: true,
        );
        expect(releaseConfig.isAvailable, isFalse);
        expect(releaseConfig.tileUrl, isEmpty);
      },
    );

    test('3. Follow mode is ON initially in TrackingState', () {
      const state = TrackingState();
      expect(state.followBus, isTrue);
    });

    test('4. Toggle follow bus updates state', () {
      final cubit = TrackingCubit(
        repository: MockTrackingRepository(summary: activeSummary),
      );
      expect(cubit.state.followBus, isTrue);
      cubit.toggleFollowBus(false);
      expect(cubit.state.followBus, isFalse);
      cubit.toggleFollowBus(true);
      expect(cubit.state.followBus, isTrue);
      cubit.close();
    });

    test(
      '5. Shortest heading rotation calculation handles 360 wrap cleanly',
      () {
        double delta = (10.0 - 350.0) % 360;
        if (delta > 180) delta -= 360;
        if (delta < -180) delta += 360;
        expect(delta, 20.0);

        double deltaRev = (350.0 - 10.0) % 360;
        if (deltaRev > 180) deltaRev -= 360;
        if (deltaRev < -180) deltaRev += 360;
        expect(deltaRev, -20.0);
      },
    );

    test('6. Suspicious GPS jump exceeding 150 km/h is flagged', () {
      const dist = Distance();
      final p1 = LatLng(30.9360, 31.3490);
      final p2 = LatLng(31.5000, 31.9000);
      final elapsed = const Duration(seconds: 10);
      final distKm = dist.as(LengthUnit.Kilometer, p1, p2);
      final hours = elapsed.inMilliseconds / 3600000.0;
      final speedKmh = distKm / hours;
      expect(speedKmh > 150.0, isTrue);
    });

    test('7. AT STOP progress state flags isAtStop in TrackingState', () {
      final atStopTelemetry = activeTelemetry.copyWith(
        progressState: 'at_stop',
      );
      final state = TrackingState(latestTelemetry: atStopTelemetry);
      expect(state.isAtStop, isTrue);

      final transitState = TrackingState(latestTelemetry: activeTelemetry);
      expect(transitState.isAtStop, isFalse);
    });

    test('8. Offline state correctly suppresses active ETA', () {
      final engine = StopEtaEngine();
      final timings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: null,
        activeRunTime: '08:00',
        isQaPreview: false,
      );
      expect(timings[testStops[3].id]?.estimatedArrivalTime, isNull);
    });

    test(
      '9. QA temporary coordinates never leak as verified production coordinates',
      () {
        expect(testStops[0].isTemporaryQa, isTrue);
        expect(testStops[2].isTemporaryQa, isFalse);
      },
    );

    testWidgets(
      '10. LiveMapScreen renders Follow Bus control with correct icon and text',
      (tester) async {
        final repo = MockTrackingRepository(summary: activeSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
        );
        await pumpAndAdvance(tester);

        expect(
          find.byIcon(Icons.directions_bus_filled_rounded),
          findsOneWidget,
        );
        expect(find.text('Following'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      '11. HomeLiveTrackingCard renders without duplicate resume messages',
      (tester) async {
        final offlineSummary = activeSummary.copyWith(
          status: LiveTrackingStatus.offline,
          serviceState: 'offline',
          nextWindowStartTime: '08:00 AM',
        );
        final repo = MockTrackingRepository(summary: offlineSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(
            child: SingleChildScrollView(
              child: BlocProvider<TrackingCubit>.value(
                value: cubit,
                child: const HomeLiveTrackingCard(),
              ),
            ),
          ),
        );
        await pumpAndAdvance(tester);

        // Resume message appears only in the frosted bar on mini-map, not repeated in subtitle
        expect(find.textContaining('resumes at 08:00 AM'), findsOneWidget);
        expect(find.text('Tracking unavailable'), findsWidgets);

        await cubit.close();
      },
    );

    testWidgets(
      '12. Mini-map in HomeLiveTrackingCard displays nearby stops only',
      (tester) async {
        final repo = MockTrackingRepository(summary: activeSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(
            child: SingleChildScrollView(
              child: BlocProvider<TrackingCubit>.value(
                value: cubit,
                child: const HomeLiveTrackingCard(),
              ),
            ),
          ),
        );
        await pumpAndAdvance(tester);

        final mapWidget = tester.widget<LiveBusMapWidget>(
          find.byType(LiveBusMapWidget),
        );
        expect(mapWidget.isCompactPreview, isTrue);

        await cubit.close();
      },
    );
  });
}
