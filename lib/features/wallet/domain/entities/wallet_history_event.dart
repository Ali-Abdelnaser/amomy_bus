import 'package:equatable/equatable.dart';

/// Semantic event types returned by public.get_my_wallet_history
enum WalletSemanticType {
  tripBooking,
  roundTripBooking,
  extraSeat,
  refund,
  pointsTopup,
  extraPoints,
  subscriptionPoints,
  pointsExpired,
  balanceAdjustment,
  welcomeGift,
  campaignGift,
  unknown;

  static WalletSemanticType fromString(String? raw) {
    if (raw == null) return WalletSemanticType.unknown;
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'trip_booking':
        return WalletSemanticType.tripBooking;
      case 'round_trip_booking':
        return WalletSemanticType.roundTripBooking;
      case 'extra_seat':
        return WalletSemanticType.extraSeat;
      case 'refund':
        return WalletSemanticType.refund;
      case 'points_topup':
        return WalletSemanticType.pointsTopup;
      case 'extra_points':
        return WalletSemanticType.extraPoints;
      case 'subscription_points':
        return WalletSemanticType.subscriptionPoints;
      case 'points_expired':
        return WalletSemanticType.pointsExpired;
      case 'balance_adjustment':
        return WalletSemanticType.balanceAdjustment;
      case 'welcome_gift':
        return WalletSemanticType.welcomeGift;
      case 'campaign_gift':
        return WalletSemanticType.campaignGift;
      default:
        return WalletSemanticType.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case WalletSemanticType.tripBooking:
        return 'trip_booking';
      case WalletSemanticType.roundTripBooking:
        return 'round_trip_booking';
      case WalletSemanticType.extraSeat:
        return 'extra_seat';
      case WalletSemanticType.refund:
        return 'refund';
      case WalletSemanticType.pointsTopup:
        return 'points_topup';
      case WalletSemanticType.extraPoints:
        return 'extra_points';
      case WalletSemanticType.subscriptionPoints:
        return 'subscription_points';
      case WalletSemanticType.pointsExpired:
        return 'points_expired';
      case WalletSemanticType.balanceAdjustment:
        return 'balance_adjustment';
      case WalletSemanticType.welcomeGift:
        return 'welcome_gift';
      case WalletSemanticType.campaignGift:
        return 'campaign_gift';
      case WalletSemanticType.unknown:
        return 'unknown';
    }
  }
}

/// A human-facing semantic wallet history event.
class WalletHistoryEvent extends Equatable {
  final String eventId;
  final WalletSemanticType semanticType;
  final int? signedAmount;
  final DateTime? createdAt;

  // Optional contextual trip & booking metadata
  final String? bookingId;
  final String? tripId;
  final String? tripDirection;
  final DateTime? serviceDate;
  final DateTime? departureAt;
  final String? seatNumber;
  final String? originNameAr;
  final String? originNameEn;
  final String? destinationNameAr;
  final String? destinationNameEn;
  final String? boardingNameAr;
  final String? boardingNameEn;
  final String? alightingNameAr;
  final String? alightingNameEn;
  final String? bookingKind;

  // Optional round trip bundle metadata
  final String? bundleId;
  final String? outboundBookingId;
  final String? returnBookingId;
  final String? outboundTripId;
  final String? returnTripId;
  final DateTime? outboundDepartureAt;
  final DateTime? returnDepartureAt;
  final String? outboundSeatNumber;
  final String? returnSeatNumber;
  final num? outboundBaseFarePoints;
  final num? returnBaseFarePoints;
  final num? subtotalPoints;
  final num? discountPercent;
  final num? discountPoints;
  final num? totalPaidPoints;

  const WalletHistoryEvent({
    required this.eventId,
    required this.semanticType,
    this.signedAmount,
    this.createdAt,
    this.bookingId,
    this.tripId,
    this.tripDirection,
    this.serviceDate,
    this.departureAt,
    this.seatNumber,
    this.originNameAr,
    this.originNameEn,
    this.destinationNameAr,
    this.destinationNameEn,
    this.boardingNameAr,
    this.boardingNameEn,
    this.alightingNameAr,
    this.alightingNameEn,
    this.bookingKind,
    this.bundleId,
    this.outboundBookingId,
    this.returnBookingId,
    this.outboundTripId,
    this.returnTripId,
    this.outboundDepartureAt,
    this.returnDepartureAt,
    this.outboundSeatNumber,
    this.returnSeatNumber,
    this.outboundBaseFarePoints,
    this.returnBaseFarePoints,
    this.subtotalPoints,
    this.discountPercent,
    this.discountPoints,
    this.totalPaidPoints,
  });

  bool get isCredit => (signedAmount ?? 0) > 0;
  bool get isDebit => (signedAmount ?? 0) < 0;
  bool get isNeutral => signedAmount == null || signedAmount == 0;

  String? localizedTripDirection(bool isArabic) {
    if (tripDirection == null) return null;
    final dir = tripDirection!.toLowerCase().trim();
    if (dir == 'outbound' || dir == 'going') {
      return isArabic ? 'ذهاب' : 'Outbound';
    } else if (dir == 'return' || dir == 'coming') {
      return isArabic ? 'عودة' : 'Return';
    } else if (dir == 'round_trip' || dir == 'roundtrip') {
      return isArabic ? 'ذهاب وعودة' : 'Round Trip';
    }
    return tripDirection;
  }

  String? localizedBoardingName(bool isArabic) {
    return isArabic
        ? (boardingNameAr ?? boardingNameEn)
        : (boardingNameEn ?? boardingNameAr);
  }

  String? localizedAlightingName(bool isArabic) {
    return isArabic
        ? (alightingNameAr ?? alightingNameEn)
        : (alightingNameEn ?? alightingNameAr);
  }

  @override
  List<Object?> get props => [
    eventId,
    semanticType,
    signedAmount,
    createdAt,
    bookingId,
    tripId,
    tripDirection,
    serviceDate,
    departureAt,
    seatNumber,
    originNameAr,
    originNameEn,
    destinationNameAr,
    destinationNameEn,
    boardingNameAr,
    boardingNameEn,
    alightingNameAr,
    alightingNameEn,
    bookingKind,
    bundleId,
    outboundBookingId,
    returnBookingId,
    outboundTripId,
    returnTripId,
    outboundDepartureAt,
    returnDepartureAt,
    outboundSeatNumber,
    returnSeatNumber,
    outboundBaseFarePoints,
    returnBaseFarePoints,
    subtotalPoints,
    discountPercent,
    discountPoints,
    totalPaidPoints,
  ];
}

/// Opaque pagination cursor for get_my_wallet_history
class WalletHistoryCursor extends Equatable {
  final String createdAt;
  final String eventId;

  const WalletHistoryCursor({required this.createdAt, required this.eventId});

  factory WalletHistoryCursor.fromJson(Map<String, dynamic> json) {
    return WalletHistoryCursor(
      createdAt: json['created_at']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'created_at': createdAt,
    'event_id': eventId,
  };

  @override
  List<Object?> get props => [createdAt, eventId];
}

/// Response page from get_my_wallet_history RPC
class WalletHistoryPage extends Equatable {
  final List<WalletHistoryEvent> events;
  final bool hasMore;
  final WalletHistoryCursor? nextCursor;

  const WalletHistoryPage({
    required this.events,
    required this.hasMore,
    this.nextCursor,
  });

  const WalletHistoryPage.empty()
    : events = const [],
      hasMore = false,
      nextCursor = null;

  @override
  List<Object?> get props => [events, hasMore, nextCursor];
}
