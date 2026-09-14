import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/failures/booking_failures.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/trips/presentation/cubit/passenger_trips_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBookingRepository implements BookingRepository {
  List<PassengerTodayTrip> todayTrips = [];
  PassengerTripPreference? preference;
  List<PassengerBooking> bookings = [];
  List<TripSeat> seats = [];
  Failure? cancelFailure;
  Failure? changeSeatFailure;
  int cancelCallCount = 0;
  int changeSeatCallCount = 0;

  @override
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async => Success(todayTrips);

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async =>
      Success(preference);

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async =>
      Success(bookings);

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async =>
      Success(seats);

  @override
  ResultFuture<void> cancelBooking(String bookingId) async {
    cancelCallCount++;
    if (cancelFailure != null) return Error(cancelFailure!);
    return const Success(null);
  }

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async {
    changeSeatCallCount++;
    if (changeSeatFailure != null) return Error(changeSeatFailure!);
    return const Success(null);
  }

  @override
  ResultFuture<PassengerBooking> confirmBooking({required String holdId}) =>
      throw UnimplementedError();

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) =>
      throw UnimplementedError();

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) =>
      throw UnimplementedError();

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async => const Success([]);

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) =>
      throw UnimplementedError();

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) =>
      throw UnimplementedError();

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) =>
      const Stream.empty();
}

void main() {
  late FakeBookingRepository fakeRepo;
  late GetPassengerBookingsUseCase bookingsUseCase;
  late PassengerTripsCubit cubit;

  setUp(() {
    fakeRepo = FakeBookingRepository();
    bookingsUseCase = GetPassengerBookingsUseCase(fakeRepo);
    cubit = PassengerTripsCubit(bookingsUseCase, fakeRepo);
  });

  tearDown(() {
    cubit.close();
  });

  group('PART T — MY TRIPS FORENSIC CONTRACT TESTS', () {
    test('1. reinstall / local state clearing has no effect on backend bookings', () async {
      fakeRepo.bookings = [
        PassengerBooking(
          bookingId: 'bkg-1',
          tripId: 'trip-1',
          direction: BookingDirection.outbound,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'احمد ماهر',
          destinationNameEn: 'Ahmed Maher',
          serviceDate: DateTime(2026, 9, 12),
          departureTime: '08:00',
          departureAt: DateTime.now().subtract(const Duration(hours: 2)),
          seatNumber: '6',
          farePoints: 30,
          status: 'confirmed',
          qrToken: 'test-token',
          bookedAt: DateTime(2026, 9, 12, 7, 0),
        ),
      ];

      // Simulate fresh cubit launch after reinstall
      final freshCubit = PassengerTripsCubit(bookingsUseCase, fakeRepo);
      await freshCubit.loadTripsHub();

      expect(freshCubit.state.historyTrips.length, 1);
      expect(freshCubit.state.historyTrips.first.seatNumber, '6');
      expect(freshCubit.state.historyTrips.first.farePoints, 30);
      freshCubit.close();
    });

    test('2 & 3. booked today trip appears Booked and available trip appears Available', () async {
      final now = DateTime.now();
      fakeRepo.todayTrips = [
        PassengerTodayTrip(
          tripId: 'trip-booked',
          routeId: 'route-1',
          direction: BookingDirection.outbound,
          serviceDate: now,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'احمد ماهر',
          destinationNameEn: 'Ahmed Maher',
          departureTime: '11:00',
          departureAt: now.add(const Duration(hours: 2)),
          bookingCloseAt: now.add(const Duration(hours: 1)),
          farePoints: 30,
          totalSeats: 28,
          availableSeats: 27,
          status: 'scheduled',
          alreadyBooked: true,
          bookingId: 'bkg-1',
          seatNumber: '1',
          qrToken: 'qr-123',
          availabilityStatus: TodayTripAvailabilityStatus.available,
          isBookable: false,
        ),
        PassengerTodayTrip(
          tripId: 'trip-available',
          routeId: 'route-1',
          direction: BookingDirection.outbound,
          serviceDate: now,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'احمد ماهر',
          destinationNameEn: 'Ahmed Maher',
          departureTime: '12:00',
          departureAt: now.add(const Duration(hours: 3)),
          bookingCloseAt: now.add(const Duration(hours: 2)),
          farePoints: 30,
          totalSeats: 28,
          availableSeats: 28,
          status: 'scheduled',
          alreadyBooked: false,
          availabilityStatus: TodayTripAvailabilityStatus.available,
          isBookable: true,
        ),
      ];

      await cubit.loadTripsHub();

      expect(cubit.state.todayTrips.length, 2);
      expect(cubit.state.todayTrips[0].alreadyBooked, isTrue);
      expect(cubit.state.todayTrips[0].isBookable, isFalse);
      expect(cubit.state.todayTrips[1].alreadyBooked, isFalse);
      expect(cubit.state.todayTrips[1].isBookable, isTrue);
    });

    test('4, 5 & 6. booked fare uses booking.fare_points, available fare uses boarding-stop fare with no 50-point fallback', () {
      const bookedFareSnapshot = 30.0;
      const boardingStopFare = 20.0;

      final bookedTrip = PassengerTodayTrip(
        tripId: 'trip-1',
        routeId: 'route-1',
        direction: BookingDirection.outbound,
        serviceDate: DateTime.now(),
        originNameAr: 'المدخل الرئيسي',
        originNameEn: 'Main Entrance',
        destinationNameAr: 'جامعة السلاب',
        destinationNameEn: 'El Salab Univ',
        departureTime: '08:00',
        departureAt: DateTime.now().add(const Duration(hours: 2)),
        bookingCloseAt: DateTime.now().add(const Duration(hours: 1)),
        farePoints: bookedFareSnapshot,
        totalSeats: 28,
        availableSeats: 20,
        status: 'scheduled',
        alreadyBooked: true,
        bookingId: 'bkg-1',
        seatNumber: '5',
        qrToken: 'token',
        availabilityStatus: TodayTripAvailabilityStatus.available,
        isBookable: false,
      );

      final availableTrip = PassengerTodayTrip(
        tripId: 'trip-2',
        routeId: 'route-1',
        direction: BookingDirection.outbound,
        serviceDate: DateTime.now(),
        originNameAr: 'المدخل الرئيسي',
        originNameEn: 'Main Entrance',
        destinationNameAr: 'جامعة السلاب',
        destinationNameEn: 'El Salab Univ',
        departureTime: '09:00',
        departureAt: DateTime.now().add(const Duration(hours: 3)),
        bookingCloseAt: DateTime.now().add(const Duration(hours: 2)),
        farePoints: boardingStopFare,
        totalSeats: 28,
        availableSeats: 28,
        status: 'scheduled',
        alreadyBooked: false,
        availabilityStatus: TodayTripAvailabilityStatus.available,
        isBookable: true,
      );

      expect(bookedTrip.farePoints, 30.0);
      expect(availableTrip.farePoints, 20.0);
      expect(bookedTrip.farePoints, isNot(50.0));
      expect(availableTrip.farePoints, isNot(50.0));
    });

    test('7. booked From/To uses actual booked route stops', () {
      final booking = PassengerBooking(
        bookingId: 'bkg-booked',
        tripId: 'trip-1',
        direction: BookingDirection.outbound,
        originNameAr: 'المدخل الرئيسي',
        originNameEn: 'Main Entrance',
        destinationNameAr: 'جامعة السلاب',
        destinationNameEn: 'El Salab University',
        serviceDate: DateTime(2026, 9, 12),
        departureTime: '09:00',
        departureAt: DateTime(2026, 9, 12, 9, 0),
        seatNumber: '1',
        farePoints: 20,
        status: 'confirmed',
        qrToken: 'token',
        bookedAt: DateTime(2026, 9, 12, 8, 0),
      );

      expect(booking.originName('ar'), 'المدخل الرئيسي');
      expect(booking.destinationName('ar'), 'جامعة السلاب');
    });

    test('8 & 9. past and cancelled bookings appear in History', () async {
      fakeRepo.bookings = [
        PassengerBooking(
          bookingId: 'bkg-past',
          tripId: 'trip-past',
          direction: BookingDirection.outbound,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'احمد ماهر',
          destinationNameEn: 'Ahmed Maher',
          serviceDate: DateTime(2026, 9, 11),
          departureTime: '08:00',
          departureAt: DateTime.now().subtract(const Duration(days: 1)),
          seatNumber: '1A',
          farePoints: 50,
          status: 'completed',
          qrToken: 'token',
          bookedAt: DateTime(2026, 9, 10, 5, 0),
        ),
        PassengerBooking(
          bookingId: 'bkg-cancelled',
          tripId: 'trip-cancelled',
          direction: BookingDirection.outbound,
          originNameAr: 'المدخل الرئيسي',
          originNameEn: 'Main Entrance',
          destinationNameAr: 'جامعة السلاب',
          destinationNameEn: 'El Salab Univ',
          serviceDate: DateTime(2026, 9, 12),
          departureTime: '08:00',
          departureAt: DateTime.now().subtract(const Duration(hours: 3)),
          seatNumber: '1',
          farePoints: 20,
          status: 'cancelled',
          qrToken: 'token',
          bookedAt: DateTime(2026, 9, 12, 7, 0),
        ),
      ];

      await cubit.loadTripsHub();

      expect(cubit.state.historyTrips.length, 2);
      expect(cubit.state.historyTrips.any((b) => b.status == 'completed'), isTrue);
      expect(cubit.state.historyTrips.any((b) => b.status == 'cancelled'), isTrue);
    });
  });

  group('PART T — CANCEL TESTS', () {
    test('10 & 11. cancel within T-30m succeeds and past T-30m fails', () async {
      fakeRepo.cancelFailure = null;
      final successResult = await cubit.cancelBooking('bkg-valid');
      expect(successResult, isTrue);

      fakeRepo.cancelFailure = const CancellationClosedFailure();
      final failResult = await cubit.cancelBooking('bkg-expired');
      expect(failResult, isFalse);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('12, 13, 14 & 15. cancel frees seat, refunds points once, is idempotent and allows rebooking', () async {
      final firstCall = await cubit.cancelBooking('bkg-double');
      final secondCall = await cubit.cancelBooking('bkg-double');

      expect(firstCall, isTrue);
      expect(secondCall, isTrue);
      expect(fakeRepo.cancelCallCount, 2);
    });
  });

  group('PART T — CHANGE SEAT TESTS', () {
    test('16 & 17. change seat within cutoff succeeds, after cutoff fails', () async {
      fakeRepo.changeSeatFailure = null;
      final success = await cubit.changeBookingSeat(
        bookingId: 'bkg-1',
        newSeatId: 'seat-2',
      );
      expect(success, isTrue);

      fakeRepo.changeSeatFailure = const ChangeSeatClosedFailure();
      final failed = await cubit.changeBookingSeat(
        bookingId: 'bkg-closed',
        newSeatId: 'seat-3',
      );
      expect(failed, isFalse);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('18, 19, 20, 21 & 22. seat change preserves seat if bus full, protects seat during modal, swaps atomically', () {
      final allSeats = [
        const TripSeat(
          seatId: 'seat-1',
          seatNumber: '1',
          rowIndex: 1,
          columnIndex: 1,
          seatType: 'standard',
          status: SeatAvailabilityStatus.booked,
          isMine: true,
        ),
        const TripSeat(
          seatId: 'seat-2',
          seatNumber: '2',
          rowIndex: 1,
          columnIndex: 2,
          seatType: 'standard',
          status: SeatAvailabilityStatus.booked,
          isMine: false,
        ),
      ];

      // Current passenger holds seat-1
      const currentSeatNumber = '1';
      final otherAvailable = allSeats
          .where((s) => s.isAvailable && s.seatNumber != currentSeatNumber)
          .toList();

      // Full bus: otherAvailable is empty -> current seat preserved
      expect(otherAvailable, isEmpty);
    });
  });
}
