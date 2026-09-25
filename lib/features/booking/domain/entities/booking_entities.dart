import 'package:equatable/equatable.dart';
import '../services/passenger_booking_availability.dart';

enum BookingDirection {
  outbound,
  returnTrip;

  String get backendValue {
    switch (this) {
      case BookingDirection.outbound:
        return 'outbound';
      case BookingDirection.returnTrip:
        return 'return';
    }
  }

  static BookingDirection fromString(String val) {
    if (val.toLowerCase() == 'return') {
      return BookingDirection.returnTrip;
    }
    return BookingDirection.outbound;
  }
}

enum BookingMode {
  single,
  roundTrip;

  bool get isRoundTrip => this == BookingMode.roundTrip;
  bool get isSingle => this == BookingMode.single;
}

enum RoundTripSeatStep {
  outbound,
  returnSeat;

  bool get isOutbound => this == RoundTripSeatStep.outbound;
  bool get isReturnSeat => this == RoundTripSeatStep.returnSeat;
}

enum SeatAvailabilityStatus { available, held, booked }

class TripOption extends Equatable {
  final String tripId;
  final String routeId;
  final BookingDirection direction;
  final String originNameAr;
  final String originNameEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final String departureTime;
  final DateTime departureAt;
  final DateTime? bookingCloseAt;
  final double farePoints;
  final int availableSeatsCount;
  final String status;
  final bool isBookable;

  const TripOption({
    required this.tripId,
    required this.routeId,
    required this.direction,
    required this.originNameAr,
    required this.originNameEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    required this.departureTime,
    required this.departureAt,
    this.bookingCloseAt,
    required this.farePoints,
    required this.availableSeatsCount,
    required this.status,
    this.isBookable = true,
  });

  bool isBookingClosed({DateTime? now}) =>
      status == 'closed' ||
      status == 'booking_closed' ||
      PassengerBookingAvailability.isBookingClosed(bookingCloseAt, now: now);

  bool get isClosed =>
      status == 'closed' || status == 'departed' || status == 'cancelled';
  bool get isFull => availableSeatsCount <= 0;
  bool get canBook => isBookable && !isClosed && !isFull && !isBookingClosed();
  bool canBookAt({DateTime? now}) =>
      isBookable && !isClosed && !isFull && !isBookingClosed(now: now);

  String originName(String locale) => locale.startsWith('ar')
      ? (originNameAr.trim().isNotEmpty ? originNameAr : originNameEn)
      : (originNameEn.trim().isNotEmpty ? originNameEn : originNameAr);
  String destinationName(String locale) => locale.startsWith('ar')
      ? (destinationNameAr.trim().isNotEmpty
            ? destinationNameAr
            : destinationNameEn)
      : (destinationNameEn.trim().isNotEmpty
            ? destinationNameEn
            : destinationNameAr);

  @override
  List<Object?> get props => [
    tripId,
    routeId,
    direction,
    originNameAr,
    originNameEn,
    destinationNameAr,
    destinationNameEn,
    departureTime,
    departureAt,
    bookingCloseAt,
    farePoints,
    availableSeatsCount,
    status,
    isBookable,
  ];
}

class TripSeat extends Equatable {
  final String seatId;
  final String seatNumber;
  final int rowIndex;
  final int columnIndex;
  final String seatType;
  final SeatAvailabilityStatus status;
  final bool isMine;
  final String? passengerGender;
  final DateTime? heldExpiresAt;

  const TripSeat({
    required this.seatId,
    required this.seatNumber,
    required this.rowIndex,
    required this.columnIndex,
    required this.seatType,
    required this.status,
    required this.isMine,
    this.passengerGender,
    this.heldExpiresAt,
  });

  bool get isSupervisorReserved =>
      seatType.trim().toLowerCase() == 'supervisor_reserved';
  bool get isAvailable =>
      !isSupervisorReserved && status == SeatAvailabilityStatus.available;
  bool get isHeld => status == SeatAvailabilityStatus.held;
  bool get isBooked => status == SeatAvailabilityStatus.booked;

  @override
  List<Object?> get props => [
    seatId,
    seatNumber,
    rowIndex,
    columnIndex,
    seatType,
    status,
    isMine,
    passengerGender,
    heldExpiresAt,
  ];
}

class RouteStop extends Equatable {
  final String routeStopId;
  final String stopId;
  final int stopOrder;
  final String stopNameAr;
  final String? stopNameEn;
  final String localityAr;
  final String? localityEn;
  final String fareZoneId;
  final double farePoints;

  const RouteStop({
    required this.routeStopId,
    required this.stopId,
    required this.stopOrder,
    required this.stopNameAr,
    this.stopNameEn,
    required this.localityAr,
    this.localityEn,
    required this.fareZoneId,
    required this.farePoints,
  });

  String stopName(String locale) =>
      (locale.startsWith('ar') || stopNameEn == null || stopNameEn!.isEmpty)
      ? stopNameAr
      : stopNameEn!;

  String locality(String locale) =>
      (locale.startsWith('ar') || localityEn == null || localityEn!.isEmpty)
      ? localityAr
      : localityEn!;

  String displayName(String locale) {
    return stopName(locale);
  }

  @override
  List<Object?> get props => [
    routeStopId,
    stopId,
    stopOrder,
    stopNameAr,
    stopNameEn,
    localityAr,
    localityEn,
    fareZoneId,
    farePoints,
  ];
}

class BookingHold extends Equatable {
  final String holdId;
  final String tripId;
  final String seatId;
  final String seatNumber;
  final double farePoints;
  final DateTime expiresAt;
  final DateTime serverTime;
  final int initialRemainingSeconds;
  final DateTime clientReceivedAt;
  final String? routeStopId;
  final String? destinationRouteStopId;
  final String? stopName;
  final String? destinationStopName;
  final String? locality;
  final String? fareZoneId;

  BookingHold({
    required this.holdId,
    required this.tripId,
    required this.seatId,
    required this.seatNumber,
    required this.farePoints,
    required this.expiresAt,
    required this.serverTime,
    int? initialRemainingSeconds,
    DateTime? clientReceivedAt,
    this.routeStopId,
    this.destinationRouteStopId,
    this.stopName,
    this.destinationStopName,
    this.locality,
    this.fareZoneId,
  }) : clientReceivedAt = clientReceivedAt ?? DateTime.now(),
       initialRemainingSeconds =
           initialRemainingSeconds ??
           _calculateInitialRemaining(expiresAt, serverTime);

  static int _calculateInitialRemaining(
    DateTime expiresAt,
    DateTime serverTime,
  ) {
    final diff = expiresAt.toUtc().difference(serverTime.toUtc()).inSeconds;
    if (diff <= 0) return 0;
    return diff > 300 ? 300 : diff;
  }

  /// Server-authoritative remaining seconds decremented locally via client elapsed time
  int get remainingSeconds {
    final elapsed = DateTime.now().difference(clientReceivedAt).inSeconds;
    if (elapsed < 0) return initialRemainingSeconds;
    final remaining = initialRemainingSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isExpired => remainingSeconds <= 0;

  @override
  List<Object?> get props => [
    holdId,
    tripId,
    seatId,
    seatNumber,
    farePoints,
    expiresAt,
    serverTime,
    initialRemainingSeconds,
    clientReceivedAt,
    routeStopId,
    destinationRouteStopId,
    stopName,
    destinationStopName,
    locality,
    fareZoneId,
  ];
}

class PassengerBooking extends Equatable {
  final String bookingId;
  final String tripId;
  final BookingDirection direction;
  final String originNameAr;
  final String originNameEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final DateTime serviceDate;
  final String departureTime;
  final DateTime departureAt;
  final String seatNumber;
  final double farePoints;
  final String status;
  final String qrToken;
  final DateTime bookedAt;
  final String? routeStopId;
  final String? stopName;
  final String? locality;
  final DateTime? checkedInAt;

  const PassengerBooking({
    required this.bookingId,
    required this.tripId,
    required this.direction,
    required this.originNameAr,
    required this.originNameEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    required this.serviceDate,
    required this.departureTime,
    required this.departureAt,
    required this.seatNumber,
    required this.farePoints,
    required this.status,
    required this.qrToken,
    required this.bookedAt,
    this.routeStopId,
    this.stopName,
    this.locality,
    this.checkedInAt,
  });

  bool get isFinished => checkedInAt != null;
  String get id => bookingId;

  bool get isUpcoming =>
      status == 'confirmed' &&
      checkedInAt == null &&
      departureAt.isAfter(DateTime.now());

  String originName(String locale) => locale.startsWith('ar')
      ? (originNameAr.trim().isNotEmpty ? originNameAr : originNameEn)
      : (originNameEn.trim().isNotEmpty ? originNameEn : originNameAr);
  String destinationName(String locale) => locale.startsWith('ar')
      ? (destinationNameAr.trim().isNotEmpty
            ? destinationNameAr
            : destinationNameEn)
      : (destinationNameEn.trim().isNotEmpty
            ? destinationNameEn
            : destinationNameAr);

  @override
  List<Object?> get props => [
    bookingId,
    tripId,
    direction,
    originNameAr,
    originNameEn,
    destinationNameAr,
    destinationNameEn,
    serviceDate,
    departureTime,
    departureAt,
    seatNumber,
    farePoints,
    status,
    qrToken,
    bookedAt,
    routeStopId,
    stopName,
    locality,
    checkedInAt,
  ];
}

enum TodayTripAvailabilityStatus {
  available,
  alreadyBooked,
  full,
  bookingClosed,
  departed,
  cancelled,
  unavailable,
  finished;

  static TodayTripAvailabilityStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'FINISHED':
        return TodayTripAvailabilityStatus.finished;
      case 'ALREADY_BOOKED':
        return TodayTripAvailabilityStatus.alreadyBooked;
      case 'FULL':
        return TodayTripAvailabilityStatus.full;
      case 'BOOKING_CLOSED':
        return TodayTripAvailabilityStatus.bookingClosed;
      case 'DEPARTED':
        return TodayTripAvailabilityStatus.departed;
      case 'CANCELLED':
        return TodayTripAvailabilityStatus.cancelled;
      case 'AVAILABLE':
        return TodayTripAvailabilityStatus.available;
      default:
        return TodayTripAvailabilityStatus.unavailable;
    }
  }
}

class PassengerTodayTrip extends Equatable {
  final String tripId;
  final String routeId;
  final BookingDirection direction;
  final DateTime serviceDate;
  final String originNameAr;
  final String originNameEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final String departureTime;
  final DateTime departureAt;
  final DateTime? bookingCloseAt;
  final double farePoints;
  final int totalSeats;
  final int availableSeats;
  final String status;
  final bool alreadyBooked;
  final String? bookingId;
  final String? seatNumber;
  final String? qrToken;
  final TodayTripAvailabilityStatus availabilityStatus;
  final bool isBookable;
  final DateTime? checkedInAt;

  bool get isCheckedIn =>
      checkedInAt != null ||
      availabilityStatus == TodayTripAvailabilityStatus.finished;
  bool get isFinished => isCheckedIn || status == 'completed';

  bool isBookingClosed({DateTime? now}) =>
      availabilityStatus == TodayTripAvailabilityStatus.bookingClosed ||
      PassengerBookingAvailability.isBookingClosed(bookingCloseAt, now: now);

  bool canBookTrip({DateTime? now}) =>
      isBookable &&
      !alreadyBooked &&
      !isCheckedIn &&
      !isFinished &&
      availabilityStatus != TodayTripAvailabilityStatus.bookingClosed &&
      availabilityStatus != TodayTripAvailabilityStatus.departed &&
      availabilityStatus != TodayTripAvailabilityStatus.cancelled &&
      !isBookingClosed(now: now);

  const PassengerTodayTrip({
    required this.tripId,
    required this.routeId,
    required this.direction,
    required this.serviceDate,
    required this.originNameAr,
    required this.originNameEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    required this.departureTime,
    required this.departureAt,
    this.bookingCloseAt,
    required this.farePoints,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
    required this.alreadyBooked,
    this.bookingId,
    this.seatNumber,
    this.qrToken,
    required this.availabilityStatus,
    required this.isBookable,
    this.checkedInAt,
  });

  String originName(String locale) {
    if (locale.startsWith('ar')) {
      return originNameAr.trim().isNotEmpty ? originNameAr : originNameEn;
    }
    return originNameEn.trim().isNotEmpty ? originNameEn : originNameAr;
  }

  String destinationName(String locale) {
    if (locale.startsWith('ar')) {
      return destinationNameAr.trim().isNotEmpty
          ? destinationNameAr
          : destinationNameEn;
    }
    return destinationNameEn.trim().isNotEmpty
        ? destinationNameEn
        : destinationNameAr;
  }

  bool get isUrgentSeats => availableSeats > 0 && availableSeats <= 3;

  @override
  List<Object?> get props => [
    tripId,
    routeId,
    direction,
    serviceDate,
    originNameAr,
    originNameEn,
    destinationNameAr,
    destinationNameEn,
    departureTime,
    departureAt,
    bookingCloseAt,
    farePoints,
    totalSeats,
    availableSeats,
    status,
    alreadyBooked,
    bookingId,
    seatNumber,
    qrToken,
    availabilityStatus,
    isBookable,
    checkedInAt,
  ];
}

class PassengerTripPreference extends Equatable {
  final String originStopId;
  final String destinationStopId;
  final String? originRouteStopId;
  final String? destinationRouteStopId;
  final String originNameAr;
  final String originNameEn;
  final String originLocalityAr;
  final String originLocalityEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final String destinationLocalityAr;
  final String destinationLocalityEn;
  final DateTime updatedAt;

  const PassengerTripPreference({
    required this.originStopId,
    required this.destinationStopId,
    this.originRouteStopId,
    this.destinationRouteStopId,
    required this.originNameAr,
    required this.originNameEn,
    required this.originLocalityAr,
    required this.originLocalityEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    required this.destinationLocalityAr,
    required this.destinationLocalityEn,
    required this.updatedAt,
  });

  String originName(String locale) {
    if (locale.startsWith('ar')) {
      return originNameAr.trim().isNotEmpty ? originNameAr : originNameEn;
    }
    return originNameEn.trim().isNotEmpty ? originNameEn : originNameAr;
  }

  String destinationName(String locale) {
    if (locale.startsWith('ar')) {
      return destinationNameAr.trim().isNotEmpty
          ? destinationNameAr
          : destinationNameEn;
    }
    return destinationNameEn.trim().isNotEmpty
        ? destinationNameEn
        : destinationNameAr;
  }

  @override
  List<Object?> get props => [
    originStopId,
    destinationStopId,
    originRouteStopId,
    destinationRouteStopId,
    originNameAr,
    originNameEn,
    originLocalityAr,
    originLocalityEn,
    destinationNameAr,
    destinationNameEn,
    destinationLocalityAr,
    destinationLocalityEn,
    updatedAt,
  ];
}

class RoundTripReturnOption extends Equatable {
  final String returnTripId;
  final String departureTime;
  final DateTime departureAt;
  final DateTime? bookingCloseAt;
  final int availableSeats;
  final double outboundBaseFarePoints;
  final double returnBaseFarePoints;
  final double subtotalPoints;
  final double discountPercent;
  final double discountPoints;
  final double totalPoints;
  final bool isBookable;

  const RoundTripReturnOption({
    required this.returnTripId,
    required this.departureTime,
    required this.departureAt,
    this.bookingCloseAt,
    required this.availableSeats,
    required this.outboundBaseFarePoints,
    required this.returnBaseFarePoints,
    required this.subtotalPoints,
    required this.discountPercent,
    required this.discountPoints,
    required this.totalPoints,
    required this.isBookable,
  });

  bool isBookingClosed({DateTime? now}) =>
      PassengerBookingAvailability.isBookingClosed(bookingCloseAt, now: now);

  bool get canBookReturn => isBookable && !isBookingClosed();
  bool canBookReturnAt({DateTime? now}) =>
      isBookable && !isBookingClosed(now: now);

  @override
  List<Object?> get props => [
    returnTripId,
    departureTime,
    departureAt,
    bookingCloseAt,
    availableSeats,
    outboundBaseFarePoints,
    returnBaseFarePoints,
    subtotalPoints,
    discountPercent,
    discountPoints,
    totalPoints,
    isBookable,
  ];
}

class RoundTripBundleHold extends Equatable {
  final String bundleHoldId;
  final String outboundHoldId;
  final String outboundSeatId;
  final String outboundSeatNumber;
  final String? returnSeatId;
  final String? returnSeatNumber;
  final String outboundTripId;
  final String returnTripId;
  final String outboundRouteStopId;
  final String? returnRouteStopId;
  final double outboundBaseFarePoints;
  final double returnBaseFarePoints;
  final double subtotalPoints;
  final double discountPercent;
  final double discountPoints;
  final double totalPoints;
  final DateTime expiresAt;
  final DateTime serverTime;
  final int initialRemainingSeconds;
  final DateTime clientReceivedAt;

  RoundTripBundleHold({
    required this.bundleHoldId,
    required this.outboundHoldId,
    required this.outboundSeatId,
    required this.outboundSeatNumber,
    this.returnSeatId,
    this.returnSeatNumber,
    required this.outboundTripId,
    required this.returnTripId,
    required this.outboundRouteStopId,
    this.returnRouteStopId,
    required this.outboundBaseFarePoints,
    required this.returnBaseFarePoints,
    required this.subtotalPoints,
    required this.discountPercent,
    required this.discountPoints,
    required this.totalPoints,
    required this.expiresAt,
    required this.serverTime,
    int? initialRemainingSeconds,
    DateTime? clientReceivedAt,
  }) : clientReceivedAt = clientReceivedAt ?? DateTime.now(),
       initialRemainingSeconds =
           initialRemainingSeconds ??
           _calculateInitialRemaining(expiresAt, serverTime);

  static int _calculateInitialRemaining(
    DateTime expiresAt,
    DateTime serverTime,
  ) {
    final diff = expiresAt.toUtc().difference(serverTime.toUtc()).inSeconds;
    if (diff <= 0) return 0;
    return diff > 300 ? 300 : diff;
  }

  int get remainingSeconds {
    final elapsed = DateTime.now().difference(clientReceivedAt).inSeconds;
    if (elapsed < 0) return initialRemainingSeconds;
    final remaining = initialRemainingSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isExpired => remainingSeconds <= 0;

  RoundTripBundleHold copyWith({
    String? bundleHoldId,
    String? outboundHoldId,
    String? outboundSeatId,
    String? outboundSeatNumber,
    String? returnSeatId,
    String? returnSeatNumber,
    String? outboundTripId,
    String? returnTripId,
    String? outboundRouteStopId,
    String? returnRouteStopId,
    double? outboundBaseFarePoints,
    double? returnBaseFarePoints,
    double? subtotalPoints,
    double? discountPercent,
    double? discountPoints,
    double? totalPoints,
    DateTime? expiresAt,
    DateTime? serverTime,
    int? initialRemainingSeconds,
    DateTime? clientReceivedAt,
  }) {
    return RoundTripBundleHold(
      bundleHoldId: bundleHoldId ?? this.bundleHoldId,
      outboundHoldId: outboundHoldId ?? this.outboundHoldId,
      outboundSeatId: outboundSeatId ?? this.outboundSeatId,
      outboundSeatNumber: outboundSeatNumber ?? this.outboundSeatNumber,
      returnSeatId: returnSeatId ?? this.returnSeatId,
      returnSeatNumber: returnSeatNumber ?? this.returnSeatNumber,
      outboundTripId: outboundTripId ?? this.outboundTripId,
      returnTripId: returnTripId ?? this.returnTripId,
      outboundRouteStopId: outboundRouteStopId ?? this.outboundRouteStopId,
      returnRouteStopId: returnRouteStopId ?? this.returnRouteStopId,
      outboundBaseFarePoints:
          outboundBaseFarePoints ?? this.outboundBaseFarePoints,
      returnBaseFarePoints: returnBaseFarePoints ?? this.returnBaseFarePoints,
      subtotalPoints: subtotalPoints ?? this.subtotalPoints,
      discountPercent: discountPercent ?? this.discountPercent,
      discountPoints: discountPoints ?? this.discountPoints,
      totalPoints: totalPoints ?? this.totalPoints,
      expiresAt: expiresAt ?? this.expiresAt,
      serverTime: serverTime ?? this.serverTime,
      initialRemainingSeconds:
          initialRemainingSeconds ?? this.initialRemainingSeconds,
      clientReceivedAt: clientReceivedAt ?? this.clientReceivedAt,
    );
  }

  /// Merges updated hold data (such as return seat hold from RPC) while preserving
  /// authoritative fields that the return seat RPC does not return.
  RoundTripBundleHold mergeWith(RoundTripBundleHold other) {
    return copyWith(
      bundleHoldId: other.bundleHoldId.isNotEmpty
          ? other.bundleHoldId
          : bundleHoldId,
      outboundHoldId: other.outboundHoldId.isNotEmpty
          ? other.outboundHoldId
          : outboundHoldId,
      outboundSeatId: other.outboundSeatId.isNotEmpty
          ? other.outboundSeatId
          : outboundSeatId,
      outboundSeatNumber: other.outboundSeatNumber.isNotEmpty
          ? other.outboundSeatNumber
          : outboundSeatNumber,
      returnSeatId: other.returnSeatId ?? returnSeatId,
      returnSeatNumber: other.returnSeatNumber ?? returnSeatNumber,
      outboundTripId: other.outboundTripId.isNotEmpty
          ? other.outboundTripId
          : outboundTripId,
      returnTripId: other.returnTripId.isNotEmpty
          ? other.returnTripId
          : returnTripId,
      outboundRouteStopId: other.outboundRouteStopId.isNotEmpty
          ? other.outboundRouteStopId
          : outboundRouteStopId,
      returnRouteStopId: other.returnRouteStopId ?? returnRouteStopId,
      outboundBaseFarePoints: other.outboundBaseFarePoints > 0
          ? other.outboundBaseFarePoints
          : outboundBaseFarePoints,
      returnBaseFarePoints: other.returnBaseFarePoints > 0
          ? other.returnBaseFarePoints
          : returnBaseFarePoints,
      subtotalPoints: other.subtotalPoints > 0
          ? other.subtotalPoints
          : subtotalPoints,
      discountPercent: other.discountPercent > 0
          ? other.discountPercent
          : discountPercent,
      discountPoints: other.discountPoints > 0
          ? other.discountPoints
          : discountPoints,
      totalPoints: other.totalPoints > 0 ? other.totalPoints : totalPoints,
      expiresAt: other.expiresAt,
      serverTime: other.serverTime,
      initialRemainingSeconds: other.initialRemainingSeconds,
      clientReceivedAt: other.clientReceivedAt,
    );
  }

  /// Ensures authoritative fares are present by taking them from matched RPC return option if missing/zero.
  RoundTripBundleHold ensureAuthoritativeFares(RoundTripReturnOption? option) {
    if (option == null) return this;
    return copyWith(
      outboundBaseFarePoints: outboundBaseFarePoints > 0
          ? outboundBaseFarePoints
          : option.outboundBaseFarePoints,
      returnBaseFarePoints: returnBaseFarePoints > 0
          ? returnBaseFarePoints
          : option.returnBaseFarePoints,
      subtotalPoints: subtotalPoints > 0
          ? subtotalPoints
          : option.subtotalPoints,
      discountPercent: discountPercent > 0
          ? discountPercent
          : option.discountPercent,
      discountPoints: discountPoints > 0
          ? discountPoints
          : option.discountPoints,
      totalPoints: totalPoints > 0 ? totalPoints : option.totalPoints,
    );
  }

  @override
  List<Object?> get props => [
    bundleHoldId,
    outboundHoldId,
    outboundSeatId,
    outboundSeatNumber,
    returnSeatId,
    returnSeatNumber,
    outboundTripId,
    returnTripId,
    outboundRouteStopId,
    returnRouteStopId,
    outboundBaseFarePoints,
    returnBaseFarePoints,
    subtotalPoints,
    discountPercent,
    discountPoints,
    totalPoints,
    expiresAt,
    serverTime,
    initialRemainingSeconds,
    clientReceivedAt,
  ];
}

class RoundTripConfirmation extends Equatable {
  final String bundleId;
  final String outboundBookingId;
  final String returnBookingId;
  final String outboundTripId;
  final String returnTripId;
  final String outboundSeatNumber;
  final String returnSeatNumber;
  final double subtotalPoints;
  final double discountPercent;
  final double discountPoints;
  final double totalPaidPoints;
  final String status;

  const RoundTripConfirmation({
    required this.bundleId,
    required this.outboundBookingId,
    required this.returnBookingId,
    required this.outboundTripId,
    required this.returnTripId,
    required this.outboundSeatNumber,
    required this.returnSeatNumber,
    required this.subtotalPoints,
    required this.discountPercent,
    required this.discountPoints,
    required this.totalPaidPoints,
    required this.status,
  });

  @override
  List<Object?> get props => [
    bundleId,
    outboundBookingId,
    returnBookingId,
    outboundTripId,
    returnTripId,
    outboundSeatNumber,
    returnSeatNumber,
    subtotalPoints,
    discountPercent,
    discountPoints,
    totalPaidPoints,
    status,
  ];
}

class RoundTripBundleContext extends Equatable {
  final bool isRoundTripBundle;
  final String? bundleId;
  final String? outboundBookingId;
  final String? returnBookingId;
  final double? discountPoints;
  final double? totalPaidPoints;
  final bool cancellationEligible;
  final String? cancellationReason;

  const RoundTripBundleContext({
    required this.isRoundTripBundle,
    this.bundleId,
    this.outboundBookingId,
    this.returnBookingId,
    this.discountPoints,
    this.totalPaidPoints,
    required this.cancellationEligible,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [
    isRoundTripBundle,
    bundleId,
    outboundBookingId,
    returnBookingId,
    discountPoints,
    totalPaidPoints,
    cancellationEligible,
    cancellationReason,
  ];
}
