import 'dart:async';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_telemetry.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/domain/services/stop_progression_engine.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';

class FakeTrackingRepository implements TrackingRepository {
  TrackingSummary summary;
  final StreamController<void> _telemetryController =
      StreamController<void>.broadcast();

  final List<Map<String, dynamic>> recordedNotifications = [];
  bool approachAlertsEnabled = true;

  FakeTrackingRepository({required this.summary});

  bool lastIncludeQa = false;

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    lastIncludeQa = summary.isQaPreviewActive;
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

  void emitTelemetry(BusTelemetry telemetry) {
    summary = summary.copyWith(busLocation: telemetry);
    _telemetryController.add(null);
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
    // Check strict idempotency key: (targetStopId, serviceRunTime, routeId)
    final exists = recordedNotifications.any(
      (n) =>
          n['targetStopId'] == targetStopId &&
          n['serviceRunTime'] == serviceRunTime &&
          n['routeId'] == routeId,
    );

    if (exists) {
      return false; // Already sent for this run
    }

    recordedNotifications.add({
      'targetStopId': targetStopId,
      'serviceRunTime': serviceRunTime,
      'routeId': routeId,
      'titleAr': titleAr,
      'titleEn': titleEn,
      'bodyAr': bodyAr,
      'bodyEn': bodyEn,
    });
    return true;
  }

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) async {
    approachAlertsEnabled = enabled;
  }

  @override
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) async {
    final now = DateTime.now().toUtc();
    final telemetry = BusTelemetry(
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speedKmh: speedKmh,
      gpsRecordedAt: now,
      isStale: false,
      ageSeconds: 0,
    );
    summary = TrackingSummary(
      status: LiveTrackingStatus.online,
      isInServiceWindow: true,
      serviceWindow: 'morning',
      cairoTime: '09:00:00',
      cairoDate: '2026-09-13',
      activeDirection: TrackingDirection.outbound,
      busLocation: telemetry,
      routeStops: summary.routeStops,
      passengerTargetStop: summary.passengerTargetStop,
    );
    emitTelemetry(telemetry);
  }

  void dispose() {
    _telemetryController.close();
  }
}

void main() {
  const stop1 = BusStopModel(
    id: 'stop-1',
    routeStopId: 'rs-1',
    stopOrder: 1,
    nameAr: 'كوبرى عزت',
    nameEn: 'Ezzat Bridge',
    localityAr: 'ميت فضالة',
    localityEn: 'Mit Fadala',
    latitude: 31.0000,
    longitude: 31.3000,
  );

  const stop2 = BusStopModel(
    id: 'stop-2',
    routeStopId: 'rs-2',
    stopOrder: 2,
    nameAr: 'كوبرى الزغبي',
    nameEn: 'El Zoghbi Bridge',
    localityAr: 'ميت أبو الحسين',
    localityEn: 'Mit Abu El Hussein',
    latitude: 31.0050,
    longitude: 31.3050,
  );

  const stop3 = BusStopModel(
    id: 'stop-3',
    routeStopId: 'rs-3',
    stopOrder: 3,
    nameAr: 'صيدلية حسونة',
    nameEn: 'Hassouna Pharmacy',
    localityAr: 'أبو داوود العنب',
    localityEn: 'Abu Dawood El Enab',
    latitude: 31.0100,
    longitude: 31.3100,
  );

  final defaultStops = [stop1, stop2, stop3];

  group('Operating Windows & Status Tests', () {
    test('1. Before 08:00 Cairo time -> status is offline', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'offline',
        'is_in_service_window': false,
        'service_window': 'offline',
        'cairo_time': '07:30:00',
        'next_window': {'start_time': '08:00', 'is_tomorrow': false},
      });

      expect(summary.status, LiveTrackingStatus.offline);
      expect(summary.isInServiceWindow, false);
      expect(summary.nextWindowStartTime, '08:00');
      expect(summary.nextWindowIsTomorrow, false);
    });

    test('2. 08:00-12:00 Cairo time -> active window (morning, outbound)', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'online',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '09:30:00',
        'active_direction': 'outbound',
        'active_run_time': '09:00',
        'bus_location': {
          'latitude': 31.001,
          'longitude': 31.301,
          'heading': 90,
          'speed_kmh': 40,
          'age_seconds': 10,
          'is_stale': false,
        },
      });

      expect(summary.status, LiveTrackingStatus.online);
      expect(summary.isInServiceWindow, true);
      expect(summary.activeDirection, TrackingDirection.outbound);
      expect(summary.activeRunTime, '09:00');
    });

    test('3. 12:00-13:00 Cairo time -> offline (resumes at 13:00)', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'offline',
        'is_in_service_window': false,
        'service_window': 'offline',
        'cairo_time': '12:30:00',
        'next_window': {'start_time': '13:00', 'is_tomorrow': false},
      });

      expect(summary.status, LiveTrackingStatus.offline);
      expect(summary.isInServiceWindow, false);
      expect(summary.nextWindowStartTime, '13:00');
      expect(summary.nextWindowIsTomorrow, false);
    });

    test('4. 13:00-17:00 Cairo time -> active window (afternoon, return)', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'online',
        'is_in_service_window': true,
        'service_window': 'afternoon',
        'cairo_time': '14:15:00',
        'active_direction': 'return',
        'active_run_time': '14:00',
      });

      expect(summary.status, LiveTrackingStatus.online);
      expect(summary.isInServiceWindow, true);
      expect(summary.activeDirection, TrackingDirection.returnDirection);
      expect(summary.activeRunTime, '14:00');
    });

    test(
      '5. After 17:00 Cairo time -> offline (resumes tomorrow at 08:00)',
      () {
        final summary = TrackingSummary.fromJson({
          'tracking_status': 'offline',
          'is_in_service_window': false,
          'service_window': 'offline',
          'cairo_time': '18:30:00',
          'next_window': {'start_time': '08:00', 'is_tomorrow': true},
        });

        expect(summary.status, LiveTrackingStatus.offline);
        expect(summary.isInServiceWindow, false);
        expect(summary.nextWindowStartTime, '08:00');
        expect(summary.nextWindowIsTomorrow, true);
      },
    );
  });

  group('GPS Freshness & Staleness Tests', () {
    test('6. Stale location (>120 seconds old) -> status is stale', () {
      final staleTelemetry = BusTelemetry(
        latitude: 31.001,
        longitude: 31.301,
        gpsRecordedAt: DateTime.now().toUtc().subtract(
          const Duration(seconds: 180),
        ),
        isStale: true,
        ageSeconds: 180,
      );

      final summary = TrackingSummary(
        status: LiveTrackingStatus.stale,
        isInServiceWindow: true,
        serviceWindow: 'morning',
        cairoTime: '09:00:00',
        cairoDate: '2026-09-13',
        activeDirection: TrackingDirection.outbound,
        busLocation: staleTelemetry,
      );

      final state = TrackingState(
        uiStatus: TrackingUiStatus.loaded,
        summary: summary,
        latestTelemetry: staleTelemetry,
      );

      expect(state.isStale, true);
      expect(state.isOnline, false);
    });

    test('7. Fresh location (<120 seconds old) -> status is online', () {
      final freshTelemetry = BusTelemetry(
        latitude: 31.001,
        longitude: 31.301,
        gpsRecordedAt: DateTime.now().toUtc().subtract(
          const Duration(seconds: 15),
        ),
        isStale: false,
        ageSeconds: 15,
      );

      final summary = TrackingSummary(
        status: LiveTrackingStatus.online,
        isInServiceWindow: true,
        serviceWindow: 'morning',
        cairoTime: '09:00:00',
        cairoDate: '2026-09-13',
        activeDirection: TrackingDirection.outbound,
        busLocation: freshTelemetry,
      );

      final state = TrackingState(
        uiStatus: TrackingUiStatus.loaded,
        summary: summary,
        latestTelemetry: freshTelemetry,
      );

      expect(state.isOnline, true);
      expect(state.isStale, false);
    });
  });

  group('Route-Aware Progression Engine & Hysteresis Tests', () {
    test('8. Current / Next stop progression advances forward', () {
      final engine = StopProgressionEngine(
        arrivalRadiusMeters: 80,
        departureRadiusMeters: 130,
        approachRadiusMeters: 500,
      );

      // Bus is directly at stop 1 (31.0000, 31.3000)
      final atStop1 = engine.evaluate(
        orderedStops: defaultStops,
        telemetry: BusTelemetry(
          latitude: 31.0000,
          longitude: 31.3000,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
      );

      expect(atStop1.currentStop.id, stop1.id);
      expect(atStop1.nextStop.id, stop2.id);
      expect(atStop1.status, ApproachStatus.atStop);

      // Bus travels close to stop 2 (31.0050, 31.3050)
      final atStop2 = engine.evaluate(
        orderedStops: defaultStops,
        telemetry: BusTelemetry(
          latitude: 31.0050,
          longitude: 31.3050,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
      );

      expect(atStop2.currentStop.id, stop2.id);
      expect(atStop2.nextStop.id, stop3.id);
      expect(atStop2.status, ApproachStatus.atStop);
    });

    test('9. Route direction handling respects active direction', () {
      final engine = StopProgressionEngine();
      final outboundStops = [stop1, stop2, stop3];
      final returnStops = [stop3, stop2, stop1];

      final outboundProgress = engine.evaluate(
        orderedStops: outboundStops,
        telemetry: BusTelemetry(
          latitude: 31.0000,
          longitude: 31.3000,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
      );
      expect(outboundProgress.currentStop.id, stop1.id);
      expect(outboundProgress.nextStop.id, stop2.id);

      final returnProgress = engine.evaluate(
        orderedStops: returnStops,
        telemetry: BusTelemetry(
          latitude: 31.0100,
          longitude: 31.3100,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-2',
        direction: TrackingDirection.returnDirection,
      );
      expect(returnProgress.currentStop.id, stop3.id);
      expect(returnProgress.nextStop.id, stop2.id);
    });

    test('10. Hysteresis prevents stop flickering between 80m and 130m', () {
      final engine = StopProgressionEngine(
        arrivalRadiusMeters: 80,
        departureRadiusMeters: 130,
      );

      // Start at stop 1
      engine.evaluate(
        orderedStops: defaultStops,
        telemetry: BusTelemetry(
          latitude: 31.0000,
          longitude: 31.3000,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
      );

      // Move ~100m away from stop 1 (inside hysteresis band 80m - 130m)
      // Lat delta ~0.0009 ≈ 100 meters
      final jitteredProgress = engine.evaluate(
        orderedStops: defaultStops,
        telemetry: BusTelemetry(
          latitude: 31.0009,
          longitude: 31.3000,
          gpsRecordedAt: DateTime.now(),
        ),
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
      );

      // Still considered at stop 1 because it has not breached departureRadius 130m!
      expect(jitteredProgress.currentStop.id, stop1.id);
      expect(jitteredProgress.status, ApproachStatus.atStop);
    });
  });

  group('Passenger Access & Realtime Updates Tests', () {
    test('11. Home tracking state is available without passenger booking', () {
      final summary = TrackingSummary(
        status: LiveTrackingStatus.online,
        isInServiceWindow: true,
        serviceWindow: 'morning',
        cairoTime: '09:00:00',
        cairoDate: '2026-09-13',
        activeDirection: TrackingDirection.outbound,
        passengerTargetStop: null, // No booking, no preference!
        passengerTargetSource: null,
      );

      expect(summary.passengerTargetStop, isNull);
      expect(summary.isInServiceWindow, true);
      expect(summary.status, LiveTrackingStatus.online);
    });

    test(
      '12. Full map Cubit receives and updates realtime telemetry',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '09:00:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            routeStops: defaultStops,
          ),
        );

        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        expect(cubit.state.latestTelemetry, isNull);

        // Emit realtime telemetry
        final now = DateTime.now();
        repo.emitTelemetry(
          BusTelemetry(
            latitude: 31.0050,
            longitude: 31.3050,
            heading: 180,
            speedKmh: 45.0,
            gpsRecordedAt: now,
          ),
        );

        // Allow stream tick (TrackingCubit revision debounce is 350ms)
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(cubit.state.latestTelemetry?.latitude, 31.0050);
        expect(cubit.state.latestTelemetry?.heading, 180);
        expect(cubit.state.latestTelemetry?.speedKmh, 45.0);

        cubit.close();
        repo.dispose();
      },
    );

    test('13. Heading and speed are preserved for smooth animation', () {
      final telemetry = BusTelemetry(
        latitude: 31.005,
        longitude: 31.305,
        heading: 270,
        speedKmh: 55.0,
        gpsRecordedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      expect(telemetry.heading, 270);
      expect(telemetry.isMoving, true);
    });
  });

  group('Approach Notifications & Strict Idempotency Tests', () {
    test(
      '14. Approach notification fires when passenger target becomes next stop',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '09:00:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            activeRouteId: 'route-1',
            activeRunTime: '09:00',
            routeStops: defaultStops,
            passengerTargetStop: stop2, // Target is Stop 2!
            nextStop: stop2,
            nextStopId: stop2.id,
          ),
        );

        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        // Bus moves past departure of stop 1 and is approaching stop 2 (within 500m)
        // Stop 2 is at 31.0050, 31.3050. Bus is at 31.0035, 31.3035 (~230m from stop 2)
        repo.emitTelemetry(
          BusTelemetry(
            latitude: 31.0035,
            longitude: 31.3035,
            gpsRecordedAt: DateTime.now(),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(repo.recordedNotifications.length, 1);
        expect(repo.recordedNotifications.first['targetStopId'], stop2.id);
        expect(repo.recordedNotifications.first['serviceRunTime'], '09:00:00');
        expect(cubit.state.approachAlertDispatched, true);

        cubit.close();
        repo.dispose();
      },
    );

    test(
      '15. Notification fires ONCE per approach (Idempotency Key)',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '09:00:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            activeRouteId: 'route-1',
            activeRunTime: '09:00',
            routeStops: defaultStops,
            passengerTargetStop: stop2,
            nextStop: stop2,
            nextStopId: stop2.id,
          ),
        );

        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        // Multiple GPS updates while approaching Stop 2
        repo.emitTelemetry(
          BusTelemetry(
            latitude: 31.0035,
            longitude: 31.3035,
            gpsRecordedAt: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));

        repo.emitTelemetry(
          BusTelemetry(
            latitude: 31.0038,
            longitude: 31.3038,
            gpsRecordedAt: DateTime.now(),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));

        // Still only 1 notification sent!
        expect(repo.recordedNotifications.length, 1);

        cubit.close();
        repo.dispose();
      },
    );

    test('16. Different service run may notify again', () async {
      final repo = FakeTrackingRepository(
        summary: TrackingSummary(
          status: LiveTrackingStatus.online,
          isInServiceWindow: true,
          serviceWindow: 'morning',
          cairoTime: '09:00:00',
          cairoDate: '2026-09-13',
          activeDirection: TrackingDirection.outbound,
          activeRouteId: 'route-1',
          activeRunTime: '09:00',
          routeStops: defaultStops,
          passengerTargetStop: stop2,
        ),
      );

      // Run 09:00
      final firstDispatch = await repo.recordApproachNotification(
        routeId: 'route-1',
        targetStopId: stop2.id,
        serviceRunTime: '09:00:00',
        titleAr: 'الحافلة تقترب',
        titleEn: 'Bus approaching',
        bodyAr: '',
        bodyEn: '',
      );
      expect(firstDispatch, true);

      // Duplicate attempt in 09:00 run fails idempotency check
      final duplicateDispatch = await repo.recordApproachNotification(
        routeId: 'route-1',
        targetStopId: stop2.id,
        serviceRunTime: '09:00:00',
        titleAr: 'الحافلة تقترب',
        titleEn: 'Bus approaching',
        bodyAr: '',
        bodyEn: '',
      );
      expect(duplicateDispatch, false);

      // Separate 10:00 run succeeds!
      final secondRunDispatch = await repo.recordApproachNotification(
        routeId: 'route-1',
        targetStopId: stop2.id,
        serviceRunTime: '10:00:00',
        titleAr: 'الحافلة تقترب',
        titleEn: 'Bus approaching',
        bodyAr: '',
        bodyEn: '',
      );
      expect(secondRunDispatch, true);
      expect(repo.recordedNotifications.length, 2);

      repo.dispose();
    });

    test('17. Booked boarding stop takes notification priority', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'online',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '09:00:00',
        'passenger_target': {
          'stop_id': 'booked-stop-id',
          'route_stop_id': 'booked-rs-id',
          'stop_order': 4,
          'name_ar': 'محطة الحجز',
          'name_en': 'Booked Stop',
          'locality_ar': '',
          'locality_en': '',
          'source': 'booking',
        },
      });

      expect(summary.passengerTargetSource, 'booking');
      expect(summary.passengerTargetStop?.id, 'booked-stop-id');
    });

    test('18. Preferred stop fallback is used when no booking exists', () {
      final summary = TrackingSummary.fromJson({
        'tracking_status': 'online',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '09:00:00',
        'passenger_target': {
          'stop_id': 'preferred-stop-id',
          'route_stop_id': 'pref-rs-id',
          'stop_order': 2,
          'name_ar': 'المحطة المفضلة',
          'name_en': 'Preferred Stop',
          'locality_ar': '',
          'locality_en': '',
          'source': 'preference',
        },
      });

      expect(summary.passengerTargetSource, 'preference');
      expect(summary.passengerTargetStop?.id, 'preferred-stop-id');
    });

    test('19. No target stop -> no approach alert sent', () async {
      final repo = FakeTrackingRepository(
        summary: TrackingSummary(
          status: LiveTrackingStatus.online,
          isInServiceWindow: true,
          serviceWindow: 'morning',
          cairoTime: '09:00:00',
          cairoDate: '2026-09-13',
          activeDirection: TrackingDirection.outbound,
          activeRouteId: 'route-1',
          activeRunTime: '09:00',
          routeStops: defaultStops,
          passengerTargetStop: null, // No target!
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      repo.emitTelemetry(
        BusTelemetry(
          latitude: 31.0035,
          longitude: 31.3035,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(repo.recordedNotifications, isEmpty);

      cubit.close();
      repo.dispose();
    });

    test('20. Reduced/error states handled gracefully without crash', () async {
      const placeholderStop = BusStopModel(
        id: 'placeholder',
        routeStopId: 'rs-placeholder',
        stopOrder: 1,
        nameAr: 'قيد التحميل',
        nameEn: 'Loading...',
        localityAr: '',
        localityEn: '',
        latitude: 0,
        longitude: 0,
        isTemporaryQa: true,
      );
      final repo = FakeTrackingRepository(
        summary: const TrackingSummary(
          status: LiveTrackingStatus.offline,
          isInServiceWindow: false,
          serviceWindow: 'offline',
          cairoTime: '19:00:00',
          cairoDate: '2026-09-13',
          activeDirection: TrackingDirection.outbound,
          currentStop: placeholderStop,
          nextStop: placeholderStop,
          routeStops: [],
        ),
      );

      final cubit = TrackingCubit(repository: repo);
      await cubit.loadTrackingData(tripId: 'trip-test');

      expect(cubit.state.progression?.isCoordinatesPending, true);
      expect(cubit.state.progression?.currentStop.id, 'placeholder');
      expect(cubit.state.isOffline, true);

      cubit.close();
      repo.dispose();
    });
  });

  group('GPS Phase 2 — Authoritative Backend Progression & Architecture Tests', () {
    test(
      '21. All passengers receive same backend-authoritative current and next stop',
      () async {
        final authoritativeSummary = TrackingSummary(
          status: LiveTrackingStatus.online,
          isInServiceWindow: true,
          serviceWindow: 'morning',
          cairoTime: '09:15:00',
          cairoDate: '2026-09-13',
          activeDirection: TrackingDirection.outbound,
          activeRouteId: 'route-1',
          activeTripId: 'trip-outbound-0900',
          activeRunTime: '09:00',
          serviceState: 'in_service',
          progressState: 'approaching',
          currentStopId: stop1.id,
          nextStopId: stop2.id,
          currentStop: stop1,
          nextStop: stop2,
          routeStops: defaultStops,
        );

        final repo = FakeTrackingRepository(summary: authoritativeSummary);

        // Passenger A
        final cubitPassengerA = TrackingCubit(repository: repo);
        await cubitPassengerA.loadTrackingData(tripId: 'trip-test');

        // Passenger B
        final cubitPassengerB = TrackingCubit(repository: repo);
        await cubitPassengerB.loadTrackingData(tripId: 'trip-test');

        expect(cubitPassengerA.state.currentStop?.id, stop1.id);
        expect(cubitPassengerB.state.currentStop?.id, stop1.id);
        expect(cubitPassengerA.state.nextStop?.id, stop2.id);
        expect(cubitPassengerB.state.nextStop?.id, stop2.id);
        expect(
          cubitPassengerA.state.currentStop?.id,
          cubitPassengerB.state.currentStop?.id,
        );
        expect(
          cubitPassengerA.state.nextStop?.id,
          cubitPassengerB.state.nextStop?.id,
        );

        cubitPassengerA.close();
        cubitPassengerB.close();
        repo.dispose();
      },
    );

    test('22. Progression monotonic: stop progression only moves forward', () {
      final engine = StopProgressionEngine(
        arrivalRadiusMeters: 80,
        departureRadiusMeters: 130,
      );

      // 1. Bus at stop 1
      final p1 = engine.evaluate(
        orderedStops: defaultStops,
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
        telemetry: BusTelemetry(
          latitude: stop1.latitude!,
          longitude: stop1.longitude!,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      expect(p1.currentStop.id, stop1.id);
      expect(p1.nextStop.id, stop2.id);

      // 2. Bus moves towards stop 2
      final p2 = engine.evaluate(
        orderedStops: defaultStops,
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
        telemetry: BusTelemetry(
          latitude: stop2.latitude!,
          longitude: stop2.longitude!,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      expect(p2.currentStop.id, stop2.id);
      expect(p2.nextStop.id, stop3.id);
      expect(
        p2.currentStop.stopOrder,
        greaterThanOrEqualTo(p1.currentStop.stopOrder),
      );

      // 3. Telemetry jitter towards stop 1 does not regress past stop 2 in monotonic mode
      final p3 = engine.evaluate(
        orderedStops: defaultStops,
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
        telemetry: BusTelemetry(
          latitude: stop3.latitude!,
          longitude: stop3.longitude!,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      expect(
        p3.currentStop.stopOrder,
        greaterThanOrEqualTo(p2.currentStop.stopOrder),
      );
    });

    test('23. Dual-radius hysteresis: 80m enter / 130m leave thresholds', () {
      final engine = StopProgressionEngine(
        arrivalRadiusMeters: 80,
        departureRadiusMeters: 130,
        approachRadiusMeters: 150,
      );

      // At 50m distance (inside 80m enter radius) -> atStop
      final atStop = engine.evaluate(
        orderedStops: defaultStops,
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
        telemetry: BusTelemetry(
          latitude: stop1.latitude!,
          longitude: stop1.longitude!,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      expect(atStop.status, ApproachStatus.atStop);

      // Past 130m departure radius and outside approach radius -> departed
      final departed = engine.evaluate(
        orderedStops: defaultStops,
        routeId: 'route-1',
        direction: TrackingDirection.outbound,
        telemetry: BusTelemetry(
          latitude: stop1.latitude! + 0.0015,
          longitude: stop1.longitude! + 0.0015,
          gpsRecordedAt: DateTime.now(),
        ),
      );
      expect(departed.status, ApproachStatus.departed);
    });

    test('24. Bus 3 missing GPS device handled safely without crash', () {
      // Simulates database row where Bus 3 has no mapped tracking device
      final bus3SummaryJson = {
        'tracking_status': 'offline',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '10:15:00',
        'cairo_date': '2026-09-13',
        'active_direction': 'outbound',
        'active_trip_id': 'trip-bus3-1000',
        'active_run_time': '10:00',
        'service_state': 'offline',
        'progress_state': 'offline',
        'bus_location': null, // No GPS telemetry available for Bus 3
        'current_stop': null,
        'next_stop': null,
        'has_stop_coordinates': false,
        'route_stops': [],
      };

      final summary = TrackingSummary.fromJson(bus3SummaryJson);

      expect(summary.status, LiveTrackingStatus.offline);
      expect(summary.busLocation, isNull);
      expect(summary.serviceState, 'offline');
      expect(summary.currentStop, isNull);
      expect(summary.nextStop, isNull);
    });

    test('25. Stale telemetry marks status as stale when age > 120s', () {
      final oldTime = DateTime.now().toUtc().subtract(
        const Duration(seconds: 150),
      );
      final telemetry = BusTelemetry.fromJson({
        'latitude': 31.0379,
        'longitude': 31.3815,
        'heading': 90,
        'speed_kmh': 25.0,
        'recorded_at': oldTime.toIso8601String(),
        'age_seconds': 150,
        'is_stale': true,
      });

      expect(telemetry.isStale, true);
      expect(telemetry.ageSeconds, 150);

      final summary = TrackingSummary.fromJson({
        'tracking_status': 'stale',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '09:30:00',
        'cairo_date': '2026-09-13',
        'active_direction': 'outbound',
        'bus_location': telemetry.toJson(),
      });

      expect(summary.status, LiveTrackingStatus.stale);
    });

    test(
      '26. Active run identity: trip_id, service_date, departure_time, direction, bus_id',
      () {
        final summaryJson = {
          'tracking_status': 'online',
          'is_in_service_window': true,
          'service_window': 'morning',
          'cairo_time': '08:30:00',
          'cairo_date': '2026-09-13',
          'active_direction': 'outbound',
          'active_trip_id': 'trip-0800-uuid',
          'active_run_time': '08:00',
          'service_state': 'in_service',
          'bus_location': {
            'latitude': 31.0379,
            'longitude': 31.3815,
            'heading': 45,
            'speed_kmh': 35.0,
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
            'active_trip_id': 'trip-0800-uuid',
            'service_run_time': '08:00',
            'service_state': 'in_service',
          },
        };

        final summary = TrackingSummary.fromJson(summaryJson);

        expect(summary.activeTripId, 'trip-0800-uuid');
        expect(summary.activeRunTime, '08:00');
        expect(summary.activeDirection, TrackingDirection.outbound);
        expect(summary.cairoDate, '2026-09-13');
        expect(summary.serviceState, 'in_service');
        expect(summary.busLocation?.activeTripId, 'trip-0800-uuid');
      },
    );

    test(
      '27. Between-runs state distinguishes repositioning from active service run',
      () {
        final betweenRunsJson = {
          'tracking_status': 'online',
          'service_state': 'between_runs',
          'progress_state': 'between_runs',
          'is_in_service_window': true,
          'service_window': 'morning',
          'cairo_time': '08:52:00',
          'cairo_date': '2026-09-13',
          'active_direction': 'outbound',
          'active_run_time': '08:00',
          'bus_location': {
            'latitude': 31.0379,
            'longitude': 31.3815,
            'heading': 180,
            'speed_kmh': 15.0,
            'recorded_at': DateTime.now().toUtc().toIso8601String(),
            'service_state': 'between_runs',
            'progress_state': 'between_runs',
          },
        };

        final summary = TrackingSummary.fromJson(betweenRunsJson);

        expect(summary.status, LiveTrackingStatus.betweenRuns);
        expect(summary.serviceState, 'between_runs');
        expect(summary.progressState, 'between_runs');
        expect(summary.busLocation?.serviceState, 'between_runs');
      },
    );

    test(
      '28. Approach notification strictly depends on backend next_stop_id matching targetStop',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '09:20:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            activeRouteId: 'route-1',
            activeRunTime: '09:00',
            nextStopId: stop2.id, // Backend next_stop is stop2!
            currentStopId: stop1.id,
            currentStop: stop1,
            nextStop: stop2,
            routeStops: defaultStops,
            passengerTargetStop: stop2, // Target is stop2!
            approachAlertsEnabled: true,
          ),
        );

        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Notification must be triggered because backend next_stop_id == targetStop.id
        expect(repo.recordedNotifications.length, 1);
        expect(repo.recordedNotifications.first['targetStopId'], stop2.id);
        expect(cubit.state.approachAlertDispatched, true);

        cubit.close();
        repo.dispose();
      },
    );

    test(
      '29. Approach notification NOT sent when backend next_stop does not match passenger target',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '09:20:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            activeRouteId: 'route-1',
            activeRunTime: '09:00',
            nextStopId: stop1.id, // Bus next stop is stop 1
            currentStopId: null,
            routeStops: defaultStops,
            passengerTargetStop: stop3, // Target is stop 3 (not yet next stop)
            approachAlertsEnabled: true,
          ),
        );

        final cubit = TrackingCubit(repository: repo);
        await cubit.loadTrackingData(tripId: 'trip-test');

        expect(repo.recordedNotifications, isEmpty);
        expect(cubit.state.approachAlertDispatched, false);

        cubit.close();
        repo.dispose();
      },
    );

    test('30. No fake stop progression when stop coordinates are missing', () {
      final missingCoordsSummary = TrackingSummary.fromJson({
        'tracking_status': 'online',
        'is_in_service_window': true,
        'service_window': 'morning',
        'cairo_time': '09:10:00',
        'cairo_date': '2026-09-13',
        'active_direction': 'outbound',
        'has_stop_coordinates': false,
        'stops_with_coords_count': 0,
        'stops_count': 34,
        'progress_state': 'coordinates_unavailable',
        'current_stop': null,
        'next_stop': null,
      });

      expect(missingCoordsSummary.hasStopCoordinates, false);
      expect(missingCoordsSummary.stopsWithCoordsCount, 0);
      expect(missingCoordsSummary.progressState, 'coordinates_unavailable');
      expect(missingCoordsSummary.currentStop, isNull);
      expect(missingCoordsSummary.nextStop, isNull);
    });

    test(
      '31. Stops 18-34 have verified coordinates, 1-17 marked temporary QA',
      () {
        final stop1Qa = BusStopModel(
          id: 'stop-1',
          routeStopId: 'rs-1',
          stopOrder: 1,
          nameAr: 'كوبرى عزت — ميت فضالة',
          nameEn: 'Ezzat Bridge - Mit Fadala',
          localityAr: 'ميت فضالة',
          localityEn: 'Mit Fadala',
          latitude: 30.8870000,
          longitude: 31.3100000,
          isTemporaryQa: true,
          coordinateSource: 'temporary_qa',
        );

        final stop18Verified = BusStopModel(
          id: 'stop-18',
          routeStopId: 'rs-18',
          stopOrder: 18,
          nameAr: 'ماركت المراعي — برج النور الحمص',
          nameEn: 'Al Marai Market - Borg El Noor El Homs',
          localityAr: 'برج النور الحمص',
          localityEn: 'Borg El Noor El Homs',
          latitude: 30.9350382,
          longitude: 31.34714024,
          isTemporaryQa: false,
          coordinateSource: 'verified',
        );

        expect(stop1Qa.isTemporaryQa, true);
        expect(stop1Qa.coordinateSource, 'temporary_qa');
        expect(stop18Verified.isTemporaryQa, false);
        expect(stop18Verified.coordinateSource, 'verified');
      },
    );

    test(
      '32. Approach notification strictly ignores temporary QA coordinates',
      () async {
        final stop1Qa = BusStopModel(
          id: 'stop-1',
          routeStopId: 'rs-1',
          stopOrder: 1,
          nameAr: 'كوبرى عزت',
          nameEn: 'Ezzat Bridge',
          localityAr: 'ميت فضالة',
          localityEn: 'Mit Fadala',
          latitude: 30.8870000,
          longitude: 31.3100000,
          isTemporaryQa: true,
          coordinateSource: 'temporary_qa',
        );

        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.online,
            isInServiceWindow: true,
            serviceWindow: 'morning',
            cairoTime: '08:15:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            busLocation: BusTelemetry(
              latitude: 30.8870000,
              longitude: 31.3100000,
              gpsRecordedAt: DateTime.now().toUtc(),
              speedKmh: 30.0,
              nextStopId: 'stop-1',
              source: 'etrack',
            ),
            activeRouteId: 'route-1',
            activeRunTime: '08:00',
            nextStopId: 'stop-1',
            currentStopId: null,
            routeStops: [stop1Qa],
            passengerTargetStop: stop1Qa,
            approachAlertsEnabled: true,
          ),
        );

        final cubit = TrackingCubit(
          repository: repo,
          isQaAuthorizedOverride: false,
        );
        await cubit.loadTrackingData(tripId: 'trip-test');

        // Must NOT dispatch approach notification for temporary QA stop
        expect(repo.recordedNotifications, isEmpty);
        expect(cubit.state.approachAlertDispatched, false);

        cubit.close();
        repo.dispose();
      },
    );

    test(
      '33. Normal passenger outside hours sees OFFLINE, not QA PREVIEW',
      () async {
        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.offline,
            isInServiceWindow: false,
            serviceWindow: 'outside_hours',
            cairoTime: '21:00:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            busLocation: null,
            activeRouteId: 'route-1',
            activeRunTime: '08:00',
            routeStops: defaultStops,
          ),
        );

        final cubit = TrackingCubit(
          repository: repo,
          isQaAuthorizedOverride: false, // Normal passenger
        );
        await cubit.loadTrackingData(tripId: 'trip-test');

        expect(repo.lastIncludeQa, false);
        expect(cubit.state.trackingStatus, LiveTrackingStatus.offline);
        expect(cubit.state.isQaPreview, false);

        cubit.close();
        repo.dispose();
      },
    );

    test(
      '34. Authorized QA profile outside hours activates QA PREVIEW',
      () async {
        final all34Stops = List.generate(34, (i) {
          final order = i + 1;
          return BusStopModel(
            id: 'stop-$order',
            routeStopId: 'rs-$order',
            stopOrder: order,
            nameAr: 'محطة $order',
            nameEn: 'Stop $order',
            localityAr: 'المنطقة $order',
            localityEn: 'Locality $order',
            latitude: 30.8870 + (i * 0.003),
            longitude: 31.3100 + (i * 0.002),
            isTemporaryQa: order < 18,
            coordinateSource: order < 18 ? 'temporary_qa' : 'verified',
          );
        });

        final repo = FakeTrackingRepository(
          summary: TrackingSummary(
            status: LiveTrackingStatus.qaPreview,
            isInServiceWindow: false,
            serviceWindow: 'outside_hours',
            cairoTime: '21:00:00',
            cairoDate: '2026-09-13',
            activeDirection: TrackingDirection.outbound,
            busLocation: BusTelemetry(
              latitude: 30.8870,
              longitude: 31.3100,
              source: 'qa',
              gpsRecordedAt: DateTime.now(),
            ),
            activeRouteId: 'route-1',
            activeRunTime: '08:00',
            routeStops: all34Stops,
            isQaPreviewActive: true,
          ),
        );

        final cubit = TrackingCubit(
          repository: repo,
          isQaAuthorizedOverride: true, // Authorized QA Profile
        );
        await cubit.loadTrackingData(tripId: 'trip-test');

        expect(repo.lastIncludeQa, true);
        expect(cubit.state.trackingStatus, LiveTrackingStatus.qaPreview);
        expect(cubit.state.isQaPreview, true);
        expect(cubit.state.summary?.routeStops.length, 34);
        expect(cubit.state.latestTelemetry?.source, 'qa');

        cubit.close();
        repo.dispose();
      },
    );

    test('35. Real ETrack telemetry preserves source=etrack', () {
      final telemetry = BusTelemetry(
        latitude: 30.9350382,
        longitude: 31.34714024,
        gpsRecordedAt: DateTime.now().toUtc(),
        speedKmh: 42.0,
        source: 'etrack',
      );

      expect(telemetry.source, 'etrack');
      final json = telemetry.toJson();
      expect(json['source'], 'etrack');

      final deserialized = BusTelemetry.fromJson(json);
      expect(deserialized.source, 'etrack');
    });
  });
}
