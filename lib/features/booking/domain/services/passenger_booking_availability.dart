import 'package:flutter/foundation.dart';
import '../entities/booking_entities.dart';

/// Central authoritative booking availability and cutoff evaluation for Passenger app.
class PassengerBookingAvailability {
  const PassengerBookingAvailability._();

  @visibleForTesting
  static DateTime Function()? nowProvider;

  static DateTime get currentNow =>
      nowProvider != null ? nowProvider!() : DateTime.now();

  /// Centralized rule:
  /// if bookingCloseAt != null: closed when now >= bookingCloseAt
  static bool isBookingClosed(DateTime? bookingCloseAt, {DateTime? now}) {
    if (bookingCloseAt == null) return false;
    final current = now ?? currentNow;
    return current.millisecondsSinceEpoch >=
        bookingCloseAt.millisecondsSinceEpoch;
  }

  /// Returns true if booking is still permitted before cutoff.
  static bool canCreateBooking(DateTime? bookingCloseAt, {DateTime? now}) {
    return !isBookingClosed(bookingCloseAt, now: now);
  }

  /// Returns true if at least one trip is bookable and has not passed booking cutoff.
  static bool hasAnyBookableTrip(
    Iterable<PassengerTodayTrip> trips, {
    DateTime? now,
  }) {
    return trips.any((trip) => trip.canBookTrip(now: now));
  }
}
