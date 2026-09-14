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
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final stops = await _remoteDataSource.getRouteStops(
        direction: direction.backendValue,
      );
      return Success(stops);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final dateStr = date != null
          ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
          : null;
      final trips = await _remoteDataSource.getAvailableTrips(
        direction: direction.backendValue,
        date: dateStr,
        routeStopId: routeStopId,
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
    String? routeStopId,
    String? destinationRouteStopId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final hold = await _remoteDataSource.createBookingHold(
        tripId: tripId,
        seatId: seatId,
        routeStopId: routeStopId,
        destinationRouteStopId: destinationRouteStopId,
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
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final trips = await _remoteDataSource.getPassengerTodayTrips(
        direction: direction,
        originRouteStopId: originRouteStopId,
      );
      return Success(trips);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final pref = await _remoteDataSource.getMyTripPreferences();
      return Success(pref);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final pref = await _remoteDataSource.setMyTripPreferences(
        originStopId: originStopId,
        destinationStopId: destinationStopId,
      );
      return Success(pref);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<void> cancelBooking(String bookingId) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.cancelBooking(bookingId);
      return const Success(null);
    } catch (e) {
      return Error(_mapExceptionToFailure(e));
    }
  }

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.changeBookingSeat(
        bookingId: bookingId,
        newSeatId: newSeatId,
      );
      return const Success(null);
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
    if (message.contains('cancellation_window_closed')) {
      return const CancellationClosedFailure();
    }
    if (message.contains('change_seat_window_closed')) {
      return const ChangeSeatClosedFailure();
    }
    if (message.contains('insufficient_points') ||
        message.contains('insufficient_unexpired_points')) {
      return const InsufficientPointsFailure();
    }
    if (message.contains('seat_unavailable') ||
        message.contains('seat_already_booked') ||
        message.contains('seat_held_by_another_user')) {
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
    if (message.contains('already_booked_trip') ||
        message.contains('uq_passenger_active_trip_booking')) {
      return const AlreadyBookedTripFailure();
    }
    if (message.contains('trip_unavailable') || message.contains('trip_not_found')) {
      return const TripUnavailableFailure();
    }
    return ServerFailure(message: error.toString());
  }
}
