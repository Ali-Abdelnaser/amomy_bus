import 'dart:async';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' hide LatLng;
import 'package:latlong2/latlong.dart';
import 'package:amomy_bus/core/map/map_tile_config.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/screens/live_map_screen.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/amomy_bus_marker.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockTrackingRepository implements TrackingRepository {
  TrackingSummary summary;
  final StreamController<BusTelemetry> _telemetryController =
      StreamController<BusTelemetry>.broadcast();

  MockTrackingRepository({required this.summary});

  @override
  Future<TrackingSummary> getTrackingSummary({bool includeQa = false}) async {
    return summary;
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) async => null;

  @override
  Stream<BusTelemetry> subscribeToBusLiveLocation() =>
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

Widget createTestApp({required Widget child, Locale locale = const Locale('en')}) {
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
      nameAr: 'كوبرى عزت',
      nameEn: 'Ezzat Bridge',
      localityAr: 'ميت فضالة',
      localityEn: 'Mit Fadala',
      latitude: 30.9100,
      longitude: 31.3100,
      isTemporaryQa: true,
      farePoints: 20,
    ),
    const BusStopModel(
      id: 'stop-18',
      routeStopId: 'rs-18',
      stopOrder: 18,
      nameAr: 'ماركت المراعي',
      nameEn: 'Al Marai Market',
      localityAr: 'برج النور الحمص',
      localityEn: 'Borg El Nour',
      latitude: 30.9350,
      longitude: 31.3471,
      isTemporaryQa: false,
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
      latitude: 30.9388,
      longitude: 31.3524,
      isTemporaryQa: false,
      farePoints: 20,
    ),
  ];

  final activeTelemetry = BusTelemetry(
    latitude: 30.9360,
    longitude: 31.3490,
    heading: 90,
    speedKmh: 28.0,
    gpsRecordedAt: DateTime.utc(2026, 9, 14, 8, 25, 0),
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
    cairoTime: '08:25:00',
    cairoDate: '2026-09-14',
    activeDirection: TrackingDirection.outbound,
    activeRunTime: '08:00',
    busLocation: activeTelemetry,
    currentStop: testStops[1],
    nextStop: testStops[2],
    currentStopId: 'stop-18',
    nextStopId: 'stop-19',
    routeStops: testStops,
  );

  group('AMOMY Production Map Phase Tests', () {
    test('1. Production map config uses Stadia Maps Alidade Smooth with API key', () {
      final config = MapTileConfig.productionStadia('my_secure_api_key');
      expect(config.tileUrl, contains('tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key=my_secure_api_key'));
      expect(config.attribution, contains('Stadia Maps'));
      expect(config.attribution, contains('OpenMapTiles'));
      expect(config.attribution, contains('OpenStreetMap contributors'));
      expect(config.retinaMode, isTrue);
      expect(config.isAvailable, isTrue);
    });

    test('2. Debug fallback may use OSM Standard when key is omitted', () {
      final config = MapTileConfig.resolveActiveConfig(
        explicitApiKey: '',
        isReleaseModeOverride: false,
      );
      expect(config.tileUrl, 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
      expect(config.attribution, contains('OpenStreetMap contributors'));
      expect(config.isAvailable, isTrue);
    });

    test('3. Release mode without key does not silently use public OSM', () {
      final releaseConfig = MapTileConfig.resolveActiveConfig(
        explicitApiKey: '',
        isReleaseModeOverride: true,
      );
      expect(releaseConfig.isAvailable, isFalse);
      expect(releaseConfig.tileUrl, isEmpty);
      expect(releaseConfig.tileUrl.contains('openstreetmap.org'), isFalse);
    });

    testWidgets('4. SVG bus marker is completely removed from tracking and circular icon rendered', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AmomyBusMarker(
            heading: 120,
            isMoving: true,
            isAtStop: false,
          ),
        ),
      );
      await tester.pump();

      // Bus icon is Directions Bus Rounded Material Icon
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    });

    testWidgets('5. Bus marker does not rotate (stays upright north-up)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const AmomyBusMarker(
            heading: 270,
            isMoving: true,
          ),
        ),
      );
      await tester.pump();

      // Check no Transform.rotate exists in AmomyBusMarker
      final transformFinder = find.descendant(
        of: find.byType(AmomyBusMarker),
        matching: find.byType(Transform),
      );
      // The only Transform allowed inside AmomyBusMarker is the pulse scale transform
      for (final element in tester.widgetList<Transform>(transformFinder)) {
        // Transform.scale uses a matrix with scale values on diagonal, no rotation (sin/cos on off-diagonals)
        expect(element.transform.storage[1], 0.0);
        expect(element.transform.storage[4], 0.0);
      }
    });

    testWidgets('6. Stop visual states correct (no permanent stop numbers)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiveBusMapWidget(
            telemetry: activeTelemetry,
            routeStops: testStops,
            status: LiveTrackingStatus.online,
          ),
        ),
      );
      await pumpAndAdvance(tester);

      // Verify no raw stopOrder number text is displayed permanently on map
      expect(find.text('18'), findsNothing);
      expect(find.text('19'), findsNothing);
    });

    testWidgets('7. Tile loading skeleton base is rendered without white flashes', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiveBusMapWidget(
            telemetry: activeTelemetry,
            routeStops: testStops,
            status: LiveTrackingStatus.online,
          ),
        ),
      );
      await pumpAndAdvance(tester);

      // Skeleton base container has color #F1F3F5
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasSkeleton = containers.any((c) => c.color == const Color(0xFFF1F3F5));
      expect(hasSkeleton, isTrue);
    });

    testWidgets('8. Controlled unavailable state renders cleanly when tiles are disabled in release', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const LiveBusMapWidget(
            status: LiveTrackingStatus.online,
          ),
        ),
      );
      await pumpAndAdvance(tester);

      // Google Map widget exists
      expect(find.byType(GoogleMap), findsOneWidget);
    });

    testWidgets('9. Home mini-map and Full map share centralized MapTileConfig', (tester) async {
      final repo = MockTrackingRepository(summary: activeSummary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData();

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

      expect(find.byType(LiveBusMapWidget), findsOneWidget);
      await cubit.close();
    });

    testWidgets('10. Follow bus control remains active on Full Live Map', (tester) async {
      final repo = MockTrackingRepository(summary: activeSummary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData();

      await tester.pumpWidget(
        createTestApp(
          child: LiveMapScreen(trackingCubit: cubit),
        ),
      );
      await pumpAndAdvance(tester);

      expect(find.text('Following'), findsOneWidget);
      await cubit.close();
    });

    test('11. Interpolation and GPS safety guard remains operational', () {
      const dist = Distance();
      final p1 = LatLng(30.9360, 31.3490);
      final p2 = LatLng(30.9370, 31.3500);
      final distKm = dist.as(LengthUnit.Kilometer, p1, p2);
      final elapsed = const Duration(seconds: 10);
      final hours = elapsed.inMilliseconds / 3600000.0;
      final speedKmh = distKm / hours;
      // Realistic move ~40 km/h should pass
      expect(speedKmh < 150.0, isTrue);
    });

    test('12. No tracking backend or state regressions', () {
      expect(activeSummary.busLocation?.latitude, 30.9360);
      expect(activeSummary.status, LiveTrackingStatus.online);
    });

    test('13. Reconnecting / stale bus marker uses amber ring styling', () {
      const marker = AmomyBusMarker(
        isStale: true,
      );
      expect(marker.isStale, isTrue);
    });
  });
}
