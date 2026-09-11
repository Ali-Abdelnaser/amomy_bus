import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_state.dart';

class FakeBookingRepository implements BookingRepository {
  List<TripOption> trips = [];
  List<TripSeat> seats = [];
  BookingHold? hold;
  PassengerBooking? confirmedBooking;
  Failure? failure;

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    required DateTime date,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(trips);
  }

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async {
    if (failure != null) return Error(failure!);
    return Success(seats);
  }

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
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
  ResultFuture<PassengerBooking> confirmBooking({required String holdId}) async {
    if (failure != null) return Error(failure!);
    return Success(confirmedBooking!);
  }

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async {
    return const Success([]);
  }

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) {
    return const Stream.empty();
  }
}

void main() {
  late FakeBookingRepository fakeRepo;
  late GetAvailableTripsUseCase getAvailableTripsUseCase;
  late GetTripSeatMapUseCase getTripSeatMapUseCase;
  late CreateBookingHoldUseCase createBookingHoldUseCase;
  late ReleaseBookingHoldUseCase releaseBookingHoldUseCase;
  late ConfirmBookingUseCase confirmBookingUseCase;
  late BookingCubit cubit;

  final sampleTrip = TripOption(
    tripId: 'trip-1',
    routeId: 'route-1',
    direction: BookingDirection.outbound,
    originNameAr: 'محطة أكتوبر',
    originNameEn: 'October Station',
    destinationNameAr: 'محطة التجمع',
    destinationNameEn: 'Tagamoa Station',
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(days: 1, hours: 8)),
    farePoints: 50.0,
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
    farePoints: 50.0,
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    serverTime: DateTime.now(),
  );

  final sampleBooking = PassengerBooking(
    bookingId: 'booking-1',
    tripId: 'trip-1',
    direction: BookingDirection.outbound,
    originNameAr: 'محطة أكتوبر',
    originNameEn: 'October Station',
    destinationNameAr: 'محطة التجمع',
    destinationNameEn: 'Tagamoa Station',
    serviceDate: DateTime.now().add(const Duration(days: 1)),
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(days: 1, hours: 8)),
    seatNumber: '1A',
    farePoints: 50.0,
    status: 'confirmed',
    qrToken: 'AMY_SAMPLE_QR_TOKEN_123',
    bookedAt: DateTime.now(),
  );

  setUp(() {
    fakeRepo = FakeBookingRepository();
    getAvailableTripsUseCase = GetAvailableTripsUseCase(fakeRepo);
    getTripSeatMapUseCase = GetTripSeatMapUseCase(fakeRepo);
    createBookingHoldUseCase = CreateBookingHoldUseCase(fakeRepo);
    releaseBookingHoldUseCase = ReleaseBookingHoldUseCase(fakeRepo);
    confirmBookingUseCase = ConfirmBookingUseCase(fakeRepo);

    cubit = BookingCubit(
      getAvailableTripsUseCase: getAvailableTripsUseCase,
      getTripSeatMapUseCase: getTripSeatMapUseCase,
      createBookingHoldUseCase: createBookingHoldUseCase,
      releaseBookingHoldUseCase: releaseBookingHoldUseCase,
      confirmBookingUseCase: confirmBookingUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state has default step directionAndDate and outbound direction', () {
    expect(cubit.state.currentStep, BookingStep.directionAndDate);
    expect(cubit.state.selectedDirection, BookingDirection.outbound);
    expect(cubit.state.availableTrips, isEmpty);
    expect(cubit.state.seats, isEmpty);
  });

  test('setDirection updates direction and triggers loadAvailableTrips', () async {
    fakeRepo.trips = [sampleTrip];

    cubit.setDirection(BookingDirection.returnTrip);
    expect(cubit.state.selectedDirection, BookingDirection.returnTrip);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.availableTrips, contains(sampleTrip));
    expect(cubit.state.status, BookingStatus.tripsLoaded);
  });

  test('setDate updates selected date and reloads trips', () async {
    fakeRepo.trips = [sampleTrip];
    final nextDate = DateTime.now().add(const Duration(days: 2));

    cubit.setDate(nextDate);
    expect(cubit.state.selectedDate.day, nextDate.day);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.availableTrips, contains(sampleTrip));
  });

  test('selectTrip loads seat map and advances step to seatMap', () async {
    fakeRepo.seats = [sampleSeat];

    cubit.selectTrip(sampleTrip);

    expect(cubit.state.selectedTrip, sampleTrip);
    expect(cubit.state.currentStep, BookingStep.seatMap);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.state.seats, contains(sampleSeat));
    expect(cubit.state.status, BookingStatus.seatMapLoaded);
  });

  test('selectSeatAndHold on available seat calls createBookingHold and starts hold timer', () async {
    fakeRepo.seats = [sampleSeat];
    fakeRepo.hold = sampleHold;

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await cubit.selectSeatAndHold(sampleSeat);

    expect(cubit.state.activeHold, sampleHold);
    expect(cubit.state.selectedSeat, sampleSeat);
    expect(cubit.state.status, BookingStatus.seatHeld);
    expect(cubit.state.holdSecondsRemaining, inInclusiveRange(290, 300));
  });

  test('selectSeatAndHold fails with InsufficientPoints failure and reports error', () async {
    fakeRepo.seats = [sampleSeat];
    fakeRepo.failure = const ServerFailure(message: 'INSUFFICIENT_POINTS');

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    await cubit.selectSeatAndHold(sampleSeat);

    expect(cubit.state.activeHold, isNull);
    expect(cubit.state.status, BookingStatus.error);
    expect(cubit.state.errorMessage, 'INSUFFICIENT_POINTS');
  });

  test('confirmBooking succeeds, marks step as success and stores confirmedBooking', () async {
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
  });

  test('backToTrips resets state back to directionAndDate step', () async {
    fakeRepo.seats = [sampleSeat];
    fakeRepo.hold = sampleHold;

    cubit.selectTrip(sampleTrip);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await cubit.selectSeatAndHold(sampleSeat);

    cubit.backToTrips();

    expect(cubit.state.currentStep, BookingStep.directionAndDate);
    expect(cubit.state.selectedTrip, isNull);
    expect(cubit.state.activeHold, isNull);
  });
}
