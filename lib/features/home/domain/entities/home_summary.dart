import 'package:equatable/equatable.dart';

/// Lightweight passenger profile data for the Home screen.
class PassengerProfileSummary extends Equatable {
  final String fullName;
  final String? avatarUrl;

  const PassengerProfileSummary({
    required this.fullName,
    this.avatarUrl,
  });

  String get initials {
    if (fullName.trim().isEmpty) return 'P';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  String get firstName {
    if (fullName.trim().isEmpty) return '';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  @override
  List<Object?> get props => [fullName, avatarUrl];
}

/// Passenger upcoming trip data for the Home screen.
/// Note: bus internal details, plate number, and driver details are excluded for passenger privacy.
class PassengerUpcomingTrip extends Equatable {
  final String bookingId;
  final String tripId;
  final String direction;
  final String originNameAr;
  final String originNameEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final DateTime serviceDate;
  final DateTime departureAt;
  final String departureTime;
  final String seatNumber;
  final int farePoints;
  final String bookingStatus;
  final String qrToken;
  final String? routeStopId;
  final String? stopNameAr;
  final String? localityAr;

  const PassengerUpcomingTrip({
    required this.bookingId,
    required this.tripId,
    required this.direction,
    required this.originNameAr,
    required this.originNameEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    required this.serviceDate,
    required this.departureAt,
    required this.departureTime,
    required this.seatNumber,
    required this.farePoints,
    required this.bookingStatus,
    required this.qrToken,
    this.routeStopId,
    this.stopNameAr,
    this.localityAr,
  });

  String originName(String locale) =>
      locale == 'ar' ? originNameAr : originNameEn;

  String destinationName(String locale) =>
      locale == 'ar' ? destinationNameAr : destinationNameEn;

  String? get boardingStopDisplayName {
    if (stopNameAr == null || stopNameAr!.isEmpty) return null;
    if (localityAr != null && localityAr!.isNotEmpty && localityAr != stopNameAr) {
      return '$stopNameAr — $localityAr';
    }
    return stopNameAr;
  }

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
        departureAt,
        departureTime,
        seatNumber,
        farePoints,
        bookingStatus,
        qrToken,
        routeStopId,
        stopNameAr,
        localityAr,
      ];
}

/// Passenger activity analytics metrics for the Home screen.
class PassengerActivityMetrics extends Equatable {
  final int tripsThisMonth;
  final int completedTrips;
  final int pointsSpentThisMonth;
  final int missedTrips;

  const PassengerActivityMetrics({
    required this.tripsThisMonth,
    required this.completedTrips,
    required this.pointsSpentThisMonth,
    required this.missedTrips,
  });

  @override
  List<Object?> get props => [
        tripsThisMonth,
        completedTrips,
        pointsSpentThisMonth,
        missedTrips,
      ];
}

/// Aggregated passenger home summary returned by `get_passenger_home_summary`.
class HomeSummary extends Equatable {
  final PassengerProfileSummary profile;
  final int availablePoints;
  final PassengerUpcomingTrip? upcomingTrip;
  final PassengerActivityMetrics activity;

  const HomeSummary({
    required this.profile,
    required this.availablePoints,
    this.upcomingTrip,
    required this.activity,
  });

  @override
  List<Object?> get props => [
        profile,
        availablePoints,
        upcomingTrip,
        activity,
      ];
}
