import '../entities/booking_entities.dart';

class PassengerBookingAvailability {
  const PassengerBookingAvailability._();

  static bool hasAnyBookableTrip(Iterable<PassengerTodayTrip> trips) {
    return trips.any((trip) => trip.isBookable);
  }
}
