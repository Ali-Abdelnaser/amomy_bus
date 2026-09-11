import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../entities/booking_entities.dart';
import '../repositories/booking_repository.dart';

@lazySingleton
class GetAvailableTripsUseCase {
  final BookingRepository _repository;

  const GetAvailableTripsUseCase(this._repository);

  ResultFuture<List<TripOption>> call({
    required BookingDirection direction,
    required DateTime date,
  }) =>
      _repository.getAvailableTrips(direction: direction, date: date);
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
  }) =>
      _repository.createBookingHold(tripId: tripId, seatId: seatId);
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
