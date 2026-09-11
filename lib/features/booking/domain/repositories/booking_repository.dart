import '../../../../core/typedefs/typedefs.dart';
import '../entities/booking_entities.dart';

abstract class BookingRepository {
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    required DateTime date,
  });

  ResultFuture<List<TripSeat>> getTripSeatMap({
    required String tripId,
  });

  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
  });

  ResultFuture<void> releaseBookingHold({
    required String holdId,
  });

  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  });

  ResultFuture<List<PassengerBooking>> getPassengerBookings();

  Stream<void> subscribeToTripSeatUpdates(String tripId);
}
