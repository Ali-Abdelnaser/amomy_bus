import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/qr_ticket_modal.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _TestBookingRepo implements BookingRepository {
  List<PassengerTodayTrip> todayTrips = [];
  List<PassengerBooking> bookings = [];

  @override
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async =>
      Success(todayTrips);

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async =>
      const Success(null);

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async =>
      Success(bookings);

  @override
  ResultFuture<List<RouteStop>> getRouteStops({BookingDirection? direction}) async =>
      const Success([]);

  @override
  Stream<void> subscribeToPassengerBookingUpdates() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AMOMY Passenger Extra Seat QR Contract Tests', () {
    test('1. Each booking has its own unique qr_token and never reuses primary QR', () {
      const primaryQr = 'qr_token_primary_seat_4';
      const extraQr = 'qr_token_extra_seat_5';
      const tripId = 'trip-100';
      const userId = 'user-200';
      final now = DateTime.now();

      final primaryBooking = PassengerBooking(
        bookingId: 'booking-p',
        tripId: tripId,
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'القاهرة',
        destinationNameEn: 'Cairo',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '4',
        farePoints: 20,
        status: 'confirmed',
        qrToken: primaryQr,
        bookedAt: now,
      );

      final extraBooking = PassengerBooking(
        bookingId: 'booking-e',
        tripId: tripId,
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'القاهرة',
        destinationNameEn: 'Cairo',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '5',
        farePoints: 20,
        status: 'confirmed',
        qrToken: extraQr,
        bookedAt: now,
      );

      final ticket1 = QrTicketItem.fromBooking(
        primaryBooking,
        locale: 'ar',
        isExtraSeat: false,
      );

      final ticket2 = QrTicketItem.fromBooking(
        extraBooking,
        locale: 'ar',
        isExtraSeat: true,
      );

      // Verify each seat has its own distinct QR token
      expect(ticket1.qrToken, equals(primaryQr));
      expect(ticket2.qrToken, equals(extraQr));
      expect(ticket1.qrToken, isNot(equals(ticket2.qrToken)));

      // Verify neither ticket uses tripId or userId as QR
      expect(ticket1.qrToken, isNot(equals(tripId)));
      expect(ticket1.qrToken, isNot(equals(userId)));
      expect(ticket2.qrToken, isNot(equals(tripId)));
      expect(ticket2.qrToken, isNot(equals(userId)));

      // Verify seat numbers and extra seat status
      expect(ticket1.seatNumber, equals('4'));
      expect(ticket1.isExtraSeat, isFalse);
      expect(ticket2.seatNumber, equals('5'));
      expect(ticket2.isExtraSeat, isTrue);
    });

    testWidgets('2. QrTicketModal renders tabs for multiple seats and switches QR token', (tester) async {
      const primaryQr = 'qr_token_seat_4_authoritative';
      const extraQr = 'qr_token_seat_5_authoritative';

      final List<QrTicketItem> tickets = [
        const QrTicketItem(
          bookingId: 'b-1',
          seatNumber: '4',
          qrToken: primaryQr,
          farePoints: 25,
          departureTime: '09:00 ص',
          originName: 'المنصورة',
          destinationName: 'القاهرة',
          isExtraSeat: false,
        ),
        const QrTicketItem(
          bookingId: 'b-2',
          seatNumber: '5',
          qrToken: extraQr,
          farePoints: 25,
          departureTime: '09:00 ص',
          originName: 'المنصورة',
          destinationName: 'القاهرة',
          isExtraSeat: true,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          QrTicketModal(tickets: tickets),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Should show tabs for both seats
      expect(find.text('مقعد 4'), findsOneWidget);
      expect(find.text('مقعد 5 (إضافي)'), findsOneWidget);

      // 2. Currently showing seat 4 (primary) QR
      final qrFinderPrimary = find.byType(AppQrTicketWidget);
      expect(qrFinderPrimary, findsOneWidget);
      final qrWidget1 = tester.widget<AppQrTicketWidget>(qrFinderPrimary);
      expect(qrWidget1.data, equals(primaryQr));
      expect(qrWidget1.data, isNot(equals(extraQr)));

      // 3. Tap on seat 5 (extra seat) tab
      await tester.tap(find.text('مقعد 5 (إضافي)'));
      await tester.pumpAndSettle();

      // 4. QR should now strictly be seat 5's unique QR
      final qrWidget2 = tester.widget<AppQrTicketWidget>(qrFinderPrimary);
      expect(qrWidget2.data, equals(extraQr));
      expect(qrWidget2.data, isNot(equals(primaryQr)));
    });

    testWidgets('3. QrTicketModal opens directly with initialIndex for extra seat', (tester) async {
      const primaryQr = 'qr_token_seat_10';
      const extraQr = 'qr_token_seat_11';

      final List<QrTicketItem> tickets = [
        const QrTicketItem(
          bookingId: 'b-10',
          seatNumber: '10',
          qrToken: primaryQr,
          farePoints: 30,
          departureTime: '10:00 ص',
          originName: 'طنطا',
          destinationName: 'الإسكندرية',
          isExtraSeat: false,
        ),
        const QrTicketItem(
          bookingId: 'b-11',
          seatNumber: '11',
          qrToken: extraQr,
          farePoints: 30,
          departureTime: '10:00 ص',
          originName: 'طنطا',
          destinationName: 'الإسكندرية',
          isExtraSeat: true,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          QrTicketModal(tickets: tickets, initialIndex: 1),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      // QR should immediately show seat 11's unique QR
      final qrFinder = find.byType(AppQrTicketWidget);
      final qrWidget = tester.widget<AppQrTicketWidget>(qrFinder);
      expect(qrWidget.data, equals(extraQr));
    });

    test('4. PassengerTripsCubit enriches todayTrips with confirmed bookings and separate qrTokens', () async {
      final repo = _TestBookingRepo();
      final now = DateTime.now();

      final todayTrip = PassengerTodayTrip(
        tripId: 'trip-multi',
        routeId: 'route-1',
        direction: BookingDirection.outbound,
        serviceDate: now,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'القاهرة',
        destinationNameEn: 'Cairo',
        departureTime: '08:00',
        departureAt: now,
        bookingCloseAt: now.subtract(const Duration(minutes: 10)),
        farePoints: 20,
        totalSeats: 14,
        availableSeats: 0,
        status: 'scheduled',
        alreadyBooked: true,
        bookingId: 'b-primary',
        seatNumber: '4، 5', // Aggregated seat string from RPC
        qrToken: 'qr-primary-aggregated',
        availabilityStatus: TodayTripAvailabilityStatus.alreadyBooked,
        isBookable: false,
      );

      final booking1 = PassengerBooking(
        bookingId: 'b-primary',
        tripId: 'trip-multi',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'القاهرة',
        destinationNameEn: 'Cairo',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '4',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr_token_authoritative_4',
        bookedAt: now,
      );

      final booking2 = PassengerBooking(
        bookingId: 'b-extra',
        tripId: 'trip-multi',
        direction: BookingDirection.outbound,
        originNameAr: 'المنصورة',
        originNameEn: 'Mansoura',
        destinationNameAr: 'القاهرة',
        destinationNameEn: 'Cairo',
        serviceDate: now,
        departureTime: '08:00',
        departureAt: now,
        seatNumber: '5',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'qr_token_authoritative_5',
        bookedAt: now.add(const Duration(minutes: 5)),
      );

      repo.todayTrips = [todayTrip];
      repo.bookings = [booking1, booking2];

      final cubit = PassengerTripsCubit(
        GetPassengerBookingsUseCase(repo),
        repo,
      );

      await cubit.loadTripsHub();

      // Check enriched bookings on today trip
      final loadedToday = cubit.state.todayTrips;
      expect(loadedToday, isNotEmpty);
      final trip = loadedToday.first;
      expect(trip.bookings.length, equals(2));
      expect(trip.bookings[0].seatNumber, equals('4'));
      expect(trip.bookings[0].qrToken, equals('qr_token_authoritative_4'));
      expect(trip.bookings[1].seatNumber, equals('5'));
      expect(trip.bookings[1].qrToken, equals('qr_token_authoritative_5'));

      // Check getBookingsForTrip helper
      final forTrip = await cubit.getBookingsForTrip('trip-multi');
      expect(forTrip.length, equals(2));
      expect(forTrip[0].qrToken, equals('qr_token_authoritative_4'));
      expect(forTrip[1].qrToken, equals('qr_token_authoritative_5'));

      // Check getCachedBookingsForTrip helper
      final cachedForTrip = cubit.getCachedBookingsForTrip('trip-multi');
      expect(cachedForTrip.length, equals(2));
      expect(cachedForTrip[0].qrToken, equals('qr_token_authoritative_4'));
      expect(cachedForTrip[1].qrToken, equals('qr_token_authoritative_5'));
    });
  });
}
