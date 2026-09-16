// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/booking_usecases.dart';
import 'booking_state.dart';

@injectable
class BookingCubit extends Cubit<BookingState> {
  final GetRouteStopsUseCase _getRouteStopsUseCase;
  final GetAvailableTripsUseCase _getAvailableTripsUseCase;
  final GetTripSeatMapUseCase _getTripSeatMapUseCase;
  final CreateBookingHoldUseCase _createBookingHoldUseCase;
  final ReleaseBookingHoldUseCase _releaseBookingHoldUseCase;
  final ConfirmBookingUseCase _confirmBookingUseCase;
  final GetMyTripPreferencesUseCase? _getMyTripPreferencesUseCase;
  final GetPassengerBookingsUseCase? _getPassengerBookingsUseCase;
  final BookingRepository? _bookingRepository;

  Timer? _countdownTimer;
  StreamSubscription? _seatSubscription;
  bool _seatMapRefreshInFlight = false;
  bool _seatMapRefreshQueued = false;

  BookingCubit({
    required GetRouteStopsUseCase getRouteStopsUseCase,
    required GetAvailableTripsUseCase getAvailableTripsUseCase,
    required GetTripSeatMapUseCase getTripSeatMapUseCase,
    required CreateBookingHoldUseCase createBookingHoldUseCase,
    required ReleaseBookingHoldUseCase releaseBookingHoldUseCase,
    required ConfirmBookingUseCase confirmBookingUseCase,
    GetMyTripPreferencesUseCase? getMyTripPreferencesUseCase,
    GetPassengerBookingsUseCase? getPassengerBookingsUseCase,
    BookingRepository? bookingRepository,
  }) : _getRouteStopsUseCase = getRouteStopsUseCase,
       _getAvailableTripsUseCase = getAvailableTripsUseCase,
       _getTripSeatMapUseCase = getTripSeatMapUseCase,
       _createBookingHoldUseCase = createBookingHoldUseCase,
       _releaseBookingHoldUseCase = releaseBookingHoldUseCase,
       _confirmBookingUseCase = confirmBookingUseCase,
       _getMyTripPreferencesUseCase = getMyTripPreferencesUseCase,
       _getPassengerBookingsUseCase = getPassengerBookingsUseCase,
       _bookingRepository = bookingRepository,
       super(const BookingState());

  /// Initializes smart booking:
  /// - If `initialTripId` is passed (e.g. from a specific trip card), the trip is pre-selected and locked.
  /// - Origin and Destination are pre-filled from passenger's Preferred Journey if available.
  /// - If generic booking, automatically selects the next available trip for today.
  Future<void> initBooking({
    String? initialTripId,
    BookingDirection? initialDirection,
    String? initialOriginStopId,
    String? initialDestinationStopId,
  }) async {
    final direction = initialDirection ?? state.selectedDirection;
    emit(
      state.copyWith(
        status: BookingStatus.loading,
        currentStep: BookingStep.setup,
        selectedDirection: direction,
        isTripLocked: initialTripId != null,
        clearAvailableTrips: true,
        clearSelectedTrip: true,
        clearSelectedRouteStop: true,
        clearSelectedDestinationStop: true,
        clearError: true,
        clearAutoTripAlert: true,
      ),
    );

    // 1. Fetch preferred journey from backend if not provided explicitly
    PassengerTripPreference? pref;
    if (initialOriginStopId == null) {
      if (_getMyTripPreferencesUseCase != null) {
        final res = await _getMyTripPreferencesUseCase();
        res.fold(onSuccess: (p) => pref = p, onError: (_) {});
      } else if (getIt.isRegistered<BookingRepository>()) {
        final res = await getIt<BookingRepository>().getMyTripPreferences();
        res.fold(onSuccess: (p) => pref = p, onError: (_) {});
      }
    }

    // 2. Fetch route stops for the direction
    final stopsRes = await _getRouteStopsUseCase(direction: direction);
    List<RouteStop> stops = [];
    stopsRes.fold(
      onSuccess: (s) => stops = s,
      onError: (err) => emit(
        state.copyWith(status: BookingStatus.error, errorMessage: err.message),
      ),
    );

    // Resolve Origin and Destination stops
    RouteStop? resolvedOrigin;
    RouteStop? resolvedDestination;

    final targetOriginId = initialOriginStopId ?? pref?.originStopId;
    final targetDestId = initialDestinationStopId ?? pref?.destinationStopId;

    if (targetOriginId != null) {
      resolvedOrigin = stops.cast<RouteStop?>().firstWhere(
        (s) => s?.stopId == targetOriginId,
        orElse: () => null,
      );
    }
    resolvedOrigin ??= stops.isNotEmpty ? stops.first : null;

    if (targetDestId != null) {
      resolvedDestination = stops.cast<RouteStop?>().firstWhere(
        (s) =>
            s?.stopId == targetDestId &&
            (resolvedOrigin == null || s!.stopOrder > resolvedOrigin.stopOrder),
        orElse: () => null,
      );
    }
    resolvedDestination ??= stops.length > 1 ? stops.last : null;

    // 3. Fetch today's available trips
    final tripsRes = await _getAvailableTripsUseCase(
      direction: direction,
      routeStopId: resolvedOrigin?.routeStopId,
    );

    List<TripOption> trips = [];
    String? tripErrorMessage;
    tripsRes.fold(
      onSuccess: (t) => trips = t,
      onError: (err) => tripErrorMessage = err.message,
    );

    final bookedTripIds = await _fetchActiveBookedTripIds();
    final availableTrips = trips
        .where((t) => !bookedTripIds.contains(t.tripId))
        .toList();

    // 4. Resolve trip
    TripOption? resolvedTrip;
    String? tripAlert;
    bool isLocked = initialTripId != null;

    if (initialTripId != null) {
      if (bookedTripIds.contains(initialTripId)) {
        tripAlert = 'لقد قمت بحجز هذه الرحلة بالفعل';
        isLocked = false;
      } else {
        resolvedTrip = availableTrips.cast<TripOption?>().firstWhere(
          (t) => t?.tripId == initialTripId,
          orElse: () => null,
        );
      }
    }

    if (resolvedTrip == null) {
      // Pick next available bookable trip for today
      final bookableTrips = availableTrips
          .where((t) => t.availableSeatsCount > 0)
          .toList();
      if (bookableTrips.isNotEmpty) {
        resolvedTrip = bookableTrips.first;
      } else if (availableTrips.isNotEmpty) {
        resolvedTrip = availableTrips.first;
      }
    }

    emit(
      state.copyWith(
        status: tripErrorMessage != null
            ? BookingStatus.error
            : BookingStatus.tripsLoaded,
        errorMessage: tripErrorMessage,
        currentStep: BookingStep.setup,
        selectedDirection: direction,
        routeStops: stops,
        selectedRouteStop: resolvedOrigin,
        selectedDestinationStop: resolvedDestination,
        availableTrips: availableTrips,
        selectedTrip: resolvedTrip,
        isTripLocked: isLocked && resolvedTrip != null,
        autoTripAlert: tripAlert,
      ),
    );
  }

  Future<Set<String>> _fetchActiveBookedTripIds() async {
    final bookedTripIds = <String>{};
    final useCase =
        _getPassengerBookingsUseCase ??
        (getIt.isRegistered<GetPassengerBookingsUseCase>()
            ? getIt<GetPassengerBookingsUseCase>()
            : null);
    if (useCase != null) {
      final res = await useCase();
      res.fold(
        onSuccess: (bookings) {
          for (final b in bookings) {
            if (b.status != 'cancelled') {
              bookedTripIds.add(b.tripId);
            }
          }
        },
        onError: (_) {},
      );
    }
    return bookedTripIds;
  }

  /// Sets direction and refreshes route stops & trips.
  void setDirection(BookingDirection direction) {
    if (state.currentStep == BookingStep.setup) {
      if (state.selectedDirection == direction && state.routeStops.isNotEmpty) {
        return;
      }
      initBooking(initialDirection: direction);
    } else {
      emit(
        state.copyWith(
          selectedDirection: direction,
          currentStep: BookingStep.direction,
          clearSelectedRouteStop: true,
          clearSelectedTrip: true,
          clearSelectedSeat: true,
          clearActiveHold: true,
          clearError: true,
        ),
      );
      loadRouteStops();
    }
  }

  /// Selects Origin (Boarding) Stop
  void selectOriginStop(RouteStop stop) {
    RouteStop? currentDest = state.selectedDestinationStop;
    // If destination is before new origin, pick last stop
    if (currentDest != null && currentDest.stopOrder <= stop.stopOrder) {
      final validStops = state.routeStops
          .where((s) => s.stopOrder > stop.stopOrder)
          .toList();
      currentDest = validStops.isNotEmpty ? validStops.last : null;
    }

    emit(
      state.copyWith(
        selectedRouteStop: stop,
        selectedDestinationStop: currentDest,
        clearSelectedSeat: true,
        clearActiveHold: true,
        clearError: true,
      ),
    );
    loadAvailableTrips();
  }

  /// Selects Destination (Drop-off) Stop
  void selectDestinationStop(RouteStop stop) {
    emit(state.copyWith(selectedDestinationStop: stop, clearError: true));
  }

  /// Selects a trip departure
  void selectTrip(TripOption trip) {
    if (state.currentStep == BookingStep.setup) {
      emit(
        state.copyWith(
          selectedTrip: trip,
          clearSelectedSeat: true,
          clearActiveHold: true,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedTrip: trip,
          currentStep: BookingStep.seatMap,
          clearSelectedSeat: true,
          clearActiveHold: true,
          clearError: true,
        ),
      );
      loadSeatMap(trip.tripId);
    }
  }

  /// Unlocks a locked trip so passenger can pick another time
  void unlockTrip() {
    emit(state.copyWith(isTripLocked: false));
  }

  /// Proceeds from Smart Setup (Step 1) to Seat Map (Step 2)
  void proceedToSeatMap() {
    if (state.selectedRouteStop == null ||
        state.selectedDestinationStop == null ||
        state.selectedTrip == null) {
      emit(
        state.copyWith(
          errorMessage: 'يرجى تحديد محطة الركوب، محطة النزول، وموعد الرحلة.',
        ),
      );
      return;
    }

    final trip = state.selectedTrip!;
    emit(
      state.copyWith(
        currentStep: BookingStep.seatMap,
        clearSelectedSeat: true,
        clearActiveHold: true,
        clearError: true,
      ),
    );
    loadSeatMap(trip.tripId);
  }

  /// Loads route stops
  Future<void> loadRouteStops() async {
    emit(state.copyWith(status: BookingStatus.loading, clearError: true));
    final result = await _getRouteStopsUseCase(
      direction: state.selectedDirection,
    );
    result.fold(
      onSuccess: (stops) {
        emit(
          state.copyWith(
            status: BookingStatus.routeStopsLoaded,
            routeStops: stops,
            selectedRouteStop: stops.isNotEmpty ? stops.first : null,
            selectedDestinationStop: stops.length > 1 ? stops.last : null,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Loads today-only available trips from backend
  Future<void> loadAvailableTrips() async {
    final bookedTripIds = await _fetchActiveBookedTripIds();
    final result = await _getAvailableTripsUseCase(
      direction: state.selectedDirection,
      routeStopId: state.selectedRouteStop?.routeStopId,
    );

    result.fold(
      onSuccess: (rawTrips) {
        final trips = rawTrips
            .where((t) => !bookedTripIds.contains(t.tripId))
            .toList();
        TripOption? current = state.selectedTrip;
        String? alert;
        if (current != null && !state.isTripLocked) {
          final stillValid = trips.any(
            (t) => t.tripId == current!.tripId && t.availableSeatsCount > 0,
          );
          if (!stillValid) {
            final next = trips
                .where((t) => t.availableSeatsCount > 0)
                .firstOrNull;
            if (next != null) {
              alert =
                  'رحلة ${current.departureTime} غير متاحة، تم اختيار رحلة ${next.departureTime}';
              current = next;
            } else if (trips.isNotEmpty) {
              current = trips.first;
            } else {
              current = null;
            }
          }
        } else if (current == null && trips.isNotEmpty) {
          current =
              trips.where((t) => t.availableSeatsCount > 0).firstOrNull ??
              trips.first;
        } else if (current != null && bookedTripIds.contains(current.tripId)) {
          current =
              trips.where((t) => t.availableSeatsCount > 0).firstOrNull ??
              (trips.isNotEmpty ? trips.first : null);
        }
        emit(
          state.copyWith(
            status: BookingStatus.tripsLoaded,
            availableTrips: trips,
            selectedTrip: current,
            autoTripAlert: alert,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Loads seat map for selected trip.
  Future<void> loadSeatMap(String tripId) async {
    emit(state.copyWith(status: BookingStatus.loading, clearError: true));

    final result = await _getTripSeatMapUseCase(tripId: tripId);

    result.fold(
      onSuccess: (seats) {
        emit(state.copyWith(status: BookingStatus.seatMapLoaded, seats: seats));
        _startSeatUpdatesSubscription(tripId);
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  Future<void> _refreshSeatMapSilently(String tripId) async {
    if (_seatMapRefreshInFlight) {
      _seatMapRefreshQueued = true;
      return;
    }

    _seatMapRefreshInFlight = true;
    try {
      do {
        _seatMapRefreshQueued = false;
        final result = await _getTripSeatMapUseCase(tripId: tripId);
        if (isClosed || state.selectedTrip?.tripId != tripId) return;

        result.fold(
          onSuccess: (seats) {
            if (isClosed) return;
            final currentSeat = state.selectedSeat;
            final refreshedSelectedSeat = currentSeat == null
                ? null
                : seats.cast<TripSeat?>().firstWhere(
                    (seat) => seat?.seatId == currentSeat.seatId,
                    orElse: () => null,
                  );
            final canKeepSelectedSeat =
                refreshedSelectedSeat != null &&
                (refreshedSelectedSeat.isAvailable ||
                    refreshedSelectedSeat.isMine ||
                    state.activeHold?.seatId == refreshedSelectedSeat.seatId);

            emit(
              state.copyWith(
                seats: seats,
                selectedSeat: canKeepSelectedSeat
                    ? refreshedSelectedSeat
                    : null,
                clearSelectedSeat: currentSeat != null && !canKeepSelectedSeat,
              ),
            );
          },
          onError: (_) {},
        );
      } while (_seatMapRefreshQueued &&
          !isClosed &&
          state.selectedTrip?.tripId == tripId);
    } finally {
      _seatMapRefreshInFlight = false;
    }
  }

  void _startSeatUpdatesSubscription(String tripId) {
    _seatSubscription?.cancel();
    final repo =
        _bookingRepository ??
        (getIt.isRegistered<BookingRepository>()
            ? getIt<BookingRepository>()
            : null);
    if (repo == null) return;

    _seatSubscription = repo
        .subscribeToTripSeatUpdates(tripId)
        .listen(
          (_) => _refreshSeatMapSilently(tripId),
          onError: (error, stackTrace) {},
          cancelOnError: false,
        );
  }

  /// Selects a seat and creates a server hold snapshotting stop fare and destination.
  Future<void> selectSeatAndHold(TripSeat seat) async {
    // Double-submit guard
    if (state.status == BookingStatus.holdingSeat) return;
    final currentTrip = state.selectedTrip;
    if (currentTrip == null) return;

    if (!seat.isAvailable && !seat.isMine) {
      return;
    }

    _cancelHoldTimer();

    // If there was an active hold on a different seat, release it cleanly
    final oldHold = state.activeHold;
    if (oldHold != null && state.selectedSeat?.seatId != seat.seatId) {
      _releaseBookingHoldUseCase(holdId: oldHold.holdId);
    }

    emit(
      state.copyWith(
        status: BookingStatus.holdingSeat,
        clearError: true,
        clearActiveHold: true,
        holdSecondsRemaining: 0,
      ),
    );

    final result = await _createBookingHoldUseCase(
      tripId: currentTrip.tripId,
      seatId: seat.seatId,
      routeStopId: state.selectedRouteStop?.routeStopId,
      destinationRouteStopId: state.selectedDestinationStop?.routeStopId,
    );

    result.fold(
      onSuccess: (hold) {
        _startHoldTimer(hold);
        emit(
          state.copyWith(
            status: BookingStatus.seatHeld,
            selectedSeat: seat,
            activeHold: hold,
            holdSecondsRemaining: hold.remainingSeconds,
            clearError: true,
          ),
        );
      },
      onError: (failure) {
        loadSeatMap(currentTrip.tripId);
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Seat Map -> Review
  void proceedToReview() {
    if (state.activeHold == null || state.selectedSeat == null) return;
    emit(state.copyWith(currentStep: BookingStep.review, clearError: true));
  }

  /// Navigation: Back to Setup
  void backToSetup() {
    _cancelHoldTimer();
    final hold = state.activeHold;
    if (hold != null) {
      _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    emit(
      state.copyWith(
        currentStep: BookingStep.setup,
        clearSelectedSeat: true,
        clearActiveHold: true,
        clearError: true,
      ),
    );
  }

  /// Navigation: Back to Seat Map
  /// Releases old active hold, cancels countdown timer, clears hold state, and refreshes the seat map.
  void backToSeatMap() {
    _cancelHoldTimer();
    final hold = state.activeHold;
    if (hold != null) {
      _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    emit(
      state.copyWith(
        status: BookingStatus.seatMapLoaded,
        currentStep: BookingStep.seatMap,
        clearSelectedSeat: true,
        clearActiveHold: true,
        holdSecondsRemaining: 0,
        clearError: true,
      ),
    );
    if (state.selectedTrip != null) {
      loadSeatMap(state.selectedTrip!.tripId);
    }
  }

  /// Backward-compatible navigation
  void backToDirection() => backToSetup();
  void backToBoardingStop() => backToSetup();
  void backToDepartureTime() => backToSetup();
  void backToTrips() {
    _cancelHoldTimer();
    final hold = state.activeHold;
    if (hold != null) {
      _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    emit(
      state.copyWith(
        currentStep: BookingStep.departureTime,
        clearSelectedTrip: true,
        clearSelectedSeat: true,
        clearActiveHold: true,
        clearError: true,
      ),
    );
  }

  void proceedToBoardingStop() {
    emit(
      state.copyWith(currentStep: BookingStep.boardingStop, clearError: true),
    );
  }

  void selectRouteStop(RouteStop stop) {
    selectOriginStop(stop);
    emit(state.copyWith(currentStep: BookingStep.departureTime));
  }

  /// Cancels hold and resets to setup
  Future<void> cancelHoldAndReset() async {
    _cancelHoldTimer();
    final hold = state.activeHold;
    if (hold != null) {
      await _releaseBookingHoldUseCase(holdId: hold.holdId);
    }
    emit(
      state.copyWith(
        currentStep: BookingStep.setup,
        clearSelectedSeat: true,
        clearActiveHold: true,
        clearError: true,
      ),
    );
    if (state.selectedTrip != null) {
      loadSeatMap(state.selectedTrip!.tripId);
    }
  }

  /// Confirms booking with double-submit guard
  Future<void> confirmBooking() async {
    // Prevent concurrent or duplicate confirm requests
    if (state.status == BookingStatus.confirming) return;
    final hold = state.activeHold;
    if (hold == null) return;

    emit(state.copyWith(status: BookingStatus.confirming, clearError: true));

    final result = await _confirmBookingUseCase(holdId: hold.holdId);

    result.fold(
      onSuccess: (booking) {
        _cancelHoldTimer();
        emit(
          state.copyWith(
            status: BookingStatus.confirmed,
            currentStep: BookingStep.success,
            confirmedBooking: booking,
            clearActiveHold: true,
            clearError: true,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Consumes and clears transient error, restoring stable status without resetting user selections
  void clearError() {
    if (state.errorMessage != null || state.status == BookingStatus.error) {
      emit(
        state.copyWith(
          status: state.activeHold != null
              ? BookingStatus.seatHeld
              : BookingStatus.seatMapLoaded,
          clearError: true,
        ),
      );
    }
  }

  /// Resyncs countdown and hold validity when app resumes from background
  void resyncHoldOnResume() {
    final hold = state.activeHold;
    if (hold == null) return;
    final remaining = hold.remainingSeconds;
    if (remaining <= 0) {
      _cancelHoldTimer();
      emit(
        state.copyWith(
          status: BookingStatus.error,
          holdSecondsRemaining: 0,
          currentStep: BookingStep.seatMap,
          clearActiveHold: true,
          clearSelectedSeat: true,
          errorMessage: 'HOLD_EXPIRED',
        ),
      );
      if (state.selectedTrip != null) {
        loadSeatMap(state.selectedTrip!.tripId);
      }
    } else {
      emit(state.copyWith(holdSecondsRemaining: remaining));
    }
  }

  void _startHoldTimer(BookingHold hold) {
    _cancelHoldTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = hold.remainingSeconds;
      if (remaining <= 0) {
        _cancelHoldTimer();
        emit(
          state.copyWith(
            status: BookingStatus.error,
            holdSecondsRemaining: 0,
            currentStep: BookingStep.seatMap,
            clearActiveHold: true,
            clearSelectedSeat: true,
            errorMessage: 'HOLD_EXPIRED',
          ),
        );
        if (state.selectedTrip != null) {
          loadSeatMap(state.selectedTrip!.tripId);
        }
      } else {
        // Countdown ticks must NEVER re-emit or retain error status / messages
        final hasError =
            state.errorMessage != null || state.status == BookingStatus.error;
        emit(
          state.copyWith(
            holdSecondsRemaining: remaining,
            status: hasError ? BookingStatus.seatHeld : state.status,
            clearError: hasError,
          ),
        );
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
    return super.close();
  }
}
