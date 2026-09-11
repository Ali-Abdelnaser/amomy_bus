import '../../domain/entities/booking_entities.dart';

class TripOptionModel extends TripOption {
  const TripOptionModel({
    required super.tripId,
    required super.routeId,
    required super.direction,
    required super.originNameAr,
    required super.originNameEn,
    required super.destinationNameAr,
    required super.destinationNameEn,
    required super.departureTime,
    required super.departureAt,
    required super.farePoints,
    required super.availableSeatsCount,
    required super.status,
  });

  factory TripOptionModel.fromJson(Map<String, dynamic> json) {
    return TripOptionModel(
      tripId: json['trip_id'] as String,
      routeId: json['route_id'] as String,
      direction: BookingDirection.fromString(json['direction'] as String? ?? 'outbound'),
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      departureTime: json['departure_time'] as String? ?? '',
      departureAt: DateTime.parse(json['departure_at'] as String),
      farePoints: (json['fare_points'] as num).toDouble(),
      availableSeatsCount: (json['available_seats_count'] as num).toInt(),
      status: json['status'] as String? ?? 'scheduled',
    );
  }
}

class TripSeatModel extends TripSeat {
  const TripSeatModel({
    required super.seatId,
    required super.seatNumber,
    required super.rowIndex,
    required super.columnIndex,
    required super.seatType,
    required super.status,
    required super.isMine,
    super.passengerGender,
  });

  factory TripSeatModel.fromJson(Map<String, dynamic> json) {
    SeatAvailabilityStatus status;
    final statusStr = (json['status'] as String? ?? 'available').toLowerCase();
    if (statusStr == 'booked') {
      status = SeatAvailabilityStatus.booked;
    } else if (statusStr == 'held') {
      status = SeatAvailabilityStatus.held;
    } else {
      status = SeatAvailabilityStatus.available;
    }

    return TripSeatModel(
      seatId: json['seat_id'] as String,
      seatNumber: json['seat_number'] as String,
      rowIndex: (json['row_index'] as num).toInt(),
      columnIndex: (json['column_index'] as num).toInt(),
      seatType: json['seat_type'] as String? ?? 'standard',
      status: status,
      isMine: json['is_mine'] as bool? ?? false,
      passengerGender: json['passenger_gender'] as String?,
    );
  }
}

class BookingHoldModel extends BookingHold {
  const BookingHoldModel({
    required super.holdId,
    required super.tripId,
    required super.seatId,
    required super.seatNumber,
    required super.farePoints,
    required super.expiresAt,
    required super.serverTime,
  });

  factory BookingHoldModel.fromJson(Map<String, dynamic> json) {
    return BookingHoldModel(
      holdId: json['hold_id'] as String,
      tripId: json['trip_id'] as String,
      seatId: json['seat_id'] as String,
      seatNumber: json['seat_number'] as String,
      farePoints: (json['fare_points'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      serverTime: DateTime.parse(json['server_time'] as String),
    );
  }
}

class PassengerBookingModel extends PassengerBooking {
  const PassengerBookingModel({
    required super.bookingId,
    required super.tripId,
    required super.direction,
    required super.originNameAr,
    required super.originNameEn,
    required super.destinationNameAr,
    required super.destinationNameEn,
    required super.serviceDate,
    required super.departureTime,
    required super.departureAt,
    required super.seatNumber,
    required super.farePoints,
    required super.status,
    required super.qrToken,
    required super.bookedAt,
  });

  factory PassengerBookingModel.fromJson(Map<String, dynamic> json) {
    return PassengerBookingModel(
      bookingId: json['booking_id'] as String,
      tripId: json['trip_id'] as String,
      direction: BookingDirection.fromString(json['direction'] as String? ?? 'outbound'),
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      serviceDate: DateTime.parse(json['service_date'] as String),
      departureTime: json['departure_time'] as String? ?? '',
      departureAt: DateTime.parse(json['departure_at'] as String),
      seatNumber: json['seat_number'] as String,
      farePoints: (json['fare_points'] as num).toDouble(),
      status: json['status'] as String? ?? 'confirmed',
      qrToken: json['qr_token'] as String,
      bookedAt: DateTime.parse(json['booked_at'] as String),
    );
  }
}
