import '../../../../core/typedefs/typedefs.dart';
import '../entities/booking_entities.dart';

abstract class BookingRepository {
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  });

  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  });

  ResultFuture<List<TripSeat>> getTripSeatMap({
    required String tripId,
  });

  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  });

  ResultFuture<void> releaseBookingHold({
    required String holdId,
  });

  ResultFuture<PassengerBooking> confirmBooking({
    required String holdId,
  });

  ResultFuture<List<PassengerBooking>> getPassengerBookings();

  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  });

  ResultFuture<PassengerTripPreference?> getMyTripPreferences();

  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  });

  ResultFuture<void> cancelBooking(String bookingId);

  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  });

  Stream<void> subscribeToTripSeatUpdates(String tripId);
}
