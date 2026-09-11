import 'package:equatable/equatable.dart';
import '../../../booking/domain/entities/booking_entities.dart';

enum PassengerTripsStatus { initial, loading, loaded, error }

class PassengerTripsState extends Equatable {
  final PassengerTripsStatus status;
  final List<PassengerBooking> upcomingTrips;
  final List<PassengerBooking> pastTrips;
  final String? errorMessage;

  const PassengerTripsState({
    this.status = PassengerTripsStatus.initial,
    this.upcomingTrips = const [],
    this.pastTrips = const [],
    this.errorMessage,
  });

  PassengerBooking? get nearestUpcomingTrip =>
      upcomingTrips.isNotEmpty ? upcomingTrips.first : null;

  PassengerTripsState copyWith({
    PassengerTripsStatus? status,
    List<PassengerBooking>? upcomingTrips,
    List<PassengerBooking>? pastTrips,
    String? errorMessage,
  }) {
    return PassengerTripsState(
      status: status ?? this.status,
      upcomingTrips: upcomingTrips ?? this.upcomingTrips,
      pastTrips: pastTrips ?? this.pastTrips,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, upcomingTrips, pastTrips, errorMessage];
}
