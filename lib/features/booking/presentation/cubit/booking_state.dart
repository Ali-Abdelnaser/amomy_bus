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
  final BookingMode bookingMode;
  final RoundTripSeatStep roundTripSeatStep;
  final List<RouteStop> routeStops;
  final RouteStop? selectedRouteStop; // Origin / Boarding Stop
  final RouteStop? selectedDestinationStop; // Drop-off / Destination Stop
  final List<TripOption> availableTrips;
  final TripOption? selectedTrip;
  final bool isTripLocked;
<<<<<<< HEAD
  final bool isLoadingRoundTripReturnOptions;
  final String? roundTripReturnOptionsError;
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
  final List<RoundTripReturnOption> returnOptions;
  final RoundTripReturnOption? selectedReturnOption;
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final List<TripSeat> returnSeats;
  final TripSeat? selectedReturnSeat;
  final BookingHold? activeHold;
  final RoundTripBundleHold? bundleHold;
  final int holdSecondsRemaining;
  final PassengerBooking? confirmedBooking;
  final RoundTripConfirmation? confirmedBundle;
  final String? errorMessage;
  final String? autoTripAlert;

  const BookingState({
    this.currentStep = BookingStep.direction,
    this.status = BookingStatus.initial,
    this.selectedDirection = BookingDirection.outbound,
    this.bookingMode = BookingMode.single,
    this.roundTripSeatStep = RoundTripSeatStep.outbound,
    this.routeStops = const [],
    this.selectedRouteStop,
    this.selectedDestinationStop,
    this.availableTrips = const [],
    this.selectedTrip,
    this.isTripLocked = false,
<<<<<<< HEAD
    this.isLoadingRoundTripReturnOptions = false,
    this.roundTripReturnOptionsError,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    this.returnOptions = const [],
    this.selectedReturnOption,
    this.seats = const [],
    this.selectedSeat,
    this.returnSeats = const [],
    this.selectedReturnSeat,
    this.activeHold,
    this.bundleHold,
    this.holdSecondsRemaining = 300,
    this.confirmedBooking,
    this.confirmedBundle,
    this.errorMessage,
    this.autoTripAlert,
  });

  bool get isRoundTrip => bookingMode == BookingMode.roundTrip;
  bool get isSingle => bookingMode == BookingMode.single;

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
    BookingMode? bookingMode,
    RoundTripSeatStep? roundTripSeatStep,
    List<RouteStop>? routeStops,
    RouteStop? selectedRouteStop,
    RouteStop? selectedDestinationStop,
    List<TripOption>? availableTrips,
    TripOption? selectedTrip,
    bool? isTripLocked,
<<<<<<< HEAD
    bool? isLoadingRoundTripReturnOptions,
    String? roundTripReturnOptionsError,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    List<RoundTripReturnOption>? returnOptions,
    RoundTripReturnOption? selectedReturnOption,
    List<TripSeat>? seats,
    TripSeat? selectedSeat,
    List<TripSeat>? returnSeats,
    TripSeat? selectedReturnSeat,
    BookingHold? activeHold,
    RoundTripBundleHold? bundleHold,
    int? holdSecondsRemaining,
    PassengerBooking? confirmedBooking,
    RoundTripConfirmation? confirmedBundle,
    String? errorMessage,
    String? autoTripAlert,
    bool clearSelectedRouteStop = false,
    bool clearSelectedDestinationStop = false,
    bool clearSelectedTrip = false,
    bool clearSelectedReturnOption = false,
    bool clearReturnOptions = false,
<<<<<<< HEAD
    bool clearRoundTripReturnOptionsError = false,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    bool clearSelectedSeat = false,
    bool clearSelectedReturnSeat = false,
    bool clearActiveHold = false,
    bool clearBundleHold = false,
    bool clearError = false,
    bool clearAutoTripAlert = false,
    bool clearAvailableTrips = false,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      selectedDirection: selectedDirection ?? this.selectedDirection,
      bookingMode: bookingMode ?? this.bookingMode,
      roundTripSeatStep: roundTripSeatStep ?? this.roundTripSeatStep,
      routeStops: routeStops ?? this.routeStops,
      selectedRouteStop: clearSelectedRouteStop
          ? null
          : (selectedRouteStop ?? this.selectedRouteStop),
      selectedDestinationStop: clearSelectedDestinationStop
          ? null
          : (selectedDestinationStop ?? this.selectedDestinationStop),
      availableTrips: clearAvailableTrips
          ? const []
          : (availableTrips ?? this.availableTrips),
      selectedTrip: clearSelectedTrip
          ? null
          : (selectedTrip ?? this.selectedTrip),
      isTripLocked: isTripLocked ?? this.isTripLocked,
<<<<<<< HEAD
      isLoadingRoundTripReturnOptions:
          isLoadingRoundTripReturnOptions ??
          this.isLoadingRoundTripReturnOptions,
      roundTripReturnOptionsError: clearRoundTripReturnOptionsError
          ? null
          : (roundTripReturnOptionsError ?? this.roundTripReturnOptionsError),
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
      returnOptions: clearReturnOptions
          ? const []
          : (returnOptions ?? this.returnOptions),
      selectedReturnOption: clearSelectedReturnOption
          ? null
          : (selectedReturnOption ?? this.selectedReturnOption),
      seats: seats ?? this.seats,
      selectedSeat: clearSelectedSeat
          ? null
          : (selectedSeat ?? this.selectedSeat),
      returnSeats: returnSeats ?? this.returnSeats,
      selectedReturnSeat: clearSelectedReturnSeat
          ? null
          : (selectedReturnSeat ?? this.selectedReturnSeat),
      activeHold: clearActiveHold ? null : (activeHold ?? this.activeHold),
      bundleHold: clearBundleHold ? null : (bundleHold ?? this.bundleHold),
      holdSecondsRemaining: holdSecondsRemaining ?? this.holdSecondsRemaining,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
      confirmedBundle: confirmedBundle ?? this.confirmedBundle,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      autoTripAlert: clearAutoTripAlert
          ? null
          : (autoTripAlert ?? this.autoTripAlert),
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    status,
    selectedDirection,
    bookingMode,
    roundTripSeatStep,
    routeStops,
    selectedRouteStop,
    selectedDestinationStop,
    availableTrips,
    selectedTrip,
    isTripLocked,
<<<<<<< HEAD
    isLoadingRoundTripReturnOptions,
    roundTripReturnOptionsError,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    returnOptions,
    selectedReturnOption,
    seats,
    selectedSeat,
    returnSeats,
    selectedReturnSeat,
    activeHold,
    bundleHold,
    holdSecondsRemaining,
    confirmedBooking,
    confirmedBundle,
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
        'mode: ${bookingMode.name}, '
        'status: ${status.name}, '
        'trip: $shortTrip, '
        'seat: ${selectedSeat?.seatNumber ?? 'none'}, '
        'returnSeat: ${selectedReturnSeat?.seatNumber ?? 'none'}, '
        'holdRemaining: ${holdSecondsRemaining}s'
        '${errorMessage != null ? ', error: $errorMessage' : ''})';
  }
}
