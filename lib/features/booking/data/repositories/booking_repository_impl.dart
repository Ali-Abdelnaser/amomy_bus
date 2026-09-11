import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/failures/booking_failures.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_data_source.dart';

@LazySingleton(as: BookingRepository)
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  BookingRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    required DateTime date,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final dateStr =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final trips = await _remoteDataSource.getAvailableTrips(
        direction: direction.backendValue,
        date: dateStr,
      );
      return Success(trips);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({
    required String tripId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final seats = await _remoteDataSource.getTripSeatMap(tripId: tripId);
      return Success(seats);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final hold = await _remoteDataSource.createBookingHold(
        tripId: tripId,
        seatId: seatId,
      );
      return Success(hold);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<void> releaseBookingHold({
    required String holdId,
  }) async {
    try {
      await _remoteDataSource.releaseBookingHold(holdId: holdId);
      return const Success(null);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final booking = await _remoteDataSource.confirmBooking(holdId: holdId);
      return Success(booking);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final bookings = await _remoteDataSource.getPassengerBookings();
      return Success(bookings);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) {
    return _remoteDataSource.subscribeToTripSeatUpdates(tripId);
  }

  Failure _mapExceptionToFailure(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('insufficient_points')) {
      return const InsufficientPointsFailure();
    }
    if (message.contains('seat_unavailable') || message.contains('seat_already_booked')) {
      return const SeatUnavailableFailure();
    }
    if (message.contains('hold_expired')) {
      return const HoldExpiredFailure();
    }
    if (message.contains('profile_incomplete')) {
      return const ProfileIncompleteFailure();
    }
    if (message.contains('booking_closed')) {
      return const BookingClosedFailure();
    }
    if (message.contains('trip_unavailable') || message.contains('trip_not_found')) {
      return const TripUnavailableFailure();
    }
    return ServerFailure(message: error.toString());
  }
}
