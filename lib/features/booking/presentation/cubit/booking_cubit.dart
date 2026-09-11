// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/usecases/booking_usecases.dart';
import 'booking_state.dart';

@injectable
class BookingCubit extends Cubit<BookingState> {
  final GetAvailableTripsUseCase _getAvailableTripsUseCase;
  final GetTripSeatMapUseCase _getTripSeatMapUseCase;
  final CreateBookingHoldUseCase _createBookingHoldUseCase;
  final ReleaseBookingHoldUseCase _releaseBookingHoldUseCase;
  final ConfirmBookingUseCase _confirmBookingUseCase;

  Timer? _countdownTimer;
  StreamSubscription? _seatSubscription;

  BookingCubit({
    required GetAvailableTripsUseCase getAvailableTripsUseCase,
    required GetTripSeatMapUseCase getTripSeatMapUseCase,
    required CreateBookingHoldUseCase createBookingHoldUseCase,
    required ReleaseBookingHoldUseCase releaseBookingHoldUseCase,
    required ConfirmBookingUseCase confirmBookingUseCase,
  })  : _getAvailableTripsUseCase = getAvailableTripsUseCase,
        _getTripSeatMapUseCase = getTripSeatMapUseCase,
        _createBookingHoldUseCase = createBookingHoldUseCase,
        _releaseBookingHoldUseCase = releaseBookingHoldUseCase,
        _confirmBookingUseCase = confirmBookingUseCase,
        super(BookingState(
          selectedDate: DateTime.now().add(const Duration(days: 1)),
        ));

  void setDirection(BookingDirection direction) {
    emit(state.copyWith(
      selectedDirection: direction,
      currentStep: BookingStep.directionAndDate,
      selectedTrip: null,
      clearSelectedSeat: true,
      clearActiveHold: true,
      clearError: true,
    ));
    loadAvailableTrips();
  }

  void setDate(DateTime date) {
    emit(state.copyWith(
      selectedDate: date,
      selectedTrip: null,
      clearSelectedSeat: true,
      clearActiveHold: true,
      clearError: true,
    ));
    loadAvailableTrips();
  }

  Future<void> loadAvailableTrips() async {
    emit(state.copyWith(status: BookingStatus.loading, clearError: true));

    final result = await _getAvailableTripsUseCase(
      direction: state.selectedDirection,
      date: state.selectedDate,
    );

    result.fold(
      onSuccess: (trips) {
        emit(state.copyWith(
          status: BookingStatus.tripsLoaded,
          availableTrips: trips,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          status: BookingStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  void selectTrip(TripOption trip) {
    emit(state.copyWith(
      selectedTrip: trip,
      currentStep: BookingStep.seatMap,
      clearSelectedSeat: true,
      clearActiveHold: true,
      clearError: true,
    ));
    loadSeatMap(trip.tripId);
  }

  Future<void> loadSeatMap(String tripId) async {
    emit(state.copyWith(status: BookingStatus.loading, clearError: true));

    final result = await _getTripSeatMapUseCase(tripId: tripId);

    result.fold(
      onSuccess: (seats) {
        emit(state.copyWith(
          status: BookingStatus.seatMapLoaded,
          seats: seats,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          status: BookingStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  Future<void> selectSeatAndHold(TripSeat seat) async {
    final currentTrip = state.selectedTrip;
    if (currentTrip == null) return;

    if (!seat.isAvailable && !seat.isMine) {
      return;
    }

    emit(state.copyWith(status: BookingStatus.holdingSeat, clearError: true));

    final result = await _createBookingHoldUseCase(
      tripId: currentTrip.tripId,
      seatId: seat.seatId,
    );

    result.fold(
      onSuccess: (hold) {
        _startHoldTimer(hold);
        emit(state.copyWith(
          status: BookingStatus.seatHeld,
          selectedSeat: seat,
          activeHold: hold,
          holdSecondsRemaining: hold.remainingSeconds,
        ));
      },
      onError: (failure) {
        loadSeatMap(currentTrip.tripId);
        emit(state.copyWith(
          status: BookingStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  void proceedToReview() {
    if (state.activeHold == null || state.selectedSeat == null) return;
    emit(state.copyWith(currentStep: BookingStep.review, clearError: true));
  }

  void backToSeatMap() {
    emit(state.copyWith(currentStep: BookingStep.seatMap, clearError: true));
  }

  void backToTrips() {
    _cancelHoldTimer();
    final hold = state.activeHold;
    if (hold != null) {
      _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    emit(state.copyWith(
      currentStep: BookingStep.directionAndDate,
      clearSelectedTrip: true,
      clearSelectedSeat: true,
      clearActiveHold: true,
      clearError: true,
    ));
    loadAvailableTrips();
  }

  Future<void> confirmBooking() async {
    final hold = state.activeHold;
    if (hold == null) return;

    emit(state.copyWith(status: BookingStatus.confirming, clearError: true));

    final result = await _confirmBookingUseCase(holdId: hold.holdId);

    result.fold(
      onSuccess: (booking) {
        _cancelHoldTimer();
        emit(state.copyWith(
          status: BookingStatus.confirmed,
          currentStep: BookingStep.success,
          confirmedBooking: booking,
          clearActiveHold: true,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          status: BookingStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }

  void _startHoldTimer(BookingHold hold) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = hold.remainingSeconds;
      if (remaining <= 0) {
        timer.cancel();
        emit(state.copyWith(
          holdSecondsRemaining: 0,
          clearActiveHold: true,
          clearSelectedSeat: true,
          currentStep: BookingStep.seatMap,
          errorMessage: 'HOLD_EXPIRED',
        ));
        if (state.selectedTrip != null) {
          loadSeatMap(state.selectedTrip!.tripId);
        }
      } else {
        emit(state.copyWith(holdSecondsRemaining: remaining));
      }
    });
  }

  void _cancelHoldTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelHoldTimer();
    _seatSubscription?.cancel();
    final hold = state.activeHold;
    if (hold != null) {
      _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    return super.close();
  }
}
