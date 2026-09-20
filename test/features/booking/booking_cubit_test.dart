import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/failures/booking_failures.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_state.dart';

class FakeBookingRepository implements BookingRepository {
  List<RouteStop> routeStops = [];
  List<TripOption> trips = [];
  List<TripSeat> seats = [];
  BookingHold? hold;
  PassengerBooking? confirmedBooking;
  Failure? failure;
  int seatMapCallCount = 0;
  Duration seatMapDelay = Duration.zero;
  List<List<TripSeat>> queuedSeatMapResponses = [];
  bool seatUpdatesCancelled = false;
  final seatUpdatesController = StreamController<void>.broadcast();

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(routeStops);
  }

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(trips);
  }

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async {
    seatMapCallCount++;
    if (seatMapDelay > Duration.zero) {
      await Future<void>.delayed(seatMapDelay);
    }
    if (failure != null) return Error(failure!);
    if (queuedSeatMapResponses.isNotEmpty) {
      seats = queuedSeatMapResponses.removeAt(0);
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
    if (failure != null) return Error(failure!);
    return Success(hold!);
  }

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(confirmedBooking!);
  }

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async {
    return const Success([]);
  }

  @override
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async {
    return const Success([]);
  }

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async {
    return const Success(null);
  }

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async {
    return Success(
      PassengerTripPreference(
        originStopId: originStopId,
        destinationStopId: destinationStopId,
        originNameAr: 'ميت العامل',
        originNameEn: 'Mit El Amel',
        originLocalityAr: 'ميت العامل',
        originLocalityEn: 'Mit El Amel',
        destinationNameAr: 'بوابة حاسبات',
        destinationNameEn: 'Computers Gate',
        destinationLocalityAr: 'المنصورة',
        destinationLocalityEn: 'Mansoura',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) {
    return seatUpdatesController.stream.asBroadcastStream(
      onCancel: (_) => seatUpdatesCancelled = true,
    );
  }

  @override
  Stream<void> subscribeToPassengerBookingUpdates() {
    return const Stream.empty();
  }

  @override
  ResultFuture<void> cancelBooking(String bookingId) async {
    return const Success(null);
  }

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async {
    return const Success(null);
  }

  @override
  ResultFuture<List<RoundTripReturnOption>> getRoundTripReturnOptions({
    required String outboundTripId,
    required String outboundRouteStopId,
  }) async {
    return const Success([]);
  }

  @override
  ResultFuture<RoundTripBundleHold> createRoundTripBundleHold({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(
      RoundTripBundleHold(
        bundleHoldId: 'bundle_1',
        outboundHoldId: 'out_1',
        outboundTripId: outboundTripId,
        returnTripId: returnTripId,
        outboundSeatId: outboundSeatId,
        outboundSeatNumber: '1',
        outboundRouteStopId: outboundRouteStopId,
        returnRouteStopId: 'stop_ret_1',
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
    if (failure != null) return Error(failure!);
    return Success(
      RoundTripBundleHold(
        bundleHoldId: bundleHoldId,
        outboundHoldId: 'out_1',
        outboundTripId: 'out_trip',
        returnTripId: 'ret_trip',
        outboundSeatId: 'seat_1',
        returnSeatId: returnSeatId,
        outboundSeatNumber: '1',
        returnSeatNumber: '2',
        outboundRouteStopId: 'stop_1',
        returnRouteStopId: 'stop_ret_1',
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
    return const Success(null);
  }

  @override
  ResultFuture<RoundTripConfirmation> confirmRoundTripBundle({
    required String bundleHoldId,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(
      RoundTripConfirmation(
        bundleId: 'bundle_1',
        outboundBookingId: 'b_out_1',
        returnBookingId: 'b_ret_1',
        outboundTripId: 'out_trip',
        returnTripId: 'ret_trip',
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
    return const Success(
      RoundTripBundleContext(
        isRoundTripBundle: false,
        cancellationEligible: true,
      ),
    );
  }
}

class FakeTestStopwatch implements Stopwatch {
  int _elapsedMillis = 0;
  bool _running = false;

  void advance(Duration duration) {
    _elapsedMillis += duration.inMilliseconds;
  }

  @override
  Duration get elapsed => Duration(milliseconds: _elapsedMillis);

  @override
  int get elapsedMilliseconds => _elapsedMillis;

  @override
  int get elapsedMicroseconds => _elapsedMillis * 1000;

  @override
  int get elapsedTicks => _elapsedMillis;

  @override
  int get frequency => 1000;

  @override
  bool get isRunning => _running;

  @override
  void reset() {
    _elapsedMillis = 0;
  }

  @override
  void start() {
    _running = true;
  }

  @override
  void stop() {
    _running = false;
  }
}

void main() {
  late FakeBookingRepository fakeRepo;
  late GetRouteStopsUseCase getRouteStopsUseCase;
  late GetAvailableTripsUseCase getAvailableTripsUseCase;
  late GetTripSeatMapUseCase getTripSeatMapUseCase;
  late CreateBookingHoldUseCase createBookingHoldUseCase;
  late ReleaseBookingHoldUseCase releaseBookingHoldUseCase;
  late ConfirmBookingUseCase confirmBookingUseCase;
  late BookingCubit cubit;

  const sampleStopZone30 = RouteStop(
    routeStopId: 'rs-1',
    stopId: 'stop-1',
    stopOrder: 1,
    stopNameAr: 'كوبرى عزت',
    localityAr: 'ميت فضالة',
    fareZoneId: 'zone-30',
    farePoints: 30.0,
  );

  const sampleStopZone25 = RouteStop(
    routeStopId: 'rs-6',
    stopId: 'stop-6',
    stopOrder: 6,
    stopNameAr: 'القنطرة البيضة',
    localityAr: 'ميت العامل',
    fareZoneId: 'zone-25',
    farePoints: 25.0,
  );

  const sampleStopZone20 = RouteStop(
    routeStopId: 'rs-18',
    stopId: 'stop-18',
    stopOrder: 18,
    stopNameAr: 'ماركت المراعي',
    localityAr: 'برج النور الحمص',
    fareZoneId: 'zone-20',
    farePoints: 20.0,
  );

  final sampleTrip = TripOption(
    tripId: 'trip-1',
    routeId: 'route-1',
    direction: BookingDirection.outbound,
    originNameAr: 'محطة ميت فضالة',
    originNameEn: 'Meet Fadala',
    destinationNameAr: 'محطة المنصورة',
    destinationNameEn: 'Mansoura',
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(hours: 2)),
    farePoints: 25.0,
    availableSeatsCount: 12,
    status: 'scheduled',
  );

  final sampleSeat = const TripSeat(
    seatId: 'seat-1',
    seatNumber: '1A',
    rowIndex: 0,
    columnIndex: 0,
    seatType: 'standard',
    status: SeatAvailabilityStatus.available,
    isMine: false,
  );

  final sampleHold = BookingHold(
    holdId: 'hold-1',
    tripId: 'trip-1',
    seatId: 'seat-1',
    seatNumber: '1A',
    farePoints: 25.0,
    routeStopId: 'rs-6',
    stopName: 'القنطرة البيضة',
    locality: 'ميت العامل',
    fareZoneId: 'zone-25',
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    serverTime: DateTime.now(),
  );

  final sampleBooking = PassengerBooking(
    bookingId: 'booking-1',
    tripId: 'trip-1',
    direction: BookingDirection.outbound,
    originNameAr: 'محطة ميت فضالة',
    originNameEn: 'Meet Fadala',
    destinationNameAr: 'محطة المنصورة',
    destinationNameEn: 'Mansoura',
    serviceDate: DateTime.now(),
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(hours: 2)),
    seatNumber: '1A',
    farePoints: 25.0,
    routeStopId: 'rs-6',
    stopName: 'القنطرة البيضة',
    locality: 'ميت العامل',
    status: 'confirmed',
    qrToken: 'AMY_SAMPLE_QR_TOKEN_123',
    bookedAt: DateTime.now(),
  );

  setUp(() {
    fakeRepo = FakeBookingRepository();
    fakeRepo.routeStops = [
      sampleStopZone30,
      sampleStopZone25,
      sampleStopZone20,
    ];
    getRouteStopsUseCase = GetRouteStopsUseCase(fakeRepo);
    getAvailableTripsUseCase = GetAvailableTripsUseCase(fakeRepo);
    getTripSeatMapUseCase = GetTripSeatMapUseCase(fakeRepo);
    createBookingHoldUseCase = CreateBookingHoldUseCase(fakeRepo);
    releaseBookingHoldUseCase = ReleaseBookingHoldUseCase(fakeRepo);
    confirmBookingUseCase = ConfirmBookingUseCase(fakeRepo);

    cubit = BookingCubit(
      getRouteStopsUseCase: getRouteStopsUseCase,
      getAvailableTripsUseCase: getAvailableTripsUseCase,
      getTripSeatMapUseCase: getTripSeatMapUseCase,
      createBookingHoldUseCase: createBookingHoldUseCase,
      releaseBookingHoldUseCase: releaseBookingHoldUseCase,
      confirmBookingUseCase: confirmBookingUseCase,
      bookingRepository: fakeRepo,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state has default step direction and outbound direction', () {
    expect(cubit.state.currentStep, BookingStep.direction);
    expect(cubit.state.selectedDirection, BookingDirection.outbound);
    expect(cubit.state.availableTrips, isEmpty);
    expect(cubit.state.seats, isEmpty);
  });

  test('setDirection updates direction and reloads route stops', () async {
    fakeRepo.routeStops = [sampleStopZone30];

    cubit.setDirection(BookingDirection.returnTrip);
    expect(cubit.state.selectedDirection, BookingDirection.returnTrip);
    expect(cubit.state.currentStep, BookingStep.direction);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.routeStops, contains(sampleStopZone30));
  });

  test('proceedToBoardingStop advances step to boardingStop', () {
    cubit.proceedToBoardingStop();
    expect(cubit.state.currentStep, BookingStep.boardingStop);
  });

  test(
    'selectRouteStop sets stop and advances step to departureTime and loads trips',
    () async {
      fakeRepo.trips = [sampleTrip];

      cubit.selectRouteStop(sampleStopZone25);

      expect(cubit.state.selectedRouteStop, sampleStopZone25);
      expect(cubit.state.currentStep, BookingStep.departureTime);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.availableTrips, contains(sampleTrip));
      expect(cubit.state.status, BookingStatus.tripsLoaded);
    },
  );

  test('selectTrip loads seat map and advances step to seatMap', () async {
    fakeRepo.seats = [sampleSeat];

    cubit.selectTrip(sampleTrip);

    expect(cubit.state.selectedTrip, sampleTrip);
    expect(cubit.state.currentStep, BookingStep.seatMap);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.seats, contains(sampleSeat));
    expect(cubit.state.status, BookingStatus.seatMapLoaded);
  });

  test(
    'no initial trip seat state row is required for active seat map subscription',
    () async {
      fakeRepo.seats = [sampleSeat];

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.seats, contains(sampleSeat));
      expect(fakeRepo.seatMapCallCount, 1);
      expect(fakeRepo.seatUpdatesController.hasListener, isTrue);
    },
  );

  test(
    'trip seat state insert event refreshes seats without manual reload',
    () async {
      fakeRepo.seats = [sampleSeat];

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.seats.single.status, SeatAvailabilityStatus.available);

      final remotelyHeldSeat = TripSeat(
        seatId: sampleSeat.seatId,
        seatNumber: sampleSeat.seatNumber,
        rowIndex: sampleSeat.rowIndex,
        columnIndex: sampleSeat.columnIndex,
        seatType: sampleSeat.seatType,
        status: SeatAvailabilityStatus.held,
        isMine: false,
      );
      fakeRepo.seats = [remotelyHeldSeat];
      fakeRepo.seatUpdatesController.add(null);
      await pumpEventQueue();

      expect(cubit.state.seats.single.status, SeatAvailabilityStatus.held);
    },
  );

  test(
    'trip seat state revision update refreshes seats without manual reload',
    () async {
      fakeRepo.seats = [sampleSeat];

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final remotelyBookedSeat = TripSeat(
        seatId: sampleSeat.seatId,
        seatNumber: sampleSeat.seatNumber,
        rowIndex: sampleSeat.rowIndex,
        columnIndex: sampleSeat.columnIndex,
        seatType: sampleSeat.seatType,
        status: SeatAvailabilityStatus.booked,
        isMine: false,
      );
      fakeRepo.seats = [remotelyBookedSeat];
      fakeRepo.seatUpdatesController.add(null);
      await pumpEventQueue();

      expect(cubit.state.seats.single.status, SeatAvailabilityStatus.booked);
    },
  );

  test(
    'rapid trip seat state events coalesce without stale seat map overwrite',
    () async {
      fakeRepo.seats = [sampleSeat];

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final heldSeat = TripSeat(
        seatId: sampleSeat.seatId,
        seatNumber: sampleSeat.seatNumber,
        rowIndex: sampleSeat.rowIndex,
        columnIndex: sampleSeat.columnIndex,
        seatType: sampleSeat.seatType,
        status: SeatAvailabilityStatus.held,
        isMine: false,
      );
      final bookedSeat = TripSeat(
        seatId: sampleSeat.seatId,
        seatNumber: sampleSeat.seatNumber,
        rowIndex: sampleSeat.rowIndex,
        columnIndex: sampleSeat.columnIndex,
        seatType: sampleSeat.seatType,
        status: SeatAvailabilityStatus.booked,
        isMine: false,
      );

      fakeRepo.seatMapDelay = const Duration(milliseconds: 20);
      fakeRepo.queuedSeatMapResponses = [
        [heldSeat],
        [bookedSeat],
      ];

      fakeRepo.seatUpdatesController.add(null);
      fakeRepo.seatUpdatesController.add(null);
      fakeRepo.seatUpdatesController.add(null);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(fakeRepo.seatMapCallCount, 3);
      expect(cubit.state.seats.single.status, SeatAvailabilityStatus.booked);
    },
  );

  test('trip seat state subscription is cancelled on cubit close', () async {
    fakeRepo.seats = [sampleSeat];

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.close();

    expect(fakeRepo.seatUpdatesCancelled, isTrue);
  });

  test(
    'selectSeatAndHold on available seat calls createBookingHold and starts hold timer',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.selectSeatAndHold(sampleSeat);

      expect(cubit.state.activeHold, sampleHold);
      expect(cubit.state.selectedSeat, sampleSeat);
      expect(cubit.state.status, BookingStatus.seatHeld);
      expect(cubit.state.holdSecondsRemaining, inInclusiveRange(290, 300));
    },
  );

  test(
    'selectSeatAndHold fails with InsufficientPoints failure and reports error',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.failure = const ServerFailure(message: 'INSUFFICIENT_POINTS');

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.selectSeatAndHold(sampleSeat);

      expect(cubit.state.activeHold, isNull);
      expect(cubit.state.status, BookingStatus.error);
      expect(cubit.state.errorMessage, 'INSUFFICIENT_POINTS');
    },
  );

  test(
    'confirmBooking succeeds, marks step as success and stores confirmedBooking',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;
      fakeRepo.confirmedBooking = sampleBooking;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      expect(cubit.state.currentStep, BookingStep.review);

      await cubit.confirmBooking();

      expect(cubit.state.currentStep, BookingStep.success);
      expect(cubit.state.status, BookingStatus.confirmed);
      expect(cubit.state.confirmedBooking, sampleBooking);
    },
  );

  test(
    'C & I. HoldExpiredFailure during confirm cancels timer, clears hold, navigates to seatMap, and refreshes seat map',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;
      fakeRepo.failure = null;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      expect(cubit.state.currentStep, BookingStep.review);
      expect(cubit.state.activeHold, isNotNull);
      expect(cubit.state.selectedSeat, sampleSeat);

      final initialSeatMapCalls = fakeRepo.seatMapCallCount;

      // Fail with HoldExpiredFailure
      fakeRepo.failure = const HoldExpiredFailure();
      await cubit.confirmBooking();

      expect(cubit.state.currentStep, BookingStep.seatMap);
      expect(cubit.state.status, BookingStatus.error);
      expect(cubit.state.activeHold, isNull);
      expect(cubit.state.selectedSeat, isNull);
      expect(cubit.state.holdSecondsRemaining, 0);
      expect(cubit.state.errorMessage, contains('seat hold has expired'));
      // Verifies seat-map refresh happens after HoldExpiredFailure (I)
      expect(fakeRepo.seatMapCallCount, greaterThan(initialSeatMapCalls));
    },
  );

  test(
    'D. After HoldExpiredFailure, advancing time does not resurrect seatHeld or wipe error',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      fakeRepo.failure = const HoldExpiredFailure();
      await cubit.confirmBooking();

      expect(cubit.state.status, BookingStatus.error);
      expect(cubit.state.errorMessage, contains('seat hold has expired'));

      // Wait 1.5 seconds to ensure any residual periodic timer would have ticked
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      // Error must NOT be wiped and status must NOT be seatHeld
      expect(cubit.state.status, BookingStatus.error);
      expect(cubit.state.errorMessage, contains('seat hold has expired'));
      expect(cubit.state.activeHold, isNull);
    },
  );

  test(
    'G. Natural countdown reaching zero clears hold, resets to seatMap, and prevents confirmation',
    () async {
      // Hold with 1 second remaining
      final expiringHold = BookingHold(
        holdId: 'hold-short',
        tripId: 'trip-1',
        seatId: 'seat-7',
        seatNumber: '7',
        farePoints: 30.0,
        expiresAt: DateTime.now().add(const Duration(seconds: 1)),
        serverTime: DateTime.now(),
        initialRemainingSeconds: 1,
      );

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = expiringHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      // Wait for countdown to expire naturally
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(cubit.state.currentStep, BookingStep.seatMap);
      expect(cubit.state.activeHold, isNull);
      expect(cubit.state.holdSecondsRemaining, 0);

      // Attempting to confirm without active hold does nothing
      await cubit.confirmBooking();
      expect(cubit.state.status, isNot(BookingStatus.confirmed));
    },
  );

  test(
    'A. Server returns remaining_seconds = 231 -> countdown starts at 231',
    () async {
      final hold231 = BookingHold(
        holdId: 'hold-231',
        tripId: 'trip-1',
        seatId: 'seat-7',
        seatNumber: '7',
        farePoints: 30.0,
        expiresAt: DateTime.now().add(const Duration(seconds: 231)),
        serverTime: DateTime.now(),
        initialRemainingSeconds: 231,
      );

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = hold231;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);

      expect(cubit.state.status, BookingStatus.seatHeld);
      expect(cubit.state.holdSecondsRemaining, 231);
    },
  );

  test(
    'B. expires_at is intentionally inconsistent with local device wall clock -> countdown still starts from 231',
    () async {
      final inconsistentHold = BookingHold(
        holdId: 'hold-past-expires',
        tripId: 'trip-1',
        seatId: 'seat-7',
        seatNumber: '7',
        farePoints: 30.0,
        expiresAt: DateTime.now().subtract(const Duration(hours: 5)),
        serverTime: DateTime.now().subtract(
          const Duration(hours: 5, seconds: 231),
        ),
        initialRemainingSeconds: 231,
      );

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = inconsistentHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);

      expect(cubit.state.status, BookingStatus.seatHeld);
      expect(cubit.state.holdSecondsRemaining, 231);
      expect(cubit.state.activeHold, isNotNull);
    },
  );

  test(
    'C. Simulated wall-clock change / monotonic elapsed time must not reset or increase countdown',
    () async {
      final fakeStopwatch = FakeTestStopwatch();
      cubit.stopwatchFactory = () => fakeStopwatch;

      final hold231 = BookingHold(
        holdId: 'hold-monotonic',
        tripId: 'trip-1',
        seatId: 'seat-7',
        seatNumber: '7',
        farePoints: 30.0,
        expiresAt: DateTime.now().add(const Duration(seconds: 231)),
        serverTime: DateTime.now(),
        initialRemainingSeconds: 231,
      );

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = hold231;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);
      expect(cubit.state.holdSecondsRemaining, 231);

      // Advance monotonic elapsed time by 31 seconds
      fakeStopwatch.advance(const Duration(seconds: 31));

      // Simulate app resume resync
      cubit.resyncHoldOnResume();

      // Countdown strictly decreased to 200, did not reset to 300 or gain time
      expect(cubit.state.holdSecondsRemaining, 200);

      // Advancing further by 100 seconds
      fakeStopwatch.advance(const Duration(seconds: 100));
      cubit.resyncHoldOnResume();
      expect(cubit.state.holdSecondsRemaining, 100);
    },
  );

  test('D. Elapsed runtime decreases countdown correctly', () async {
    final hold10 = BookingHold(
      holdId: 'hold-runtime',
      tripId: 'trip-1',
      seatId: 'seat-7',
      seatNumber: '7',
      farePoints: 30.0,
      expiresAt: DateTime.now().add(const Duration(seconds: 10)),
      serverTime: DateTime.now(),
      initialRemainingSeconds: 10,
    );

    fakeRepo.seats = [sampleSeat];
    fakeRepo.hold = hold10;

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.selectSeatAndHold(sampleSeat);
    expect(cubit.state.holdSecondsRemaining, 10);

    // Wait 1.1s of real runtime for periodic timer to tick
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(cubit.state.holdSecondsRemaining, inInclusiveRange(8, 9));
  });

  test(
    'E. Countdown reaches zero once -> hold invalid lifecycle executes',
    () async {
      final expiringHold = BookingHold(
        holdId: 'hold-zero-lifecycle',
        tripId: 'trip-1',
        seatId: 'seat-7',
        seatNumber: '7',
        farePoints: 30.0,
        expiresAt: DateTime.now().add(const Duration(seconds: 1)),
        serverTime: DateTime.now(),
        initialRemainingSeconds: 1,
      );

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = expiringHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      // Wait for countdown to reach zero
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      expect(cubit.state.currentStep, BookingStep.seatMap);
      expect(cubit.state.activeHold, isNull);
      expect(cubit.state.selectedSeat, isNull);
      expect(cubit.state.holdSecondsRemaining, 0);
      expect(cubit.state.status, BookingStatus.error);
      expect(cubit.state.errorMessage, 'HOLD_EXPIRED');

      // Attempting to confirm without active hold fails/is blocked
      await cubit.confirmBooking();
      expect(cubit.state.status, isNot(BookingStatus.confirmed));
    },
  );

  test(
    'H. Back navigation releases hold, resets remaining to 0, and avoids duplicate timer on re-entry',
    () async {
      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await cubit.selectSeatAndHold(sampleSeat);
      cubit.proceedToReview();

      expect(cubit.state.activeHold, isNotNull);

      cubit.backToSeatMap();

      expect(cubit.state.currentStep, BookingStep.seatMap);
      expect(cubit.state.activeHold, isNull);
      expect(cubit.state.selectedSeat, isNull);
      expect(cubit.state.holdSecondsRemaining, 0);
    },
  );

  test('backToTrips resets state back to departureTime step', () async {
    fakeRepo.seats = [sampleSeat];
    fakeRepo.hold = sampleHold;

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.selectSeatAndHold(sampleSeat);

    cubit.backToTrips();

    expect(cubit.state.currentStep, BookingStep.departureTime);
    expect(cubit.state.selectedTrip, isNull);
    expect(cubit.state.activeHold, isNull);
  });

  test(
    'loadRouteStops populates stops and defaults to first stop (Zone 30: 30 pts)',
    () async {
      await cubit.loadRouteStops();

      expect(cubit.state.routeStops.length, 3);
      expect(cubit.state.selectedRouteStop, sampleStopZone30);
      expect(cubit.state.selectedRouteStop!.farePoints, 30.0);
    },
  );

  test(
    'selectRouteStop updates selected stop to Zone 25 (25 pts) and reloads trips',
    () async {
      await cubit.loadRouteStops();
      fakeRepo.trips = [sampleTrip];

      cubit.selectRouteStop(sampleStopZone25);

      expect(cubit.state.selectedRouteStop, sampleStopZone25);
      expect(cubit.state.selectedRouteStop!.farePoints, 25.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.availableTrips, contains(sampleTrip));
    },
  );

  test(
    'selectRouteStop updates selected stop to Zone 20 (20 pts) and reloads trips',
    () async {
      await cubit.loadRouteStops();
      fakeRepo.trips = [sampleTrip];

      cubit.selectRouteStop(sampleStopZone20);

      expect(cubit.state.selectedRouteStop, sampleStopZone20);
      expect(cubit.state.selectedRouteStop!.farePoints, 20.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.availableTrips, contains(sampleTrip));
    },
  );

  test(
    'selectSeatAndHold passes selectedRouteStop id to backend hold RPC',
    () async {
      await cubit.loadRouteStops();
      cubit.selectRouteStop(sampleStopZone25);

      fakeRepo.seats = [sampleSeat];
      fakeRepo.hold = sampleHold;

      cubit.selectTrip(sampleTrip);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await cubit.selectSeatAndHold(sampleSeat);

      expect(cubit.state.activeHold?.farePoints, 25.0);
      expect(cubit.state.activeHold?.routeStopId, 'rs-6');
    },
  );
}
