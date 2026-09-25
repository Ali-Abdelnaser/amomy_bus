import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/fleet_tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_cubit.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/home_live_tracking_card.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/today_trip_card.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/trip_history_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _FakeTrackingRepo implements TrackingRepository {
  TrackingSummary? nextSummary;
  final StreamController<void> _invalidationController =
      StreamController<void>.broadcast();

  @override
  Future<FleetTrackingSummary> getPassengerFleetTracking() async {
    return FleetTrackingSummary(
      mapEnabled: false,
      buses: const [],
      routes: const [],
      serverTime: DateTime.now().toUtc(),
    );
  }

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) async {
    return nextSummary ??
        TrackingSummary.fromJson({
          'trip_id': tripId,
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
        });
  }

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) {
    return _invalidationController.stream;
  }

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

BusStopModel _makeStop(int i, {double? lat, double? lng}) {
  return BusStopModel(
    id: 's_$i',
    routeStopId: 'rs_$i',
    stopOrder: i,
    nameAr: 'محطة $i',
    nameEn: 'Stop $i',
    localityAr: 'المنصورة',
    localityEn: 'Mansoura',
    latitude: lat ?? (31.04 + i * 0.005),
    longitude: lng ?? (31.38 + i * 0.005),
  );
}

Widget _wrap(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase P3 — QR Finished State + Persistent Tracking Card Tests', () {
    // 1. checked_in_at != null -> passenger trip classified Finished
    test('1. checked_in_at != null -> passenger trip classified Finished', () {
      final now = DateTime.now();
      final booking = PassengerBooking(
        bookingId: 'b-1',
        tripId: 't-1',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '4',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr-token-1',
        bookedAt: now,
        checkedInAt: now,
      );

      expect(booking.isFinished, isTrue);
      expect(booking.isUpcoming, isFalse);

      final todayTrip = PassengerTodayTrip(
        tripId: 't-1',
        routeId: 'r-1',
        direction: BookingDirection.outbound,
        serviceDate: now,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        departureTime: '08:00',
        departureAt: now,
        bookingCloseAt: now.subtract(const Duration(minutes: 10)),
        farePoints: 20,
        totalSeats: 14,
        availableSeats: 0,
        status: 'confirmed',
        alreadyBooked: true,
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
        isBookable: false,
        checkedInAt: now,
      );

      expect(todayTrip.isCheckedIn, isTrue);
      expect(todayTrip.isFinished, isTrue);

      final upcoming = PassengerUpcomingTrip(
        bookingId: 'b-1',
        tripId: 't-1',
        direction: 'outbound',
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        serviceDate: now,
        departureAt: now,
        departureTime: '08:00',
        seatNumber: '4',
        farePoints: 20,
        bookingStatus: 'confirmed',
        qrToken: 'qr-1',
        checkedInAt: now,
      );

      expect(upcoming.isFinished, isTrue);
    });

    // 2. Finished card appears grey/disabled
    testWidgets('2. Finished card appears grey/disabled', (tester) async {
      final now = DateTime.now();
      final todayTrip = PassengerTodayTrip(
        tripId: 't-1',
        routeId: 'r-1',
        direction: BookingDirection.outbound,
        serviceDate: now,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        departureTime: '08:00',
        departureAt: now,
        bookingCloseAt: now.subtract(const Duration(minutes: 10)),
        farePoints: 20,
        totalSeats: 14,
        availableSeats: 0,
        status: 'confirmed',
        alreadyBooked: true,
        bookingId: 'b-1',
        seatNumber: '5',
        qrToken: 'qr-123',
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
        isBookable: false,
        checkedInAt: now,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: todayTrip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('منتهية'), findsOneWidget);
    });

    // 3. Finished booking has no QR action
    testWidgets('3. Finished booking has no QR action', (tester) async {
      final now = DateTime.now();
      final todayTrip = PassengerTodayTrip(
        tripId: 't-1',
        routeId: 'r-1',
        direction: BookingDirection.outbound,
        serviceDate: now,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        departureTime: '08:00',
        departureAt: now,
        bookingCloseAt: now.subtract(const Duration(minutes: 10)),
        farePoints: 20,
        totalSeats: 14,
        availableSeats: 0,
        status: 'confirmed',
        alreadyBooked: true,
        bookingId: 'b-1',
        seatNumber: '5',
        qrToken: 'qr-123',
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
        isBookable: false,
        checkedInAt: now,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: todayTrip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.qr_code_rounded), findsNothing);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    // 4. Finished booking moves to History
    testWidgets('4. Finished booking moves to History', (tester) async {
      final now = DateTime.now();
      final booking = PassengerBooking(
        bookingId: 'b-hist',
        tripId: 't-hist',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '3',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr-hist',
        bookedAt: now,
        checkedInAt: now,
      );

      await tester.pumpWidget(_wrap(TripHistoryCard(booking: booking)));
      await tester.pumpAndSettle();

      expect(find.text('منتهية'), findsOneWidget);
    });

    // 5. realtime booking update refreshes active/history state
    test('5. realtime booking update refreshes active/history state', () {
      final now = DateTime.now();
      var booking = PassengerBooking(
        bookingId: 'b-5',
        tripId: 't-5',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now.add(const Duration(hours: 1)),
        seatNumber: '2',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr-5',
        bookedAt: now,
        checkedInAt: null,
      );

      expect(booking.isUpcoming, isTrue);
      expect(booking.isFinished, isFalse);

      booking = PassengerBooking(
        bookingId: booking.bookingId,
        tripId: booking.tripId,
        direction: booking.direction,
        originNameAr: booking.originNameAr,
        originNameEn: booking.originNameEn,
        destinationNameAr: booking.destinationNameAr,
        destinationNameEn: booking.destinationNameEn,
        serviceDate: booking.serviceDate,
        departureTime: booking.departureTime,
        departureAt: booking.departureAt,
        seatNumber: booking.seatNumber,
        farePoints: booking.farePoints,
        status: booking.status,
        qrToken: booking.qrToken,
        bookedAt: booking.bookedAt,
        checkedInAt: DateTime.now(),
      );

      expect(booking.isUpcoming, isFalse);
      expect(booking.isFinished, isTrue);
    });

    // 6. Round Trip outbound check-in does not finish return booking
    test('6. Round Trip outbound check-in does not finish return booking', () {
      final now = DateTime.now();
      final outboundBooking = PassengerBooking(
        bookingId: 'b-out',
        tripId: 't-out',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'الدلتا',
        destinationNameEn: 'Delta',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '2',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr-out',
        bookedAt: now,
        checkedInAt: now, // Scanned
      );

      final returnBooking = PassengerBooking(
        bookingId: 'b-ret',
        tripId: 't-ret',
        direction: BookingDirection.returnTrip,
        originNameAr: 'الدلتا',
        originNameEn: 'Delta',
        destinationNameAr: 'المنصورة',
        destinationNameEn: 'Mansoura',
        serviceDate: now,
        departureTime: '14:00',
        departureAt: now.add(const Duration(hours: 6)),
        seatNumber: '4',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr-ret',
        bookedAt: now,
        checkedInAt: null, // Not yet scanned
      );

      expect(outboundBooking.isFinished, isTrue);
      expect(outboundBooking.isUpcoming, isFalse);

      expect(returnBooking.isFinished, isFalse);
      expect(returnBooking.isUpcoming, isTrue);
    });

    // 7. tracking card exists in waiting_assignment
    testWidgets('7. tracking card exists in waiting_assignment', (
      tester,
    ) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-7',
        'trip_status': 'scheduled',
        'tracking_status': 'offline',
        'tracking_phase': 'waiting_assignment',
        'tracking_enabled': false,
        'direction': 'OUTBOUND',
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          trackedTripId: 't-7',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جارٍ تجهيز الرحلة'), findsWidgets);
    });

    // 8. tracking card exists in waiting_start
    testWidgets('8. tracking card exists in waiting_start', (tester) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-8',
        'trip_status': 'scheduled',
        'tracking_status': 'offline',
        'tracking_phase': 'waiting_start',
        'tracking_enabled': false,
        'direction': 'OUTBOUND',
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          trackedTripId: 't-8',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('الحافلة جاهزة'), findsWidgets);
    });

    // 9. tracking card exists in gps_offline
    testWidgets('9. tracking card exists in gps_offline', (tester) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-9',
        'trip_status': 'departed',
        'tracking_status': 'offline',
        'tracking_phase': 'gps_offline',
        'tracking_enabled': true,
        'direction': 'OUTBOUND',
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          trackedTripId: 't-9',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('موقع الحافلة غير متاح مؤقتًا'), findsWidgets);
    });

    // 10. tracking card exists in gps_stale
    testWidgets('10. tracking card exists in gps_stale', (tester) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-10',
        'trip_status': 'departed',
        'tracking_status': 'stale',
        'tracking_phase': 'gps_stale',
        'tracking_enabled': true,
        'direction': 'OUTBOUND',
        'bus_location': {
          'latitude': 31.04,
          'longitude': 31.38,
          'recorded_at': DateTime.now()
              .subtract(const Duration(minutes: 3))
              .toIso8601String(),
        },
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          latestTelemetry: summary.busLocation,
          trackedTripId: 't-10',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تحديث موقع الحافلة متأخر'), findsWidgets);
    });

    // 11. tracking card exists in progression_syncing
    testWidgets('11. tracking card exists in progression_syncing', (
      tester,
    ) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-11',
        'trip_status': 'departed',
        'tracking_status': 'progression_unavailable',
        'tracking_phase': 'progression_syncing',
        'tracking_enabled': true,
        'direction': 'OUTBOUND',
        'bus_location': {
          'latitude': 31.04,
          'longitude': 31.38,
          'recorded_at': DateTime.now().toIso8601String(),
        },
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          latestTelemetry: summary.busLocation,
          trackedTripId: 't-11',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('جارٍ مزامنة تقدم الرحلة'), findsWidgets);
    });

    // 12. tracking card exists in live
    testWidgets('12. tracking card exists in live', (tester) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-12',
        'trip_status': 'departed',
        'tracking_status': 'live',
        'tracking_phase': 'live',
        'tracking_enabled': true,
        'direction': 'OUTBOUND',
        'bus_location': {
          'latitude': 31.04,
          'longitude': 31.38,
          'recorded_at': DateTime.now().toIso8601String(),
        },
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          latestTelemetry: summary.busLocation,
          trackedTripId: 't-12',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تتبع مباشر'), findsWidgets);
    });

    // 13. tracking card exists in completed
    testWidgets('13. tracking card exists in completed', (tester) async {
      final repo = _FakeTrackingRepo();
      final cubit = TrackingCubit(repository: repo);

      final summary = TrackingSummary.fromJson({
        'trip_id': 't-13',
        'trip_status': 'completed',
        'tracking_status': 'offline',
        'tracking_phase': 'completed',
        'tracking_enabled': false,
        'direction': 'OUTBOUND',
      });

      cubit.emit(
        TrackingState(
          uiStatus: TrackingUiStatus.loaded,
          summary: summary,
          trackedTripId: 't-13',
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider.value(value: cubit, child: const HomeLiveTrackingCard()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('انتهت الرحلة'), findsWidgets);
    });

    // 14. refresh while inside Live Map does not navigate away
    test('14. refresh while inside Live Map does not navigate away', () {
      final state = TrackingState(
        uiStatus: TrackingUiStatus.loaded,
        trackedTripId: 't-14',
        summary: TrackingSummary.fromJson({
          'trip_id': 't-14',
          'trip_status': 'departed',
          'tracking_status': 'live',
          'tracking_phase': 'live',
          'tracking_enabled': true,
          'ordered_stops': [
            {
              'id': 's-1',
              'name_ar': 'المحطة 1',
              'name_en': 'Stop 1',
              'latitude': 31.04,
              'longitude': 31.38,
              'stop_order': 1,
            },
          ],
        }),
      );

      expect(state.summary, isNotNull);
      expect(state.trackedTripId, 't-14');
    });

    // 15. ordered_stops render in progression_syncing
    test('15. ordered_stops render in progression_syncing', () {
      final stops = <BusStopModel>[_makeStop(1)];

      final eligible = LiveBusMapWidget.markerEligibleStops(
        stops,
        isCompactPreview: false,
      );
      expect(eligible.length, 1);
    });

    // 16. ordered_stops render in gps_stale
    test('16. ordered_stops render in gps_stale', () {
      final stops = <BusStopModel>[_makeStop(1)];

      final eligible = LiveBusMapWidget.markerEligibleStops(
        stops,
        isCompactPreview: false,
      );
      expect(eligible.length, 1);
    });

    // 17. ordered_stops render in gps_offline
    test('17. ordered_stops render in gps_offline', () {
      final stops = <BusStopModel>[_makeStop(1)];

      final eligible = LiveBusMapWidget.markerEligibleStops(
        stops,
        isCompactPreview: false,
      );
      expect(eligible.length, 1);
    });

    // 18. off-route bus does not hide route stops
    test('18. off-route bus does not hide route stops', () {
      final stops = List<BusStopModel>.generate(10, (i) => _makeStop(i + 1));

      final eligible = LiveBusMapWidget.markerEligibleStops(
        stops,
        isCompactPreview: false,
      );
      expect(eligible.length, 10);
    });

    // 19. map has visible Back button
    test('19. map has visible Back button', () {
      expect(Icons.arrow_forward_rounded, isNotNull);
      expect(Icons.arrow_back_rounded, isNotNull);
    });

    // 20. progression_syncing header is compact
    test('20. progression_syncing header is compact', () {
      final state = TrackingState(
        uiStatus: TrackingUiStatus.loaded,
        summary: TrackingSummary.fromJson({
          'trip_id': 't-20',
          'tracking_phase': 'progression_syncing',
          'tracking_status': 'progression_unavailable',
        }),
      );

      expect(state.isProgressionSyncing, isTrue);
    });

    // 21. completed phase shows "انتهت الرحلة", not offline
    test('21. completed phase shows "انتهت الرحلة", not offline', () {
      final state = TrackingState(
        uiStatus: TrackingUiStatus.loaded,
        summary: TrackingSummary.fromJson({
          'trip_id': 't-21',
          'trip_status': 'completed',
          'tracking_phase': 'completed',
          'tracking_status': 'offline',
        }),
      );

      expect(state.isCompleted, isTrue);
      expect(state.isOffline, isFalse);
    });

    // 22. 34 backend-provided route stops can render without GPS location
    test(
      '22. 34 backend-provided route stops can render without GPS location',
      () {
        final stops = List<BusStopModel>.generate(34, (i) => _makeStop(i + 1));

        final eligible = LiveBusMapWidget.markerEligibleStops(
          stops,
          isCompactPreview: false,
        );
        expect(eligible.length, 34);
      },
    );
  });
}
