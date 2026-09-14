import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/booking_entities.dart';
import '../repositories/booking_repository.dart';

@lazySingleton
class GetRouteStopsUseCase {
  final BookingRepository _repository;

  const GetRouteStopsUseCase(this._repository);

  ResultFuture<List<RouteStop>> call({
    required BookingDirection direction,
  }) =>
      _repository.getRouteStops(direction: direction);
}

@lazySingleton
class GetAvailableTripsUseCase {
  final BookingRepository _repository;

  const GetAvailableTripsUseCase(this._repository);

  ResultFuture<List<TripOption>> call({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) =>
      _repository.getAvailableTrips(
        direction: direction,
        date: date,
        routeStopId: routeStopId,
      );
}

@lazySingleton
class GetTripSeatMapUseCase {
  final BookingRepository _repository;

  const GetTripSeatMapUseCase(this._repository);

  ResultFuture<List<TripSeat>> call({required String tripId}) =>
      _repository.getTripSeatMap(tripId: tripId);
}

@lazySingleton
class CreateBookingHoldUseCase {
  final BookingRepository _repository;

  const CreateBookingHoldUseCase(this._repository);

  ResultFuture<BookingHold> call({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) =>
      _repository.createBookingHold(
        tripId: tripId,
        seatId: seatId,
        routeStopId: routeStopId,
        destinationRouteStopId: destinationRouteStopId,
      );
}

@lazySingleton
class ReleaseBookingHoldUseCase {
  final BookingRepository _repository;

  const ReleaseBookingHoldUseCase(this._repository);

  ResultFuture<void> call({required String holdId}) =>
      _repository.releaseBookingHold(holdId: holdId);
}

@lazySingleton
class ConfirmBookingUseCase {
  final BookingRepository _repository;

  const ConfirmBookingUseCase(this._repository);

  ResultFuture<PassengerBooking> call({required String holdId}) =>
      _repository.confirmBooking(holdId: holdId);
}

@lazySingleton
class GetPassengerBookingsUseCase {
  final BookingRepository _repository;

  const GetPassengerBookingsUseCase(this._repository);

  ResultFuture<List<PassengerBooking>> call() =>
      _repository.getPassengerBookings();
}

@lazySingleton
class GetPassengerTodayTripsUseCase {
  final BookingRepository _repository;

  const GetPassengerTodayTripsUseCase(this._repository);

  ResultFuture<List<PassengerTodayTrip>> call({
    String? direction,
    String? originRouteStopId,
  }) =>
      _repository.getPassengerTodayTrips(
        direction: direction,
        originRouteStopId: originRouteStopId,
      );
}

@lazySingleton
class GetMyTripPreferencesUseCase {
  final BookingRepository _repository;

  const GetMyTripPreferencesUseCase(this._repository);

  ResultFuture<PassengerTripPreference?> call() =>
      _repository.getMyTripPreferences();
}

@lazySingleton
class SetMyTripPreferencesUseCase {
  final BookingRepository _repository;

  const SetMyTripPreferencesUseCase(this._repository);

  ResultFuture<PassengerTripPreference> call({
    required String originStopId,
    required String destinationStopId,
  }) =>
      _repository.setMyTripPreferences(
        originStopId: originStopId,
        destinationStopId: destinationStopId,
      );
}

@lazySingleton
class CancelBookingUseCase {
  final BookingRepository _repository;

  const CancelBookingUseCase(this._repository);

  ResultFuture<void> call(String bookingId) =>
      _repository.cancelBooking(bookingId);
}

@lazySingleton
class ChangeBookingSeatUseCase {
  final BookingRepository _repository;

  const ChangeBookingSeatUseCase(this._repository);

  ResultFuture<void> call({
    required String bookingId,
    required String newSeatId,
  }) =>
      _repository.changeBookingSeat(
        bookingId: bookingId,
        newSeatId: newSeatId,
      );
}


