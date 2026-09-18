import 'package:equatable/equatable.dart';

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
    required this.farePoints,
    required this.availableSeatsCount,
    required this.status,
    this.isBookable = true,
  });

  bool get isClosed =>
      status == 'closed' || status == 'departed' || status == 'cancelled';
  bool get isFull => availableSeatsCount <= 0;
  bool get canBook => isBookable && !isClosed && !isFull;

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
    final name = stopName(locale);
    final loc = locality(locale);
    if (loc.isNotEmpty && name != loc) {
      return '$name — $loc';
    }
    return name;
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
  unavailable;

  static TodayTripAvailabilityStatus fromString(String val) {
    switch (val.toUpperCase()) {
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
  final DateTime bookingCloseAt;
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
    required this.bookingCloseAt,
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
