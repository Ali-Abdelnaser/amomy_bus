import '../../domain/entities/wallet_history_event.dart';

class WalletHistoryEventModel extends WalletHistoryEvent {
  const WalletHistoryEventModel({
    required super.eventId,
    required super.semanticType,
    super.signedAmount,
    super.createdAt,
    super.bookingId,
    super.tripId,
    super.tripDirection,
    super.serviceDate,
    super.departureAt,
    super.seatNumber,
    super.originNameAr,
    super.originNameEn,
    super.destinationNameAr,
    super.destinationNameEn,
    super.boardingNameAr,
    super.boardingNameEn,
    super.alightingNameAr,
    super.alightingNameEn,
    super.bookingKind,
  });

  factory WalletHistoryEventModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['signed_amount'];
    final int? signedAmount = (rawAmount is num) ? rawAmount.toInt() : null;

    final rawCreatedAt = json['created_at'];
    final createdAt = rawCreatedAt != null
        ? DateTime.tryParse(rawCreatedAt.toString())
        : null;

    final rawServiceDate = json['service_date'];
    final serviceDate = rawServiceDate != null
        ? DateTime.tryParse(rawServiceDate.toString())
        : null;

    final rawDepartureAt = json['departure_at'];
    final departureAt = rawDepartureAt != null
        ? DateTime.tryParse(rawDepartureAt.toString())
        : null;

    return WalletHistoryEventModel(
      eventId: json['event_id']?.toString() ?? '',
      semanticType: WalletSemanticType.fromString(
        json['semantic_type'] as String?,
      ),
      signedAmount: signedAmount,
      createdAt: createdAt,
      bookingId: json['booking_id'] as String?,
      tripId: json['trip_id'] as String?,
      tripDirection: json['trip_direction'] as String?,
      serviceDate: serviceDate,
      departureAt: departureAt,
      seatNumber: json['seat_number']?.toString(),
      originNameAr: json['origin_name_ar'] as String?,
      originNameEn: json['origin_name_en'] as String?,
      destinationNameAr: json['destination_name_ar'] as String?,
      destinationNameEn: json['destination_name_en'] as String?,
      boardingNameAr: json['boarding_name_ar'] as String?,
      boardingNameEn: json['boarding_name_en'] as String?,
      alightingNameAr: json['alighting_name_ar'] as String?,
      alightingNameEn: json['alighting_name_en'] as String?,
      bookingKind: json['booking_kind'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'event_id': eventId,
    'semantic_type': semanticType.toDbString(),
    'signed_amount': signedAmount,
    'created_at': createdAt?.toIso8601String(),
    'booking_id': bookingId,
    'trip_id': tripId,
    'trip_direction': tripDirection,
    'service_date': serviceDate?.toIso8601String(),
    'departure_at': departureAt?.toIso8601String(),
    'seat_number': seatNumber,
    'origin_name_ar': originNameAr,
    'origin_name_en': originNameEn,
    'destination_name_ar': destinationNameAr,
    'destination_name_en': destinationNameEn,
    'boarding_name_ar': boardingNameAr,
    'boarding_name_en': boardingNameEn,
    'alighting_name_ar': alightingNameAr,
    'alighting_name_en': alightingNameEn,
    'booking_kind': bookingKind,
  };
}

class WalletHistoryPageModel extends WalletHistoryPage {
  const WalletHistoryPageModel({
    required super.events,
    required super.hasMore,
    super.nextCursor,
  });

  factory WalletHistoryPageModel.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'];
    final List<WalletHistoryEventModel> events = (rawEvents is List)
        ? rawEvents
              .map(
                (e) => WalletHistoryEventModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
        : const [];

    final hasMore = json['has_more'] as bool? ?? false;

    final rawCursor = json['next_cursor'];
    final nextCursor = (rawCursor is Map)
        ? WalletHistoryCursor.fromJson(Map<String, dynamic>.from(rawCursor))
        : null;

    return WalletHistoryPageModel(
      events: events,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }
}
