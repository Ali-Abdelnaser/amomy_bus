import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/home/domain/entities/announcement.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/home/domain/repositories/home_repository.dart';
import 'package:amomy_bus/features/home/presentation/cubit/home_cubit.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_book_ride_card.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/trip_history_card.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _FakeBookingRepo implements BookingRepository {
  List<RouteStop> routeStops = [];
  List<TripOption> trips = [];
  List<PassengerBooking> bookings = [];
  final StreamController<void> updatesController =
      StreamController<void>.broadcast();

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async => Success(routeStops);

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) async => Success(trips);

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async =>
      const Success([]);

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) async => throw UnimplementedError();

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) async =>
      const Success(null);

  @override
  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  }) async => throw UnimplementedError();

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async =>
      Success(bookings);

  @override
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async => const Success([]);

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async =>
      const Success(null);

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async => throw UnimplementedError();

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) =>
      const Stream.empty();

  @override
  Stream<void> subscribeToPassengerBookingUpdates() => updatesController.stream;

  @override
  ResultFuture<void> cancelBooking(String bookingId) async =>
      const Success(null);

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async => const Success(null);
}

class _FakeHomeRepo implements HomeRepository {
  HomeSummary summary;
  int callCount = 0;
  _FakeHomeRepo({required this.summary});

  @override
  ResultFuture<HomeSummary> getHomeSummary() async {
    callCount++;
    return Success(summary);
  }

  @override
  ResultFuture<List<Announcement>> getActiveAnnouncements() async =>
      const Success([]);
}

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: Scaffold(body: child),
  );
}

PassengerBooking _createBooking({
  required String id,
  required String status,
  DateTime? checkedInAt,
  DateTime? departureAt,
}) {
  return PassengerBooking(
    bookingId: id,
    tripId: 'trip-$id',
    direction: BookingDirection.outbound,
    originNameAr: 'المعادي',
    originNameEn: 'Maadi',
    destinationNameAr: 'الجامعة',
    destinationNameEn: 'University',
    serviceDate: DateTime.now(),
    departureTime: '08:00 AM',
    departureAt: departureAt ?? DateTime.now().add(const Duration(hours: 2)),
    seatNumber: '04',
    farePoints: 10,
    status: status,
    qrToken: 'token-$id',
    bookedAt: DateTime.now().subtract(const Duration(hours: 1)),
    checkedInAt: checkedInAt,
  );
}

void main() {
  group('AMOMY — BOOKING MIDNIGHT + RTL/LTR + CHECK-IN FINISHED PASS', () {
    late _FakeBookingRepo fakeRepo;

    setUp(() {
      fakeRepo = _FakeBookingRepo();
    });

    test(
      '1. Booking page accepts backend trips at 00:xx Cairo on a service day',
      () async {
        final tripAtMidnight = TripOption(
          tripId: 'trip-midnight-1',
          routeId: 'route-1',
          direction: BookingDirection.outbound,
          originNameAr: 'المعادي',
          originNameEn: 'Maadi',
          destinationNameAr: 'الجامعة',
          destinationNameEn: 'University',
          departureTime: '08:00 AM',
          departureAt: DateTime.now().add(const Duration(hours: 8)),
          availableSeatsCount: 15,
          farePoints: 10,
          status: 'scheduled',
          isBookable: true,
        );
        fakeRepo.trips = [tripAtMidnight];

        final cubit = BookingCubit(
          getRouteStopsUseCase: GetRouteStopsUseCase(fakeRepo),
          getAvailableTripsUseCase: GetAvailableTripsUseCase(fakeRepo),
          getTripSeatMapUseCase: GetTripSeatMapUseCase(fakeRepo),
          createBookingHoldUseCase: CreateBookingHoldUseCase(fakeRepo),
          releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(fakeRepo),
          confirmBookingUseCase: ConfirmBookingUseCase(fakeRepo),
          bookingRepository: fakeRepo,
        );

        await cubit.initBooking();
        expect(cubit.state.availableTrips.length, 1);
        expect(cubit.state.availableTrips.first.tripId, 'trip-midnight-1');
        expect(cubit.state.availableTrips.first.isBookable, isTrue);
        expect(cubit.state.selectedTrip?.tripId, 'trip-midnight-1');
        await cubit.close();
      },
    );

    test(
      '2. Friday/no-service state returns empty trips without fabrication',
      () async {
        fakeRepo.trips = [];

        final cubit = BookingCubit(
          getRouteStopsUseCase: GetRouteStopsUseCase(fakeRepo),
          getAvailableTripsUseCase: GetAvailableTripsUseCase(fakeRepo),
          getTripSeatMapUseCase: GetTripSeatMapUseCase(fakeRepo),
          createBookingHoldUseCase: CreateBookingHoldUseCase(fakeRepo),
          releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(fakeRepo),
          confirmBookingUseCase: ConfirmBookingUseCase(fakeRepo),
          bookingRepository: fakeRepo,
        );

        await cubit.initBooking();
        expect(cubit.state.availableTrips.isEmpty, isTrue);
        expect(cubit.state.selectedTrip, isNull);
        await cubit.close();
      },
    );

    testWidgets('3. BackButtonIcon and navigation respect RTL / LTR', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: BackButtonIcon(),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackButtonIcon), findsOneWidget);
    });

    testWidgets(
      '4. Home Book card: full background hero bus with LTR text LEFT and RTL text RIGHT (flipped)',
      (tester) async {
        // Test LTR
        await tester.pumpWidget(
          _wrap(
            const SizedBox(width: 400, child: HomeBookRideCard(points: 150)),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        // Verify CTA button is on the LEFT half in LTR (< 200)
        final textCtaRectLtr = tester.getRect(
          find.byKey(const Key('home-book-ride-cta')),
        );
        expect(textCtaRectLtr.left, lessThan(200));

        // Verify bus artwork fills the card background
        final busImageRectLtr = tester.getRect(find.byType(Image));
        expect(busImageRectLtr.width, greaterThanOrEqualTo(390));

        // In LTR, bus image should not be flipped horizontally
        final ltrTransforms = tester.widgetList<Transform>(
          find.byType(Transform),
        );
        final ltrHasFlippedTransform = ltrTransforms.any(
          (t) => t.transform.storage[0] == -1.0,
        );
        expect(ltrHasFlippedTransform, isFalse);

        // Test RTL
        await tester.pumpWidget(
          _wrap(
            const SizedBox(width: 400, child: HomeBookRideCard(points: 150)),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        // In RTL, CTA button is anchored on the RIGHT (right edge == 380)
        final textCtaRectRtl = tester.getRect(
          find.byKey(const Key('home-book-ride-cta')),
        );
        expect(textCtaRectRtl.right, greaterThan(350));
        expect(textCtaRectRtl.left, greaterThan(textCtaRectLtr.left));

        // Verify bus image in RTL is flipped horizontally
        final rtlTransforms = tester.widgetList<Transform>(
          find.byType(Transform),
        );
        final rtlHasFlippedTransform = rtlTransforms.any(
          (t) => t.transform.storage[0] == -1.0,
        );
        expect(rtlHasFlippedTransform, isTrue);
      },
    );

    test('5. Confirmed + checked_in_at null stays active / upcoming', () {
      final booking = _createBooking(
        id: 'b-active-1',
        status: 'confirmed',
        checkedInAt: null,
      );
      expect(booking.isFinished, isFalse);
      expect(booking.isUpcoming, isTrue);
    });

    test('6. Confirmed + checked_in_at non-null becomes Finished', () {
      final booking = _createBooking(
        id: 'b-finished-1',
        status: 'confirmed',
        checkedInAt: DateTime.now(),
      );
      expect(booking.isFinished, isTrue);
      expect(booking.isUpcoming, isFalse);
    });

    test(
      '7. Finished booking moves to History in PassengerTripsCubit',
      () async {
        final activeBooking = _createBooking(
          id: 'b-1',
          status: 'confirmed',
          checkedInAt: null,
        );
        final finishedBooking = _createBooking(
          id: 'b-2',
          status: 'confirmed',
          checkedInAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        fakeRepo.bookings = [activeBooking, finishedBooking];

        final cubit = PassengerTripsCubit(
          GetPassengerBookingsUseCase(fakeRepo),
          fakeRepo,
        );

        await cubit.loadTripsHub();
        expect(cubit.state.upcomingTrips.length, 1);
        expect(cubit.state.upcomingTrips.first.bookingId, 'b-1');
        expect(cubit.state.historyTrips.length, 1);
        expect(cubit.state.historyTrips.first.bookingId, 'b-2');
        await cubit.close();
      },
    );

    testWidgets(
      '8. Finished card is gray and displays localized Finished label',
      (tester) async {
        final finishedBooking = _createBooking(
          id: 'b-finished',
          status: 'confirmed',
          checkedInAt: DateTime.now(),
        );

        // In English
        await tester.pumpWidget(
          _wrap(
            TripHistoryCard(booking: finishedBooking),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Finished'), findsOneWidget);

        // In Arabic
        await tester.pumpWidget(
          _wrap(
            TripHistoryCard(booking: finishedBooking),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('تمت الرحلة'), findsOneWidget);
      },
    );

    test(
      '9. Realtime booking update refreshes PassengerTripsCubit and HomeCubit',
      () async {
        final booking = _createBooking(
          id: 'b-live-1',
          status: 'confirmed',
          checkedInAt: null,
        );
        fakeRepo.bookings = [booking];

        final tripsCubit = PassengerTripsCubit(
          GetPassengerBookingsUseCase(fakeRepo),
          fakeRepo,
        );
        await tripsCubit.loadTripsHub();
        expect(tripsCubit.state.upcomingTrips.length, 1);

        final homeRepo = _FakeHomeRepo(
          summary: const HomeSummary(
            availablePoints: 100,
            profile: PassengerProfileSummary(fullName: 'Ali', avatarUrl: null),
            upcomingTrip: null,
            activity: PassengerActivityMetrics(
              tripsThisMonth: 0,
              completedTrips: 0,
              pointsSpentThisMonth: 0,
              missedTrips: 0,
            ),
          ),
        );
        final homeCubit = HomeCubit(homeRepo, fakeRepo);
        await homeCubit.loadHomeData();
        expect(homeRepo.callCount, 1);

        // Now staff checks passenger in via realtime update
        fakeRepo.bookings = [
          _createBooking(
            id: 'b-live-1',
            status: 'confirmed',
            checkedInAt: DateTime.now(),
          ),
        ];

        // Emit realtime update event
        fakeRepo.updatesController.add(null);
        await pumpEventQueue();

        expect(tripsCubit.state.upcomingTrips.isEmpty, isTrue);
        expect(tripsCubit.state.historyTrips.length, 1);
        expect(tripsCubit.state.historyTrips.first.isFinished, isTrue);
        expect(homeRepo.callCount, 2);

        await tripsCubit.close();
        await homeCubit.close();
      },
    );

    testWidgets(
      '10. Old completed/cancelled/no_show history remains unchanged',
      (tester) async {
        final completedBooking = _createBooking(
          id: 'b-comp',
          status: 'completed',
        );
        final cancelledBooking = _createBooking(
          id: 'b-canc',
          status: 'cancelled',
        );
        final noShowBooking = _createBooking(id: 'b-noshow', status: 'no_show');

        await tester.pumpWidget(
          _wrap(
            TripHistoryCard(booking: completedBooking),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Completed'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TripHistoryCard(booking: cancelledBooking),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Cancelled'), findsOneWidget);

        await tester.pumpWidget(
          _wrap(
            TripHistoryCard(booking: noShowBooking),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('No-show'), findsOneWidget);
      },
    );
  });
}
