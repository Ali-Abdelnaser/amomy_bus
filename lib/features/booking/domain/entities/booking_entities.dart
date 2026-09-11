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

enum SeatAvailabilityStatus {
  available,
  held,
  booked,
}

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
  });

  String originName(String locale) => locale.startsWith('ar') ? originNameAr : originNameEn;
  String destinationName(String locale) => locale.startsWith('ar') ? destinationNameAr : destinationNameEn;

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

  const TripSeat({
    required this.seatId,
    required this.seatNumber,
    required this.rowIndex,
    required this.columnIndex,
    required this.seatType,
    required this.status,
    required this.isMine,
    this.passengerGender,
  });

  bool get isAvailable => status == SeatAvailabilityStatus.available;
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

  const BookingHold({
    required this.holdId,
    required this.tripId,
    required this.seatId,
    required this.seatNumber,
    required this.farePoints,
    required this.expiresAt,
    required this.serverTime,
  });

  /// Seconds remaining calculated relative to server time anchor
  int get remainingSeconds {
    final now = DateTime.now();
    final difference = expiresAt.difference(now).inSeconds;
    return difference > 0 ? difference : 0;
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
  });

  bool get isUpcoming =>
      status == 'confirmed' && departureAt.isAfter(DateTime.now());

  String originName(String locale) => locale.startsWith('ar') ? originNameAr : originNameEn;
  String destinationName(String locale) => locale.startsWith('ar') ? destinationNameAr : destinationNameEn;

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
      ];
}
