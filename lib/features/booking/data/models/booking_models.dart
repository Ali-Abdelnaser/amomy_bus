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
    super.isBookable,
  });

  factory TripOptionModel.fromJson(Map<String, dynamic> json) {
    DateTime departureDateTime;
    if (json['departure_at'] != null) {
      departureDateTime = DateTime.parse(json['departure_at'] as String);
    } else if (json['service_date'] != null && json['departure_time'] != null) {
      final sDate = json['service_date'] as String;
      final dTime = (json['departure_time'] as String).padLeft(5, '0');
      departureDateTime =
          DateTime.tryParse('${sDate}T$dTime:00') ?? DateTime.now();
    } else {
      departureDateTime = DateTime.now();
    }

    final availableSeats =
        json['available_seats'] ?? json['available_seats_count'] ?? 0;
    final farePts = json['fare_points'] ?? 0;

    String statusStr = 'scheduled';
    if (json['status'] is String) {
      statusStr = json['status'] as String;
    } else if (json['is_active'] == false) {
      statusStr = 'cancelled';
    }
    final isClosed =
        statusStr == 'closed' ||
        statusStr == 'departed' ||
        statusStr == 'cancelled';
    final inferredBookable = !isClosed && (availableSeats as num).toInt() > 0;
    final isBookable = json['is_bookable'] is bool
        ? json['is_bookable'] as bool
        : inferredBookable;

    return TripOptionModel(
      tripId: (json['trip_id'] ?? json['id'] ?? '') as String,
      routeId: (json['route_id'] ?? '') as String,
      direction: BookingDirection.fromString(
        json['direction'] as String? ?? 'outbound',
      ),
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      departureTime: json['departure_time'] as String? ?? '',
      departureAt: departureDateTime,
      farePoints: (farePts as num).toDouble(),
      availableSeatsCount: (availableSeats as num).toInt(),
      status: statusStr,
      isBookable: isBookable,
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
    super.heldExpiresAt,
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

    final rawGender = json['passenger_gender'] as String?;
    final normalizedGender = (rawGender == 'male' || rawGender == 'female')
        ? rawGender
        : null;

    final rawExpires = json['held_expires_at'] as String?;
    final DateTime? heldExpiresAt = rawExpires != null
        ? DateTime.tryParse(rawExpires)
        : null;

    return TripSeatModel(
      seatId: json['seat_id'] as String,
      seatNumber: json['seat_number'] as String,
      rowIndex: (json['row_index'] as num).toInt(),
      columnIndex: (json['column_index'] as num).toInt(),
      seatType: json['seat_type'] as String? ?? 'standard',
      status: status,
      isMine: json['is_mine'] as bool? ?? false,
      passengerGender: normalizedGender,
      heldExpiresAt: heldExpiresAt,
    );
  }
}

class RouteStopModel extends RouteStop {
  const RouteStopModel({
    required super.routeStopId,
    required super.stopId,
    required super.stopOrder,
    required super.stopNameAr,
    super.stopNameEn,
    required super.localityAr,
    super.localityEn,
    required super.fareZoneId,
    required super.farePoints,
  });

  factory RouteStopModel.fromJson(Map<String, dynamic> json) {
    final routeStopId =
        json['route_stop_id'] ?? json['id'] ?? json['stop_id'] ?? '';
    final stopId = json['stop_id'] ?? json['route_stop_id'] ?? json['id'] ?? '';
    final fareZoneId = json['fare_zone_id'] ?? '';
    final farePoints = json['fare_points'] ?? 0;
    final stopOrder = json['stop_order'] ?? 0;

    return RouteStopModel(
      routeStopId: routeStopId.toString(),
      stopId: stopId.toString(),
      stopOrder: (stopOrder as num).toInt(),
      stopNameAr: json['stop_name_ar'] as String? ?? '',
      stopNameEn: json['stop_name_en'] as String?,
      localityAr: json['locality_ar'] as String? ?? '',
      localityEn: json['locality_en'] as String?,
      fareZoneId: fareZoneId.toString(),
      farePoints: (farePoints as num).toDouble(),
    );
  }
}

class BookingHoldModel extends BookingHold {
  BookingHoldModel({
    required super.holdId,
    required super.tripId,
    required super.seatId,
    required super.seatNumber,
    required super.farePoints,
    required super.expiresAt,
    required super.serverTime,
    super.initialRemainingSeconds,
    super.clientReceivedAt,
    super.routeStopId,
    super.destinationRouteStopId,
    super.stopName,
    super.destinationStopName,
    super.locality,
    super.fareZoneId,
  });

  factory BookingHoldModel.fromJson(Map<String, dynamic> json) {
    final expiresAt = DateTime.parse(json['expires_at'] as String);
    final serverTime = json['server_time'] != null
        ? DateTime.parse(json['server_time'] as String)
        : (json['server_now'] != null
              ? DateTime.parse(json['server_now'] as String)
              : DateTime.now());
    final remainingSecs = json['remaining_seconds'] != null
        ? (json['remaining_seconds'] as num).toInt()
        : null;

    return BookingHoldModel(
      holdId: (json['hold_id'] ?? '') as String,
      tripId: (json['trip_id'] ?? '') as String,
      seatId: (json['seat_id'] ?? '') as String,
      seatNumber: (json['seat_number'] ?? '') as String,
      farePoints: ((json['fare_points'] ?? 0) as num).toDouble(),
      expiresAt: expiresAt,
      serverTime: serverTime,
      initialRemainingSeconds: remainingSecs,
      routeStopId: json['route_stop_id'] as String?,
      destinationRouteStopId: json['destination_route_stop_id'] as String?,
      stopName: (json['stop_name'] ?? json['stop_name_ar']) as String?,
      destinationStopName:
          (json['destination_stop_name'] ?? json['destination_stop_name_ar'])
              as String?,
      locality: json['locality'] as String?,
      fareZoneId: json['fare_zone_id'] as String?,
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
    super.routeStopId,
    super.stopName,
    super.locality,
    super.checkedInAt,
  });

  factory PassengerBookingModel.fromJson(Map<String, dynamic> json) {
    DateTime departureDateTime;
    if (json['departure_at'] != null) {
      departureDateTime = DateTime.parse(json['departure_at'] as String);
    } else if (json['service_date'] != null && json['departure_time'] != null) {
      final sDate = json['service_date'] as String;
      final dTime = (json['departure_time'] as String).padLeft(5, '0');
      departureDateTime =
          DateTime.tryParse('${sDate}T$dTime:00') ?? DateTime.now();
    } else {
      departureDateTime = DateTime.now();
    }

    return PassengerBookingModel(
      bookingId: (json['booking_id'] ?? json['id'] ?? '') as String,
      tripId: (json['trip_id'] ?? '') as String,
      direction: BookingDirection.fromString(
        json['direction'] as String? ?? 'outbound',
      ),
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'] as String)
          : departureDateTime,
      departureTime: json['departure_time'] as String? ?? '',
      departureAt: departureDateTime,
      seatNumber: (json['seat_number'] ?? '') as String,
      farePoints: ((json['fare_points'] ?? 0) as num).toDouble(),
      status: json['status'] as String? ?? 'confirmed',
      qrToken: (json['qr_token'] ?? '') as String,
      bookedAt: json['booked_at'] != null
          ? DateTime.parse(json['booked_at'] as String)
          : DateTime.now(),
      routeStopId: json['route_stop_id'] as String?,
      stopName: (json['stop_name_ar'] ?? json['stop_name']) as String?,
      locality: json['locality_ar'] as String?,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'] as String)
          : null,
    );
  }
}

class PassengerTodayTripModel extends PassengerTodayTrip {
  const PassengerTodayTripModel({
    required super.tripId,
    required super.routeId,
    required super.direction,
    required super.serviceDate,
    required super.originNameAr,
    required super.originNameEn,
    required super.destinationNameAr,
    required super.destinationNameEn,
    required super.departureTime,
    required super.departureAt,
    required super.bookingCloseAt,
    required super.farePoints,
    required super.totalSeats,
    required super.availableSeats,
    required super.status,
    required super.alreadyBooked,
    super.bookingId,
    super.seatNumber,
    super.qrToken,
    required super.availabilityStatus,
    required super.isBookable,
  });

  factory PassengerTodayTripModel.fromJson(Map<String, dynamic> json) {
    return PassengerTodayTripModel(
      tripId: (json['trip_id'] ?? json['id'] ?? '') as String,
      routeId: (json['route_id'] ?? '') as String,
      direction: BookingDirection.fromString(
        json['direction'] as String? ?? 'outbound',
      ),
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'] as String)
          : DateTime.now(),
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      departureTime: json['departure_time'] as String? ?? '',
      departureAt: json['departure_at'] != null
          ? DateTime.parse(json['departure_at'] as String)
          : DateTime.now(),
      bookingCloseAt: json['booking_close_at'] != null
          ? DateTime.parse(json['booking_close_at'] as String)
          : DateTime.now(),
      farePoints: ((json['fare_points'] ?? 0) as num).toDouble(),
      totalSeats: (json['total_seats'] as num? ?? 14).toInt(),
      availableSeats: (json['available_seats'] as num? ?? 0).toInt(),
      status: json['status'] as String? ?? 'scheduled',
      alreadyBooked: json['already_booked'] as bool? ?? false,
      bookingId: json['booking_id'] as String?,
      seatNumber: json['seat_number'] as String?,
      qrToken: json['qr_token'] as String?,
      availabilityStatus: TodayTripAvailabilityStatus.fromString(
        json['availability_status'] as String? ?? 'UNAVAILABLE',
      ),
      isBookable: json['is_bookable'] as bool? ?? false,
    );
  }
}

class PassengerTripPreferenceModel extends PassengerTripPreference {
  const PassengerTripPreferenceModel({
    required super.originStopId,
    required super.destinationStopId,
    super.originRouteStopId,
    super.destinationRouteStopId,
    required super.originNameAr,
    required super.originNameEn,
    required super.originLocalityAr,
    required super.originLocalityEn,
    required super.destinationNameAr,
    required super.destinationNameEn,
    required super.destinationLocalityAr,
    required super.destinationLocalityEn,
    required super.updatedAt,
  });

  factory PassengerTripPreferenceModel.fromJson(Map<String, dynamic> json) {
    return PassengerTripPreferenceModel(
      originStopId: json['origin_stop_id'] as String,
      destinationStopId: json['destination_stop_id'] as String,
      originRouteStopId: json['origin_route_stop_id'] as String?,
      destinationRouteStopId: json['destination_route_stop_id'] as String?,
      originNameAr: json['origin_name_ar'] as String? ?? '',
      originNameEn: json['origin_name_en'] as String? ?? '',
      originLocalityAr: json['origin_locality_ar'] as String? ?? '',
      originLocalityEn: json['origin_locality_en'] as String? ?? '',
      destinationNameAr: json['destination_name_ar'] as String? ?? '',
      destinationNameEn: json['destination_name_en'] as String? ?? '',
      destinationLocalityAr: json['destination_locality_ar'] as String? ?? '',
      destinationLocalityEn: json['destination_locality_en'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
