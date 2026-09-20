import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_state.dart';

class MockBookingRepository implements BookingRepository {
  int confirmBookingCallCount = 0;
  int releaseBookingHoldCallCount = 0;
  int createBookingHoldCallCount = 0;

  Failure? confirmFailure;
  BookingHold? holdToReturn;
  PassengerBooking? bookingToReturn;

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async => const Success([]);

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) async => const Success([]);

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async =>
      const Success([]);

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) async {
    createBookingHoldCallCount++;
    return Success(holdToReturn!);
  }

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) async {
    releaseBookingHoldCallCount++;
    return const Success(null);
  }

  @override
  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  }) async {
    confirmBookingCallCount++;
    if (confirmFailure != null) {
      return Error(confirmFailure!);
    }
    return Success(bookingToReturn!);
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
  Stream<void> subscribeToTripSeatUpdates(String tripId) =>
      const Stream.empty();

  @override
  Stream<void> subscribeToPassengerBookingUpdates() => const Stream.empty();

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async => throw UnimplementedError();

  @override
  ResultFuture<void> cancelBooking(String bookingId) async =>
      const Success(null);

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async => const Success(null);

  @override
  ResultFuture<List<RoundTripReturnOption>> getRoundTripReturnOptions({
    required String outboundTripId,
    required String outboundRouteStopId,
  }) async => const Success([]);

  @override
  ResultFuture<RoundTripBundleHold> createRoundTripBundleHold({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  }) => throw UnimplementedError();

  @override
  ResultFuture<RoundTripBundleHold> setRoundTripReturnSeat({
    required String bundleHoldId,
    required String returnSeatId,
  }) => throw UnimplementedError();

  @override
  ResultFuture<void> releaseRoundTripBundleHold({
    required String bundleHoldId,
  }) async => const Success(null);

  @override
  ResultFuture<RoundTripConfirmation> confirmRoundTripBundle({
    required String bundleHoldId,
  }) => throw UnimplementedError();

  @override
  ResultFuture<RoundTripBundleContext> getRoundTripBundleContext({
    required String bookingId,
  }) async => const Success(
    RoundTripBundleContext(
      isRoundTripBundle: false,
      cancellationEligible: true,
    ),
  );
}

void main() {
  late MockBookingRepository mockRepo;
  late BookingCubit cubit;

  final sampleTrip = TripOption(
    tripId: 'trip-123',
    routeId: 'route-1',
    departureTime: '08:00',
    departureAt: DateTime.now(),
    originNameAr: 'ميت العامل',
    originNameEn: 'Mit El Amel',
    destinationNameAr: 'المنصورة',
    destinationNameEn: 'Mansoura',
    availableSeatsCount: 20,
    farePoints: 25.0,
    status: 'scheduled',
    direction: BookingDirection.outbound,
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

  final sampleHold1 = BookingHold(
    holdId: 'hold-1',
    tripId: 'trip-123',
    seatId: 'seat-1',
    seatNumber: '1',
    farePoints: 25.0,
    expiresAt: DateTime.now().add(const Duration(seconds: 300)),
    serverTime: DateTime.now(),
  );

  final sampleHold2 = BookingHold(
    holdId: 'hold-2',
    tripId: 'trip-123',
    seatId: 'seat-2',
    seatNumber: '2',
    farePoints: 25.0,
    expiresAt: DateTime.now().add(const Duration(seconds: 300)),
    serverTime: DateTime.now(),
  );

  final sampleBooking = PassengerBooking(
    bookingId: 'bkg-123',
    tripId: 'trip-123',
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
    qrToken: 'AMY-123456',
    bookedAt: DateTime.now(),
  );

  setUp(() {
    mockRepo = MockBookingRepository();
    cubit = BookingCubit(
      getRouteStopsUseCase: GetRouteStopsUseCase(mockRepo),
      getAvailableTripsUseCase: GetAvailableTripsUseCase(mockRepo),
      getTripSeatMapUseCase: GetTripSeatMapUseCase(mockRepo),
      createBookingHoldUseCase: CreateBookingHoldUseCase(mockRepo),
      releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(mockRepo),
      confirmBookingUseCase: ConfirmBookingUseCase(mockRepo),
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('Booking Flow Stability & Timer Lifecycle', () {
    test(
      '1 & 6. Error listener filter fires once and ignores countdown ticks',
      () {
        bool shouldListen(BookingState prev, BookingState curr) {
          final hasNewError =
              curr.errorMessage != null &&
              curr.errorMessage!.isNotEmpty &&
              (curr.errorMessage != prev.errorMessage ||
                  curr.status != prev.status);
          final hasNewAlert =
              curr.autoTripAlert != null &&
              curr.autoTripAlert!.isNotEmpty &&
              curr.autoTripAlert != prev.autoTripAlert;
          return hasNewError || hasNewAlert;
        }

        final stateReady = BookingState(
          status: BookingStatus.seatHeld,
          holdSecondsRemaining: 46,
          activeHold: sampleHold1,
        );

        final stateError = stateReady.copyWith(
          status: BookingStatus.error,
          errorMessage: 'Something went wrong',
        );

        // First transition into error -> listenWhen MUST return true
        expect(shouldListen(stateReady, stateError), isTrue);

        // Countdown tick: holdSecondsRemaining decreases 46 -> 45
        // With our fix, countdown clears error and restores stable status
        final stateTickFixed = stateError.copyWith(
          holdSecondsRemaining: 45,
          status: BookingStatus.seatHeld,
          clearError: true,
        );
        expect(shouldListen(stateError, stateTickFixed), isFalse);

        // Even if previous tick was countdown only without clearing, same errorMessage is filtered
        final stateTickSameError = stateError.copyWith(
          holdSecondsRemaining: 45,
        );
        expect(shouldListen(stateError, stateTickSameError), isFalse);
      },
    );

    test(
      '2. Error dialog does not re-open every second because clearError consumes it',
      () async {
        mockRepo.confirmFailure = const ServerFailure(
          message: 'PostgrestException: enum error',
        );
        mockRepo.holdToReturn = sampleHold1;

        // Seed state with trip and active hold
        cubit.selectTrip(sampleTrip);
        cubit.emit(
          cubit.state.copyWith(
            selectedTrip: sampleTrip,
            selectedSeat: sampleSeat1,
            activeHold: sampleHold1,
            status: BookingStatus.seatHeld,
          ),
        );

        // Call confirmBooking which fails
        await cubit.confirmBooking();

        expect(cubit.state.status, BookingStatus.error);
        expect(cubit.state.errorMessage, contains('PostgrestException'));

        // Consumer consumes the error
        cubit.clearError();

        expect(cubit.state.errorMessage, isNull);
        expect(cubit.state.status, BookingStatus.seatHeld);
      },
    );

    test(
      '3. Back from Review cancels old countdown and releases hold appropriately',
      () async {
        mockRepo.holdToReturn = sampleHold1;
        cubit.selectTrip(sampleTrip);
        await cubit.selectSeatAndHold(sampleSeat1);

        expect(cubit.state.activeHold, isNotNull);
        expect(cubit.state.selectedSeat, sampleSeat1);

        cubit.proceedToReview();
        expect(cubit.state.currentStep, BookingStep.review);

        // User taps Back to choose another seat
        cubit.backToSeatMap();

        expect(cubit.state.currentStep, BookingStep.seatMap);
        expect(cubit.state.activeHold, isNull);
        expect(cubit.state.selectedSeat, isNull);
        expect(cubit.state.holdSecondsRemaining, 0);
        expect(mockRepo.releaseBookingHoldCallCount, 1);
      },
    );

    test(
      '4. Selecting another seat releases old hold and does not stack timers',
      () async {
        mockRepo.holdToReturn = sampleHold1;
        cubit.selectTrip(sampleTrip);
        await cubit.selectSeatAndHold(sampleSeat1);

        expect(cubit.state.activeHold?.seatId, 'seat-1');

        // Now user chooses Seat 2
        mockRepo.holdToReturn = sampleHold2;
        await cubit.selectSeatAndHold(sampleSeat2);

        expect(mockRepo.releaseBookingHoldCallCount, 1);
        expect(cubit.state.activeHold?.seatId, 'seat-2');
        expect(cubit.state.selectedSeat?.seatId, 'seat-2');
      },
    );

    test(
      '5. Confirm button double tap produces exactly ONE confirm call',
      () async {
        mockRepo.holdToReturn = sampleHold1;
        mockRepo.bookingToReturn = sampleBooking;

        cubit.selectTrip(sampleTrip);
        await cubit.selectSeatAndHold(sampleSeat1);
        cubit.proceedToReview();

        // Double tap confirmBooking concurrently
        final future1 = cubit.confirmBooking();
        final future2 = cubit.confirmBooking();

        await Future.wait([future1, future2]);

        expect(mockRepo.confirmBookingCallCount, 1);
        expect(cubit.state.status, BookingStatus.confirmed);
      },
    );

    test('7. Cubit close cleanly cancels active hold timer', () async {
      mockRepo.holdToReturn = sampleHold1;
      cubit.selectTrip(sampleTrip);
      await cubit.selectSeatAndHold(sampleSeat1);

      expect(cubit.state.activeHold, isNotNull);

      // Closing cubit should not throw and should cancel internal timer
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });

    test(
      '8. Compact toString formatting does not dump 34 stops or 28 seats',
      () {
        final stateWithFullLists = BookingState(
          currentStep: BookingStep.review,
          status: BookingStatus.seatHeld,
          selectedTrip: sampleTrip,
          selectedSeat: sampleSeat1,
          holdSecondsRemaining: 45,
          routeStops: List.generate(
            34,
            (i) => RouteStop(
              routeStopId: 'rs-$i',
              stopId: 'stop-$i',
              stopOrder: i,
              stopNameAr: 'محطة $i',
              localityAr: 'منطقة $i',
              fareZoneId: 'fz-1',
              farePoints: 25.0,
            ),
          ),
          seats: List.generate(
            28,
            (i) => TripSeat(
              seatId: 'seat-$i',
              seatNumber: '$i',
              rowIndex: i ~/ 4,
              columnIndex: i % 4,
              seatType: 'standard',
              status: SeatAvailabilityStatus.available,
              isMine: false,
            ),
          ),
        );

        final stateString = stateWithFullLists.toString();

        expect(stateString, contains('BookingState('));
        expect(stateString, contains('step: review'));
        expect(stateString, contains('status: seatHeld'));
        expect(stateString, contains('seat: 1'));
        expect(stateString, contains('holdRemaining: 45s'));
        // Must NOT contain 34 stops or 28 seats dumped
        expect(stateString, isNot(contains('محطة 33')));
        expect(stateString, isNot(contains('seat-27')));
      },
    );
  });
}
