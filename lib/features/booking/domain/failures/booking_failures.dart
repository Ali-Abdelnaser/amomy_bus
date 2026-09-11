import '../../../../core/error/failures.dart';

class TripUnavailableFailure extends Failure {
  const TripUnavailableFailure({
    super.message = 'The requested trip is no longer available.',
  });
}

class SeatUnavailableFailure extends Failure {
  const SeatUnavailableFailure({
    super.message = 'This seat is already held or booked by another passenger.',
  });
}

class HoldExpiredFailure extends Failure {
  const HoldExpiredFailure({
    super.message = 'The 5-minute seat hold has expired. Please select a seat again.',
  });
}

class InsufficientPointsFailure extends Failure {
  const InsufficientPointsFailure({
    super.message = 'You do not have enough points for this trip.',
  });
}

class ProfileIncompleteFailure extends Failure {
  const ProfileIncompleteFailure({
    super.message = 'Please complete your passenger profile before booking.',
  });
}

class BookingClosedFailure extends Failure {
  const BookingClosedFailure({
    super.message = 'Booking has closed for this departure.',
  });
}

class AlreadyBookedFailure extends Failure {
  const AlreadyBookedFailure({
    super.message = 'This seat is already booked.',
  });
}
