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
    super.message =
        'The 5-minute seat hold has expired. Please select a seat again.',
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
    super.message = 'Booking for this trip is closed.',
  });
}

class AlreadyBookedFailure extends Failure {
  const AlreadyBookedFailure({super.message = 'This seat is already booked.'});
}

class AlreadyBookedTripFailure extends Failure {
  const AlreadyBookedTripFailure({
    super.message = 'You already have an active booking for this trip.',
  });
}

class CancellationClosedFailure extends Failure {
  const CancellationClosedFailure({
    super.message = 'Cancellation is closed within 30 minutes of departure.',
  });
}

class ChangeSeatClosedFailure extends Failure {
  const ChangeSeatClosedFailure({
    super.message = 'Changing seats is closed within 30 minutes of departure.',
  });
}

class RoundTripMustStartWithOutboundFailure extends Failure {
  const RoundTripMustStartWithOutboundFailure({
    super.message = 'ROUND_TRIP_MUST_START_WITH_OUTBOUND',
  });
}

class InvalidRoundTripDirectionsFailure extends Failure {
  const InvalidRoundTripDirectionsFailure({
    super.message = 'INVALID_ROUND_TRIP_DIRECTIONS',
  });
}

class RoundTripSameDayRequiredFailure extends Failure {
  const RoundTripSameDayRequiredFailure({
    super.message = 'ROUND_TRIP_SAME_DAY_REQUIRED',
  });
}

class ReturnMustBeAfterOutboundFailure extends Failure {
  const ReturnMustBeAfterOutboundFailure({
    super.message = 'RETURN_MUST_BE_AFTER_OUTBOUND',
  });
}

class RoundTripDiscountAlreadyUsedTodayFailure extends Failure {
  const RoundTripDiscountAlreadyUsedTodayFailure({
    super.message = 'ROUND_TRIP_DISCOUNT_ALREADY_USED_TODAY',
  });
}

class RoundTripRequiresUnbookedTripsFailure extends Failure {
  const RoundTripRequiresUnbookedTripsFailure({
    super.message = 'ROUND_TRIP_REQUIRES_UNBOOKED_TRIPS',
  });
}

class RoundTripHoldAlreadyActiveFailure extends Failure {
  const RoundTripHoldAlreadyActiveFailure({
    super.message = 'ROUND_TRIP_HOLD_ALREADY_ACTIVE',
  });
}

class RoundTripHoldNotFoundFailure extends Failure {
  const RoundTripHoldNotFoundFailure({
    super.message = 'ROUND_TRIP_HOLD_NOT_FOUND',
  });
}

class RoundTripHoldInvalidFailure extends Failure {
  const RoundTripHoldInvalidFailure({
    super.message = 'ROUND_TRIP_HOLD_INVALID',
  });
}

class ReturnSeatRequiredFailure extends Failure {
  const ReturnSeatRequiredFailure({super.message = 'RETURN_SEAT_REQUIRED'});
}

class RoundTripCancellationWindowClosedFailure extends Failure {
  const RoundTripCancellationWindowClosedFailure({
    super.message = 'ROUND_TRIP_CANCELLATION_WINDOW_CLOSED',
  });
}

class RoundTripAlreadyUsedFailure extends Failure {
  const RoundTripAlreadyUsedFailure({
    super.message = 'ROUND_TRIP_ALREADY_USED',
  });
}

class RoundTripBundleNotCancellableFailure extends Failure {
  const RoundTripBundleNotCancellableFailure({
    super.message = 'ROUND_TRIP_BUNDLE_NOT_CANCELLABLE',
  });
}
