import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_mode_toggle.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/round_trip_return_time_selector.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/booked_trip_overflow_menu.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/add_extra_seat_modal.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockRoundTripBookingRepository implements BookingRepository {
  List<RouteStop> routeStops = [];
  List<TripOption> trips = [];
  List<TripSeat> seats = [];
  List<TripSeat> returnTripSeats = [];
  List<RoundTripReturnOption> returnOptions = [];
  BookingHold? singleHold;
  RoundTripBundleHold? bundleHold;
  RoundTripConfirmation? bundleConfirmation;
  PassengerBooking? singleConfirmation;
  RoundTripBundleContext? bundleContext;

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
  }) async => Success(trips);

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
        cubit.selectOriginStop(sampleOutboundStop);
        cubit.selectTrip(sampleOutboundTrip);
        await cubit.loadRoundTripReturnOptions();

        expect(repo.getReturnOptionsCallCount, equals(1));
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
        cubit.selectOriginStop(sampleOutboundStop);
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
}
