// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/failures/booking_failures.dart';
import '../../domain/services/passenger_booking_availability.dart';
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
  Timer? _cutoffTimer;
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
       _getRoundTripReturnOptionsUseCase =
           getRoundTripReturnOptionsUseCase ??
           (bookingRepository != null
               ? GetRoundTripReturnOptionsUseCase(bookingRepository)
               : (getIt.isRegistered<GetRoundTripReturnOptionsUseCase>()
                     ? getIt<GetRoundTripReturnOptionsUseCase>()
                     : null)),
       _createRoundTripBundleHoldUseCase =
           createRoundTripBundleHoldUseCase ??
           (bookingRepository != null
               ? CreateRoundTripBundleHoldUseCase(bookingRepository)
               : (getIt.isRegistered<CreateRoundTripBundleHoldUseCase>()
                     ? getIt<CreateRoundTripBundleHoldUseCase>()
                     : null)),
       _setRoundTripReturnSeatUseCase =
           setRoundTripReturnSeatUseCase ??
           (bookingRepository != null
               ? SetRoundTripReturnSeatUseCase(bookingRepository)
               : (getIt.isRegistered<SetRoundTripReturnSeatUseCase>()
                     ? getIt<SetRoundTripReturnSeatUseCase>()
                     : null)),
       _releaseRoundTripBundleHoldUseCase =
           releaseRoundTripBundleHoldUseCase ??
           (bookingRepository != null
               ? ReleaseRoundTripBundleHoldUseCase(bookingRepository)
               : (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                     ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                     : null)),
       _confirmRoundTripBundleUseCase =
           confirmRoundTripBundleUseCase ??
           (bookingRepository != null
               ? ConfirmRoundTripBundleUseCase(bookingRepository)
               : (getIt.isRegistered<ConfirmRoundTripBundleUseCase>()
                     ? getIt<ConfirmRoundTripBundleUseCase>()
                     : null)),
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
      await loadRoundTripReturnOptions(
        outboundTrip: resolvedTrip,
        outboundStop: resolvedOrigin,
      );
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
        await loadRoundTripReturnOptions(
          outboundTrip: state.selectedTrip,
          outboundStop: state.selectedRouteStop,
        );
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
  Future<void> selectOriginStop(RouteStop stop) async {
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
    await loadAvailableTrips(originStop: stop);
  }

  /// Selects Destination (Drop-off) Stop
  void selectDestinationStop(RouteStop stop) {
    emit(state.copyWith(selectedDestinationStop: stop, clearError: true));
  }

  /// Selects an outbound trip departure
  Future<void> selectTrip(TripOption trip) async {
    if (state.currentStep == BookingStep.setup) {
      final stop = state.selectedRouteStop;
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
      if (state.isRoundTrip && stop != null) {
        await loadRoundTripReturnOptions(
          outboundTrip: trip,
          outboundStop: stop,
        );
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

  /// Loads available return trips using the canonical Return-trip loader
  /// (the exact same usecase and filter used by Return-only booking).
  Future<List<TripOption>> loadAvailableReturnTrips({
    String? routeStopId,
  }) async {
    final bookedTripIds = await _fetchActiveBookedTripIds();
    final result = await _getAvailableTripsUseCase(
      direction: BookingDirection.returnTrip,
      routeStopId: routeStopId,
    );
    List<TripOption> trips = [];
    result.fold(
      onSuccess: (rawTrips) {
        trips = rawTrips
            .where((t) => !bookedTripIds.contains(t.tripId))
            .toList();
      },
      onError: (_) {},
    );
    return trips;
  }

  /// Loads return options for Round Trip.
  /// Reuses canonical Return-trip loader for the visible schedule list,
  /// and queries the Round Trip RPC for authoritative bundle eligibility/pricing.
  Future<void> loadRoundTripReturnOptions({
    TripOption? outboundTrip,
    RouteStop? outboundStop,
  }) async {
    if (isClosed) return;
    final trip = outboundTrip ?? state.selectedTrip;
    final stop = outboundStop ?? state.selectedRouteStop;

    if (kDebugMode) {
      debugPrint('ROUND_TRIP_DEBUG bookingMode ${state.bookingMode}');
      debugPrint('ROUND_TRIP_DEBUG outboundTripId ${trip?.tripId}');
      debugPrint('ROUND_TRIP_DEBUG outboundRouteStopId ${stop?.routeStopId}');
      debugPrint('ROUND_TRIP_DEBUG outboundStopName ${stop?.stopNameAr}');
    }

    if (trip == null || stop == null) return;

    emit(
      state.copyWith(
        isLoadingRoundTripReturnOptions: true,
        clearRoundTripReturnOptionsError: true,
      ),
    );

    // 1. Launch canonical Return trips loader and Round Trip RPC in parallel
    final useCase =
        _getRoundTripReturnOptionsUseCase ??
        (getIt.isRegistered<GetRoundTripReturnOptionsUseCase>()
            ? getIt<GetRoundTripReturnOptionsUseCase>()
            : null);

    final returnTripsFuture = loadAvailableReturnTrips();
    final rpcFuture = useCase != null
        ? useCase(
            outboundTripId: trip.tripId,
            outboundRouteStopId: stop.routeStopId,
          )
        : null;

    final canonicalReturnTrips = await returnTripsFuture;
    if (isClosed) return;

    List<RoundTripReturnOption> rpcOptions = [];
    String? rpcErrorMessage;
    if (rpcFuture != null) {
      final rpcResult = await rpcFuture;
      rpcResult.fold(
        onSuccess: (opts) => rpcOptions = opts,
        onError: (f) {
          rpcErrorMessage = f.message;
        },
      );
    }

    if (isClosed) return;

    // 3. Merge: canonical Return-only trips supply the visible list,
    // and matching RPC options supply authoritative bundle pricing/eligibility.
    // Canonical Return trips are NEVER authoritative for pricing or bookability.
    final Map<String, RoundTripReturnOption> optionsByTripId = {};

    // First populate from RPC options (authoritative pricing/bundle validation)
    for (final rpcOpt in rpcOptions) {
      optionsByTripId[rpcOpt.returnTripId] = rpcOpt;
    }

    // Next merge with canonical return trips from Return-only loader
    for (final retTrip in canonicalReturnTrips) {
      if (retTrip.direction != BookingDirection.returnTrip) continue;
      final existingRpc = optionsByTripId[retTrip.tripId];
      if (existingRpc != null) {
        optionsByTripId[retTrip.tripId] = RoundTripReturnOption(
          returnTripId: retTrip.tripId,
          departureTime: retTrip.departureTime,
          departureAt: retTrip.departureAt,
          bookingCloseAt: existingRpc.bookingCloseAt ?? retTrip.bookingCloseAt,
          availableSeats: existingRpc.availableSeats,
          outboundBaseFarePoints: existingRpc.outboundBaseFarePoints,
          returnBaseFarePoints: existingRpc.returnBaseFarePoints,
          subtotalPoints: existingRpc.subtotalPoints,
          discountPercent: existingRpc.discountPercent,
          discountPoints: existingRpc.discountPoints,
          totalPoints: existingRpc.totalPoints,
          isBookable: existingRpc.isBookable && retTrip.isBookable,
        );
      } else {
        // Strict Authority: If RPC did NOT return a matching row for this return trip,
        // it remains visible in the schedule but CANNOT be booked for Round Trip.
        // Never synthesize 15% discount or allow Round Trip checkout without an RPC row.
        optionsByTripId[retTrip.tripId] = RoundTripReturnOption(
          returnTripId: retTrip.tripId,
          departureTime: retTrip.departureTime,
          departureAt: retTrip.departureAt,
          bookingCloseAt: retTrip.bookingCloseAt,
          availableSeats: retTrip.availableSeatsCount,
          outboundBaseFarePoints: 0,
          returnBaseFarePoints: 0,
          subtotalPoints: 0,
          discountPercent: 0,
          discountPoints: 0,
          totalPoints: 0,
          isBookable: false,
        );
      }
    }

    final List<RoundTripReturnOption> options = optionsByTripId.values.toList();

    RoundTripReturnOption? selected = state.selectedReturnOption;
    if (selected != null) {
      selected = options.cast<RoundTripReturnOption?>().firstWhere(
        (o) => o?.returnTripId == selected!.returnTripId && o!.canBookReturn,
        orElse: () => null,
      );
    }
    selected ??= options.where((o) => o.canBookReturn).firstOrNull;

    emit(
      state.copyWith(
        isLoadingRoundTripReturnOptions: false,
        returnOptions: options,
        selectedReturnOption: selected,
        clearSelectedReturnOption: selected == null,
        roundTripReturnOptionsError: rpcErrorMessage,
        clearRoundTripReturnOptionsError: rpcErrorMessage == null,
      ),
    );
    _scheduleCutoffTimer();

    if (kDebugMode) {
      debugPrint(
        'ROUND_TRIP_DEBUG state returnOptions count after emit ${state.returnOptions.length}',
      );
    }
  }

  /// Selects a return departure option
  void selectReturnOption(RoundTripReturnOption option) {
    if (!option.canBookReturn) return;
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

    final trip = state.selectedTrip!;
    if (trip.isBookingClosed()) {
      emit(state.copyWith(errorMessage: 'انتهى وقت الحجز لهذه الرحلة.'));
      return;
    }

    if (state.isRoundTrip) {
      if (state.selectedReturnOption == null ||
          !state.selectedReturnOption!.canBookReturn) {
        final isClosed = state.selectedReturnOption?.isBookingClosed() ?? false;
        emit(
          state.copyWith(
            errorMessage: isClosed
                ? 'انتهى وقت الحجز لهذه الرحلة.'
                : 'يرجى اختيار ميعاد العودة المناسب أولاً.',
          ),
        );
        return;
      }
    }

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
  Future<void> loadAvailableTrips({RouteStop? originStop}) async {
    if (isClosed) return;
    final stop = originStop ?? state.selectedRouteStop;
    final bookedTripIds = await _fetchActiveBookedTripIds();
    if (isClosed) return;
    final result = await _getAvailableTripsUseCase(
      direction: state.selectedDirection,
      routeStopId: stop?.routeStopId,
    );
    if (isClosed) return;

    result.fold(
      onSuccess: (rawTrips) async {
        if (isClosed) return;
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
        _scheduleCutoffTimer();
        if (state.isRoundTrip && current != null && stop != null) {
          await loadRoundTripReturnOptions(
            outboundTrip: current,
            outboundStop: stop,
          );
        }
      },
      onError: (failure) {
        if (isClosed) return;
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
                  (state.status == BookingStatus.holdingSeat ||
                      refreshedSelectedSeat.isAvailable ||
                      refreshedSelectedSeat.isMine ||
                      state.bundleHold?.returnSeatId ==
                          refreshedSelectedSeat.seatId);

              emit(
                state.copyWith(
                  returnSeats: seats,
                  selectedReturnSeat: canKeepSelectedSeat
                      ? (currentSeat ?? refreshedSelectedSeat)
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
                  (state.status == BookingStatus.holdingSeat ||
                      refreshedSelectedSeat.isAvailable ||
                      refreshedSelectedSeat.isMine ||
                      state.activeHold?.seatId ==
                          refreshedSelectedSeat.seatId ||
                      state.bundleHold?.outboundSeatId ==
                          refreshedSelectedSeat.seatId);

              emit(
                state.copyWith(
                  seats: seats,
                  selectedSeat: canKeepSelectedSeat
                      ? (currentSeat ?? refreshedSelectedSeat)
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
    if (kDebugMode) {
      debugPrint('ROUND_TRIP_SEAT tap seatId ${seat.seatId}');
      debugPrint('ROUND_TRIP_SEAT seatNumber ${seat.seatNumber}');
      debugPrint('ROUND_TRIP_SEAT isAvailable ${seat.isAvailable}');
      debugPrint('ROUND_TRIP_SEAT bookingMode ${state.bookingMode.name}');
      debugPrint('ROUND_TRIP_SEAT seatStep ${state.roundTripSeatStep.name}');
      debugPrint(
        'ROUND_TRIP_SEAT selectedReturnTripId ${state.selectedReturnOption?.returnTripId}',
      );
      debugPrint(
        'ROUND_TRIP_SEAT matchedReturnOption ${state.selectedReturnOption != null}',
      );
      debugPrint('ROUND_TRIP_SEAT callbackEntered true');
    }

    // Double-submit guard
    if (state.status == BookingStatus.holdingSeat) return;

    if (!seat.isAvailable && !seat.isMine) {
      return;
    }

    if (state.isSingle) {
      final currentTrip = state.selectedTrip;
      if (currentTrip == null) return;

      if (currentTrip.isBookingClosed()) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        return;
      }

      _cancelHoldTimer();

      // If there was an active hold on a different seat, release it cleanly
      final oldHold = state.activeHold;
      if (oldHold != null && state.selectedSeat?.seatId != seat.seatId) {
        _releaseBookingHoldUseCase(holdId: oldHold.holdId);
      }

      final previousSeat = state.selectedSeat;
      emit(
        state.copyWith(
          status: BookingStatus.holdingSeat,
          selectedSeat: seat,
          clearError: true,
          clearActiveHold: true,
          holdSecondsRemaining: 0,
        ),
      );

      try {
        final result = await _createBookingHoldUseCase(
          tripId: currentTrip.tripId,
          seatId: seat.seatId,
          routeStopId: state.selectedRouteStop?.routeStopId,
          destinationRouteStopId: state.selectedDestinationStop?.routeStopId,
        );

        result.fold(
          onSuccess: (hold) {
            _startHoldTimer(
              hold.remainingSeconds,
              hold.holdId,
              isBundle: false,
            );
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
            final isBookingClosed =
                failure is BookingClosedFailure ||
                failure.message.toUpperCase().contains('BOOKING_CLOSED');

            emit(
              state.copyWith(
                status: BookingStatus.error,
                selectedSeat: previousSeat,
                clearSelectedSeat: previousSeat == null,
                errorMessage: isBookingClosed
                    ? 'انتهى وقت الحجز لهذه الرحلة.'
                    : failure.message,
              ),
            );
            _refreshSeatMapSilently(currentTrip.tripId);
            if (isBookingClosed && state.selectedRouteStop != null) {
              loadAvailableTrips(originStop: state.selectedRouteStop);
            }
          },
        );
      } catch (e) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            selectedSeat: previousSeat,
            clearSelectedSeat: previousSeat == null,
            errorMessage: 'حدث خطأ أثناء حجز المقعد، يرجى المحاولة مرة أخرى',
          ),
        );
        _refreshSeatMapSilently(currentTrip.tripId);
      }
    } else {
      // ROUND TRIP MODE
      if (state.roundTripSeatStep == RoundTripSeatStep.outbound) {
        final outboundTrip = state.selectedTrip;
        final returnOption = state.selectedReturnOption;
        final outboundStop = state.selectedRouteStop;
        if (outboundTrip == null ||
            returnOption == null ||
            outboundStop == null) {
          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage:
                  'بيانات رحلة الذهاب والعودة غير مكتملة. يرجى إعادة المحاولة.',
            ),
          );
          return;
        }

        if (outboundTrip.isBookingClosed() || returnOption.isBookingClosed()) {
          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
            ),
          );
          return;
        }

        _cancelHoldTimer();

        // If old bundle hold existed, release it
        final oldBundle = state.bundleHold;
        if (oldBundle != null) {
          final releaseBundleUseCase =
              _releaseRoundTripBundleHoldUseCase ??
              (_bookingRepository != null
                  ? ReleaseRoundTripBundleHoldUseCase(_bookingRepository)
                  : (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                        ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                        : null));
          if (releaseBundleUseCase != null) {
            releaseBundleUseCase(bundleHoldId: oldBundle.bundleHoldId);
          }
        }

        final previousSeat = state.selectedSeat;
        emit(
          state.copyWith(
            status: BookingStatus.holdingSeat,
            selectedSeat: seat,
            clearError: true,
            clearBundleHold: true,
            clearSelectedReturnSeat: true,
            holdSecondsRemaining: 0,
          ),
        );

        if (kDebugMode) {
          debugPrint(
            'ROUND_TRIP_SEAT selectedSeatAfterEmit ${state.selectedSeat?.seatId}',
          );
        }

        final createBundleUseCase =
            _createRoundTripBundleHoldUseCase ??
            (_bookingRepository != null
                ? CreateRoundTripBundleHoldUseCase(_bookingRepository)
                : (getIt.isRegistered<CreateRoundTripBundleHoldUseCase>()
                      ? getIt<CreateRoundTripBundleHoldUseCase>()
                      : null));

        if (createBundleUseCase == null) {
          emit(
            state.copyWith(
              status: BookingStatus.error,
              selectedSeat: previousSeat,
              clearSelectedSeat: previousSeat == null,
              errorMessage: 'تعذر الاتصال بخدمة حجز الرحلات',
            ),
          );
          return;
        }

        if (kDebugMode) {
          debugPrint('ROUND_TRIP_SEAT bundleHoldStarted true');
        }

        try {
          final result = await createBundleUseCase(
            outboundTripId: outboundTrip.tripId,
            returnTripId: returnOption.returnTripId,
            outboundSeatId: seat.seatId,
            outboundRouteStopId: outboundStop.routeStopId,
          );

          result.fold(
            onSuccess: (bundleHold) {
              if (kDebugMode) {
                debugPrint('ROUND_TRIP_SEAT bundleHoldSuccess true');
              }
              _startHoldTimer(
                bundleHold.remainingSeconds,
                bundleHold.bundleHoldId,
                isBundle: true,
              );
              final resolvedBundle =
                  (bundleHold.outboundBaseFarePoints <= 0 ||
                          bundleHold.returnBaseFarePoints <= 0) &&
                      state.selectedReturnOption != null
                  ? bundleHold.ensureAuthoritativeFares(
                      state.selectedReturnOption,
                    )
                  : bundleHold;
              emit(
                state.copyWith(
                  status: BookingStatus.seatHeld,
                  selectedSeat: seat,
                  bundleHold: resolvedBundle,
                  holdSecondsRemaining: resolvedBundle.remainingSeconds,
                  roundTripSeatStep: RoundTripSeatStep.returnSeat,
                  clearError: true,
                ),
              );
              loadSeatMap(returnOption.returnTripId);
            },
            onError: (failure) {
              final isBookingClosed =
                  failure is BookingClosedFailure ||
                  failure.message.toUpperCase().contains('BOOKING_CLOSED');

              if (kDebugMode) {
                debugPrint(
                  'ROUND_TRIP_SEAT bundleHoldError ${failure.runtimeType}: ${failure.message}',
                );
              }
              emit(
                state.copyWith(
                  status: BookingStatus.error,
                  selectedSeat: previousSeat,
                  clearSelectedSeat: previousSeat == null,
                  errorMessage: isBookingClosed
                      ? 'انتهى وقت الحجز لهذه الرحلة.'
                      : failure.message,
                ),
              );
              _refreshSeatMapSilently(outboundTrip.tripId);
              if (isBookingClosed && state.selectedRouteStop != null) {
                loadAvailableTrips(originStop: state.selectedRouteStop);
              }
            },
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ROUND_TRIP_SEAT bundleHoldError $e');
          }
          emit(
            state.copyWith(
              status: BookingStatus.error,
              selectedSeat: previousSeat,
              clearSelectedSeat: previousSeat == null,
              errorMessage: 'حدث خطأ أثناء حجز المقعد، يرجى المحاولة مرة أخرى',
            ),
          );
          _refreshSeatMapSilently(outboundTrip.tripId);
        }
      } else {
        // RoundTripSeatStep.returnSeat
        final bundle = state.bundleHold;
        if (bundle == null) return;

        if (state.selectedTrip?.isBookingClosed() == true ||
            state.selectedReturnOption?.isBookingClosed() == true) {
          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
            ),
          );
          return;
        }

        final setReturnSeatUseCase =
            _setRoundTripReturnSeatUseCase ??
            (_bookingRepository != null
                ? SetRoundTripReturnSeatUseCase(_bookingRepository)
                : (getIt.isRegistered<SetRoundTripReturnSeatUseCase>()
                      ? getIt<SetRoundTripReturnSeatUseCase>()
                      : null));

        if (setReturnSeatUseCase == null) {
          emit(
            state.copyWith(
              status: BookingStatus.error,
              errorMessage: 'تعذر الاتصال بخدمة حجز الرحلات',
            ),
          );
          return;
        }

        final previousReturnSeat = state.selectedReturnSeat;
        emit(
          state.copyWith(
            status: BookingStatus.holdingSeat,
            selectedReturnSeat: seat,
            clearError: true,
          ),
        );

        try {
          final result = await setReturnSeatUseCase(
            bundleHoldId: bundle.bundleHoldId,
            returnSeatId: seat.seatId,
          );

          result.fold(
            onSuccess: (updatedBundle) {
              final mergedBundle = bundle
                  .mergeWith(updatedBundle)
                  .ensureAuthoritativeFares(state.selectedReturnOption);

              emit(
                state.copyWith(
                  status: BookingStatus.seatHeld,
                  selectedReturnSeat: seat,
                  bundleHold: mergedBundle,
                  clearError: true,
                ),
              );
            },
            onError: (failure) {
              final isBookingClosed =
                  failure is BookingClosedFailure ||
                  failure.message.toUpperCase().contains('BOOKING_CLOSED');
              final returnTripId = state.selectedReturnOption?.returnTripId;
              emit(
                state.copyWith(
                  status: BookingStatus.error,
                  selectedReturnSeat: previousReturnSeat,
                  clearSelectedReturnSeat: previousReturnSeat == null,
                  errorMessage: isBookingClosed
                      ? 'انتهى وقت الحجز لهذه الرحلة.'
                      : failure.message,
                ),
              );
              if (returnTripId != null) {
                _refreshSeatMapSilently(returnTripId);
              }
              if (isBookingClosed && state.selectedRouteStop != null) {
                loadAvailableTrips(originStop: state.selectedRouteStop);
              }
            },
          );
        } catch (e) {
          final returnTripId = state.selectedReturnOption?.returnTripId;
          emit(
            state.copyWith(
              status: BookingStatus.error,
              selectedReturnSeat: previousReturnSeat,
              clearSelectedReturnSeat: previousReturnSeat == null,
              errorMessage: 'حدث خطأ أثناء حجز المقعد، يرجى المحاولة مرة أخرى',
            ),
          );
          if (returnTripId != null) {
            _refreshSeatMapSilently(returnTripId);
          }
        }
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

    if (state.selectedTrip?.isBookingClosed() == true ||
        state.selectedReturnOption?.isBookingClosed() == true) {
      emit(
        state.copyWith(
          status: BookingStatus.error,
          errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
        ),
      );
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
      if (state.selectedTrip?.isBookingClosed() == true) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        return;
      }
      emit(state.copyWith(currentStep: BookingStep.review, clearError: true));
    } else {
      if (state.bundleHold == null ||
          state.selectedSeat == null ||
          state.selectedReturnSeat == null) {
        return;
      }

      if (state.selectedTrip?.isBookingClosed() == true ||
          state.selectedReturnOption?.isBookingClosed() == true) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        return;
      }

      var bundle = state.bundleHold!;
      if ((bundle.outboundBaseFarePoints <= 0 ||
              bundle.returnBaseFarePoints <= 0) &&
          state.selectedReturnOption != null) {
        bundle = bundle.ensureAuthoritativeFares(state.selectedReturnOption);
      }

      if (bundle.outboundBaseFarePoints <= 0 ||
          bundle.returnBaseFarePoints <= 0 ||
          bundle.totalPoints <= 0) {
        emit(
          state.copyWith(
            status: BookingStatus.error,
            errorMessage:
                'بيانات تسعير رحلة الذهاب والعودة غير متوفرة، يرجى المحاولة مرة أخرى',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          currentStep: BookingStep.review,
          bundleHold: bundle,
          clearError: true,
        ),
      );
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

      if (state.selectedTrip?.isBookingClosed() == true) {
        _cancelHoldTimer();
        _releaseBookingHoldUseCase(holdId: hold.holdId);
        emit(
          state.copyWith(
            status: BookingStatus.error,
            currentStep: BookingStep.seatMap,
            clearActiveHold: true,
            clearSelectedSeat: true,
            holdSecondsRemaining: 0,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        if (state.selectedRouteStop != null) {
          loadAvailableTrips(originStop: state.selectedRouteStop);
        }
        return;
      }

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
          final isBookingClosed =
              failure is BookingClosedFailure ||
              failure.message.toUpperCase().contains('BOOKING_CLOSED');

          if (isBookingClosed) {
            _cancelHoldTimer();
            emit(
              state.copyWith(
                status: BookingStatus.error,
                currentStep: BookingStep.seatMap,
                clearActiveHold: true,
                clearSelectedSeat: true,
                holdSecondsRemaining: 0,
                errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
              ),
            );
            if (state.selectedRouteStop != null) {
              loadAvailableTrips(originStop: state.selectedRouteStop);
            }
            return;
          }

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

      if (state.selectedTrip?.isBookingClosed() == true ||
          state.selectedReturnOption?.isBookingClosed() == true) {
        _cancelHoldTimer();
        final releaseBundleUseCase =
            _releaseRoundTripBundleHoldUseCase ??
            (_bookingRepository != null
                ? ReleaseRoundTripBundleHoldUseCase(_bookingRepository)
                : (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                      ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                      : null));
        if (releaseBundleUseCase != null) {
          releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
        }
        emit(
          state.copyWith(
            status: BookingStatus.error,
            currentStep: BookingStep.seatMap,
            roundTripSeatStep: RoundTripSeatStep.outbound,
            clearBundleHold: true,
            clearSelectedSeat: true,
            clearSelectedReturnSeat: true,
            holdSecondsRemaining: 0,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        if (state.selectedRouteStop != null) {
          loadAvailableTrips(originStop: state.selectedRouteStop);
        }
        return;
      }

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
          final isBookingClosed =
              failure is BookingClosedFailure ||
              failure.message.toUpperCase().contains('BOOKING_CLOSED');

          if (isBookingClosed) {
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
                errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
              ),
            );
            if (state.selectedRouteStop != null) {
              loadAvailableTrips(originStop: state.selectedRouteStop);
            }
            return;
          }

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

  void _scheduleCutoffTimer() {
    _cutoffTimer?.cancel();
    _cutoffTimer = null;

    final now = PassengerBookingAvailability.currentNow;
    DateTime? earliestCutoff;

    for (final trip in state.availableTrips) {
      final cutoff = trip.bookingCloseAt;
      if (cutoff != null && cutoff.isAfter(now)) {
        if (earliestCutoff == null || cutoff.isBefore(earliestCutoff)) {
          earliestCutoff = cutoff;
        }
      }
    }

    final selectedCutoff = state.selectedTrip?.bookingCloseAt;
    if (selectedCutoff != null && selectedCutoff.isAfter(now)) {
      if (earliestCutoff == null || selectedCutoff.isBefore(earliestCutoff)) {
        earliestCutoff = selectedCutoff;
      }
    }

    for (final opt in state.returnOptions) {
      final cutoff = opt.bookingCloseAt;
      if (cutoff != null && cutoff.isAfter(now)) {
        if (earliestCutoff == null || cutoff.isBefore(earliestCutoff)) {
          earliestCutoff = cutoff;
        }
      }
    }

    final retCutoff = state.selectedReturnOption?.bookingCloseAt;
    if (retCutoff != null && retCutoff.isAfter(now)) {
      if (earliestCutoff == null || retCutoff.isBefore(earliestCutoff)) {
        earliestCutoff = retCutoff;
      }
    }

    if (earliestCutoff != null) {
      final duration =
          earliestCutoff.difference(now) + const Duration(milliseconds: 100);
      _cutoffTimer = Timer(duration, () {
        if (!isClosed) {
          checkCutoffOnResume();
        }
      });
    }
  }

  /// Re-evaluates booking availability on resume or when cutoff timer fires
  void checkCutoffOnResume() {
    if (isClosed) return;
    _scheduleCutoffTimer();

    final isSingleClosed =
        state.selectedTrip != null && state.selectedTrip!.isBookingClosed();
    final isReturnClosed =
        state.isRoundTrip &&
        state.selectedReturnOption != null &&
        state.selectedReturnOption!.isBookingClosed();

    if (isSingleClosed || isReturnClosed) {
      if (state.currentStep == BookingStep.seatMap ||
          state.currentStep == BookingStep.review) {
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
                (_bookingRepository != null
                    ? ReleaseRoundTripBundleHoldUseCase(_bookingRepository)
                    : (getIt.isRegistered<ReleaseRoundTripBundleHoldUseCase>()
                          ? getIt<ReleaseRoundTripBundleHoldUseCase>()
                          : null));
            if (releaseBundleUseCase != null) {
              releaseBundleUseCase(bundleHoldId: bundle.bundleHoldId);
            }
          }
        }

        emit(
          state.copyWith(
            status: BookingStatus.error,
            currentStep: BookingStep.setup,
            roundTripSeatStep: RoundTripSeatStep.outbound,
            clearActiveHold: true,
            clearBundleHold: true,
            clearSelectedSeat: true,
            clearSelectedReturnSeat: true,
            holdSecondsRemaining: 0,
            errorMessage: 'انتهى وقت الحجز لهذه الرحلة.',
          ),
        );
        if (state.selectedRouteStop != null) {
          loadAvailableTrips(originStop: state.selectedRouteStop);
        }
        return;
      }
    }

    emit(state.copyWith());
  }

  @override
  Future<void> close() {
    _cancelHoldTimer();
    _cutoffTimer?.cancel();
    _seatSubscription?.cancel();
    return super.close();
  }
}
