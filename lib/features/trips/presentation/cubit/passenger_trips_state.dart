import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/services/passenger_booking_availability.dart';

enum PassengerTripsStatus { initial, loading, loaded, error }

class PassengerTripsState extends Equatable {
  final PassengerTripsStatus status;
  final List<PassengerTodayTrip> todayTrips;
  final PassengerTripPreference? preferredJourney;
  final List<PassengerBooking> historyTrips;
  final List<PassengerBooking> upcomingTrips;
  final List<RouteStop> availableStops;
  final String? errorMessage;
  final Failure? errorFailure;

  const PassengerTripsState({
    this.status = PassengerTripsStatus.initial,
    this.todayTrips = const [],
    this.preferredJourney,
    this.historyTrips = const [],
    this.upcomingTrips = const [],
    this.availableStops = const [],
    this.errorMessage,
    this.errorFailure,
  });

  List<PassengerTodayTrip> get outboundTodayTrips => todayTrips
      .where((t) => t.direction == BookingDirection.outbound)
      .toList();

  List<PassengerTodayTrip> get returnTodayTrips => todayTrips
      .where((t) => t.direction == BookingDirection.returnTrip)
      .toList();

  PassengerTodayTrip? get nextAvailableTrip {
    final available = todayTrips.where((t) => t.isBookable).toList();
    if (available.isEmpty) return null;
    available.sort((a, b) => a.departureAt.compareTo(b.departureAt));
    return available.first;
  }

  bool get hasLoadedTodayTrips => status == PassengerTripsStatus.loaded;

  bool get hasAnyBookableTrip =>
      PassengerBookingAvailability.hasAnyBookableTrip(todayTrips);

  bool get shouldDisableBookingEntry =>
      hasLoadedTodayTrips && !hasAnyBookableTrip;

  PassengerBooking? get nearestUpcomingTrip =>
      upcomingTrips.isNotEmpty ? upcomingTrips.first : null;

  PassengerTripsState copyWith({
    PassengerTripsStatus? status,
    List<PassengerTodayTrip>? todayTrips,
    PassengerTripPreference? preferredJourney,
    bool clearPreferredJourney = false,
    List<PassengerBooking>? historyTrips,
    List<PassengerBooking>? upcomingTrips,
    List<RouteStop>? availableStops,
    String? errorMessage,
    Failure? errorFailure,
    bool clearError = false,
  }) {
    return PassengerTripsState(
      status: status ?? this.status,
      todayTrips: todayTrips ?? this.todayTrips,
      preferredJourney: clearPreferredJourney
          ? null
          : (preferredJourney ?? this.preferredJourney),
      historyTrips: historyTrips ?? this.historyTrips,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      availableStops: availableStops ?? this.availableStops,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorFailure: clearError ? null : (errorFailure ?? this.errorFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    todayTrips,
    preferredJourney,
    historyTrips,
    upcomingTrips,
    availableStops,
    errorMessage,
    errorFailure,
  ];
}
