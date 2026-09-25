import 'package:amomy_bus/core/localization/app_time_formatter.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/services/passenger_booking_availability.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_state.dart';
import 'package:amomy_bus/features/trips/presentation/pages/my_trips_page.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildLocalizedApp(Widget child, {Locale locale = const Locale('en')}) {
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
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: child),
    ),
  );
}

PassengerTodayTrip _todayTrip({
  required String tripId,
  required DateTime departureAt,
  required BookingDirection direction,
  bool isBookable = true,
}) {
  return PassengerTodayTrip(
    tripId: tripId,
    routeId: 'route-1',
    direction: direction,
    serviceDate: DateTime(2026, 9, 16),
    originNameAr: 'ميت فضالة',
    originNameEn: 'Mit Fadala',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    departureTime: '${departureAt.hour.toString().padLeft(2, '0')}:00',
    departureAt: departureAt,
    bookingCloseAt: departureAt.subtract(const Duration(minutes: 30)),
    farePoints: 25,
    totalSeats: 29,
    availableSeats: 10,
    status: 'scheduled',
    alreadyBooked: false,
    availabilityStatus: TodayTripAvailabilityStatus.available,
    isBookable: isBookable,
  );
}

TripOption _tripOption({
  required String tripId,
  required DateTime departureAt,
  required BookingDirection direction,
}) {
  return TripOption(
    tripId: tripId,
    routeId: 'route-1',
    direction: direction,
    originNameAr: 'ميت فضالة',
    originNameEn: 'Mit Fadala',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    departureTime: '${departureAt.hour.toString().padLeft(2, '0')}:00',
    departureAt: departureAt,
    farePoints: 25,
    availableSeatsCount: 10,
    status: 'scheduled',
  );
}

class _TestPassengerTripsCubit extends PassengerTripsCubit {
  _TestPassengerTripsCubit(PassengerTripsState initialState) : super.idle() {
    emit(initialState);
  }
}

void main() {
  group('Phase 9 schedule timezone and availability regressions', () {
    setUp(() {
      PassengerBookingAvailability.nowProvider =
          () => DateTime.utc(2026, 9, 16, 4, 0);
    });

    tearDown(() {
      PassengerBookingAvailability.nowProvider = null;
    });

    test('S. UTC timestamptz for 08:00 Africa/Cairo displays 8:00 AM', () {
      final display = AppTimeFormatter.formatDepartureTime(
        departureAt: DateTime.utc(2026, 9, 16, 5),
        locale: 'en',
      );

      expect(display, '8:00 AM');
      expect(display, isNot('5:00 AM'));
    });

    test('T. Production outbound schedule renders exact Cairo wall-clock', () {
      final trips = [
        _tripOption(
          tripId: 'out-08',
          departureAt: DateTime.utc(2026, 9, 16, 5),
          direction: BookingDirection.outbound,
        ),
        _tripOption(
          tripId: 'out-09',
          departureAt: DateTime.utc(2026, 9, 16, 6),
          direction: BookingDirection.outbound,
        ),
        _tripOption(
          tripId: 'out-10',
          departureAt: DateTime.utc(2026, 9, 16, 7),
          direction: BookingDirection.outbound,
        ),
        _tripOption(
          tripId: 'out-11',
          departureAt: DateTime.utc(2026, 9, 16, 8),
          direction: BookingDirection.outbound,
        ),
      ];

      expect(
        trips.map(
          (trip) => AppTimeFormatter.formatTripOption(trip, locale: 'en'),
        ),
        ['8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM'],
      );
    });

    test('U. Production return schedule renders exact Cairo wall-clock', () {
      final trips = [
        _tripOption(
          tripId: 'ret-13',
          departureAt: DateTime.utc(2026, 9, 16, 10),
          direction: BookingDirection.returnTrip,
        ),
        _tripOption(
          tripId: 'ret-14',
          departureAt: DateTime.utc(2026, 9, 16, 11),
          direction: BookingDirection.returnTrip,
        ),
        _tripOption(
          tripId: 'ret-15',
          departureAt: DateTime.utc(2026, 9, 16, 12),
          direction: BookingDirection.returnTrip,
        ),
        _tripOption(
          tripId: 'ret-16',
          departureAt: DateTime.utc(2026, 9, 16, 13),
          direction: BookingDirection.returnTrip,
        ),
      ];

      expect(
        trips.map(
          (trip) => AppTimeFormatter.formatTripOption(trip, locale: 'en'),
        ),
        ['1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM'],
      );
    });

    test('V. Arabic schedule uses Cairo local 12-hour wall-clock', () {
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime.utc(2026, 9, 16, 5),
          locale: 'ar',
        ),
        '8:00 ص',
      );
      expect(
        AppTimeFormatter.formatDepartureTime(
          departureAt: DateTime.utc(2026, 9, 16, 10),
          locale: 'ar',
        ),
        '1:00 م',
      );
    });

    testWidgets('W. Any server isBookable true enables Home Book button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          const HomeBookRideCard(
            points: 1500,
            hasLoadedAvailability: true,
            isBookingAvailable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Now'), findsOneWidget);
      expect(find.text('No more trips available today'), findsNothing);
    });

    testWidgets('W2. Any server isBookable true enables My Trips Book button', (
      tester,
    ) async {
      final state = PassengerTripsState(
        status: PassengerTripsStatus.loaded,
        todayTrips: [
          _todayTrip(
            tripId: 'closed',
            departureAt: DateTime.utc(2026, 9, 16, 5),
            direction: BookingDirection.outbound,
            isBookable: false,
          ),
          _todayTrip(
            tripId: 'open',
            departureAt: DateTime.utc(2026, 9, 16, 6),
            direction: BookingDirection.outbound,
          ),
        ],
      );
      final cubit = _TestPassengerTripsCubit(state);

      await tester.pumpWidget(
        _buildLocalizedApp(MyTripsPage(tripsCubit: cubit)),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byTooltip('Book a New Trip'), findsOneWidget);
      expect(state.shouldDisableBookingEntry, isFalse);

      await cubit.close();
    });

    test('A. future/bookable trip before cutoff -> can book', () {
      final trip = _todayTrip(
        tripId: 'future-open',
        departureAt: DateTime.utc(2026, 9, 16, 6),
        direction: BookingDirection.outbound,
        isBookable: true,
      );
      expect(trip.canBookTrip(), isTrue);
      expect(
        PassengerBookingAvailability.canCreateBooking(trip.bookingCloseAt),
        isTrue,
      );
    });

    test('B. bookingCloseAt passed -> cannot book', () {
      final trip = _todayTrip(
        tripId: 'passed-cutoff',
        departureAt: DateTime.utc(2026, 9, 16, 4, 15),
        direction: BookingDirection.outbound,
        isBookable: true,
      );
      expect(trip.canBookTrip(), isFalse);
      expect(
        PassengerBookingAvailability.canCreateBooking(trip.bookingCloseAt),
        isFalse,
      );
      expect(trip.isBookingClosed(), isTrue);
    });

    testWidgets('X. All server isBookable false renders Home CTA as closed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildLocalizedApp(
          const HomeBookRideCard(
            points: 1500,
            hasLoadedAvailability: true,
            isBookingAvailable: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home-book-ride-cta')), findsOneWidget);
      expect(find.text('Booking closed'), findsOneWidget);
      expect(find.text('Book Now'), findsNothing);
    });

    testWidgets(
      'X2. All server isBookable false keeps My Trips Book entry CTA disabled with booking closed tooltip',
      (tester) async {
        final state = PassengerTripsState(
          status: PassengerTripsStatus.loaded,
          todayTrips: [
            _todayTrip(
              tripId: 'closed',
              departureAt: DateTime.utc(2026, 9, 16, 5),
              direction: BookingDirection.outbound,
              isBookable: false,
            ),
          ],
        );
        final cubit = _TestPassengerTripsCubit(state);

        await tester.pumpWidget(
          _buildLocalizedApp(MyTripsPage(tripsCubit: cubit)),
        );
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Book'), findsOneWidget);
        expect(find.byTooltip('Booking closed'), findsOneWidget);
        expect(find.byTooltip('Book a New Trip'), findsNothing);
        expect(state.shouldDisableBookingEntry, isTrue);

        await cubit.close();
      },
    );

    test(
      'Y. Zero existing bookings but a bookable trip keeps booking enabled',
      () {
        final state = PassengerTripsState(
          status: PassengerTripsStatus.loaded,
          upcomingTrips: const [],
          historyTrips: const [],
          todayTrips: [
            _todayTrip(
              tripId: 'open',
              departureAt: DateTime.utc(2026, 9, 16, 5),
              direction: BookingDirection.outbound,
            ),
          ],
        );

        expect(state.upcomingTrips, isEmpty);
        expect(state.historyTrips, isEmpty);
        expect(state.hasAnyBookableTrip, isTrue);
        expect(state.shouldDisableBookingEntry, isFalse);
      },
    );

    testWidgets(
      'Z. Loading state does not render no-trips availability message',
      (tester) async {
        await tester.pumpWidget(
          _buildLocalizedApp(
            const HomeBookRideCard(
              points: 1500,
              hasLoadedAvailability: false,
              isBookingAvailable: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No more trips available today'), findsNothing);
      },
    );

    test('AA. Home and My Trips share canonical availability source', () {
      final trips = [
        _todayTrip(
          tripId: 'closed',
          departureAt: DateTime.utc(2026, 9, 16, 5),
          direction: BookingDirection.outbound,
          isBookable: false,
        ),
        _todayTrip(
          tripId: 'open',
          departureAt: DateTime.utc(2026, 9, 16, 6),
          direction: BookingDirection.outbound,
        ),
      ];
      final state = PassengerTripsState(
        status: PassengerTripsStatus.loaded,
        todayTrips: trips,
      );

      expect(PassengerBookingAvailability.hasAnyBookableTrip(trips), isTrue);
      expect(
        PassengerBookingAvailability.hasAnyBookableTrip(trips),
        state.hasAnyBookableTrip,
      );
      expect(state.shouldDisableBookingEntry, isFalse);
    });
  });
}
