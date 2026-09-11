import 'package:equatable/equatable.dart';
import '../../domain/entities/booking_entities.dart';

enum BookingStep {
  directionAndDate,
  timeSelection,
  seatMap,
  review,
  success,
}

enum BookingStatus {
  initial,
  loading,
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
  final DateTime selectedDate;
  final List<TripOption> availableTrips;
  final TripOption? selectedTrip;
  final List<TripSeat> seats;
  final TripSeat? selectedSeat;
  final BookingHold? activeHold;
  final int holdSecondsRemaining;
  final PassengerBooking? confirmedBooking;
  final String? errorMessage;

  const BookingState({
    this.currentStep = BookingStep.directionAndDate,
    this.status = BookingStatus.initial,
    this.selectedDirection = BookingDirection.outbound,
    required this.selectedDate,
    this.availableTrips = const [],
    this.selectedTrip,
    this.seats = const [],
    this.selectedSeat,
    this.activeHold,
    this.holdSecondsRemaining = 300,
    this.confirmedBooking,
    this.errorMessage,
  });

  BookingState copyWith({
    BookingStep? currentStep,
    BookingStatus? status,
    BookingDirection? selectedDirection,
    DateTime? selectedDate,
    List<TripOption>? availableTrips,
    TripOption? selectedTrip,
    List<TripSeat>? seats,
    TripSeat? selectedSeat,
    BookingHold? activeHold,
    int? holdSecondsRemaining,
    PassengerBooking? confirmedBooking,
    String? errorMessage,
    bool clearSelectedTrip = false,
    bool clearSelectedSeat = false,
    bool clearActiveHold = false,
    bool clearError = false,
  }) {
    return BookingState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      selectedDirection: selectedDirection ?? this.selectedDirection,
      selectedDate: selectedDate ?? this.selectedDate,
      availableTrips: availableTrips ?? this.availableTrips,
      selectedTrip: clearSelectedTrip ? null : (selectedTrip ?? this.selectedTrip),
      seats: seats ?? this.seats,
      selectedSeat: clearSelectedSeat ? null : (selectedSeat ?? this.selectedSeat),
      activeHold: clearActiveHold ? null : (activeHold ?? this.activeHold),
      holdSecondsRemaining: holdSecondsRemaining ?? this.holdSecondsRemaining,
      confirmedBooking: confirmedBooking ?? this.confirmedBooking,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        status,
        selectedDirection,
        selectedDate,
        availableTrips,
        selectedTrip,
        seats,
        selectedSeat,
        activeHold,
        holdSecondsRemaining,
        confirmedBooking,
        errorMessage,
      ];
}
