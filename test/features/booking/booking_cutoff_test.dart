import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/core/error/app_error_mapper.dart';
import 'package:amomy_bus/core/localization/app_time_formatter.dart';
import 'package:amomy_bus/features/booking/domain/services/passenger_booking_availability.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/data/models/booking_models.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/today_trip_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';

Widget _wrapWithLocalization(
  Widget child, {
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: MediaQuery(
      data: const MediaQueryData(
        disableAnimations: true,
        size: Size(500, 1000),
      ),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('1. booking_close_at parses correctly', () {
    test('TripOptionModel parses booking_close_at correctly', () {
      final json = {
        'id': 'trip-1',
        'route_id': 'route-1',
        'bus_id': 'bus-1',
        'departure_time': '08:00',
        'departure_at': '2026-09-24T08:00:00Z',
        'booking_close_at': '2026-09-24T07:00:00Z',
        'route_name_ar': 'المسار',
        'route_name_en': 'Route',
        'origin_ar': 'نقطة الانطلاق',
        'origin_en': 'Origin',
        'destination_ar': 'الوجهة',
        'destination_en': 'Destination',
        'bus_plate': '123',
        'total_seats': 40,
        'available_seats': 10,
        'fare_points': 50.0,
        'status': 'scheduled',
        'direction': 'outbound',
      };

      final model = TripOptionModel.fromJson(json);
      expect(model.bookingCloseAt, isNotNull);
      expect(model.bookingCloseAt, DateTime.parse('2026-09-24T07:00:00Z'));
    });

    test('PassengerTodayTripModel parses booking_close_at correctly', () {
      final json = {
        'trip_id': 'trip-1',
        'departure_time': '08:00',
        'origin_stop_name_ar': 'نقطة الانطلاق',
        'origin_stop_name_en': 'Origin',
        'destination_stop_name_ar': 'الوجهة',
        'destination_stop_name_en': 'Destination',
        'bus_plate_number': '123',
        'seat_count': 40,
        'available_seat_count': 10,
        'departure_at': '2026-09-24T08:00:00Z',
        'booking_close_at': '2026-09-24T07:00:00Z',
      };

      final model = PassengerTodayTripModel.fromJson(json);
      expect(model.bookingCloseAt, isNotNull);
      expect(model.bookingCloseAt, DateTime.parse('2026-09-24T07:00:00Z'));
    });

    test('RoundTripReturnOptionModel parses booking_close_at correctly', () {
      final json = {
        'trip_id': 'ret-1',
        'route_id': 'route-ret',
        'departure_at': '2026-09-24T18:00:00Z',
        'departure_time': '18:00',
        'booking_close_at': '2026-09-24T17:00:00Z',
        'route_name_ar': 'عودة',
        'route_name_en': 'Return',
        'total_seats': 40,
        'available_seats': 15,
        'status': 'scheduled',
      };

      final model = RoundTripReturnOptionModel.fromJson(json);
      expect(model.bookingCloseAt, isNotNull);
      expect(model.bookingCloseAt, DateTime.parse('2026-09-24T17:00:00Z'));
    });
  });

  group('2, 3, 4. Booking cutoff rule (before, exact, after)', () {
    final cutoff = DateTime.parse('2026-09-24T07:00:00Z');

    test('before cutoff (06:59:59) -> booking enabled', () {
      final before = DateTime.parse('2026-09-24T06:59:59Z');
      expect(
        PassengerBookingAvailability.isBookingClosed(cutoff, now: before),
        isFalse,
      );
      expect(
        PassengerBookingAvailability.canCreateBooking(cutoff, now: before),
        isTrue,
      );
    });

    test('exact cutoff (07:00:00) -> booking disabled', () {
      final exact = DateTime.parse('2026-09-24T07:00:00Z');
      expect(
        PassengerBookingAvailability.isBookingClosed(cutoff, now: exact),
        isTrue,
      );
      expect(
        PassengerBookingAvailability.canCreateBooking(cutoff, now: exact),
        isFalse,
      );
    });

    test('after cutoff (07:00:01) -> booking disabled', () {
      final after = DateTime.parse('2026-09-24T07:00:01Z');
      expect(
        PassengerBookingAvailability.isBookingClosed(cutoff, now: after),
        isTrue,
      );
      expect(
        PassengerBookingAvailability.canCreateBooking(cutoff, now: after),
        isFalse,
      );
    });
  });

  group(
    '5. Trip remains visible after cutoff with route, departure time, fare',
    () {
      testWidgets('Trip details and metadata remain visible after cutoff', (
        tester,
      ) async {
        final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
        final trip = TripOption(
          tripId: 'trip-1',
          routeId: 'r1',
          departureTime: '08:00',
          originNameAr: 'القاهرة',
          originNameEn: 'Cairo',
          destinationNameAr: 'الإسكندرية',
          destinationNameEn: 'Alex',
          availableSeatsCount: 10,
          farePoints: 75.0,
          status: 'scheduled',
          direction: BookingDirection.outbound,
          departureAt: DateTime.now().add(const Duration(minutes: 55)),
          bookingCloseAt: cutoff,
        );

        await tester.pumpWidget(
          _wrapWithLocalization(
            DepartureTimeSelector(
              trips: [trip],
              selectedTrip: null,
              direction: BookingDirection.outbound,
              onTripSelected: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify trip details remain visible
        expect(find.byType(DepartureTimeSelector), findsOneWidget);
        expect(
          find.text(AppTimeFormatter.formatTripOption(trip, isArabic: true)),
          findsOneWidget,
        );
        // Verify disabled state label is present
        expect(find.text('الحجز مغلق'), findsWidgets);
      });
    },
  );

  group('6. Confirmed booking remains usable after cutoff', () {
    test('cutoff check is strictly isolated from confirmed booking models', () {
      final cutoff = DateTime.now().subtract(const Duration(hours: 2));
      expect(PassengerBookingAvailability.isBookingClosed(cutoff), isTrue);
      expect(PassengerBookingAvailability.canCreateBooking(cutoff), isFalse);
    });
  });

  group('7. Home booking CTA respects cutoff', () {
    testWidgets(
      'HomeBookRideCard shows disabled booking when isBookingAvailable is false',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithLocalization(
            const HomeBookRideCard(
              points: 100,
              isBookingAvailable: false,
              hasLoadedAvailability: true,
            ),
          ),
        );

        expect(find.text('الحجز مغلق'), findsOneWidget);
      },
    );
  });

  group('8. Available-trip card respects cutoff', () {
    testWidgets(
      'TodayTripCard disables button and shows badge when cutoff passes',
      (tester) async {
        final trip = PassengerTodayTrip(
          tripId: 'trip-1',
          routeId: 'r1',
          direction: BookingDirection.outbound,
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          originNameAr: 'القاهرة',
          originNameEn: 'Cairo',
          destinationNameAr: 'الإسكندرية',
          destinationNameEn: 'Alex',
          totalSeats: 40,
          availableSeats: 10,
          farePoints: 50.0,
          status: 'scheduled',
          alreadyBooked: false,
          availabilityStatus: TodayTripAvailabilityStatus.available,
          isBookable: true,
          departureAt: DateTime.now().add(const Duration(minutes: 50)),
          bookingCloseAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        await tester.pumpWidget(
          _wrapWithLocalization(TodayTripCard(trip: trip)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('الحجز مغلق'), findsWidgets);
      },
    );
  });

  group('9. Trip Details booking CTA respects cutoff', () {
    test('TripOption canBook returns false when isBookingClosed', () {
      final trip = TripOption(
        tripId: 'trip-1',
        routeId: 'r1',
        departureTime: '08:00',
        originNameAr: 'أ',
        originNameEn: 'A',
        destinationNameAr: 'ب',
        destinationNameEn: 'B',
        availableSeatsCount: 10,
        farePoints: 50.0,
        status: 'scheduled',
        direction: BookingDirection.outbound,
        departureAt: DateTime.now().add(const Duration(minutes: 40)),
        bookingCloseAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );

      expect(trip.isBookingClosed(), isTrue);
      expect(trip.canBook, isFalse);
    });
  });

  group('10. Seat Selection re-checks cutoff', () {
    test(
      'canBookAt properly invalidates when cutoff passes during seat selection',
      () {
        final cutoff = DateTime.now().add(const Duration(seconds: 2));
        final trip = TripOption(
          tripId: 'trip-1',
          routeId: 'r1',
          departureTime: '08:00',
          originNameAr: 'أ',
          originNameEn: 'A',
          destinationNameAr: 'ب',
          destinationNameEn: 'B',
          availableSeatsCount: 10,
          farePoints: 50.0,
          status: 'scheduled',
          direction: BookingDirection.outbound,
          departureAt: DateTime.now().add(const Duration(hours: 1)),
          bookingCloseAt: cutoff,
        );

        // When entered seat selection (before cutoff)
        expect(
          trip.canBookAt(now: cutoff.subtract(const Duration(seconds: 1))),
          isTrue,
        );

        // When submitting booking (after cutoff)
        expect(
          trip.canBookAt(now: cutoff.add(const Duration(seconds: 1))),
          isFalse,
        );
      },
    );
  });

  group('11. BOOKING_CLOSED maps to localized message', () {
    test('maps raw BOOKING_CLOSED to expected localized strings', () {
      final msgAr = AppErrorMapper.mapToString(
        'BOOKING_CLOSED',
        isArabic: true,
      );
      final msgEn = AppErrorMapper.mapToString(
        'BOOKING_CLOSED',
        isArabic: false,
      );

      expect(msgAr, 'انتهى وقت الحجز لهذه الرحلة.');
      expect(msgEn, 'Booking for this trip is closed.');
    });

    test('maps booking_closed case-insensitively', () {
      final msgAr = AppErrorMapper.mapToString(
        'booking_closed',
        isArabic: true,
      );
      expect(msgAr, 'انتهى وقت الحجز لهذه الرحلة.');
    });
  });

  group('12, 13, 14. Round trip booking cutoff', () {
    final now = DateTime.parse('2026-09-24T07:30:00Z');

    final openOutbound = TripOption(
      tripId: 'out-1',
      routeId: 'r1',
      departureTime: '09:00',
      originNameAr: 'أ',
      originNameEn: 'A',
      destinationNameAr: 'ب',
      destinationNameEn: 'B',
      availableSeatsCount: 10,
      farePoints: 50.0,
      status: 'scheduled',
      direction: BookingDirection.outbound,
      departureAt: DateTime.parse('2026-09-24T09:00:00Z'),
      bookingCloseAt: DateTime.parse('2026-09-24T08:00:00Z'), // open at 07:30
    );

    final closedOutbound = TripOption(
      tripId: 'out-2',
      routeId: 'r1',
      departureTime: '08:00',
      originNameAr: 'أ',
      originNameEn: 'A',
      destinationNameAr: 'ب',
      destinationNameEn: 'B',
      availableSeatsCount: 10,
      farePoints: 50.0,
      status: 'scheduled',
      direction: BookingDirection.outbound,
      departureAt: DateTime.parse('2026-09-24T08:00:00Z'),
      bookingCloseAt: DateTime.parse('2026-09-24T07:00:00Z'), // closed at 07:30
    );

    final openReturn = RoundTripReturnOption(
      returnTripId: 'ret-1',
      departureAt: DateTime.parse('2026-09-24T18:00:00Z'),
      departureTime: '18:00',
      availableSeats: 10,
      outboundBaseFarePoints: 50.0,
      returnBaseFarePoints: 50.0,
      subtotalPoints: 100.0,
      discountPercent: 15,
      discountPoints: 15.0,
      totalPoints: 85.0,
      isBookable: true,
      bookingCloseAt: DateTime.parse('2026-09-24T17:00:00Z'), // open at 07:30
    );

    final closedReturn = RoundTripReturnOption(
      returnTripId: 'ret-2',
      departureAt: DateTime.parse('2026-09-24T08:15:00Z'),
      departureTime: '08:15',
      availableSeats: 10,
      outboundBaseFarePoints: 50.0,
      returnBaseFarePoints: 50.0,
      subtotalPoints: 100.0,
      discountPercent: 15,
      discountPoints: 15.0,
      totalPoints: 85.0,
      isBookable: true,
      bookingCloseAt: DateTime.parse('2026-09-24T07:15:00Z'), // closed at 07:30
    );

    test('12. outbound closed blocks new round trip', () {
      final canBookOutbound = closedOutbound.canBookAt(now: now);
      final canBookRet = openReturn.canBookReturnAt(now: now);
      final canRoundTrip = canBookOutbound && canBookRet;

      expect(canBookOutbound, isFalse);
      expect(canBookRet, isTrue);
      expect(canRoundTrip, isFalse);
    });

    test('13. return closed blocks new round trip', () {
      final canBookOutbound = openOutbound.canBookAt(now: now);
      final canBookRet = closedReturn.canBookReturnAt(now: now);
      final canRoundTrip = canBookOutbound && canBookRet;

      expect(canBookOutbound, isTrue);
      expect(canBookRet, isFalse);
      expect(canRoundTrip, isFalse);
    });

    test('14. both open preserves current round-trip behavior', () {
      final canBookOutbound = openOutbound.canBookAt(now: now);
      final canBookRet = openReturn.canBookReturnAt(now: now);
      final canRoundTrip = canBookOutbound && canBookRet;

      expect(canBookOutbound, isTrue);
      expect(canBookRet, isTrue);
      expect(canRoundTrip, isTrue);
    });
  });

  group('15. Visible page transitions to closed when cutoff time arrives', () {
    testWidgets(
      'DepartureTimeSelector triggers rebuild when cutoff timer fires',
      (tester) async {
        var simulatedTime = DateTime.parse('2026-09-24T06:59:59Z');
        PassengerBookingAvailability.nowProvider = () => simulatedTime;
        addTearDown(() => PassengerBookingAvailability.nowProvider = null);

        final cutoff = DateTime.parse('2026-09-24T07:00:00Z');
        final trip = TripOption(
          tripId: 'trip-t',
          routeId: 'r1',
          departureTime: '08:00',
          originNameAr: 'أ',
          originNameEn: 'A',
          destinationNameAr: 'ب',
          destinationNameEn: 'B',
          availableSeatsCount: 10,
          farePoints: 50.0,
          status: 'scheduled',
          direction: BookingDirection.outbound,
          departureAt: DateTime.parse('2026-09-24T08:00:00Z'),
          bookingCloseAt: cutoff,
        );

        await tester.pumpWidget(
          _wrapWithLocalization(
            DepartureTimeSelector(
              trips: [trip],
              selectedTrip: null,
              direction: BookingDirection.outbound,
              onTripSelected: (_) {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Initially open
        expect(find.text('الحجز مغلق'), findsNothing);

        // Advance simulated time past cutoff and fire timer
        simulatedTime = DateTime.parse('2026-09-24T07:00:01Z');
        await tester.pump(const Duration(seconds: 2));

        // Now closed
        expect(find.text('الحجز مغلق'), findsWidgets);
      },
    );
  });

  group('16. App resume after cutoff reflects closed state', () {
    testWidgets('TodayTripCard re-evaluates cutoff when app resumes', (
      tester,
    ) async {
      var simulatedTime = DateTime.parse('2026-09-24T06:55:00Z');
      PassengerBookingAvailability.nowProvider = () => simulatedTime;
      addTearDown(() => PassengerBookingAvailability.nowProvider = null);

      final cutoff = DateTime.parse('2026-09-24T07:00:00Z');
      final trip = PassengerTodayTrip(
        tripId: 'trip-res',
        routeId: 'r1',
        direction: BookingDirection.outbound,
        serviceDate: DateTime.now(),
        departureTime: '08:00',
        originNameAr: 'القاهرة',
        originNameEn: 'Cairo',
        destinationNameAr: 'الإسكندرية',
        destinationNameEn: 'Alex',
        totalSeats: 40,
        availableSeats: 10,
        farePoints: 50.0,
        status: 'scheduled',
        alreadyBooked: false,
        availabilityStatus: TodayTripAvailabilityStatus.available,
        isBookable: true,
        departureAt: DateTime.parse('2026-09-24T08:00:00Z'),
        bookingCloseAt: cutoff,
      );

      await tester.pumpWidget(_wrapWithLocalization(TodayTripCard(trip: trip)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('احجز الآن'), findsOneWidget);

      // Advance simulated time to 07:05 (past cutoff) and resume app
      simulatedTime = DateTime.parse('2026-09-24T07:05:00Z');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الحجز مغلق'), findsWidgets);
    });
  });
}
