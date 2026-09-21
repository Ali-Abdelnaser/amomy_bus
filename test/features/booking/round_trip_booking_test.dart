import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:amomy_bus/core/error/failures.dart';
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
<<<<<<< HEAD
import 'package:amomy_bus/features/booking/presentation/cubit/booking_state.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_mode_toggle.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/professional_bus_seat_map.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_visual.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/return_meeting_info_card.dart';
=======
import 'package:amomy_bus/features/booking/presentation/widgets/booking_mode_toggle.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
import 'package:amomy_bus/features/booking/presentation/widgets/round_trip_return_time_selector.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/booked_trip_overflow_menu.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/add_extra_seat_modal.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockRoundTripBookingRepository implements BookingRepository {
  List<RouteStop> routeStops = [];
  List<TripOption> trips = [];
<<<<<<< HEAD
  List<TripOption> returnTrips = [];
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
  List<TripSeat> seats = [];
  List<TripSeat> returnTripSeats = [];
  List<RoundTripReturnOption> returnOptions = [];
  BookingHold? singleHold;
  RoundTripBundleHold? bundleHold;
<<<<<<< HEAD
  RoundTripBundleHold? returnSeatHold;
  RoundTripConfirmation? bundleConfirmation;
  PassengerBooking? singleConfirmation;
  RoundTripBundleContext? bundleContext;
  Failure? returnOptionsFailure;
  Failure? bundleHoldFailure;
=======
  RoundTripConfirmation? bundleConfirmation;
  PassengerBooking? singleConfirmation;
  RoundTripBundleContext? bundleContext;
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad

  int getReturnOptionsCallCount = 0;
  int createBundleHoldCallCount = 0;
  int setReturnSeatCallCount = 0;
  int releaseBundleHoldCallCount = 0;
  int confirmBundleCallCount = 0;
  int confirmSingleBookingCallCount = 0;
  int cancelBookingCallCount = 0;
  int getBundleContextCallCount = 0;

  String? lastOutboundTripId;
  String? lastOutboundRouteStopId;
  String? lastReturnTripId;
  String? lastOutboundSeatId;
  String? lastReturnSeatId;
  String? lastCancelledBookingId;

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async => Success(routeStops);

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
<<<<<<< HEAD
  }) async {
    if (direction == BookingDirection.returnTrip) {
      if (returnTrips.isNotEmpty) return Success(returnTrips);
      return Success(
        trips.where((t) => t.direction == BookingDirection.returnTrip).toList(),
      );
    }
    return Success(trips);
  }
=======
  }) async => Success(trips);
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async {
    if (tripId.contains('return')) {
      return Success(returnTripSeats);
    }
    return Success(seats);
  }

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) async {
    return Success(
      singleHold ??
          BookingHold(
            holdId: 'single-hold-1',
            tripId: tripId,
            seatId: seatId,
            seatNumber: '1',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
            farePoints: 25.0,
          ),
    );
  }

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) async =>
      const Success(null);

  @override
  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  }) async {
    confirmSingleBookingCallCount++;
    return Success(
      singleConfirmation ??
          PassengerBooking(
            bookingId: 'single-bkg-1',
            tripId: 'trip-out',
            direction: BookingDirection.outbound,
            originNameAr: 'ميت العامل',
            originNameEn: 'Mit El Amel',
            destinationNameAr: 'المنصورة',
            destinationNameEn: 'Mansoura',
            serviceDate: DateTime.now(),
            departureTime: '08:00',
            departureAt: DateTime.now(),
            seatNumber: '1',
            farePoints: 25.0,
            status: 'confirmed',
            qrToken: 'qr-single',
            bookedAt: DateTime.now(),
          ),
    );
  }

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async =>
      const Success([]);

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
  Stream<void> subscribeToPassengerBookingUpdates() => const Stream.empty();

  @override
  ResultFuture<void> cancelBooking(String bookingId) async {
    cancelBookingCallCount++;
    lastCancelledBookingId = bookingId;
    return const Success(null);
  }

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async => const Success(null);

  @override
  ResultFuture<List<RoundTripReturnOption>> getRoundTripReturnOptions({
    required String outboundTripId,
    required String outboundRouteStopId,
  }) async {
    getReturnOptionsCallCount++;
    lastOutboundTripId = outboundTripId;
    lastOutboundRouteStopId = outboundRouteStopId;
<<<<<<< HEAD
    if (returnOptionsFailure != null) {
      return Error(returnOptionsFailure!);
    }
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    return Success(returnOptions);
  }

  @override
  ResultFuture<RoundTripBundleHold> createRoundTripBundleHold({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  }) async {
    createBundleHoldCallCount++;
    lastOutboundTripId = outboundTripId;
    lastReturnTripId = returnTripId;
    lastOutboundSeatId = outboundSeatId;
    lastOutboundRouteStopId = outboundRouteStopId;

<<<<<<< HEAD
    if (bundleHoldFailure != null) {
      return Error(bundleHoldFailure!);
    }

=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    return Success(
      bundleHold ??
          RoundTripBundleHold(
            bundleHoldId: 'bundle-hold-1',
            outboundHoldId: 'hold-out-1',
            outboundTripId: outboundTripId,
            returnTripId: returnTripId,
            outboundSeatId: outboundSeatId,
            outboundSeatNumber: '1',
            outboundRouteStopId: outboundRouteStopId,
            returnRouteStopId: 'stop-return-1',
            outboundBaseFarePoints: 25,
            returnBaseFarePoints: 25,
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPoints: 43,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          ),
    );
  }

  @override
  ResultFuture<RoundTripBundleHold> setRoundTripReturnSeat({
    required String bundleHoldId,
    required String returnSeatId,
  }) async {
    setReturnSeatCallCount++;
    lastReturnSeatId = returnSeatId;

<<<<<<< HEAD
    if (returnSeatHold != null) {
      return Success(returnSeatHold!);
    }

=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    return Success(
      RoundTripBundleHold(
        bundleHoldId: bundleHoldId,
        outboundHoldId: 'hold-out-1',
        returnRouteStopId: 'stop-return-1',
        outboundTripId: lastOutboundTripId ?? 'trip-out',
        returnTripId: lastReturnTripId ?? 'trip-ret',
        outboundSeatId: lastOutboundSeatId ?? 'seat-1',
        returnSeatId: returnSeatId,
        outboundSeatNumber: '1',
        returnSeatNumber: '2',
        outboundRouteStopId: lastOutboundRouteStopId ?? 'stop-out-1',
        outboundBaseFarePoints: 25,
        returnBaseFarePoints: 25,
        subtotalPoints: 50,
        discountPercent: 15,
        discountPoints: 7,
        totalPoints: 43,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        serverTime: DateTime.now(),
      ),
    );
  }

  @override
  ResultFuture<void> releaseRoundTripBundleHold({
    required String bundleHoldId,
  }) async {
    releaseBundleHoldCallCount++;
    return const Success(null);
  }

  @override
  ResultFuture<RoundTripConfirmation> confirmRoundTripBundle({
    required String bundleHoldId,
  }) async {
    confirmBundleCallCount++;
    return Success(
      bundleConfirmation ??
          RoundTripConfirmation(
            bundleId: 'bundle-uuid-1',
            outboundBookingId: 'bkg-out-1',
            returnBookingId: 'bkg-ret-1',
            outboundTripId: 'trip-out-1',
            returnTripId: 'trip-ret-1',
            outboundSeatNumber: '1',
            returnSeatNumber: '2',
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPaidPoints: 43,
            status: 'confirmed',
          ),
    );
  }

  @override
  ResultFuture<RoundTripBundleContext> getRoundTripBundleContext({
    required String bookingId,
  }) async {
    getBundleContextCallCount++;
    return Success(
      bundleContext ??
          const RoundTripBundleContext(
            isRoundTripBundle: false,
            cancellationEligible: true,
          ),
    );
  }
}

Widget testApp(Widget child, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  late MockRoundTripBookingRepository repo;
  late BookingCubit cubit;

  const sampleOutboundStop = RouteStop(
    routeStopId: 'stop-out-1',
    stopId: 'home-stop-1',
    stopOrder: 1,
    stopNameAr: 'ميت العامل',
    stopNameEn: 'Mit El Amel',
    localityAr: 'ميت العامل',
    localityEn: 'Mit El Amel',
    fareZoneId: 'zone-25',
    farePoints: 25.0,
  );

  final sampleOutboundTrip = TripOption(
    tripId: 'trip-out-1',
    routeId: 'route-out',
    direction: BookingDirection.outbound,
    originNameAr: 'ميت العامل',
    originNameEn: 'Mit El Amel',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(hours: 2)),
    availableSeatsCount: 15,
    farePoints: 25.0,
    status: 'scheduled',
  );

  final sampleReturnOption1 = RoundTripReturnOption(
    returnTripId: 'trip-return-1',
    departureTime: '14:00',
    departureAt: DateTime(2026, 9, 20, 14, 0),
    availableSeats: 10,
    outboundBaseFarePoints: 25,
    returnBaseFarePoints: 25,
    subtotalPoints: 50,
    discountPercent: 15,
    discountPoints: 7,
    totalPoints: 43,
    isBookable: true,
  );

  final sampleReturnOptionNonBookable = RoundTripReturnOption(
    returnTripId: 'trip-return-full',
    departureTime: '15:00',
    departureAt: DateTime(2026, 9, 20, 15, 0),
    availableSeats: 0,
    outboundBaseFarePoints: 25,
    returnBaseFarePoints: 25,
    subtotalPoints: 50,
    discountPercent: 15,
    discountPoints: 7,
    totalPoints: 43,
    isBookable: false,
  );

  final sampleSeat1 = const TripSeat(
    seatId: 'seat-1',
    seatNumber: '1',
    rowIndex: 1,
    columnIndex: 1,
    seatType: 'standard',
    status: SeatAvailabilityStatus.available,
    isMine: false,
  );

  final sampleSeat2 = const TripSeat(
    seatId: 'seat-2',
    seatNumber: '2',
    rowIndex: 1,
    columnIndex: 2,
    seatType: 'standard',
    status: SeatAvailabilityStatus.available,
    isMine: false,
  );

  setUp(() {
    repo = MockRoundTripBookingRepository();
    repo.routeStops = [sampleOutboundStop];
    repo.trips = [sampleOutboundTrip];
    repo.seats = [sampleSeat1, sampleSeat2];
    repo.returnTripSeats = [sampleSeat1, sampleSeat2];
    repo.returnOptions = [sampleReturnOption1, sampleReturnOptionNonBookable];

    cubit = BookingCubit(
      getRouteStopsUseCase: GetRouteStopsUseCase(repo),
      getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
      getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
      createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
      releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
      confirmBookingUseCase: ConfirmBookingUseCase(repo),
      getRoundTripReturnOptionsUseCase: GetRoundTripReturnOptionsUseCase(repo),
      createRoundTripBundleHoldUseCase: CreateRoundTripBundleHoldUseCase(repo),
      setRoundTripReturnSeatUseCase: SetRoundTripReturnSeatUseCase(repo),
      releaseRoundTripBundleHoldUseCase: ReleaseRoundTripBundleHoldUseCase(
        repo,
      ),
      confirmRoundTripBundleUseCase: ConfirmRoundTripBundleUseCase(repo),
      bookingRepository: repo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PHASE RT2 — ROUND TRIP BOOKING SPECIFICATION TESTS', () {
    // 1. round trip appears only for outbound
    testWidgets('1. Round trip toggle appears only for outbound direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          BookingModeToggle(mode: BookingMode.single, onModeChanged: (_) {}),
        ),
      );
      expect(find.text('ذهاب وعودة'), findsOneWidget);
      expect(find.text('خصم 15%'), findsOneWidget);
    });

    // 2. 15% badge displayed
    testWidgets('2. 15% discount badge is displayed in toggle', (tester) async {
      await tester.pumpWidget(
        testApp(
          BookingModeToggle(mode: BookingMode.roundTrip, onModeChanged: (_) {}),
        ),
      );
      expect(find.text('خصم 15%'), findsOneWidget);
    });

    // 3. single mode unchanged
    test('3. Single booking mode works normally without bundle state', () {
      expect(cubit.state.bookingMode, equals(BookingMode.single));
      expect(cubit.state.bundleHold, isNull);
      expect(cubit.state.returnOptions, isEmpty);
    });

    // 4. return times loaded from backend RPC
    test(
      '4. Return times are loaded from backend get_round_trip_return_options RPC',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
<<<<<<< HEAD
        await cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        await cubit.loadRoundTripReturnOptions();

        expect(repo.getReturnOptionsCallCount, greaterThanOrEqualTo(1));
=======
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        await cubit.loadRoundTripReturnOptions();

        expect(repo.getReturnOptionsCallCount, equals(1));
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
        expect(repo.lastOutboundTripId, equals(sampleOutboundTrip.tripId));
        expect(
          repo.lastOutboundRouteStopId,
          equals(sampleOutboundStop.routeStopId),
        );
        expect(cubit.state.returnOptions.length, equals(2));
        expect(cubit.state.selectedReturnOption, equals(sampleReturnOption1));
      },
    );

    // 5. non-bookable return option disabled
    testWidgets('5. Non-bookable return option is disabled in UI', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          RoundTripReturnTimeSelector(
            returnOptions: [sampleReturnOption1, sampleReturnOptionNonBookable],
            selectedReturnOption: sampleReturnOption1,
            onOptionSelected: (_) {},
          ),
        ),
      );

      expect(find.text('2:00 م'), findsOneWidget);
      expect(find.text('3:00 م'), findsOneWidget);
      expect(find.textContaining('غير متاح'), findsOneWidget);
    });

    // 6. 25 + 25 response displays 50 - 7 = 43
    testWidgets(
      '6. 25 + 25 breakdown displays subtotal 50, discount 7, total 43 exactly',
      (tester) async {
        final bundleHold25 = RoundTripBundleHold(
          bundleHoldId: 'bundle-25',
          outboundHoldId: 'h-out',
          outboundTripId: 'trip-out',
          returnTripId: 'trip-ret',
          outboundSeatId: 'seat-1',
          returnSeatId: 'seat-2',
          outboundSeatNumber: '1',
          returnSeatNumber: '2',
          outboundRouteStopId: 'stop-1',
          outboundBaseFarePoints: 25,
          returnBaseFarePoints: 25,
          subtotalPoints: 50,
          discountPercent: 15,
          discountPoints: 7,
          totalPoints: 43,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(
          testApp(
            BookingReviewCard(
              trip: sampleOutboundTrip,
              seat: sampleSeat1,
              routeStop: sampleOutboundStop,
              returnSeat: sampleSeat2,
              returnOption: sampleReturnOption1,
              userAvailablePoints: 100,
              bundleHold: bundleHold25,
              onConfirm: () {},
            ),
          ),
        );

        expect(find.text('50 نقطة'), findsOneWidget);
        expect(find.text('-7 نقطة'), findsOneWidget);
        expect(find.text('43 نقطة'), findsOneWidget);
      },
    );

    // 7. 30 + 30 displays 60 - 9 = 51
    testWidgets(
      '7. 30 + 30 breakdown displays subtotal 60, discount 9, total 51 exactly',
      (tester) async {
        final bundleHold30 = RoundTripBundleHold(
          bundleHoldId: 'bundle-30',
          outboundHoldId: 'h-out',
          outboundTripId: 'trip-out',
          returnTripId: 'trip-ret',
          outboundSeatId: 'seat-1',
          returnSeatId: 'seat-2',
          outboundSeatNumber: '5',
          returnSeatNumber: '6',
          outboundRouteStopId: 'stop-1',
          outboundBaseFarePoints: 30,
          returnBaseFarePoints: 30,
          subtotalPoints: 60,
          discountPercent: 15,
          discountPoints: 9,
          totalPoints: 51,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(
          testApp(
            BookingReviewCard(
              trip: sampleOutboundTrip,
              seat: sampleSeat1,
              routeStop: sampleOutboundStop,
              returnSeat: sampleSeat2,
              returnOption: sampleReturnOption1,
              userAvailablePoints: 100,
              bundleHold: bundleHold30,
              onConfirm: () {},
            ),
          ),
        );

        expect(find.text('60 نقطة'), findsOneWidget);
        expect(find.text('-9 نقطة'), findsOneWidget);
        expect(find.text('51 نقطة'), findsOneWidget);
      },
    );

    // 8. outbound seat uses bundle hold RPC
    test(
      '8. Outbound seat selection uses create_round_trip_bundle_hold RPC',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
<<<<<<< HEAD
        await cubit.selectOriginStop(sampleOutboundStop);
=======
        cubit.selectOriginStop(sampleOutboundStop);
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
        cubit.selectTrip(sampleOutboundTrip);
        cubit.selectReturnOption(sampleReturnOption1);

        await cubit.selectSeatAndHold(sampleSeat1);

        expect(repo.createBundleHoldCallCount, equals(1));
        expect(repo.lastOutboundTripId, equals(sampleOutboundTrip.tripId));
        expect(repo.lastReturnTripId, equals(sampleReturnOption1.returnTripId));
        expect(repo.lastOutboundSeatId, equals(sampleSeat1.seatId));
        expect(cubit.state.bundleHold, isNotNull);

        cubit.proceedToReturnSeatMap();
        expect(
          cubit.state.roundTripSeatStep,
          equals(RoundTripSeatStep.returnSeat),
        );
      },
    );

    // 9. return seat uses set_round_trip_return_seat
    test(
      '9. Return seat selection uses set_round_trip_return_seat RPC',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        cubit.selectReturnOption(sampleReturnOption1);
        await cubit.selectSeatAndHold(sampleSeat1);
        cubit.proceedToReturnSeatMap();

        // Now on return seat step
        await cubit.selectSeatAndHold(sampleSeat2);

        expect(repo.setReturnSeatCallCount, equals(1));
        expect(repo.lastReturnSeatId, equals(sampleSeat2.seatId));
        expect(
          cubit.state.bundleHold?.returnSeatId,
          equals(sampleSeat2.seatId),
        );
      },
    );

    // 10. one hold timer shared across both seats
    test(
      '10. One shared hold timer persists from outbound hold to review',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        cubit.selectReturnOption(sampleReturnOption1);

        await cubit.selectSeatAndHold(sampleSeat1);
        expect(cubit.state.holdSecondsRemaining, inInclusiveRange(295, 300));

        cubit.proceedToReturnSeatMap();
        await cubit.selectSeatAndHold(sampleSeat2);
        // Timer continues without resetting to fresh 300
        expect(cubit.state.holdSecondsRemaining, isNotNull);
      },
    );

    // 11. review displays both trips
    // 12. review displays both seats
    testWidgets(
      '11 & 12. Review card displays both outbound and return trips with both seats',
      (tester) async {
        final bundleHold = RoundTripBundleHold(
          bundleHoldId: 'bundle-1',
          outboundHoldId: 'h-out',
          outboundTripId: 'trip-out',
          returnTripId: 'trip-ret',
          outboundSeatId: 'seat-1',
          returnSeatId: 'seat-2',
          outboundSeatNumber: '1',
          returnSeatNumber: '2',
          outboundRouteStopId: 'stop-1',
          outboundBaseFarePoints: 25,
          returnBaseFarePoints: 25,
          subtotalPoints: 50,
          discountPercent: 15,
          discountPoints: 7,
          totalPoints: 43,
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          serverTime: DateTime.now(),
        );

        await tester.pumpWidget(
          testApp(
            BookingReviewCard(
              trip: sampleOutboundTrip,
              seat: sampleSeat1,
              routeStop: sampleOutboundStop,
              returnSeat: sampleSeat2,
              returnOption: sampleReturnOption1,
              userAvailablePoints: 100,
              bundleHold: bundleHold,
              onConfirm: () {},
            ),
          ),
        );

        expect(find.text('ذهاب'), findsWidgets);
        expect(find.text('عودة'), findsWidgets);
        expect(find.text('1'), findsWidgets);
        expect(find.text('2'), findsWidgets);
      },
    );

    // 13. confirm sends exactly ONE confirm_round_trip_bundle call
    // 14. no confirm_booking calls in round-trip confirmation
    test(
      '13 & 14. Confirm sends exactly ONE confirm_round_trip_bundle and 0 confirm_booking calls',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        cubit.selectReturnOption(sampleReturnOption1);
        await cubit.selectSeatAndHold(sampleSeat1);
        cubit.proceedToReturnSeatMap();
        await cubit.selectSeatAndHold(sampleSeat2);

        await cubit.confirmBooking();

        expect(repo.confirmBundleCallCount, equals(1));
        expect(repo.confirmSingleBookingCallCount, equals(0));
        expect(cubit.state.confirmedBundle, isNotNull);
      },
    );

    // 15. success contains two bookings
    testWidgets(
      '15. Success screen displays two confirmed bookings and saved points',
      (tester) async {
        final confirmation = RoundTripConfirmation(
          bundleId: 'bundle-uuid',
          outboundBookingId: 'bkg-1',
          returnBookingId: 'bkg-2',
          outboundTripId: 'trip-out',
          returnTripId: 'trip-ret',
          outboundSeatNumber: '1',
          returnSeatNumber: '2',
          subtotalPoints: 50,
          discountPercent: 15,
          discountPoints: 7,
          totalPaidPoints: 43,
          status: 'confirmed',
        );

        await tester.pumpWidget(
          testApp(BookingSuccessView(bundleConfirmation: confirmation)),
        );

        expect(find.text('تم حجز الذهاب والعودة بنجاح'), findsOneWidget);
        expect(find.textContaining('7'), findsWidgets);
        expect(find.text('ذهاب'), findsWidgets);
        expect(find.text('عودة'), findsWidgets);
      },
    );

    // 16. abandoning flow releases bundle hold
    test(
      '16. Abandoning or resetting round-trip flow releases bundle hold',
      () async {
        cubit.setBookingMode(BookingMode.roundTrip);
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        cubit.selectReturnOption(sampleReturnOption1);
        await cubit.selectSeatAndHold(sampleSeat1);

        expect(cubit.state.bundleHold, isNotNull);

        // Switch mode back to single
        cubit.setBookingMode(BookingMode.single);
        expect(repo.releaseBundleHoldCallCount, equals(1));
        expect(cubit.state.bundleHold, isNull);
      },
    );

    // 17. bundled cancel warns both trips will cancel
    // 18. bundled cancellation never offers single-leg cancel
    testWidgets(
      '17 & 18. Bundled cancel warns both legs cancel and cancels atomically',
      (tester) async {
        repo.bundleContext = const RoundTripBundleContext(
          isRoundTripBundle: true,
          bundleId: 'bundle-1',
          outboundBookingId: 'bkg-1',
          returnBookingId: 'bkg-2',
          totalPaidPoints: 43,
          discountPoints: 7,
          cancellationEligible: true,
        );

        final tripsCubit = PassengerTripsCubit(null, repo);

        final bookedTrip = PassengerTodayTrip(
          tripId: 'trip-out',
          routeId: 'route-1',
          direction: BookingDirection.outbound,
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          departureAt: DateTime.now().add(const Duration(hours: 3)),
          bookingCloseAt: DateTime.now().add(const Duration(hours: 2)),
          originNameAr: 'ميت العامل',
          originNameEn: 'Mit El Amel',
          destinationNameAr: 'المنصورة',
          destinationNameEn: 'Mansoura',
          seatNumber: '1',
          farePoints: 25.0,
          totalSeats: 28,
          availableSeats: 20,
          status: 'confirmed',
          alreadyBooked: true,
          bookingId: 'bkg-1',
          qrToken: 'qr-token',
          availabilityStatus: TodayTripAvailabilityStatus.available,
          isBookable: false,
        );

        await tester.pumpWidget(
          testApp(
            BlocProvider<PassengerTripsCubit>.value(
              value: tripsCubit,
              child: BookedTripOverflowMenu(trip: bookedTrip),
            ),
          ),
        );

        // Open bottom sheet
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();

        // Tap Cancel Booking tile
        await tester.tap(find.text('إلغاء الحجز'));
        await tester.pumpAndSettle();

        // Dialog should clearly state round-trip bundle cancellation warning
        expect(find.text('إلغاء حجز الذهاب والعودة'), findsOneWidget);
        expect(
          find.textContaining('هذا الحجز جزء من حجز ذهاب وعودة بخصم 15%'),
          findsOneWidget,
        );
        expect(find.text('إلغاء الرحلتين معًا'), findsOneWidget);

        // Confirm cancellation
        await tester.tap(find.text('إلغاء الرحلتين معًا'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));

        expect(repo.cancelBookingCallCount, equals(1));
        expect(repo.lastCancelledBookingId, equals('bkg-1'));

        tripsCubit.close();
      },
    );

    // 19. normal booking cancellation remains unchanged
    testWidgets('19. Normal single trip cancellation remains unchanged', (
      tester,
    ) async {
      repo.bundleContext = const RoundTripBundleContext(
        isRoundTripBundle: false,
        cancellationEligible: true,
      );

      final tripsCubit = PassengerTripsCubit(null, repo);

      final bookedTrip = PassengerTodayTrip(
        tripId: 'trip-single',
        routeId: 'route-1',
        direction: BookingDirection.outbound,
        serviceDate: DateTime.now(),
        departureTime: '08:00',
        departureAt: DateTime.now().add(const Duration(hours: 3)),
        bookingCloseAt: DateTime.now().add(const Duration(hours: 2)),
        originNameAr: 'ميت العامل',
        originNameEn: 'Mit El Amel',
        destinationNameAr: 'المنصورة',
        destinationNameEn: 'Mansoura',
        seatNumber: '3',
        farePoints: 25.0,
        totalSeats: 28,
        availableSeats: 20,
        status: 'confirmed',
        alreadyBooked: true,
        bookingId: 'bkg-single-1',
        qrToken: 'qr-token',
        availabilityStatus: TodayTripAvailabilityStatus.available,
        isBookable: false,
      );

      await tester.pumpWidget(
        testApp(
          BlocProvider<PassengerTripsCubit>.value(
            value: tripsCubit,
            child: BookedTripOverflowMenu(trip: bookedTrip),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('إلغاء الحجز'));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد إلغاء الحجز'), findsOneWidget);
      expect(find.text('الاحتفاظ بالحجز'), findsOneWidget);

      await tester.tap(find.text('إلغاء الحجز'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));

      expect(repo.cancelBookingCallCount, equals(1));
      expect(repo.lastCancelledBookingId, equals('bkg-single-1'));

      tripsCubit.close();
    });

    // 20. extra-seat UI does not apply bundle discount
    testWidgets(
      '20. Extra-seat modal charges full base fare (no bundle discount)',
      (tester) async {
        final tripsCubit = PassengerTripsCubit(null, repo);

        final bookedTrip = PassengerTodayTrip(
          tripId: 'trip-extra',
          routeId: 'route-1',
          direction: BookingDirection.outbound,
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          departureAt: DateTime.now().add(const Duration(hours: 3)),
          bookingCloseAt: DateTime.now().add(const Duration(hours: 2)),
          originNameAr: 'ميت العامل',
          originNameEn: 'Mit El Amel',
          destinationNameAr: 'المنصورة',
          destinationNameEn: 'Mansoura',
          seatNumber: '1',
          farePoints: 25.0,
          totalSeats: 28,
          availableSeats: 20,
          status: 'confirmed',
          alreadyBooked: true,
          bookingId: 'bkg-extra',
          qrToken: 'qr-token',
          availabilityStatus: TodayTripAvailabilityStatus.available,
          isBookable: false,
        );

        await tester.pumpWidget(
          testApp(AddExtraSeatModal(trip: bookedTrip, tripsCubit: tripsCubit)),
        );

        // Base fare 25 points is shown, not discounted 21/22 points
        expect(find.textContaining('25'), findsWidgets);

        tripsCubit.close();
      },
    );
  });
<<<<<<< HEAD

  group('PHASE RT2.1 — ROUND TRIP RETURN OPTIONS & MEETING POINT FIX TESTS', () {
    final sampleOutbound0800 = TripOption(
      tripId: 'trip-out-08',
      routeId: 'route-out',
      direction: BookingDirection.outbound,
      originNameAr: 'ميت العامل',
      originNameEn: 'Mit El Amel',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      departureTime: '08:00',
      departureAt: DateTime(2026, 9, 21, 8, 0),
      farePoints: 25,
      availableSeatsCount: 20,
      status: 'scheduled',
      isBookable: true,
    );

    final sampleOutbound0900 = TripOption(
      tripId: 'trip-out-09',
      routeId: 'route-out',
      direction: BookingDirection.outbound,
      originNameAr: 'ميت العامل',
      originNameEn: 'Mit El Amel',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      departureTime: '09:00',
      departureAt: DateTime(2026, 9, 21, 9, 0),
      farePoints: 25,
      availableSeatsCount: 20,
      status: 'scheduled',
      isBookable: true,
    );

    final sampleOutbound1000 = TripOption(
      tripId: 'trip-out-10',
      routeId: 'route-out',
      direction: BookingDirection.outbound,
      originNameAr: 'ميت العامل',
      originNameEn: 'Mit El Amel',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      departureTime: '10:00',
      departureAt: DateTime(2026, 9, 21, 10, 0),
      farePoints: 25,
      availableSeatsCount: 20,
      status: 'scheduled',
      isBookable: true,
    );

    final sampleReturn1600 = RoundTripReturnOption(
      returnTripId: 'trip-ret-16',
      departureTime: '16:00',
      departureAt: DateTime(2026, 9, 21, 16, 0),
      availableSeats: 15,
      outboundBaseFarePoints: 25,
      returnBaseFarePoints: 25,
      subtotalPoints: 50,
      discountPercent: 15,
      discountPoints: 7,
      totalPoints: 43,
      isBookable: true,
    );

    final sampleReturn1700 = RoundTripReturnOption(
      returnTripId: 'trip-ret-17',
      departureTime: '17:00',
      departureAt: DateTime(2026, 9, 21, 17, 0),
      availableSeats: 12,
      outboundBaseFarePoints: 25,
      returnBaseFarePoints: 25,
      subtotalPoints: 50,
      discountPercent: 15,
      discountPoints: 7,
      totalPoints: 43,
      isBookable: true,
    );

    // 1. Backend returns 16:00 + 17:00 bookable → both are rendered in UI
    testWidgets(
      '1. Backend returns 16:00 + 17:00 bookable -> both rendered in UI',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            RoundTripReturnTimeSelector(
              returnOptions: [sampleReturn1600, sampleReturn1700],
              selectedReturnOption: sampleReturn1600,
              onOptionSelected: (_) {},
            ),
          ),
        );

        expect(find.text('4:00 م'), findsOneWidget);
        expect(find.text('5:00 م'), findsOneWidget);
        expect(find.text('مكان التجمع'), findsOneWidget);
        expect(find.text('أمام بوابة توشكى – حي الجامعة'), findsOneWidget);
      },
    );

    // 2. Outbound 08:00 → 16:00 and 17:00 visible
    test('2. Outbound 08:00 loads 16:00 and 17:00 return options', () async {
      repo.returnOptions = [sampleReturn1600, sampleReturn1700];
      cubit.setBookingMode(BookingMode.roundTrip);
      await cubit.selectOriginStop(sampleOutboundStop);
      cubit.selectTrip(sampleOutbound0800);
      await cubit.loadRoundTripReturnOptions();

      expect(cubit.state.returnOptions.length, equals(2));
      expect(
        cubit.state.returnOptions.any((o) => o.departureTime == '16:00'),
        isTrue,
      );
      expect(
        cubit.state.returnOptions.any((o) => o.departureTime == '17:00'),
        isTrue,
      );
      expect(cubit.state.selectedReturnOption, equals(sampleReturn1600));
    });

    // 3. Outbound 09:00 → 16:00 and 17:00 visible
    test('3. Outbound 09:00 loads 16:00 and 17:00 return options', () async {
      repo.returnOptions = [sampleReturn1600, sampleReturn1700];
      cubit.setBookingMode(BookingMode.roundTrip);
      await cubit.selectOriginStop(sampleOutboundStop);
      cubit.selectTrip(sampleOutbound0900);
      await cubit.loadRoundTripReturnOptions();

      expect(cubit.state.returnOptions.length, equals(2));
      expect(cubit.state.returnOptions[0].departureTime, equals('16:00'));
      expect(cubit.state.returnOptions[1].departureTime, equals('17:00'));
    });

    // 4. Outbound 10:00 → 16:00 and 17:00 visible
    test('4. Outbound 10:00 loads 16:00 and 17:00 return options', () async {
      repo.returnOptions = [sampleReturn1600, sampleReturn1700];
      cubit.setBookingMode(BookingMode.roundTrip);
      await cubit.selectOriginStop(sampleOutboundStop);
      cubit.selectTrip(sampleOutbound1000);
      await cubit.loadRoundTripReturnOptions();

      expect(cubit.state.returnOptions.length, equals(2));
      expect(cubit.state.returnOptions[0].departureTime, equals('16:00'));
      expect(cubit.state.returnOptions[1].departureTime, equals('17:00'));
    });

    // 5. Loading state does not show empty message
    testWidgets(
      '5. Loading state shows skeleton and does not show empty message',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            RoundTripReturnTimeSelector(
              returnOptions: const [],
              selectedReturnOption: null,
              isLoading: true,
              onOptionSelected: (_) {},
            ),
          ),
        );

        expect(
          find.text('لا توجد رحلات عودة متاحة بعد موعد الذهاب المختار.'),
          findsNothing,
        );
      },
    );

    // 6. Successful empty response shows empty state
    testWidgets('6. Successful empty response shows true empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          RoundTripReturnTimeSelector(
            returnOptions: const [],
            selectedReturnOption: null,
            isLoading: false,
            onOptionSelected: (_) {},
          ),
        ),
      );

      expect(
        find.text('لا توجد رحلات عودة متاحة بعد موعد الذهاب المختار.'),
        findsOneWidget,
      );
    });

    // 7. RPC error shows retry/error, not fake empty state
    testWidgets('7. RPC error shows retry/error state, not empty state', (
      tester,
    ) async {
      bool retried = false;
      await tester.pumpWidget(
        testApp(
          RoundTripReturnTimeSelector(
            returnOptions: const [],
            selectedReturnOption: null,
            isLoading: false,
            errorMessage: 'Network connection failed',
            onRetry: () => retried = true,
            onOptionSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
      expect(
        find.text('لا توجد رحلات عودة متاحة بعد موعد الذهاب المختار.'),
        findsNothing,
      );

      await tester.tap(find.text('إعادة المحاولة'));
      expect(retried, isTrue);
    });

    // 8. Unrelated Cubit emissions do not clear Return options
    test('8. Unrelated Cubit emissions do not clear returnOptions', () async {
      repo.returnOptions = [sampleReturn1600, sampleReturn1700];
      cubit.setBookingMode(BookingMode.roundTrip);
      await cubit.selectOriginStop(sampleOutboundStop);
      cubit.selectTrip(sampleOutbound0800);
      await cubit.loadRoundTripReturnOptions();

      expect(cubit.state.returnOptions.length, equals(2));

      // Trigger unrelated state emissions
      cubit.unlockTrip();
      expect(cubit.state.returnOptions.length, equals(2));
      expect(cubit.state.selectedReturnOption, equals(sampleReturn1600));

      cubit.clearError();
      expect(cubit.state.returnOptions.length, equals(2));
      expect(cubit.state.selectedReturnOption, equals(sampleReturn1600));
    });

    // 9. Changing outbound trip refetches Return options
    test('9. Changing outbound trip refetches Return options', () async {
      repo.returnOptions = [sampleReturn1600, sampleReturn1700];
      cubit.setBookingMode(BookingMode.roundTrip);
      await cubit.selectOriginStop(sampleOutboundStop);
      cubit.selectTrip(sampleOutbound0800);
      await cubit.loadRoundTripReturnOptions();

      final initialCallCount = repo.getReturnOptionsCallCount;
      cubit.selectTrip(sampleOutbound0900);
      await cubit.loadRoundTripReturnOptions();

      expect(repo.getReturnOptionsCallCount, greaterThan(initialCallCount));
      expect(repo.lastOutboundTripId, equals(sampleOutbound0900.tripId));
    });

    // 10. Changing outbound boarding stop refetches Return options
    test(
      '10. Changing outbound boarding stop refetches Return options',
      () async {
        final stop2 = const RouteStop(
          routeStopId: 'stop-out-2',
          stopId: 'stop-2',
          stopOrder: 2,
          stopNameAr: 'أجا',
          stopNameEn: 'Aga',
          localityAr: 'الدقهلية',
          fareZoneId: 'zone-1',
          farePoints: 25,
        );
        repo.routeStops = [sampleOutboundStop, stop2];
        repo.trips = [sampleOutbound0800];
        repo.returnOptions = [sampleReturn1600, sampleReturn1700];

        cubit.setBookingMode(BookingMode.roundTrip);
        await cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutbound0800);
        await cubit.loadRoundTripReturnOptions();

        final initialCallCount = repo.getReturnOptionsCallCount;
        await cubit.selectOriginStop(stop2);

        expect(repo.getReturnOptionsCallCount, greaterThan(initialCallCount));
        expect(repo.lastOutboundRouteStopId, equals(stop2.routeStopId));
      },
    );

    // 11. No client DateTime.now filtering removes backend-valid rows
    test(
      '11. No client-side filtering drops is_bookable rows from backend',
      () async {
        final futureReturn = RoundTripReturnOption(
          returnTripId: 'trip-ret-far',
          departureTime: '23:00',
          departureAt: DateTime(2026, 9, 21, 23, 0),
          availableSeats: 5,
          outboundBaseFarePoints: 25,
          returnBaseFarePoints: 25,
          subtotalPoints: 50,
          discountPercent: 15,
          discountPoints: 7,
          totalPoints: 43,
          isBookable: true,
        );
        repo.returnOptions = [sampleReturn1600, futureReturn];
        cubit.setBookingMode(BookingMode.roundTrip);
        await cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutbound0800);
        await cubit.loadRoundTripReturnOptions();

        expect(cubit.state.returnOptions.length, equals(2));
        expect(cubit.state.returnOptions.contains(futureReturn), isTrue);
      },
    );

    // 12. Return-only booking displays: "أمام بوابة توشكى – حي الجامعة" once below selector
    testWidgets(
      '12. Return-only booking displays "أمام بوابة توشكى – حي الجامعة" once below selector',
      (tester) async {
        final sampleReturnTrip1 = TripOption(
          tripId: 'trip-ret-1',
          routeId: 'route-ret',
          direction: BookingDirection.returnTrip,
          originNameAr: 'المنصورة',
          originNameEn: 'Mansoura',
          destinationNameAr: 'ميت العامل',
          destinationNameEn: 'Mit El Amel',
          departureTime: '16:00',
          departureAt: DateTime(2026, 9, 21, 16, 0),
          farePoints: 25,
          availableSeatsCount: 20,
          status: 'scheduled',
          isBookable: true,
        );
        final sampleReturnTrip2 = TripOption(
          tripId: 'trip-ret-2',
          routeId: 'route-ret',
          direction: BookingDirection.returnTrip,
          originNameAr: 'المنصورة',
          originNameEn: 'Mansoura',
          destinationNameAr: 'ميت العامل',
          destinationNameEn: 'Mit El Amel',
          departureTime: '17:00',
          departureAt: DateTime(2026, 9, 21, 17, 0),
          farePoints: 25,
          availableSeatsCount: 20,
          status: 'scheduled',
          isBookable: true,
        );

        await tester.pumpWidget(
          testApp(
            Column(
              children: [
                DepartureTimeSelector(
                  trips: [sampleReturnTrip1, sampleReturnTrip2],
                  selectedTrip: sampleReturnTrip1,
                  direction: BookingDirection.returnTrip,
                  onTripSelected: (_) {},
                ),
                ReturnMeetingInfoCard(selectedTrip: sampleReturnTrip1),
              ],
            ),
          ),
        );

        // Time cards render times only
        expect(find.text('4:00 م'), findsOneWidget);
        expect(find.text('5:00 م'), findsOneWidget);

        // Exactly ONE meeting point and ONE grace period container below selector
        expect(find.text('أمام بوابة توشكى – حي الجامعة'), findsOneWidget);
        expect(find.text('مكان التجمع'), findsOneWidget);
        expect(find.text('فترة السماح'), findsOneWidget);
        expect(find.text('15 دقيقة بعد الموعد المحدد'), findsOneWidget);
      },
    );

    // 13. Return-only booking displays: "15 دقيقة بعد الموعد المحدد"
    testWidgets(
      '13. Return-only booking displays "15 دقيقة بعد الموعد المحدد"',
      (tester) async {
        final sampleReturnTrip = TripOption(
          tripId: 'trip-ret-only',
          routeId: 'route-ret',
          direction: BookingDirection.returnTrip,
          originNameAr: 'المنصورة',
          originNameEn: 'Mansoura',
          destinationNameAr: 'ميت العامل',
          destinationNameEn: 'Mit El Amel',
          departureTime: '16:00',
          departureAt: DateTime(2026, 9, 21, 16, 0),
          farePoints: 25,
          availableSeatsCount: 20,
          status: 'scheduled',
          isBookable: true,
        );

        await tester.pumpWidget(
          testApp(ReturnMeetingInfoCard(selectedTrip: sampleReturnTrip)),
        );

        expect(
          find.textContaining('15 دقيقة بعد الموعد المحدد'),
          findsOneWidget,
        );
      },
    );

    // 14. Return-only UI does NOT display "ميت فضالة" as Return meeting point
    testWidgets(
      '14. Return-only UI does NOT display "ميت فضالة" as meeting point',
      (tester) async {
        final sampleReturnTrip = TripOption(
          tripId: 'trip-ret-only',
          routeId: 'route-ret',
          direction: BookingDirection.returnTrip,
          originNameAr: 'المنصورة',
          originNameEn: 'Mansoura',
          destinationNameAr: 'ميت العامل',
          destinationNameEn: 'Mit El Amel',
          departureTime: '16:00',
          departureAt: DateTime(2026, 9, 21, 16, 0),
          farePoints: 25,
          availableSeatsCount: 20,
          status: 'scheduled',
          isBookable: true,
        );

        await tester.pumpWidget(
          testApp(
            Column(
              children: [
                DepartureTimeSelector(
                  trips: [sampleReturnTrip],
                  selectedTrip: sampleReturnTrip,
                  direction: BookingDirection.returnTrip,
                  onTripSelected: (_) {},
                ),
                ReturnMeetingInfoCard(selectedTrip: sampleReturnTrip),
              ],
            ),
          ),
        );

        expect(find.textContaining('ميت فضالة'), findsNothing);
        expect(find.text('أمام بوابة توشكى – حي الجامعة'), findsOneWidget);
      },
    );

    // 15. Round Trip Return section displays: "أمام بوابة توشكى – حي الجامعة" once below selector
    testWidgets(
      '15. Round Trip Return section displays "أمام بوابة توشكى – حي الجامعة" once below selector',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            RoundTripReturnTimeSelector(
              returnOptions: [sampleReturn1600, sampleReturn1700],
              selectedReturnOption: sampleReturn1600,
              onOptionSelected: (_) {},
            ),
          ),
        );

        // Both times render cleanly
        expect(find.text('4:00 م'), findsOneWidget);
        expect(find.text('5:00 م'), findsOneWidget);

        // Only ONE meeting point text below selector
        expect(find.text('أمام بوابة توشكى – حي الجامعة'), findsOneWidget);
      },
    );

    // 16. Round Trip Return section displays: "15 دقيقة بعد الموعد المحدد" once below selector
    testWidgets(
      '16. Round Trip Return section displays "15 دقيقة بعد الموعد المحدد" once below selector',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            RoundTripReturnTimeSelector(
              returnOptions: [sampleReturn1600, sampleReturn1700],
              selectedReturnOption: sampleReturn1600,
              onOptionSelected: (_) {},
            ),
          ),
        );

        expect(find.text('15 دقيقة بعد الموعد المحدد'), findsOneWidget);
        expect(find.text('فترة السماح'), findsOneWidget);
      },
    );

    // 17. Selecting 16:00 displays movement guidance as 16:15 / 4:15 م
    testWidgets('17. Selecting 16:00 displays movement guidance as 4:15 م', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          ReturnMeetingInfoCard(
            selectedDepartureTime: '16:00',
            selectedDepartureAt: DateTime(2026, 9, 21, 16, 0),
          ),
        ),
      );

      expect(find.textContaining('4:00 م'), findsOneWidget);
      expect(find.textContaining('4:15 م'), findsOneWidget);
      expect(find.textContaining('يبدأ التحرك'), findsOneWidget);
    });

    // 18. Outbound helper information remains unchanged ("التحرك من محطة ميت فضالة")
    testWidgets(
      '18. Outbound helper information remains unchanged ("التحرك من محطة ميت فضالة")',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            DepartureTimeSelector(
              trips: [sampleOutboundTrip],
              selectedTrip: sampleOutboundTrip,
              direction: BookingDirection.outbound,
              onTripSelected: (_) {},
            ),
          ),
        );

        expect(find.textContaining('ميت فضالة'), findsOneWidget);
      },
    );

    // 19. Return meeting info uses a shared/reusable component across both flows
    testWidgets('19. ReturnMeetingInfoCard is reusable across both flows', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const Column(children: [ReturnMeetingInfoCard()])),
      );

      expect(find.byType(ReturnMeetingInfoCard), findsOneWidget);
      expect(find.text('مكان التجمع'), findsOneWidget);
      expect(find.text('أمام بوابة توشكى – حي الجامعة'), findsOneWidget);
      expect(find.text('فترة السماح'), findsOneWidget);
      expect(find.text('15 دقيقة بعد الموعد المحدد'), findsOneWidget);
    });

    // 20. State flow regression: select origin stop -> select outbound trip -> loads return options and retains two rows
    test(
      '20. State flow regression: select stop -> select trip -> loads and retains return options',
      () async {
        repo.routeStops = [
          const RouteStop(
            routeStopId: 'route-stop-main-1',
            stopId: 'stop-main-1',
            stopOrder: 1,
            stopNameAr: 'المدخل الرئيسي',
            stopNameEn: 'Main Entrance',
            localityAr: 'المنصورة',
            localityEn: 'Mansoura',
            fareZoneId: 'zone-20',
            farePoints: 20.0,
          ),
          const RouteStop(
            routeStopId: 'route-stop-dest-1',
            stopId: 'stop-dest-1',
            stopOrder: 2,
            stopNameAr: 'الجامعة',
            stopNameEn: 'University',
            localityAr: 'المنصورة',
            localityEn: 'Mansoura',
            fareZoneId: 'zone-20',
            farePoints: 20.0,
          ),
        ];

        final trip0900 = TripOption(
          tripId: 'trip-0900-uuid',
          routeId: 'route-out-1',
          direction: BookingDirection.outbound,
          originNameAr: 'المدخل الرئيسي',
          originNameEn: 'Main Entrance',
          destinationNameAr: 'الجامعة',
          destinationNameEn: 'University',
          departureTime: '09:00',
          departureAt: DateTime(2026, 9, 21, 9, 0),
          availableSeatsCount: 28,
          farePoints: 20.0,
          status: 'scheduled',
        );
        repo.trips = [trip0900];
        repo.returnOptions = [sampleReturn1600, sampleReturn1700];

        await cubit.initBooking(initialDirection: BookingDirection.outbound);
        await cubit.setBookingMode(BookingMode.roundTrip);
        await cubit.selectOriginStop(repo.routeStops.first);
        cubit.selectTrip(trip0900);
        await Future.delayed(Duration.zero);

        expect(repo.lastOutboundTripId, equals('trip-0900-uuid'));
        expect(repo.lastOutboundRouteStopId, equals('route-stop-main-1'));
        expect(cubit.state.returnOptions.length, equals(2));
        expect(
          cubit.state.returnOptions.map((o) => o.departureTime).toList(),
          equals(['16:00', '17:00']),
        );
        expect(
          cubit.state.selectedReturnOption?.departureTime,
          equals('16:00'),
        );
      },
    );

    // 21. Preserves exact route_stop_id even when multiple physical stops share Arabic display name
    test(
      '21. Preserves exact route_stop_id for duplicate Arabic stop names',
      () async {
        const stop1 = RouteStop(
          routeStopId: 'route-stop-exact-99',
          stopId: 'phys-stop-1',
          stopOrder: 1,
          stopNameAr: 'المدخل الرئيسي',
          stopNameEn: 'Main Entrance 1',
          localityAr: 'المنصورة',
          localityEn: 'Mansoura',
          fareZoneId: 'zone-20',
          farePoints: 20.0,
        );
        const stop2 = RouteStop(
          routeStopId: 'route-stop-exact-100',
          stopId: 'phys-stop-2',
          stopOrder: 2,
          stopNameAr: 'المدخل الرئيسي',
          stopNameEn: 'Main Entrance 2',
          localityAr: 'المنصورة',
          localityEn: 'Mansoura',
          fareZoneId: 'zone-20',
          farePoints: 20.0,
        );

        final trip = TripOption(
          tripId: 'trip-out-99',
          routeId: 'route-out-1',
          direction: BookingDirection.outbound,
          originNameAr: 'المدخل الرئيسي',
          originNameEn: 'Main Entrance',
          destinationNameAr: 'الجامعة',
          destinationNameEn: 'University',
          departureTime: '09:00',
          departureAt: DateTime(2026, 9, 21, 9, 0),
          availableSeatsCount: 28,
          farePoints: 20.0,
          status: 'scheduled',
        );

        repo.routeStops = [stop1, stop2];
        repo.trips = [trip];
        repo.returnOptions = [sampleReturn1600, sampleReturn1700];

        await cubit.initBooking(initialDirection: BookingDirection.outbound);
        await cubit.setBookingMode(BookingMode.roundTrip);
        await cubit.selectOriginStop(stop2);
        cubit.selectTrip(trip);
        await Future.delayed(Duration.zero);

        expect(repo.lastOutboundRouteStopId, equals('route-stop-exact-100'));
        expect(
          cubit.state.selectedRouteStop?.routeStopId,
          equals('route-stop-exact-100'),
        );
      },
    );

    // 22. RT2.4 REUSE WORKING RETURN-ONLY TRIP LOADING FOR ROUND TRIP
    group('22. RT2.4 — Shared Canonical Return Trips Loading', () {
      final retTrip1600 = TripOption(
        tripId: 'canonical-ret-1600',
        routeId: 'route-ret',
        direction: BookingDirection.returnTrip,
        originNameAr: 'الجامعة',
        originNameEn: 'University',
        destinationNameAr: 'المدخل الرئيسي',
        destinationNameEn: 'Main Entrance',
        departureTime: '16:00',
        departureAt: DateTime(2026, 9, 21, 16, 0),
        availableSeatsCount: 28,
        farePoints: 20.0,
        status: 'scheduled',
      );

      final retTrip1700 = TripOption(
        tripId: 'canonical-ret-1700',
        routeId: 'route-ret',
        direction: BookingDirection.returnTrip,
        originNameAr: 'الجامعة',
        originNameEn: 'University',
        destinationNameAr: 'المدخل الرئيسي',
        destinationNameEn: 'Main Entrance',
        departureTime: '17:00',
        departureAt: DateTime(2026, 9, 21, 17, 0),
        availableSeatsCount: 28,
        farePoints: 20.0,
        status: 'scheduled',
      );

      final outTrip0900 = TripOption(
        tripId: 'canonical-out-0900',
        routeId: 'route-out',
        direction: BookingDirection.outbound,
        originNameAr: 'المدخل الرئيسي',
        originNameEn: 'Main Entrance',
        destinationNameAr: 'الجامعة',
        destinationNameEn: 'University',
        departureTime: '09:00',
        departureAt: DateTime(2026, 9, 21, 9, 0),
        availableSeatsCount: 28,
        farePoints: 20.0,
        status: 'scheduled',
      );

      const originStop = RouteStop(
        routeStopId: 'route-stop-main-entrance',
        stopId: 'stop-main-entrance',
        stopOrder: 1,
        stopNameAr: 'المدخل الرئيسي',
        localityAr: 'المنصورة',
        fareZoneId: 'zone-20',
        farePoints: 20.0,
      );

      const destStop = RouteStop(
        routeStopId: 'route-stop-university',
        stopId: 'stop-university',
        stopOrder: 2,
        stopNameAr: 'الجامعة',
        localityAr: 'المنصورة',
        fareZoneId: 'zone-20',
        farePoints: 20.0,
      );

      testWidgets(
        'Test A: Direction = Return renders canonical 16:00 and 17:00',
        (tester) async {
          repo.routeStops = [originStop];
          repo.trips = [retTrip1600, retTrip1700];
          repo.returnTrips = [retTrip1600, retTrip1700];

          await cubit.initBooking(
            initialDirection: BookingDirection.returnTrip,
          );

          await tester.pumpWidget(
            testApp(
              DepartureTimeSelector(
                trips: cubit.state.availableTrips,
                selectedTrip: cubit.state.selectedTrip,
                direction: cubit.state.selectedDirection,
                onTripSelected: (t) => cubit.selectTrip(t),
              ),
            ),
          );
          await tester.pump();

          expect(find.text('4:00 م'), findsOneWidget);
          expect(find.text('5:00 م'), findsOneWidget);
        },
      );

      testWidgets(
        'Test B: Direction = Outbound, RoundTrip, Outbound=09:00 renders THE SAME 16:00 and 17:00',
        (tester) async {
          repo.routeStops = [originStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600, retTrip1700];
          repo.returnOptions = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: true,
            ),
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1700',
              departureTime: '17:00',
              departureAt: DateTime(2026, 9, 21, 17, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: true,
            ),
          ];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          await cubit.selectTrip(outTrip0900);

          await tester.pumpWidget(
            testApp(
              RoundTripReturnTimeSelector(
                returnOptions: cubit.state.returnOptions,
                selectedReturnOption: cubit.state.selectedReturnOption,
                isLoading: cubit.state.isLoadingRoundTripReturnOptions,
                errorMessage: cubit.state.roundTripReturnOptionsError,
                onOptionSelected: (o) => cubit.selectReturnOption(o),
              ),
            ),
          );
          await tester.pump();

          // Renders the exact same 16:00 and 17:00
          expect(find.text('4:00 م'), findsOneWidget);
          expect(find.text('5:00 م'), findsOneWidget);

          // Does NOT render empty-state
          expect(
            find.text('لا توجد رحلات عودة متاحة بعد موعد الذهاب المختار.'),
            findsNothing,
          );
        },
      );

      test(
        'Test C: Preserves exact return_trip_id, verifies Round Trip backend eligibility check, and allows selecting 16:00',
        () async {
          repo.routeStops = [originStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600, retTrip1700];
          repo.returnOptions = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: true,
            ),
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1700',
              departureTime: '17:00',
              departureAt: DateTime(2026, 9, 21, 17, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: true,
            ),
          ];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectTrip(outTrip0900);
          await Future.delayed(Duration.zero);

          // RPC was called for authoritative validation
          expect(repo.getReturnOptionsCallCount, greaterThan(0));
          expect(repo.lastOutboundTripId, equals('canonical-out-0900'));
          expect(
            repo.lastOutboundRouteStopId,
            equals('route-stop-main-entrance'),
          );

          // Return options preserve exact return_trip_id
          final options = cubit.state.returnOptions;
          expect(options.length, equals(2));
          expect(options[0].returnTripId, equals('canonical-ret-1600'));
          expect(options[1].returnTripId, equals('canonical-ret-1700'));

          // Selection of 16:00 works
          cubit.selectReturnOption(options[0]);
          expect(
            cubit.state.selectedReturnOption?.returnTripId,
            equals('canonical-ret-1600'),
          );
          expect(cubit.state.selectedReturnOption?.totalPoints, equals(34.0));
        },
      );

      testWidgets(
        'RT2.4.1 Test 1: canonical returns 16:00/17:00, RPC loading -> both visible, both disabled',
        (tester) async {
          final options = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 0,
              returnBaseFarePoints: 0,
              subtotalPoints: 0,
              discountPercent: 0,
              discountPoints: 0,
              totalPoints: 0,
              isBookable: false,
            ),
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1700',
              departureTime: '17:00',
              departureAt: DateTime(2026, 9, 21, 17, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 0,
              returnBaseFarePoints: 0,
              subtotalPoints: 0,
              discountPercent: 0,
              discountPoints: 0,
              totalPoints: 0,
              isBookable: false,
            ),
          ];

          RoundTripReturnOption? tappedOption;
          await tester.pumpWidget(
            testApp(
              RoundTripReturnTimeSelector(
                returnOptions: options,
                selectedReturnOption: null,
                isLoading: true,
                errorMessage: null,
                onOptionSelected: (o) => tappedOption = o,
              ),
            ),
          );
          await tester.pump();

          // Both visible
          expect(find.text('4:00 م'), findsOneWidget);
          expect(find.text('5:00 م'), findsOneWidget);

          // Both show verifying status badge and are disabled
          expect(find.text('جارٍ التحقق'), findsNWidgets(2));

          // Tapping while loading/unbookable does nothing
          await tester.tap(find.text('4:00 م'));
          expect(tappedOption, isNull);
        },
      );

      testWidgets(
        'RT2.4.1 Test 2: canonical returns 16:00/17:00, RPC error -> both visible, checkout blocked',
        (tester) async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600, retTrip1700];
          repo.returnOptionsFailure = const ServerFailure(
            message: 'فشل الاتصال بخدمة التحقق من رحلات العودة',
          );

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip0900);

          await tester.pumpWidget(
            testApp(
              RoundTripReturnTimeSelector(
                returnOptions: cubit.state.returnOptions,
                selectedReturnOption: cubit.state.selectedReturnOption,
                isLoading: cubit.state.isLoadingRoundTripReturnOptions,
                errorMessage: cubit.state.roundTripReturnOptionsError,
                onRetry: () => cubit.loadRoundTripReturnOptions(),
                onOptionSelected: (o) => cubit.selectReturnOption(o),
              ),
            ),
          );
          await tester.pump();

          // Both visible in schedule
          expect(find.text('4:00 م'), findsOneWidget);
          expect(find.text('5:00 م'), findsOneWidget);

          // Error banner and retry CTA are shown
          expect(
            find.text('فشل الاتصال بخدمة التحقق من رحلات العودة'),
            findsOneWidget,
          );
          expect(find.text('إعادة المحاولة'), findsOneWidget);

          // Checkout is blocked (no selection possible without RPC)
          expect(cubit.state.selectedReturnOption, isNull);
          cubit.proceedToSeatMap();
          expect(cubit.state.currentStep, equals(BookingStep.setup));
          expect(
            cubit.state.errorMessage,
            equals('يرجى اختيار ميعاد العودة المناسب أولاً.'),
          );
        },
      );

      testWidgets(
        'RT2.4.1 Test 3: canonical returns 16:00/17:00, RPC returns only 16:00 bookable -> 16:00 enabled, 17:00 disabled',
        (tester) async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600, retTrip1700];
          repo.returnOptions = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: true,
            ),
          ];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip0900);

          await tester.pumpWidget(
            testApp(
              RoundTripReturnTimeSelector(
                returnOptions: cubit.state.returnOptions,
                selectedReturnOption: cubit.state.selectedReturnOption,
                isLoading: cubit.state.isLoadingRoundTripReturnOptions,
                errorMessage: cubit.state.roundTripReturnOptionsError,
                onOptionSelected: (o) => cubit.selectReturnOption(o),
              ),
            ),
          );
          await tester.pump();

          // Both visible
          expect(find.text('4:00 م'), findsOneWidget);
          expect(find.text('5:00 م'), findsOneWidget);

          // 17:00 has no matching RPC row -> marked unbookable
          expect(find.text('غير متاح ضمن حجز ذهاب وعودة'), findsOneWidget);

          // 16:00 is bookable and was selected
          expect(
            cubit.state.selectedReturnOption?.returnTripId,
            equals('canonical-ret-1600'),
          );

          // Attempting to select 17:00 fails
          final opt1700 = cubit.state.returnOptions.firstWhere(
            (o) => o.returnTripId == 'canonical-ret-1700',
          );
          expect(opt1700.isBookable, isFalse);
          cubit.selectReturnOption(opt1700);
          expect(
            cubit.state.selectedReturnOption?.returnTripId,
            equals('canonical-ret-1600'),
          );
        },
      );

      testWidgets(
        'RT2.4.1 Test 4: RPC returns 16:00 is_bookable=false -> visible but disabled',
        (tester) async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600];
          repo.returnOptions = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 0,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 15,
              discountPoints: 6,
              totalPoints: 34,
              isBookable: false,
            ),
          ];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip0900);

          await tester.pumpWidget(
            testApp(
              RoundTripReturnTimeSelector(
                returnOptions: cubit.state.returnOptions,
                selectedReturnOption: cubit.state.selectedReturnOption,
                isLoading: cubit.state.isLoadingRoundTripReturnOptions,
                errorMessage: cubit.state.roundTripReturnOptionsError,
                onOptionSelected: (o) => cubit.selectReturnOption(o),
              ),
            ),
          );
          await tester.pump();

          // Visible
          expect(find.text('4:00 م'), findsOneWidget);
          // Disabled badge
          expect(find.text('غير متاح ضمن حجز ذهاب وعودة'), findsOneWidget);
          // Cannot select
          expect(cubit.state.selectedReturnOption, isNull);
        },
      );

      test(
        'RT2.4.1 Test 5: No matched RPC row -> cannot continue into seat flow',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600];
          repo.returnOptions = []; // Empty RPC result

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip0900);

          // Return option exists for display, but isBookable is strictly false
          expect(cubit.state.returnOptions.length, equals(1));
          expect(cubit.state.returnOptions[0].isBookable, isFalse);
          expect(cubit.state.selectedReturnOption, isNull);

          // Attempting proceedToSeatMap blocked
          cubit.proceedToSeatMap();
          expect(cubit.state.currentStep, equals(BookingStep.setup));
          expect(
            cubit.state.errorMessage,
            equals('يرجى اختيار ميعاد العودة المناسب أولاً.'),
          );
        },
      );

      test(
        'RT2.4.1 Test 6: Price and discount always taken from RPC row, never synthesized with 15% fallback',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip0900];
          repo.returnTrips = [retTrip1600];
          // Custom authoritative RPC pricing with 20% discount (e.g. promotional bundle)
          repo.returnOptions = [
            RoundTripReturnOption(
              returnTripId: 'canonical-ret-1600',
              departureTime: '16:00',
              departureAt: DateTime(2026, 9, 21, 16, 0),
              availableSeats: 28,
              outboundBaseFarePoints: 20,
              returnBaseFarePoints: 20,
              subtotalPoints: 40,
              discountPercent: 20,
              discountPoints: 8,
              totalPoints: 32,
              isBookable: true,
            ),
          ];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          await cubit.selectTrip(outTrip0900);

          expect(
            cubit.state.selectedReturnOption?.discountPercent,
            equals(20.0),
          );
          expect(cubit.state.selectedReturnOption?.discountPoints, equals(8.0));
          expect(cubit.state.selectedReturnOption?.totalPoints, equals(32.0));
        },
      );
    });

    group('PHASE RT2.5 — ROUND TRIP OUTBOUND SEAT SELECTION & HOLD TESTS', () {
      const originStop = RouteStop(
        routeStopId: 'route-stop-main-entrance-rt25',
        stopId: 'stop-main-entrance-rt25',
        stopOrder: 1,
        stopNameAr: 'المدخل الرئيسي',
        localityAr: 'المنصورة',
        fareZoneId: 'zone-20',
        farePoints: 20.0,
      );
      const destStop = RouteStop(
        routeStopId: 'route-stop-university-rt25',
        stopId: 'stop-university-rt25',
        stopOrder: 2,
        stopNameAr: 'الجامعة',
        localityAr: 'المنصورة',
        fareZoneId: 'zone-20',
        farePoints: 20.0,
      );
      final outTrip = TripOption(
        tripId: 'trip-out-rt25',
        routeId: 'route-1',
        direction: BookingDirection.outbound,
        originNameAr: 'المدخل الرئيسي',
        originNameEn: 'Main Entrance',
        destinationNameAr: 'الجامعة',
        destinationNameEn: 'University',
        departureTime: '09:00',
        departureAt: DateTime(2026, 9, 21, 9, 0),
        availableSeatsCount: 28,
        farePoints: 20.0,
        status: 'scheduled',
      );
      final retOption = RoundTripReturnOption(
        returnTripId: 'trip-ret-rt25',
        departureTime: '16:00',
        departureAt: DateTime(2026, 9, 21, 16, 0),
        availableSeats: 28,
        outboundBaseFarePoints: 20,
        returnBaseFarePoints: 20,
        subtotalPoints: 40,
        discountPercent: 15,
        discountPoints: 6,
        totalPoints: 34,
        isBookable: true,
      );
      final seat5 = const TripSeat(
        seatId: 'seat-5-uuid',
        seatNumber: '5',
        rowIndex: 2,
        columnIndex: 1,
        seatType: 'standard',
        status: SeatAvailabilityStatus.available,
        isMine: false,
      );
      final seat6 = const TripSeat(
        seatId: 'seat-6-uuid',
        seatNumber: '6',
        rowIndex: 2,
        columnIndex: 2,
        seatType: 'standard',
        status: SeatAvailabilityStatus.available,
        isMine: false,
      );

      testWidgets(
        'RT2.5 Test 1: available outbound seat tap invokes callback',
        (tester) async {
          TripSeat? tappedSeat;
          await tester.pumpWidget(
            testApp(
              ProfessionalBusSeatMap(
                seats: [seat5, seat6],
                selectedSeat: null,
                onSeatTap: (seat) => tappedSeat = seat,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Find Seat 5 and tap it
          final seatFinder = find.byWidgetPredicate(
            (w) => w is BusSeatVisual && w.label == '5',
          );
          expect(seatFinder, findsOneWidget);
          await tester.tap(seatFinder);
          await tester.pumpAndSettle();

          expect(tappedSeat, isNotNull);
          expect(tappedSeat?.seatId, equals('seat-5-uuid'));
          expect(tappedSeat?.seatNumber, equals('5'));
        },
      );

      test(
        'RT2.5 Test 2: Round Trip outbound tap calls createRoundTripBundleHold exactly once',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          expect(cubit.state.currentStep, equals(BookingStep.seatMap));
          expect(
            cubit.state.roundTripSeatStep,
            equals(RoundTripSeatStep.outbound),
          );

          await cubit.selectSeatAndHold(seat5);

          expect(repo.createBundleHoldCallCount, equals(1));
        },
      );

      test(
        'RT2.5 Test 3: correct outbound seat ID is passed to createRoundTripBundleHold',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          await cubit.selectSeatAndHold(seat5);

          expect(repo.lastOutboundSeatId, equals('seat-5-uuid'));
        },
      );

      test(
        'RT2.5 Test 4: selected outbound and return trip IDs are correct',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          await cubit.selectSeatAndHold(seat5);

          expect(repo.lastOutboundTripId, equals('trip-out-rt25'));
          expect(repo.lastReturnTripId, equals('trip-ret-rt25'));
          expect(
            repo.lastOutboundRouteStopId,
            equals('route-stop-main-entrance-rt25'),
          );
        },
      );

      test(
        'RT2.5 Test 5: loading flag does not permanently block map',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          await cubit.selectSeatAndHold(seat5);

          expect(cubit.state.status, isNot(equals(BookingStatus.holdingSeat)));
        },
      );

      test(
        'RT2.5 Test 6: bundle hold error restores seat tap ability and reverts selection',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];
          repo.bundleHoldFailure = const NetworkFailure(
            message: 'Failed to hold bundle',
          );

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          await cubit.selectSeatAndHold(seat5);

          expect(cubit.state.status, equals(BookingStatus.error));
          expect(cubit.state.selectedSeat, isNull);
          expect(cubit.state.status, isNot(equals(BookingStatus.holdingSeat)));

          // Ability to tap another seat is restored
          repo.bundleHoldFailure = null;
          await cubit.selectSeatAndHold(seat6);

          expect(repo.createBundleHoldCallCount, equals(2));
          expect(cubit.state.selectedSeat?.seatId, equals('seat-6-uuid'));
          expect(cubit.state.bundleHold, isNotNull);
        },
      );

      test('RT2.5 Test 7: success advances to Return seat step', () async {
        repo.routeStops = [originStop, destStop];
        repo.trips = [outTrip];
        repo.seats = [seat5, seat6];
        repo.returnOptions = [retOption];

        await cubit.initBooking(initialDirection: BookingDirection.outbound);
        await cubit.setBookingMode(BookingMode.roundTrip);
        await cubit.selectOriginStop(originStop);
        cubit.selectDestinationStop(destStop);
        await cubit.selectTrip(outTrip);
        cubit.selectReturnOption(retOption);
        cubit.proceedToSeatMap();

        await cubit.selectSeatAndHold(seat5);

        expect(
          cubit.state.roundTripSeatStep,
          equals(RoundTripSeatStep.returnSeat),
        );
        expect(cubit.state.selectedSeat?.seatId, equals('seat-5-uuid'));
        expect(cubit.state.bundleHold, isNotNull);
      });

      test(
        'RT2.5 Test 8: unrelated state emission does not clear selected outbound seat',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];
          repo.returnOptions = [retOption];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          await cubit.selectSeatAndHold(seat5);
          expect(cubit.state.selectedSeat?.seatId, equals('seat-5-uuid'));

          // Trigger unrelated state update via unlockTrip
          cubit.unlockTrip();
          expect(cubit.state.selectedSeat?.seatId, equals('seat-5-uuid'));
        },
      );

      test(
        'RT2.5 Test 9: Single Trip seat selection still works and uses single hold',
        () async {
          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5, seat6];

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.single);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.proceedToSeatMap();

          expect(cubit.state.isSingle, isTrue);

          await cubit.selectSeatAndHold(seat5);

          // Normal single hold used
          expect(cubit.state.activeHold, isNotNull);
          expect(cubit.state.selectedSeat?.seatId, equals('seat-5-uuid'));
          // Bundle hold NOT called
          expect(repo.createBundleHoldCallCount, equals(0));
          expect(cubit.state.bundleHold, isNull);
        },
      );
    });

    group('PHASE RT2.6 — ROUND TRIP REVIEW LEG FARE DISPLAY TESTS', () {
      testWidgets(
        'RT2.6 Test 1: RPC 20+20 displays exactly 20 / 20 / 40 / -6 / 34 on Review',
        (tester) async {
          final bundleHold20 = RoundTripBundleHold(
            bundleHoldId: 'bundle-20',
            outboundHoldId: 'h-out-20',
            outboundTripId: 'trip-out',
            returnTripId: 'trip-ret',
            outboundSeatId: 'seat-1',
            returnSeatId: 'seat-2',
            outboundSeatNumber: '5',
            returnSeatNumber: '6',
            outboundRouteStopId: 'stop-1',
            outboundBaseFarePoints: 20,
            returnBaseFarePoints: 20,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          final returnOption20 = RoundTripReturnOption(
            returnTripId: 'trip-ret',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 8)),
            availableSeats: 20,
            outboundBaseFarePoints: 20,
            returnBaseFarePoints: 20,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            isBookable: true,
          );

          await tester.pumpWidget(
            testApp(
              BookingReviewCard(
                trip: sampleOutboundTrip,
                seat: sampleSeat1,
                routeStop: sampleOutboundStop,
                returnSeat: sampleSeat2,
                returnOption: returnOption20,
                userAvailablePoints: 100,
                bundleHold: bundleHold20,
                onConfirm: () {},
              ),
            ),
          );

          expect(find.text('سعر الذهاب'), findsOneWidget);
          expect(find.text('سعر العودة'), findsOneWidget);
          expect(find.text('20 نقطة'), findsNWidgets(4));
          expect(find.text('40 نقطة'), findsOneWidget);
          expect(find.text('-6 نقطة'), findsOneWidget);
          expect(find.text('34 نقطة'), findsOneWidget);
        },
      );

      testWidgets(
        'RT2.6 Test 2: 25 + 25 displays exactly 25 / 25 / 50 / -7 / 43',
        (tester) async {
          final bundleHold25 = RoundTripBundleHold(
            bundleHoldId: 'bundle-25',
            outboundHoldId: 'h-out-25',
            outboundTripId: 'trip-out',
            returnTripId: 'trip-ret',
            outboundSeatId: 'seat-1',
            returnSeatId: 'seat-2',
            outboundSeatNumber: '5',
            returnSeatNumber: '6',
            outboundRouteStopId: 'stop-1',
            outboundBaseFarePoints: 25,
            returnBaseFarePoints: 25,
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPoints: 43,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          final returnOption25 = RoundTripReturnOption(
            returnTripId: 'trip-ret',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 8)),
            availableSeats: 20,
            outboundBaseFarePoints: 25,
            returnBaseFarePoints: 25,
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPoints: 43,
            isBookable: true,
          );

          await tester.pumpWidget(
            testApp(
              BookingReviewCard(
                trip: sampleOutboundTrip,
                seat: sampleSeat1,
                routeStop: sampleOutboundStop,
                returnSeat: sampleSeat2,
                returnOption: returnOption25,
                userAvailablePoints: 100,
                bundleHold: bundleHold25,
                onConfirm: () {},
              ),
            ),
          );

          expect(find.text('25 نقطة'), findsNWidgets(4));
          expect(find.text('50 نقطة'), findsOneWidget);
          expect(find.text('-7 نقطة'), findsOneWidget);
          expect(find.text('43 نقطة'), findsOneWidget);
        },
      );

      testWidgets(
        'RT2.6 Test 3: 30 + 30 displays exactly 30 / 30 / 60 / -9 / 51',
        (tester) async {
          final bundleHold30 = RoundTripBundleHold(
            bundleHoldId: 'bundle-30',
            outboundHoldId: 'h-out-30',
            outboundTripId: 'trip-out',
            returnTripId: 'trip-ret',
            outboundSeatId: 'seat-1',
            returnSeatId: 'seat-2',
            outboundSeatNumber: '5',
            returnSeatNumber: '6',
            outboundRouteStopId: 'stop-1',
            outboundBaseFarePoints: 30,
            returnBaseFarePoints: 30,
            subtotalPoints: 60,
            discountPercent: 15,
            discountPoints: 9,
            totalPoints: 51,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          final returnOption30 = RoundTripReturnOption(
            returnTripId: 'trip-ret',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 8)),
            availableSeats: 20,
            outboundBaseFarePoints: 30,
            returnBaseFarePoints: 30,
            subtotalPoints: 60,
            discountPercent: 15,
            discountPoints: 9,
            totalPoints: 51,
            isBookable: true,
          );

          await tester.pumpWidget(
            testApp(
              BookingReviewCard(
                trip: sampleOutboundTrip,
                seat: sampleSeat1,
                routeStop: sampleOutboundStop,
                returnSeat: sampleSeat2,
                returnOption: returnOption30,
                userAvailablePoints: 100,
                bundleHold: bundleHold30,
                onConfirm: () {},
              ),
            ),
          );

          expect(find.text('30 نقطة'), findsNWidgets(4));
          expect(find.text('60 نقطة'), findsOneWidget);
          expect(find.text('-9 نقطة'), findsOneWidget);
          expect(find.text('51 نقطة'), findsOneWidget);
        },
      );

      test(
        'RT2.6 Test 4: leg fares survive return selection -> outbound seat -> return seat -> review',
        () async {
          const originStop = RouteStop(
            routeStopId: 'route-stop-origin-rt26',
            stopId: 'stop-origin-rt26',
            stopOrder: 1,
            stopNameAr: 'المدخل الرئيسي',
            localityAr: 'المنصورة',
            fareZoneId: 'zone-20',
            farePoints: 20.0,
          );
          const destStop = RouteStop(
            routeStopId: 'route-stop-dest-rt26',
            stopId: 'stop-dest-rt26',
            stopOrder: 5,
            stopNameAr: 'جامعة السلاب',
            localityAr: 'المنصورة',
            fareZoneId: 'zone-20',
            farePoints: 20.0,
          );
          final outTrip = TripOption(
            tripId: 'trip-out-rt26',
            routeId: 'route-rt26',
            direction: BookingDirection.outbound,
            originNameAr: 'المدخل الرئيسي',
            originNameEn: 'Main Entrance',
            destinationNameAr: 'جامعة السلاب',
            destinationNameEn: 'Sellab University',
            departureTime: '08:00',
            departureAt: DateTime.now().add(const Duration(hours: 1)),
            farePoints: 20,
            availableSeatsCount: 28,
            status: 'scheduled',
            isBookable: true,
          );
          final retOption = RoundTripReturnOption(
            returnTripId: 'trip-ret-rt26',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 9)),
            availableSeats: 28,
            outboundBaseFarePoints: 20,
            returnBaseFarePoints: 20,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            isBookable: true,
          );
          const seat5 = TripSeat(
            seatId: 'seat-5-uuid',
            seatNumber: '5',
            rowIndex: 2,
            columnIndex: 1,
            seatType: 'standard',
            status: SeatAvailabilityStatus.available,
            isMine: false,
          );
          const returnSeat6 = TripSeat(
            seatId: 'seat-6-ret-uuid',
            seatNumber: '6',
            rowIndex: 2,
            columnIndex: 2,
            seatType: 'standard',
            status: SeatAvailabilityStatus.available,
            isMine: false,
          );

          repo.routeStops = [originStop, destStop];
          repo.trips = [outTrip];
          repo.seats = [seat5];
          repo.returnTripSeats = [returnSeat6];
          repo.returnOptions = [retOption];

          // Outbound bundle hold with authoritative 20+20
          repo.bundleHold = RoundTripBundleHold(
            bundleHoldId: 'bundle-rt26-hold',
            outboundHoldId: 'hold-out-rt26',
            outboundTripId: outTrip.tripId,
            returnTripId: retOption.returnTripId,
            outboundSeatId: seat5.seatId,
            outboundSeatNumber: seat5.seatNumber,
            outboundRouteStopId: originStop.routeStopId,
            outboundBaseFarePoints: 20,
            returnBaseFarePoints: 20,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          // Return seat RPC returns 0 for leg fares (reproducing Supabase RPC behavior)
          repo.returnSeatHold = RoundTripBundleHold(
            bundleHoldId: 'bundle-rt26-hold',
            outboundHoldId: '',
            outboundTripId: '',
            returnTripId: '',
            outboundSeatId: '',
            outboundSeatNumber: '',
            returnSeatId: returnSeat6.seatId,
            returnSeatNumber: returnSeat6.seatNumber,
            outboundRouteStopId: '',
            outboundBaseFarePoints: 0,
            returnBaseFarePoints: 0,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          await cubit.initBooking(initialDirection: BookingDirection.outbound);
          await cubit.setBookingMode(BookingMode.roundTrip);
          await cubit.selectOriginStop(originStop);
          cubit.selectDestinationStop(destStop);
          await cubit.selectTrip(outTrip);
          cubit.selectReturnOption(retOption);
          cubit.proceedToSeatMap();

          // Tap Outbound Seat
          await cubit.selectSeatAndHold(seat5);
          expect(cubit.state.selectedSeat?.seatId, equals('seat-5-uuid'));
          expect(
            cubit.state.roundTripSeatStep,
            equals(RoundTripSeatStep.returnSeat),
          );
          expect(cubit.state.bundleHold?.outboundBaseFarePoints, equals(20.0));
          expect(cubit.state.bundleHold?.returnBaseFarePoints, equals(20.0));

          // Tap Return Seat
          await cubit.selectSeatAndHold(returnSeat6);
          expect(
            cubit.state.selectedReturnSeat?.seatId,
            equals('seat-6-ret-uuid'),
          );

          // Authoritative leg fares MUST be preserved despite RPC returning 0
          expect(cubit.state.bundleHold?.outboundBaseFarePoints, equals(20.0));
          expect(cubit.state.bundleHold?.returnBaseFarePoints, equals(20.0));
          expect(cubit.state.bundleHold?.outboundSeatNumber, equals('5'));
          expect(cubit.state.bundleHold?.returnSeatNumber, equals('6'));

          // Proceed to Review
          cubit.proceedToReview();
          expect(cubit.state.currentStep, equals(BookingStep.review));
          expect(cubit.state.bundleHold?.outboundBaseFarePoints, equals(20.0));
          expect(cubit.state.bundleHold?.returnBaseFarePoints, equals(20.0));
        },
      );

      testWidgets(
        'RT2.6 Test 5: no Round Trip review shows 0-point leg fares when authoritative pricing exists',
        (tester) async {
          // Even if bundleHold had 0, returnOption authoritative fares are used
          final bundleHoldZero = RoundTripBundleHold(
            bundleHoldId: 'bundle-zero',
            outboundHoldId: 'h-out',
            outboundTripId: 'trip-out',
            returnTripId: 'trip-ret',
            outboundSeatId: 'seat-1',
            returnSeatId: 'seat-2',
            outboundSeatNumber: '5',
            returnSeatNumber: '6',
            outboundRouteStopId: 'stop-1',
            outboundBaseFarePoints: 0,
            returnBaseFarePoints: 0,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          final returnOptionAuthoritative = RoundTripReturnOption(
            returnTripId: 'trip-ret',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 8)),
            availableSeats: 20,
            outboundBaseFarePoints: 20,
            returnBaseFarePoints: 20,
            subtotalPoints: 40,
            discountPercent: 15,
            discountPoints: 6,
            totalPoints: 34,
            isBookable: true,
          );

          await tester.pumpWidget(
            testApp(
              BookingReviewCard(
                trip: sampleOutboundTrip,
                seat: sampleSeat1,
                routeStop: sampleOutboundStop,
                returnSeat: sampleSeat2,
                returnOption: returnOptionAuthoritative,
                userAvailablePoints: 100,
                bundleHold: bundleHoldZero,
                onConfirm: () {},
              ),
            ),
          );

          // Never shows 0 نقطة
          expect(find.text('0 نقطة'), findsNothing);
          expect(find.text('20 نقطة'), findsNWidgets(4));
        },
      );

      testWidgets(
        'RT2.6 Test 6: dynamic fares (e.g. 22 + 28 = 50) work without any hardcoded 20/25/30',
        (tester) async {
          final bundleHoldDynamic = RoundTripBundleHold(
            bundleHoldId: 'bundle-dynamic',
            outboundHoldId: 'h-out-dyn',
            outboundTripId: 'trip-out',
            returnTripId: 'trip-ret',
            outboundSeatId: 'seat-1',
            returnSeatId: 'seat-2',
            outboundSeatNumber: '5',
            returnSeatNumber: '6',
            outboundRouteStopId: 'stop-1',
            outboundBaseFarePoints: 22,
            returnBaseFarePoints: 28,
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPoints: 43,
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
            serverTime: DateTime.now(),
          );

          final returnOptionDynamic = RoundTripReturnOption(
            returnTripId: 'trip-ret',
            departureTime: '16:00',
            departureAt: DateTime.now().add(const Duration(hours: 8)),
            availableSeats: 20,
            outboundBaseFarePoints: 22,
            returnBaseFarePoints: 28,
            subtotalPoints: 50,
            discountPercent: 15,
            discountPoints: 7,
            totalPoints: 43,
            isBookable: true,
          );

          await tester.pumpWidget(
            testApp(
              BookingReviewCard(
                trip: sampleOutboundTrip,
                seat: sampleSeat1,
                routeStop: sampleOutboundStop,
                returnSeat: sampleSeat2,
                returnOption: returnOptionDynamic,
                userAvailablePoints: 100,
                bundleHold: bundleHoldDynamic,
                onConfirm: () {},
              ),
            ),
          );

          expect(
            find.text('22 نقطة'),
            findsNWidgets(2),
          ); // Outbound card + outbound price row
          expect(
            find.text('28 نقطة'),
            findsNWidgets(2),
          ); // Return card + return price row
          expect(find.text('50 نقطة'), findsOneWidget); // Subtotal
          expect(find.text('-7 نقطة'), findsOneWidget); // Discount
          expect(find.text('43 نقطة'), findsOneWidget); // Total
        },
      );
    });
  });
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
}
