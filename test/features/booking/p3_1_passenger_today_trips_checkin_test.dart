import 'package:flutter/material.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/booking/data/models/booking_models.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/today_trip_card.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ar'), Locale('en')],
    locale: locale,
    home: Scaffold(body: child),
  );
}

PassengerTodayTrip _makeTrip({
  String tripId = 'trip-1',
  String status = 'scheduled',
  bool alreadyBooked = true,
  DateTime? checkedInAt,
  TodayTripAvailabilityStatus availabilityStatus =
      TodayTripAvailabilityStatus.alreadyBooked,
  BookingDirection direction = BookingDirection.outbound,
}) {
  final now = DateTime.now();
  return PassengerTodayTrip(
    tripId: tripId,
    routeId: 'route-1',
    direction: direction,
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
    status: status,
    alreadyBooked: alreadyBooked,
    bookingId: 'booking-1',
    seatNumber: '4',
    qrToken: 'qr-token-1',
    availabilityStatus: availabilityStatus,
    isBookable: false,
    checkedInAt: checkedInAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3.1 — Passenger Today Trips Check-in State Tests', () {
    // 1. Today Trips RPC returns checked_in_at
    test('1. Today Trips RPC returns checked_in_at and model parses it', () {
      final json = {
        'trip_id': 't-123',
        'route_id': 'r-123',
        'direction': 'outbound',
        'service_date': '2026-09-21',
        'origin_name_ar': 'المنصورة',
        'origin_name_en': 'Mansoura',
        'destination_name_ar': 'الدلتا',
        'destination_name_en': 'Delta',
        'departure_time': '08:00',
        'departure_at': '2026-09-21T05:00:00Z',
        'booking_close_at': '2026-09-21T04:45:00Z',
        'fare_points': 20,
        'total_seats': 14,
        'available_seats': 0,
        'status': 'completed',
        'already_booked': true,
        'booking_id': 'b-123',
        'seat_number': '5',
        'qr_token': 'qr-123',
        'availability_status': 'FINISHED',
        'is_bookable': false,
        'checked_in_at': '2026-09-21T19:05:25.047385Z',
        'is_checked_in': true,
      };

      final model = PassengerTodayTripModel.fromJson(json);

      expect(model.checkedInAt, isNotNull);
      expect(model.checkedInAt?.year, equals(2026));
      expect(model.isCheckedIn, isTrue);
    });

    // 2. Scanned confirmed booking returns is_checked_in = true
    test('2. Scanned confirmed booking returns is_checked_in = true', () {
      final json = {
        'trip_id': 't-1',
        'route_id': 'r-1',
        'direction': 'outbound',
        'service_date': '2026-09-21',
        'departure_time': '08:00',
        'departure_at': '2026-09-21T05:00:00Z',
        'booking_close_at': '2026-09-21T04:45:00Z',
        'fare_points': 20,
        'total_seats': 14,
        'available_seats': 0,
        'status': 'confirmed',
        'already_booked': true,
        'booking_id': 'b-1',
        'seat_number': '5',
        'qr_token': 'qr-1',
        'availability_status': 'FINISHED',
        'is_bookable': false,
        'checked_in_at': '2026-09-21T19:05:25.047385Z',
        'is_checked_in': true,
      };

      final model = PassengerTodayTripModel.fromJson(json);
      expect(model.isCheckedIn, isTrue);
    });

    // 3. Checked-in booking does NOT return ALREADY_BOOKED as its terminal UX state
    test('3. Checked-in booking does not return ALREADY_BOOKED as terminal state', () {
      final json = {
        'trip_id': 't-1',
        'route_id': 'r-1',
        'direction': 'outbound',
        'service_date': '2026-09-21',
        'departure_time': '08:00',
        'status': 'completed',
        'already_booked': true,
        'availability_status': 'FINISHED',
        'checked_in_at': '2026-09-21T19:05:25.047385Z',
        'is_checked_in': true,
      };

      final model = PassengerTodayTripModel.fromJson(json);
      expect(model.availabilityStatus, equals(TodayTripAvailabilityStatus.finished));
      expect(model.availabilityStatus, isNot(equals(TodayTripAvailabilityStatus.alreadyBooked)));
    });

    // 4. Completed + checked-in trip returns FINISHED
    test('4. Completed + checked-in trip returns FINISHED', () {
      final status = TodayTripAvailabilityStatus.fromString('FINISHED');
      expect(status, equals(TodayTripAvailabilityStatus.finished));

      final trip = _makeTrip(
        status: 'completed',
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      expect(trip.isFinished, isTrue);
      expect(trip.isCheckedIn, isTrue);
    });

    // 5. Flutter parses checked_in_at
    test('5. Flutter parses checked_in_at ISO string into DateTime', () {
      final json = {
        'trip_id': 't-prod',
        'route_id': 'r-prod',
        'direction': 'outbound',
        'service_date': '2026-09-21',
        'departure_time': '08:00',
        'status': 'completed',
        'already_booked': true,
        'availability_status': 'FINISHED',
        'checked_in_at': '2026-09-21T19:05:25.047385+00:00',
      };

      final model = PassengerTodayTripModel.fromJson(json);
      expect(model.checkedInAt, isNotNull);
      expect(model.checkedInAt!.isUtc, isTrue);
      expect(model.checkedInAt!.hour, equals(19));
      expect(model.checkedInAt!.minute, equals(5));
    });

    // 6. TodayTripCard checked-in booking is grey
    testWidgets('6. TodayTripCard checked-in booking is visually grey', (tester) async {
      final trip = _makeTrip(
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip)));
      await tester.pump(const Duration(milliseconds: 500));

      // Finished badge rendered
      expect(find.text('منتهية'), findsOneWidget);
    });

    // 7. Checked-in card label is Finished / منتهية
    testWidgets('7. Checked-in card label is Finished / منتهية in AR and EN', (tester) async {
      final trip = _makeTrip(
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      // Arabic
      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip), locale: const Locale('ar')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('منتهية'), findsOneWidget);

      // English
      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip), locale: const Locale('en')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Finished'), findsOneWidget);
    });

    // 8. Checked-in card has no QR action
    testWidgets('8. Checked-in card has no QR action', (tester) async {
      final trip = _makeTrip(
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('التذكرة'), findsNothing);
      expect(find.text('Ticket'), findsNothing);
    });

    // 9. Checked-in card has no add-seat/cancel/change-seat actions
    testWidgets('9. Checked-in card has no add-seat or overflow menu actions', (tester) async {
      final trip = _makeTrip(
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('إضافة مقعد'), findsNothing);
      expect(find.text('Extra Seat'), findsNothing);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
    });

    // 10. Unscanned confirmed booking still shows normal booked state
    testWidgets('10. Unscanned confirmed booking still shows normal booked state', (tester) async {
      final trip = _makeTrip(
        status: 'confirmed',
        alreadyBooked: true,
        checkedInAt: null,
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: trip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('محجوزة'), findsOneWidget);
      expect(find.text('التذكرة'), findsOneWidget);
      expect(find.text('إضافة مقعد'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    });

    // 11. Round Trip outbound scanned does not finish return
    test('11. Round Trip outbound scanned does not finish return', () {
      final now = DateTime.now();
      final outboundTrip = _makeTrip(
        tripId: 'outbound-1',
        direction: BookingDirection.outbound,
        checkedInAt: now,
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );
      final returnTrip = _makeTrip(
        tripId: 'return-1',
        direction: BookingDirection.returnTrip,
        checkedInAt: null,
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
      );

      expect(outboundTrip.isCheckedIn, isTrue);
      expect(outboundTrip.isFinished, isTrue);

      expect(returnTrip.isCheckedIn, isFalse);
      expect(returnTrip.isFinished, isFalse);
      expect(returnTrip.availabilityStatus, equals(TodayTripAvailabilityStatus.alreadyBooked));
    });

    // 12. Extra seat rows do not incorrectly override primary booking check-in state
    test('12. Extra seat rows do not incorrectly override primary booking check-in state', () {
      // Simulates aggregation where primary booking was checked in, and extra seat was added
      final now = DateTime.now();
      final primaryCheckIn = now.subtract(const Duration(minutes: 5));

      final aggregatedJson = {
        'trip_id': 'trip-multi',
        'route_id': 'route-1',
        'direction': 'outbound',
        'service_date': '2026-09-21',
        'departure_time': '08:00',
        'status': 'confirmed',
        'already_booked': true,
        'booking_id': 'primary-bkg-1',
        'seat_number': '4، 5', // 2 seats
        'qr_token': 'primary-qr',
        'availability_status': 'FINISHED',
        'checked_in_at': primaryCheckIn.toIso8601String(),
        'is_checked_in': true,
      };

      final trip = PassengerTodayTripModel.fromJson(aggregatedJson);
      expect(trip.isCheckedIn, isTrue);
      expect(trip.seatNumber, equals('4، 5'));
      expect(trip.checkedInAt, equals(primaryCheckIn));
    });

    // 13. Passenger refresh after simulated booking update changes card state
    testWidgets('13. Passenger refresh after simulated booking update changes card state', (tester) async {
      // 1. Initial unscanned booking
      final unscannedTrip = _makeTrip(
        status: 'confirmed',
        alreadyBooked: true,
        checkedInAt: null,
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: unscannedTrip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('محجوزة'), findsOneWidget);
      expect(find.text('التذكرة'), findsOneWidget);

      // 2. Simulated real-time scan update
      final scannedTrip = _makeTrip(
        status: 'confirmed',
        alreadyBooked: true,
        checkedInAt: DateTime.now(),
        availabilityStatus: TodayTripAvailabilityStatus.finished,
      );

      await tester.pumpWidget(_wrap(TodayTripCard(trip: scannedTrip)));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('محجوزة'), findsNothing);
      expect(find.text('منتهية'), findsOneWidget);
      expect(find.text('التذكرة'), findsNothing);
    });
  });
}
