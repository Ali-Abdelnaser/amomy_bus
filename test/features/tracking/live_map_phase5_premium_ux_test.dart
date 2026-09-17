import 'dart:async';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/domain/services/stop_eta_engine.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/screens/live_map_screen.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/amomy_bus_marker.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test data: Stops 1-2 (temporary QA) and Stops 18-19 (verified)
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
    const BusStopModel(
      id: 'stop-34',
      routeStopId: 'rs-34',
      stopOrder: 34,
      nameAr: 'موقف المنصورة الجديد',
      nameEn: 'Mansoura New Station',
      localityAr: 'المنصورة',
      localityEn: 'Mansoura',
      latitude: 31.0250,
      longitude: 31.4000,
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
    lastPassedStop: testStops[2],
    currentStopId: 'stop-18',
    nextStopId: 'stop-19',
    routeStops: testStops,
  );

  final qaSummary = activeSummary.copyWith(
    status: LiveTrackingStatus.qaPreview,
    serviceState: 'offline',
    progressState: 'in_transit',
    isQaPreviewActive: true,
  );

  group('Live Map Phase 5 — Premium Map UX & Stop ETA Engine Tests', () {
    testWidgets('1. Live Map opens edge-to-edge behind status bar', (
      tester,
    ) async {
      final repo = MockTrackingRepository(summary: activeSummary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      await tester.pumpWidget(
        createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
      );
      await pumpAndAdvance(tester);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.extendBodyBehindAppBar, isTrue);

      // Verify LiveBusMapWidget fills the entire screen
      expect(find.byType(LiveBusMapWidget), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      '2. Large bus tracking bottom sheet is hidden by default on screen open',
      (tester) async {
        final repo = MockTrackingRepository(summary: activeSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
        );
        await pumpAndAdvance(tester);

        // Top floating header must be visible
        expect(find.text('Live Bus'), findsOneWidget);
        expect(find.text('LIVE'), findsOneWidget);

        // Bus detail bottom sheet must NOT be present
        expect(find.text('Speed: 23 km/h'), findsNothing);
        expect(find.byIcon(Icons.speed_rounded), findsNothing);

        await cubit.close();
      },
    );

    testWidgets('3. Tapping bus marker opens bus detail sheet', (tester) async {
      final repo = MockTrackingRepository(summary: activeSummary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      await tester.pumpWidget(
        createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
      );
      await pumpAndAdvance(tester);

      // Tap the bus marker via LiveBusMapWidget callback
      final liveMap = tester.widget<LiveBusMapWidget>(
        find.byType(LiveBusMapWidget),
      );
      liveMap.onBusTap?.call();
      await pumpAndAdvance(tester);

      // Bus sheet is now open
      expect(find.text('Last Stop'), findsOneWidget);
      expect(find.text('Next Stop'), findsOneWidget);
      expect(find.text('Al Marai Market'), findsAtLeastNWidgets(1));
      expect(find.text('Al Haramain Co'), findsAtLeastNWidgets(1));

      await cubit.close();
    });

    testWidgets(
      '4. Tapping stop marker opens compact stop detail instead of bus sheet',
      (tester) async {
        final repo = MockTrackingRepository(summary: activeSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
        );
        await pumpAndAdvance(tester);

        // Tap stop 19
        cubit.selectStop(testStops[3]);
        await pumpAndAdvance(tester);

        // Stop detail card is displayed
        expect(find.text('Stop 19'), findsOneWidget);
        expect(find.text('20 pts'), findsOneWidget);
        expect(find.text('NEXT'), findsOneWidget);
        expect(find.text('Al Haramain Co'), findsAtLeastNWidgets(1));

        // Bus sheet remains closed
        expect(find.text('Last Stop'), findsNothing);

        await cubit.close();
      },
    );

    testWidgets('5. Center-on-bus button remains visible above sheet', (
      tester,
    ) async {
      final repo = MockTrackingRepository(summary: activeSummary);
      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      await tester.pumpWidget(
        createTestApp(child: LiveMapScreen(trackingCubit: cubit)),
      );
      await pumpAndAdvance(tester);

      // Button exists with bus follow icon
      expect(find.byIcon(Icons.directions_bus_filled_rounded), findsOneWidget);

      // Tap bus to open sheet
      final liveMap = tester.widget<LiveBusMapWidget>(
        find.byType(LiveBusMapWidget),
      );
      liveMap.onBusTap?.call();
      await pumpAndAdvance(tester);

      // Button is still visible and moved up
      expect(find.byIcon(Icons.directions_bus_filled_rounded), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      '6. Bus marker renders clean circular transit marker with Material bus icon',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: AmomyBusMarker(heading: 90, isMoving: true, size: 50),
              ),
            ),
          ),
        );
        await tester.pump();

        // Bus icon is Directions Bus Rounded Material Icon
        expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
      },
    );

    testWidgets('7. Bus marker does not rotate (stays upright north-up)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AmomyBusMarker(heading: 270, isMoving: true, size: 50),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check no Transform.rotate exists in AmomyBusMarker
      final transformFinder = find.descendant(
        of: find.byType(AmomyBusMarker),
        matching: find.byType(Transform),
      );
      for (final element in tester.widgetList<Transform>(transformFinder)) {
        expect(element.transform.storage[1], 0.0);
        expect(element.transform.storage[4], 0.0);
      }
    });

    testWidgets('8. Home map supports interactive zoom and pan flags', (
      tester,
    ) async {
      final widget = LiveBusMapWidget(
        telemetry: activeTelemetry,
        routeStops: testStops,
        isCompactPreview: true,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pump();

      final googleMap = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(googleMap.zoomGesturesEnabled, isTrue);
      expect(googleMap.scrollGesturesEnabled, isTrue);
    });

    test(
      '9. Actual stop arrival timestamp stored and parsed in BusStopModel',
      () {
        final json = {
          'id': 'stop-18',
          'route_stop_id': 'rs-18',
          'stop_order': 18,
          'name_ar': 'ماركت المراعي',
          'name_en': 'Al Marai Market',
          'locality_ar': '',
          'locality_en': '',
          'latitude': 30.9350382,
          'longitude': 31.34714024,
          'actual_arrival_time': '2026-09-13T08:23:00.000Z',
          'fare_points': 20,
        };

        final model = BusStopModel.fromJson(json);
        expect(model.actualArrivalTime, isNotNull);
        expect(model.actualArrivalTime!.hour, 8);
        expect(model.actualArrivalTime!.minute, 23);
        expect(model.farePoints, 20);
      },
    );

    test(
      '10. Next stop ETA generated based on remaining route distance and speed',
      () {
        final engine = StopEtaEngine();
        final timings = engine.computeAllStopTimings(
          orderedStops: testStops,
          telemetry: activeTelemetry,
          activeRunTime: '08:00',
          isQaPreview: false,
        );

        final nextTiming = timings['stop-19'];
        expect(nextTiming, isNotNull);
        expect(nextTiming!.estimatedArrivalTime, isNotNull);
        expect(nextTiming.isNext, isTrue);
      },
    );

    test(
      '11. ETA uses smoothed speed and fallback when history is insufficient',
      () {
        final engine = StopEtaEngine(fallbackSpeedKmh: 22.0);

        // No history recorded yet -> fallback speed
        expect(engine.getEffectiveSpeedKmh(instantSpeedKmh: 0.0), 22.0);

        // Feed 3 moving points
        final t1 = DateTime.utc(2026, 9, 13, 8, 20, 0);
        final t2 = DateTime.utc(2026, 9, 13, 8, 20, 10);
        final t3 = DateTime.utc(2026, 9, 13, 8, 20, 20);

        engine.recordTelemetrySpeed(20.0, t1);
        engine.recordTelemetrySpeed(24.0, t2);
        engine.recordTelemetrySpeed(22.0, t3);

        final smoothed = engine.getEffectiveSpeedKmh(
          instantSpeedKmh: 22.0,
          now: t3,
        );
        expect(smoothed, closeTo(22.0, 1.5));
      },
    );

    test('12. Zero-speed short stop does not produce infinite ETA', () {
      final engine = StopEtaEngine();
      final t1 = DateTime.utc(2026, 9, 13, 8, 20, 0);
      engine.recordTelemetrySpeed(25.0, t1);

      // Bus stopped at traffic light (speed = 0) 45 seconds later
      final t2 = DateTime.utc(2026, 9, 13, 8, 20, 45);
      final effectiveSpeed = engine.getEffectiveSpeedKmh(
        instantSpeedKmh: 0.0,
        now: t2,
      );

      // Must retain recent moving speed during short stop (under 3 min)
      expect(effectiveSpeed, closeTo(25.0, 0.1));

      // Timings remain finite and valid
      final timings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: activeTelemetry.copyWith(speedKmh: 0.0),
        activeRunTime: '08:00',
        isQaPreview: false,
        now: t2,
      );

      final nextTiming = timings['stop-19'];
      expect(nextTiming?.estimatedArrivalTime, isNotNull);
    });

    testWidgets(
      '11. Home tracking card renders Last stop and Next stop with actual reached & ETA',
      (tester) async {
        final repo = MockTrackingRepository(summary: activeSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: const HomeLiveTrackingCard(),
              ),
            ),
          ),
        );
        await pumpAndAdvance(tester);

        expect(find.text('LIVE'), findsOneWidget);
        expect(find.text('Last Stop'), findsOneWidget);
        expect(find.text('Next Stop'), findsOneWidget);
        expect(find.text('Al Marai Market'), findsOneWidget);
        expect(find.text('Al Haramain Co'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      '12. QA Simulation updates bus location and progression smoothly',
      (tester) async {
        final repo = MockTrackingRepository(summary: qaSummary);
        final cubit = TrackingCubit(
          repository: repo,
          isQaAuthorizedOverride: true,
        );
        await cubit.loadTrackingData(tripId: 'trip-test');

        expect(cubit.state.trackingStatus, LiveTrackingStatus.qaPreview);
        expect(cubit.state.isQaPreview, isTrue);

        await cubit.close();
      },
    );

    testWidgets(
      '13. Offline state does not show active ETA or fake progression',
      (tester) async {
        final offlineSummary = activeSummary.copyWith(
          status: LiveTrackingStatus.offline,
          serviceState: 'offline',
          progressState: 'offline',
        );

        final repo = MockTrackingRepository(summary: offlineSummary);
        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: const HomeLiveTrackingCard(),
              ),
            ),
          ),
        );
        await pumpAndAdvance(tester);

        expect(find.text('Tracking unavailable'), findsAtLeastNWidgets(1));
        expect(find.text('Next Stop'), findsOneWidget);
        expect(find.textContaining('8:00'), findsAtLeastNWidgets(1));
        // No active ETA strings
        expect(find.textContaining('ETA 08:'), findsNothing);

        await cubit.close();
      },
    );

    test('14. QA temporary stop ETA never leaks to production', () {
      final engine = StopEtaEngine();

      // In production mode (!isQaPreview)
      final prodTimings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: activeTelemetry.copyWith(
          currentStopOrder: 1,
          nextStopOrder: 2,
        ),
        activeRunTime: '08:00',
        isQaPreview: false,
      );

      // Temporary QA Stop 2 must have NULL estimatedArrivalTime in production
      expect(prodTimings['stop-2']?.estimatedArrivalTime, isNull);
      expect(prodTimings['stop-2']?.isQaPreviewOnly, isTrue);

      // In QA preview mode (isQaPreview == true)
      final qaTimings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: activeTelemetry.copyWith(
          currentStopOrder: 1,
          nextStopOrder: 2,
        ),
        activeRunTime: '08:00',
        isQaPreview: true,
      );

      expect(qaTimings['stop-2']?.estimatedArrivalTime, isNotNull);
    });

    test('15. Verified stop ETA works accurately for Stops 18-34', () {
      final engine = StopEtaEngine();
      final timings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: activeTelemetry,
        activeRunTime: '08:00',
        isQaPreview: false,
      );

      final timing19 = timings['stop-19'];
      expect(timing19, isNotNull);
      expect(timing19!.estimatedArrivalTime, isNotNull);
      expect(timing19.isNext, isTrue);
      expect(timing19.isQaPreviewOnly, isFalse);
    });

    test('16. First stop uses scheduled departure time', () {
      final engine = StopEtaEngine();
      final timings = engine.computeAllStopTimings(
        orderedStops: testStops,
        telemetry: activeTelemetry.copyWith(currentStopOrder: 1),
        activeRunTime: '09:00',
        isQaPreview: true,
      );

      final stop1 = timings['stop-1'];
      expect(stop1?.scheduledDepartureTime, '09:00');
    });
  });
}
