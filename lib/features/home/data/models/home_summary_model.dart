import '../../domain/entities/home_summary.dart';

class HomeSummaryModel extends HomeSummary {
  const HomeSummaryModel({
    required super.profile,
    required super.availablePoints,
    super.upcomingTrip,
    required super.activity,
  });

  factory HomeSummaryModel.fromJson(Map<String, dynamic> json) {
    // 1. Profile
    final profileJson = json['profile'] as Map<String, dynamic>? ?? {};
    final profile = PassengerProfileSummary(
      fullName: profileJson['full_name'] as String? ?? '',
      avatarUrl: profileJson['avatar_url'] as String?,
    );

    // 2. Wallet
    final walletJson = json['wallet'] as Map<String, dynamic>? ?? {};
    final availablePoints =
        (walletJson['available_points'] as num?)?.toInt() ?? 0;

    // 3. Upcoming Trip
    PassengerUpcomingTrip? upcomingTrip;
    final tripJson = json['upcoming_trip'] as Map<String, dynamic>?;
    if (tripJson != null) {
      upcomingTrip = PassengerUpcomingTrip(
        bookingId: tripJson['booking_id'] as String? ?? '',
        tripId: tripJson['trip_id'] as String? ?? '',
        direction: tripJson['direction'] as String? ?? '',
        originNameAr: tripJson['origin_name_ar'] as String? ?? '',
        originNameEn: tripJson['origin_name_en'] as String? ?? '',
        destinationNameAr: tripJson['destination_name_ar'] as String? ?? '',
        destinationNameEn: tripJson['destination_name_en'] as String? ?? '',
        serviceDate: tripJson['service_date'] != null
            ? DateTime.tryParse(tripJson['service_date'].toString()) ??
                  DateTime.now()
            : DateTime.now(),
        departureAt: tripJson['departure_at'] != null
            ? DateTime.tryParse(tripJson['departure_at'].toString()) ??
                  DateTime.now()
            : DateTime.now(),
        departureTime: tripJson['departure_time'] as String? ?? '--:--',
        seatNumber: tripJson['seat_number'] as String? ?? '',
        farePoints: (tripJson['fare_points'] as num?)?.toInt() ?? 0,
        bookingStatus: tripJson['booking_status'] as String? ?? 'confirmed',
        qrToken: tripJson['qr_token'] as String? ?? '',
        routeStopId: tripJson['route_stop_id'] as String?,
        stopNameAr: tripJson['stop_name_ar'] as String?,
        localityAr: tripJson['locality_ar'] as String?,
        checkedInAt: tripJson['checked_in_at'] != null
            ? DateTime.tryParse(tripJson['checked_in_at'].toString())
            : null,
      );
    }

    // 4. Activity
    final activityJson = json['activity'] as Map<String, dynamic>? ?? {};
    final activity = PassengerActivityMetrics(
      tripsThisMonth: (activityJson['trips_this_month'] as num?)?.toInt() ?? 0,
      completedTrips: (activityJson['completed_trips'] as num?)?.toInt() ?? 0,
      pointsSpentThisMonth:
          (activityJson['points_spent_this_month'] as num?)?.toInt() ?? 0,
      missedTrips: (activityJson['missed_trips'] as num?)?.toInt() ?? 0,
    );

    return HomeSummaryModel(
      profile: profile,
      availablePoints: availablePoints,
      upcomingTrip: upcomingTrip,
      activity: activity,
    );
  }
}
