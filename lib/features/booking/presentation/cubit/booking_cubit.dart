// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/failures/booking_failures.dart';
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
  final GetRoundTripReturnOptionsUseCase? _getRoundTripReturnOptionsUseCase;
  final CreateRoundTripBundleHoldUseCase? _createRoundTripBundleHoldUseCase;
  final SetRoundTripReturnSeatUseCase? _setRoundTripReturnSeatUseCase;
  final ReleaseRoundTripBundleHoldUseCase? _releaseRoundTripBundleHoldUseCase;
  final ConfirmRoundTripBundleUseCase? _confirmRoundTripBundleUseCase;
  final BookingRepository? _bookingRepository;

  Timer? _countdownTimer;
  Stopwatch? _holdStopwatch;
  int _initialHoldSecondsRemaining = 0;
  Stopwatch Function() _stopwatchFactory = Stopwatch.new;

  @visibleForTesting
  set stopwatchFactory(Stopwatch Function() factory) =>
      _stopwatchFactory = factory;

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
    GetRoundTripReturnOptionsUseCase? getRoundTripReturnOptionsUseCase,
    CreateRoundTripBundleHoldUseCase? createRoundTripBundleHoldUseCase,
    SetRoundTripReturnSeatUseCase? setRoundTripReturnSeatUseCase,
    ReleaseRoundTripBundleHoldUseCase? releaseRoundTripBundleHoldUseCase,
    ConfirmRoundTripBundleUseCase? confirmRoundTripBundleUseCase,
    BookingRepository? bookingRepository,
  }) : _getRouteStopsUseCase = getRouteStopsUseCase,
       _getAvailableTripsUseCase = getAvailableTripsUseCase,
       _getTripSeatMapUseCase = getTripSeatMapUseCase,
       _createBookingHoldUseCase = createBookingHoldUseCase,
       _releaseBookingHoldUseCase = releaseBookingHoldUseCase,
       _confirmBookingUseCase = confirmBookingUseCase,
       _getMyTripPreferencesUseCase = getMyTripPreferencesUseCase,
       _getPassengerBookingsUseCase = getPassengerBookingsUseCase,
       _getRoundTripReturnOptionsUseCase = getRoundTripReturnOptionsUseCase,
       _createRoundTripBundleHoldUseCase = createRoundTripBundleHoldUseCase,
       _setRoundTripReturnSeatUseCase = setRoundTripReturnSeatUseCase,
       _releaseRoundTripBundleHoldUseCase = releaseRoundTripBundleHoldUseCase,
       _confirmRoundTripBundleUseCase = confirmRoundTripBundleUseCase,
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
        bookingMode: direction == BookingDirection.outbound
            ? state.bookingMode
            : BookingMode.single,
        isTripLocked: initialTripId != null,
        clearAvailableTrips: true,
        clearSelectedTrip: true,
        clearSelectedRouteStop: true,
        clearSelectedDestinationStop: true,
        clearReturnOptions: true,
        clearSelectedReturnOption: true,
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
      // Pick the first server-bookable trip for today.
      final bookableTrips = availableTrips.where((t) => t.canBook).toList();
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

    if (state.isRoundTrip && resolvedTrip != null && resolvedOrigin != null) {
      await loadRoundTripReturnOptions();
    }
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

  /// Sets Booking Mode (Single or Round Trip).
  /// Round Trip is offered ONLY when booking direction is Outbound.
  Future<void> setBookingMode(BookingMode mode) async {
    if (mode == BookingMode.roundTrip &&
        state.selectedDirection != BookingDirection.outbound) {
      return;
    }

    if (state.bookingMode == mode) return;

    if (mode == BookingMode.single) {
      // Cleanly release any active bundle hold if exists
      _cancelHoldTimer();
      final bundle = state.bundleHold;
      if (bundle != null) {
        final releaseBundleUseCase =
            _releaseRoundTripBundleHoldUseCase ??
            (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                : null);
        if (releaseBundleUseCase != null) {
          releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
        }
      }

      emit(
        state.copyWith(
          bookingMode: BookingMode.single,
          roundTripSeatStep: RoundTripSeatStep.outbound,
          clearBundleHold: true,
          clearSelectedReturnSeat: true,
          clearSelectedReturnOption: true,
          clearReturnOptions: true,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          bookingMode: BookingMode.roundTrip,
          roundTripSeatStep: RoundTripSeatStep.outbound,
          clearError: true,
        ),
      );
      if (state.selectedTrip != null && state.selectedRouteStop != null) {
        await loadRoundTripReturnOptions();
      }
    }
  }

  /// Sets direction and refreshes route stops & trips.
  /// If switched to Return direction, booking mode is forced to single.
  void setDirection(BookingDirection direction) {
    final newMode = direction == BookingDirection.outbound
        ? state.bookingMode
        : BookingMode.single;

    if (state.currentStep == BookingStep.setup) {
      if (state.selectedDirection == direction && state.routeStops.isNotEmpty) {
        return;
      }
      initBooking(initialDirection: direction);
    } else {
      emit(
        state.copyWith(
          selectedDirection: direction,
          bookingMode: newMode,
          currentStep: BookingStep.direction,
          clearSelectedRouteStop: true,
          clearSelectedTrip: true,
          clearSelectedSeat: true,
          clearSelectedReturnSeat: true,
          clearActiveHold: true,
          clearBundleHold: true,
          clearReturnOptions: true,
          clearSelectedReturnOption: true,
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
        clearSelectedReturnSeat: true,
        clearActiveHold: true,
        clearBundleHold: true,
        clearError: true,
      ),
    );
    loadAvailableTrips();
    if (state.isRoundTrip && state.selectedTrip != null) {
      loadRoundTripReturnOptions();
    }
  }

  /// Selects Destination (Drop-off) Stop
  void selectDestinationStop(RouteStop stop) {
    emit(state.copyWith(selectedDestinationStop: stop, clearError: true));
  }

  /// Selects an outbound trip departure
  void selectTrip(TripOption trip) {
    if (state.currentStep == BookingStep.setup) {
      emit(
        state.copyWith(
          selectedTrip: trip,
          clearSelectedSeat: true,
          clearSelectedReturnSeat: true,
          clearActiveHold: true,
          clearBundleHold: true,
          clearError: true,
        ),
      );
      if (state.isRoundTrip && state.selectedRouteStop != null) {
        loadRoundTripReturnOptions();
      }
    } else {
      emit(
        state.copyWith(
          selectedTrip: trip,
          currentStep: BookingStep.seatMap,
          clearSelectedSeat: true,
          clearSelectedReturnSeat: true,
          clearActiveHold: true,
          clearBundleHold: true,
          clearError: true,
        ),
      );
      loadSeatMap(trip.tripId);
    }
  }

  /// Loads return options for Round Trip from backend RPC
  Future<void> loadRoundTripReturnOptions() async {
    final outboundTrip = state.selectedTrip;
    final outboundStop = state.selectedRouteStop;
    if (outboundTrip == null || outboundStop == null) return;

    final useCase =
        _getRoundTripReturnOptionsUseCase ??
        (getIt.isRegistered<GetRoundTripReturnOptionsUseCase>()
            ? getIt<GetRoundTripReturnOptionsUseCase>()
            : null);
    if (useCase == null) return;

    final result = await useCase(
      outboundTripId: outboundTrip.tripId,
      outboundRouteStopId: outboundStop.routeStopId,
    );

    result.fold(
      onSuccess: (options) {
        RoundTripReturnOption? selected = state.selectedReturnOption;
        if (selected != null) {
          selected = options.cast<RoundTripReturnOption?>().firstWhere(
            (o) => o?.returnTripId == selected!.returnTripId && o!.isBookable,
            orElse: () => null,
          );
        }
        selected ??= options.where((o) => o.isBookable).firstOrNull;

        emit(
          state.copyWith(
            returnOptions: options,
            selectedReturnOption: selected,
            clearSelectedReturnOption: selected == null,
          ),
        );
      },
      onError: (failure) {
        emit(
          state.copyWith(
            errorMessage: failure.message,
            clearReturnOptions: true,
            clearSelectedReturnOption: true,
          ),
        );
      },
    );
  }

  /// Selects a return departure option
  void selectReturnOption(RoundTripReturnOption option) {
    if (!option.isBookable) return;
    emit(state.copyWith(selectedReturnOption: option, clearError: true));
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

    if (state.isRoundTrip &&
        (state.selectedReturnOption == null ||
            !state.selectedReturnOption!.isBookable)) {
      emit(
        state.copyWith(errorMessage: 'يرجى اختيار ميعاد العودة المناسب أولاً.'),
      );
      return;
    }

    final trip = state.selectedTrip!;
    emit(
      state.copyWith(
        currentStep: BookingStep.seatMap,
        roundTripSeatStep: RoundTripSeatStep.outbound,
        clearSelectedSeat: true,
        clearSelectedReturnSeat: true,
        clearActiveHold: true,
        clearBundleHold: true,
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
            (t) => t.tripId == current!.tripId && t.canBook,
          );
          if (!stillValid) {
            final next = trips.where((t) => t.canBook).firstOrNull;
            if (next != null) {
              final currentFormatted = AppTimeFormatter.formatTripOption(
                current,
                isArabic: true,
              );
              final nextFormatted = AppTimeFormatter.formatTripOption(
                next,
                isArabic: true,
              );
              alert =
                  'رحلة $currentFormatted غير متاحة، تم اختيار رحلة $nextFormatted';
              current = next;
            } else if (trips.isNotEmpty) {
              current = trips.first;
            } else {
              current = null;
            }
          }
        } else if (current == null && trips.isNotEmpty) {
          current = trips.where((t) => t.canBook).firstOrNull ?? trips.first;
        } else if (current != null && bookedTripIds.contains(current.tripId)) {
          current =
              trips.where((t) => t.canBook).firstOrNull ??
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
        if (state.isRoundTrip &&
            state.roundTripSeatStep == RoundTripSeatStep.returnSeat) {
          emit(
            state.copyWith(
              status: BookingStatus.seatMapLoaded,
              returnSeats: seats,
            ),
          );
        } else {
          emit(
            state.copyWith(status: BookingStatus.seatMapLoaded, seats: seats),
          );
        }
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
        if (isClosed) return;

        final isReturnStep =
            state.isRoundTrip &&
            state.roundTripSeatStep == RoundTripSeatStep.returnSeat;

        if (isReturnStep &&
            state.selectedReturnOption?.returnTripId != tripId) {
          return;
        }
        if (!isReturnStep && state.selectedTrip?.tripId != tripId) {
          return;
        }

        result.fold(
          onSuccess: (seats) {
            if (isClosed) return;
            if (isReturnStep) {
              final currentSeat = state.selectedReturnSeat;
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
                      state.bundleHold?.returnSeatId ==
                          refreshedSelectedSeat.seatId);

              emit(
                state.copyWith(
                  returnSeats: seats,
                  selectedReturnSeat: canKeepSelectedSeat
                      ? refreshedSelectedSeat
                      : null,
                  clearSelectedReturnSeat:
                      currentSeat != null && !canKeepSelectedSeat,
                ),
              );
            } else {
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
                      state.activeHold?.seatId ==
                          refreshedSelectedSeat.seatId ||
                      state.bundleHold?.outboundSeatId ==
                          refreshedSelectedSeat.seatId);

              emit(
                state.copyWith(
                  seats: seats,
                  selectedSeat: canKeepSelectedSeat
                      ? refreshedSelectedSeat
                      : null,
                  clearSelectedSeat:
                      currentSeat != null && !canKeepSelectedSeat,
                ),
              );
            }
          },
          onError: (_) {},
        );
      } while (_seatMapRefreshQueued && !isClosed);
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

  /// Selects a seat and holds it on the server.
  /// Handles both Single Booking hold and Round Trip Bundle hold.
  Future<void> selectSeatAndHold(TripSeat seat) async {
    // Double-submit guard
    if (state.status == BookingStatus.holdingSeat) return;

    if (!seat.isAvailable && !seat.isMine) {
      return;
    }

    if (state.isSingle) {
      final currentTrip = state.selectedTrip;
      if (currentTrip == null) return;

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
          _startHoldTimer(hold.remainingSeconds, hold.holdId, isBundle: false);
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
    } else {
      // ROUND TRIP MODE
      if (state.roundTripSeatStep == RoundTripSeatStep.outbound) {
        final outboundTrip = state.selectedTrip;
        final returnOption = state.selectedReturnOption;
        final outboundStop = state.selectedRouteStop;
        if (outboundTrip == null ||
            returnOption == null ||
            outboundStop == null) {
          return;
        }

        _cancelHoldTimer();

        // If old bundle hold existed, release it
        final oldBundle = state.bundleHold;
        if (oldBundle != null) {
          final releaseBundleUseCase =
              _releaseRoundTripBundleHoldUseCase ??
              (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                  ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                  : null);
          if (releaseBundleUseCase != null) {
            releaseBundleUseCase(bundleHoldId: oldBundle.bundleHoldId);
          }
        }

        emit(
          state.copyWith(
            status: BookingStatus.holdingSeat,
            clearError: true,
            clearBundleHold: true,
            clearSelectedReturnSeat: true,
            holdSecondsRemaining: 0,
          ),
        );

        final createBundleUseCase =
            _createRoundTripBundleHoldUseCase ??
            (getIt.isRegistered<CreateRoundTripBundleHoldUseCase>()
                ? getIt<CreateRoundTripBundleHoldUseCase>()
                : null);
        if (createBundleUseCase == null) return;

        final result = await createBundleUseCase(
          outboundTripId: outboundTrip.tripId,
          returnTripId: returnOption.returnTripId,
          outboundSeatId: seat.seatId,
          outboundRouteStopId: outboundStop.routeStopId,
        );

        result.fold(
          onSuccess: (bundleHold) {
            _startHoldTimer(
              bundleHold.remainingSeconds,
              bundleHold.bundleHoldId,
              isBundle: true,
            );
            emit(
              state.copyWith(
                status: BookingStatus.seatHeld,
                selectedSeat: seat,
                bundleHold: bundleHold,
                holdSecondsRemaining: bundleHold.remainingSeconds,
                clearError: true,
              ),
            );
          },
          onError: (failure) {
            loadSeatMap(outboundTrip.tripId);
            emit(
              state.copyWith(
                status: BookingStatus.error,
                errorMessage: failure.message,
              ),
            );
          },
        );
      } else {
        // RoundTripSeatStep.returnSeat
        final bundle = state.bundleHold;
        if (bundle == null) return;

        final setReturnSeatUseCase =
            _setRoundTripReturnSeatUseCase ??
            (getIt.isRegistered<SetRoundTripReturnSeatUseCase>()
                ? getIt<SetRoundTripReturnSeatUseCase>()
                : null);
        if (setReturnSeatUseCase == null) return;

        emit(state.copyWith(status: BookingStatus.holdingSeat));

        final result = await setReturnSeatUseCase(
          bundleHoldId: bundle.bundleHoldId,
          returnSeatId: seat.seatId,
        );

        result.fold(
          onSuccess: (updatedBundle) {
            // Note: The timer continues ticking uninterrupted
            emit(
              state.copyWith(
                status: BookingStatus.seatHeld,
                selectedReturnSeat: seat,
                bundleHold: updatedBundle,
                clearError: true,
              ),
            );
          },
          onError: (failure) {
            final returnTripId = state.selectedReturnOption?.returnTripId;
            if (returnTripId != null) {
              loadSeatMap(returnTripId);
            }
            emit(
              state.copyWith(
                status: BookingStatus.error,
                errorMessage: failure.message,
              ),
            );
          },
        );
      }
    }
  }

  /// Proceeds from Outbound Seat selection to Return Seat Map in Round Trip mode.
  void proceedToReturnSeatMap() {
    if (state.bundleHold == null ||
        state.selectedSeat == null ||
        state.selectedReturnOption == null) {
      return;
    }

    emit(
      state.copyWith(
        roundTripSeatStep: RoundTripSeatStep.returnSeat,
        clearError: true,
      ),
    );
    loadSeatMap(state.selectedReturnOption!.returnTripId);
  }

  /// Seat Map -> Review
  void proceedToReview() {
    if (state.isSingle) {
      if (state.activeHold == null || state.selectedSeat == null) return;
      emit(state.copyWith(currentStep: BookingStep.review, clearError: true));
    } else {
      if (state.bundleHold == null ||
          state.selectedSeat == null ||
          state.selectedReturnSeat == null) {
        return;
      }
      emit(state.copyWith(currentStep: BookingStep.review, clearError: true));
    }
  }

  /// Navigation: Back to Setup
  void backToSetup() {
    _cancelHoldTimer();
    if (state.isSingle) {
      final hold = state.activeHold;
      if (hold != null) {
        _releaseBookingHoldUseCase(holdId: hold.holdId);
      }
    } else {
      final bundle = state.bundleHold;
      if (bundle != null) {
        final releaseBundleUseCase =
            _releaseRoundTripBundleHoldUseCase ??
            (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                : null);
        if (releaseBundleUseCase != null) {
          releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
        }
      }
    }

    emit(
      state.copyWith(
        currentStep: BookingStep.setup,
        roundTripSeatStep: RoundTripSeatStep.outbound,
        clearSelectedSeat: true,
        clearSelectedReturnSeat: true,
        clearActiveHold: true,
        clearBundleHold: true,
        holdSecondsRemaining: 0,
        clearError: true,
      ),
    );
  }

  /// Navigation: Back to Seat Map
  void backToSeatMap() {
    if (state.isSingle) {
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
    } else {
      // In Round Trip: Go back to return seat or outbound seat
      emit(
        state.copyWith(
          status: BookingStatus.seatMapLoaded,
          currentStep: BookingStep.seatMap,
          roundTripSeatStep: RoundTripSeatStep.returnSeat,
          clearError: true,
        ),
      );
      if (state.selectedReturnOption != null) {
        loadSeatMap(state.selectedReturnOption!.returnTripId);
      }
    }
  }

  /// In Round Trip mode: Go back from Return Seat Map to Outbound Seat Map
  void backToOutboundSeatMap() {
    emit(
      state.copyWith(
        roundTripSeatStep: RoundTripSeatStep.outbound,
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
    final bundle = state.bundleHold;
    if (bundle != null) {
      final releaseBundleUseCase =
          _releaseRoundTripBundleHoldUseCase ??
          (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
              ? getIt<ReleaseRoundTripBundleHoldUseCase>()
              : null);
      if (releaseBundleUseCase != null) {
        releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
      }
    }
    emit(
      state.copyWith(
        currentStep: BookingStep.departureTime,
        roundTripSeatStep: RoundTripSeatStep.outbound,
        clearSelectedTrip: true,
        clearSelectedSeat: true,
        clearSelectedReturnSeat: true,
        clearActiveHold: true,
        clearBundleHold: true,
        holdSecondsRemaining: 0,
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
    if (state.isSingle) {
      final hold = state.activeHold;
      if (hold != null) {
        await _releaseBookingHoldUseCase(holdId: hold.holdId);
      }
    } else {
      final bundle = state.bundleHold;
      if (bundle != null) {
        final releaseBundleUseCase =
            _releaseRoundTripBundleHoldUseCase ??
            (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                : null);
        if (releaseBundleUseCase != null) {
          await releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
        }
      }
    }
    emit(
      state.copyWith(
        currentStep: BookingStep.setup,
        roundTripSeatStep: RoundTripSeatStep.outbound,
        clearSelectedSeat: true,
        clearSelectedReturnSeat: true,
        clearActiveHold: true,
        clearBundleHold: true,
        holdSecondsRemaining: 0,
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

    if (state.isSingle) {
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
          if (failure is HoldExpiredFailure) {
            _cancelHoldTimer();
            emit(
              state.copyWith(
                status: BookingStatus.error,
                currentStep: BookingStep.seatMap,
                clearActiveHold: true,
                clearSelectedSeat: true,
                holdSecondsRemaining: 0,
                errorMessage: failure.message,
              ),
            );
            if (state.selectedTrip != null) {
              _refreshSeatMapSilently(state.selectedTrip!.tripId);
            }
            return;
          }

          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
      );
    } else {
      // ROUND TRIP CONFIRMATION — EXACTLY ONE CALL to confirm_round_trip_bundle
      final bundle = state.bundleHold;
      if (bundle == null) return;

      final confirmBundleUseCase =
          _confirmRoundTripBundleUseCase ??
          (getIt.isRegistered<ConfirmRoundTripBundleUseCase>()
              ? getIt<ConfirmRoundTripBundleUseCase>()
              : null);
      if (confirmBundleUseCase == null) return;

      emit(state.copyWith(status: BookingStatus.confirming, clearError: true));

      final result = await confirmBundleUseCase(
        bundleHoldId: bundle.bundleHoldId,
      );

      result.fold(
        onSuccess: (confirmation) {
          _cancelHoldTimer();
          emit(
            state.copyWith(
              status: BookingStatus.confirmed,
              currentStep: BookingStep.success,
              confirmedBundle: confirmation,
              clearBundleHold: true,
              clearError: true,
            ),
          );
        },
        onError: (failure) {
          if (failure is HoldExpiredFailure ||
              failure is RoundTripHoldNotFoundFailure ||
              failure is RoundTripHoldInvalidFailure) {
            _cancelHoldTimer();
            emit(
              state.copyWith(
                status: BookingStatus.error,
                currentStep: BookingStep.seatMap,
                roundTripSeatStep: RoundTripSeatStep.outbound,
                clearBundleHold: true,
                clearSelectedSeat: true,
                clearSelectedReturnSeat: true,
                holdSecondsRemaining: 0,
                errorMessage: failure.message,
              ),
            );
            if (state.selectedTrip != null) {
              _refreshSeatMapSilently(state.selectedTrip!.tripId);
            }
            return;
          }

          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage: failure.message,
            ),
          );
        },
      );
    }
  }

  /// Consumes and clears transient error, restoring stable status without resetting user selections
  void clearError() {
    if (state.errorMessage != null || state.status == BookingStatus.error) {
      emit(
        state.copyWith(
          status: (state.activeHold != null || state.bundleHold != null)
              ? BookingStatus.seatHeld
              : BookingStatus.seatMapLoaded,
          clearError: true,
        ),
      );
    }
  }

  /// Resyncs countdown and hold validity when app resumes from background
  void resyncHoldOnResume() {
    final hasHold = state.activeHold != null || state.bundleHold != null;
    if (!hasHold) return;

    final remainingSecondsSource =
        state.activeHold?.remainingSeconds ??
        state.bundleHold?.remainingSeconds ??
        0;

    final int remaining;
    if (_holdStopwatch != null) {
      final elapsedSeconds = _holdStopwatch!.elapsed.inSeconds;
      final calculated = _initialHoldSecondsRemaining - elapsedSeconds;
      remaining = calculated > 0 ? calculated : 0;
    } else {
      remaining = remainingSecondsSource;
    }

    if (remaining <= 0) {
      _cancelHoldTimer();
      emit(
        state.copyWith(
          status: BookingStatus.error,
          holdSecondsRemaining: 0,
          currentStep: BookingStep.seatMap,
          roundTripSeatStep: RoundTripSeatStep.outbound,
          clearActiveHold: true,
          clearBundleHold: true,
          clearSelectedSeat: true,
          clearSelectedReturnSeat: true,
          errorMessage: 'HOLD_EXPIRED',
        ),
      );
      if (state.selectedTrip != null) {
        _refreshSeatMapSilently(state.selectedTrip!.tripId);
      }
    } else {
      emit(state.copyWith(holdSecondsRemaining: remaining));
    }
  }

  void _startHoldTimer(
    int remainingSeconds,
    String holdId, {
    required bool isBundle,
  }) {
    _cancelHoldTimer();
    // Authoritative initial value from backend: remainingSeconds
    _initialHoldSecondsRemaining = remainingSeconds;
    _holdStopwatch = _stopwatchFactory()..start();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // If the active hold was cleared, cancelled, or replaced, stop ticking immediately
      final currentHoldId = isBundle
          ? state.bundleHold?.bundleHoldId
          : state.activeHold?.holdId;

      if (currentHoldId == null || currentHoldId != holdId) {
        _cancelHoldTimer();
        return;
      }

      final elapsedSeconds = _holdStopwatch?.elapsed.inSeconds ?? 0;
      final calculated = _initialHoldSecondsRemaining - elapsedSeconds;
      final remaining = calculated > 0 ? calculated : 0;

      if (remaining <= 0) {
        _cancelHoldTimer();
        emit(
          state.copyWith(
            status: BookingStatus.error,
            holdSecondsRemaining: 0,
            currentStep: BookingStep.seatMap,
            roundTripSeatStep: RoundTripSeatStep.outbound,
            clearActiveHold: true,
            clearBundleHold: true,
            clearSelectedSeat: true,
            clearSelectedReturnSeat: true,
            errorMessage: 'HOLD_EXPIRED',
          ),
        );
        if (state.selectedTrip != null) {
          _refreshSeatMapSilently(state.selectedTrip!.tripId);
        }
      } else {
        emit(state.copyWith(holdSecondsRemaining: remaining));
      }
    });
  }

  void _cancelHoldTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _holdStopwatch?.stop();
    _holdStopwatch = null;
    _initialHoldSecondsRemaining = 0;
  }

  @override
  Future<void> close() {
    _cancelHoldTimer();
    _seatSubscription?.cancel();
    return super.close();
  }
}
