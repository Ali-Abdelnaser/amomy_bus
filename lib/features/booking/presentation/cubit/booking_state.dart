import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entities.dart';

enum BookingStep {
  setup, // Smart booking setup screen: FROM, TO, TRIP/TIME all in one step
  seatMap,
  review,
  success,
  // Backward-compatible steps
  direction,
  boardingStop,
  departureTime,
}

enum BookingStatus {
  initial,
  loading,
  routeStopsLoaded,
  tripsLoaded,
  seatMapLoaded,
  holdingSeat,
  seatHeld,
  confirming,
  confirmed,
  error,
}

class BookingState extends Equatable {
  final BookingStep currentStep;
  final BookingStatus status;
  final BookingDirection selectedDirection;
  final List<RouteStop> routeStops;
  final RouteStop? selectedRouteStop; // Origin / Boarding Stop
  final RouteStop? selectedDestinationStop; // Drop-off / Destination Stop
  final List<TripOption> availableTrips;
  final TripOption? selectedTrip;
  final bool isTripLocked;
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final BookingHold? activeHold;
  final int holdSecondsRemaining;
  final PassengerBooking? confirmedBooking;
  final String? errorMessage;
  final String? autoTripAlert;

  const BookingState({
    this.currentStep = BookingStep.direction,
    this.status = BookingStatus.initial,
    this.selectedDirection = BookingDirection.outbound,
    this.routeStops = const [],
    this.selectedRouteStop,
    this.selectedDestinationStop,
    this.availableTrips = const [],
    this.selectedTrip,
    this.isTripLocked = false,
    this.seats = const [],
    this.selectedSeat,
    this.activeHold,
    this.holdSecondsRemaining = 300,
    this.confirmedBooking,
    this.errorMessage,
    this.autoTripAlert,
  });

  /// Dynamic fare determined primarily by the passenger's selected boarding stop.
  double get farePoints =>
      selectedRouteStop?.farePoints ?? selectedTrip?.farePoints ?? 0.0;

  /// Informational readonly service date (today).
  DateTime get serviceDate => DateTime.now();

  /// Drop-off stops valid for the currently chosen boarding stop (stopOrder > origin.stopOrder).
  List<RouteStop> get destinationStops {
    if (selectedRouteStop == null) return routeStops;
    return routeStops
        .where((s) => s.stopOrder > selectedRouteStop!.stopOrder)
        .toList();
  }

  BookingState copyWith({
    BookingStep? currentStep,
    BookingStatus? status,
    BookingDirection? selectedDirection,
    List<RouteStop>? routeStops,
    RouteStop? selectedRouteStop,
    RouteStop? selectedDestinationStop,
    List<TripOption>? availableTrips,
    TripOption? selectedTrip,
    bool? isTripLocked,
    List<TripSeat>? seats,
    TripSeat? selectedSeat,
    BookingHold? activeHold,
    int? holdSecondsRemaining,
    PassengerBooking? confirmedBooking,
    String? errorMessage,
    String? autoTripAlert,
    bool clearSelectedRouteStop = false,
    bool clearSelectedDestinationStop = false,
    bool clearSelectedTrip = false,
    bool clearSelectedSeat = false,
    bool clearActiveHold = false,
    bool clearError = false,
    bool clearAutoTripAlert = false,
    bool clearAvailableTrips = false,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      selectedDirection: selectedDirection ?? this.selectedDirection,
      routeStops: routeStops ?? this.routeStops,
      selectedRouteStop: clearSelectedRouteStop
          ? null
          : (selectedRouteStop ?? this.selectedRouteStop),
      selectedDestinationStop: clearSelectedDestinationStop
          ? null
          : (selectedDestinationStop ?? this.selectedDestinationStop),
      availableTrips: clearAvailableTrips ? const [] : (availableTrips ?? this.availableTrips),
      selectedTrip:
          clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),

      isTripLocked: isTripLocked ?? this.isTripLocked,
      seats: seats ?? this.seats,
      selectedSeat:
          clearSelectedSeat ? null : (selectedSeat ?? this.selectedSeat),
      activeHold: clearActiveHold ? null : (activeHold ?? this.activeHold),
      holdSecondsRemaining:
          holdSecondsRemaining ?? this.holdSecondsRemaining,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      autoTripAlert:
          clearAutoTripAlert ? null : (autoTripAlert ?? this.autoTripAlert),
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        status,
        selectedDirection,
        routeStops,
        selectedRouteStop,
        selectedDestinationStop,
        availableTrips,
        selectedTrip,
        isTripLocked,
        seats,
        selectedSeat,
        activeHold,
        holdSecondsRemaining,
        confirmedBooking,
        errorMessage,
        autoTripAlert,
      ];

  @override
  String toString() {
    final tripId = selectedTrip?.tripId;
    final shortTrip = tripId != null
        ? (tripId.length > 8 ? '${tripId.substring(0, 8)}...' : tripId)
        : 'none';
    return 'BookingState('
        'step: ${currentStep.name}, '
        'status: ${status.name}, '
        'trip: $shortTrip, '
        'seat: ${selectedSeat?.seatNumber ?? 'none'}, '
        'holdRemaining: ${holdSecondsRemaining}s'
        '${errorMessage != null ? ', error: $errorMessage' : ''})';
  }
}
