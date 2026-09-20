import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/booking_entities.dart';
import '../repositories/booking_repository.dart';

@lazySingleton
class GetRouteStopsUseCase {
  final BookingRepository _repository;

  const GetRouteStopsUseCase(this._repository);

  ResultFuture<List<RouteStop>> call({required BookingDirection direction}) =>
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
  }) => _repository.getAvailableTrips(
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
  }) => _repository.createBookingHold(
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
  }) => _repository.getPassengerTodayTrips(
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
  }) => _repository.setMyTripPreferences(
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
      _repository.changeBookingSeat(bookingId: bookingId, newSeatId: newSeatId);
}

@lazySingleton
class GetRoundTripReturnOptionsUseCase {
  final BookingRepository _repository;

  const GetRoundTripReturnOptionsUseCase(this._repository);

  ResultFuture<List<RoundTripReturnOption>> call({
    required String outboundTripId,
    required String outboundRouteStopId,
  }) => _repository.getRoundTripReturnOptions(
    outboundTripId: outboundTripId,
    outboundRouteStopId: outboundRouteStopId,
  );
}

@lazySingleton
class CreateRoundTripBundleHoldUseCase {
  final BookingRepository _repository;

  const CreateRoundTripBundleHoldUseCase(this._repository);

  ResultFuture<RoundTripBundleHold> call({
    required String outboundTripId,
    required String returnTripId,
    required String outboundSeatId,
    required String outboundRouteStopId,
  }) => _repository.createRoundTripBundleHold(
    outboundTripId: outboundTripId,
    returnTripId: returnTripId,
    outboundSeatId: outboundSeatId,
    outboundRouteStopId: outboundRouteStopId,
  );
}

@lazySingleton
class SetRoundTripReturnSeatUseCase {
  final BookingRepository _repository;

  const SetRoundTripReturnSeatUseCase(this._repository);

  ResultFuture<RoundTripBundleHold> call({
    required String bundleHoldId,
    required String returnSeatId,
  }) => _repository.setRoundTripReturnSeat(
    bundleHoldId: bundleHoldId,
    returnSeatId: returnSeatId,
  );
}

@lazySingleton
class ReleaseRoundTripBundleHoldUseCase {
  final BookingRepository _repository;

  const ReleaseRoundTripBundleHoldUseCase(this._repository);

  ResultFuture<void> call({required String bundleHoldId}) =>
      _repository.releaseRoundTripBundleHold(bundleHoldId: bundleHoldId);
}

@lazySingleton
class ConfirmRoundTripBundleUseCase {
  final BookingRepository _repository;

  const ConfirmRoundTripBundleUseCase(this._repository);

  ResultFuture<RoundTripConfirmation> call({required String bundleHoldId}) =>
      _repository.confirmRoundTripBundle(bundleHoldId: bundleHoldId);
}

@lazySingleton
class GetRoundTripBundleContextUseCase {
  final BookingRepository _repository;

  const GetRoundTripBundleContextUseCase(this._repository);

  ResultFuture<RoundTripBundleContext> call({required String bookingId}) =>
      _repository.getRoundTripBundleContext(bookingId: bookingId);
}
