import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/domain/usecases/booking_usecases.dart';
import 'passenger_trips_state.dart';

@injectable
class PassengerTripsCubit extends Cubit<PassengerTripsState> {
  final GetPassengerBookingsUseCase? _getPassengerBookingsUseCase;
  final BookingRepository? _bookingRepository;

  PassengerTripsCubit(
    this._getPassengerBookingsUseCase, [
    this._bookingRepository,
  ]) : super(const PassengerTripsState());

  PassengerTripsCubit.idle()
      : _getPassengerBookingsUseCase = null,
        _bookingRepository = null,
        super(const PassengerTripsState());

  BookingRepository? get _repo =>
      _bookingRepository ??
      (getIt.isRegistered<BookingRepository>()
          ? getIt<BookingRepository>()
          : null);

  /// Loads the entire Passenger Daily Trips Hub in parallel:
  /// - Today's scheduled trips with seat calculations and passenger status
  /// - Passenger's preferred journey (From -> To)
  /// - Booking history
  /// - Route stops for editing preferred journey
  Future<void> loadTripsHub() async {
    emit(state.copyWith(
      status: PassengerTripsStatus.loading,
      clearError: true,
    ));

    final repo = _repo;
    final bookingsUseCase = _getPassengerBookingsUseCase ??
        (getIt.isRegistered<GetPassengerBookingsUseCase>()
            ? getIt<GetPassengerBookingsUseCase>()
            : null);

    List<PassengerTodayTrip> todayTrips = [];
    PassengerTripPreference? preferredJourney;
    List<PassengerBooking> historyTrips = [];
    List<PassengerBooking> upcomingTrips = [];
    List<RouteStop> availableStops = [];
    String? errorMsg;

    await Future.wait([
      // 1. Today's Trips
      if (repo != null)
        repo.getPassengerTodayTrips().then((res) {
          res.fold(
            onSuccess: (trips) => todayTrips = trips,
            onError: (err) => errorMsg ??= err.message,
          );
        }),

      // 2. Preferred Journey
      if (repo != null)
        repo.getMyTripPreferences().then((res) {
          res.fold(
            onSuccess: (pref) => preferredJourney = pref,
            onError: (_) {}, // Non-fatal if preference is not set yet
          );
        }),

      // 3. Passenger Bookings (History & Upcoming)
      if (bookingsUseCase != null)
        bookingsUseCase().then((res) {
          res.fold(
            onSuccess: (bookings) {
              final now = DateTime.now();
              upcomingTrips = bookings
                  .where((b) =>
                      b.status == 'confirmed' && b.departureAt.isAfter(now))
                  .toList()
                ..sort((a, b) => a.departureAt.compareTo(b.departureAt));

              historyTrips = bookings
                  .where((b) =>
                      b.status != 'confirmed' || !b.departureAt.isAfter(now))
                  .toList()
                ..sort((a, b) => b.departureAt.compareTo(a.departureAt));
            },
            onError: (err) => errorMsg ??= err.message,
          );
        }),

      // 4. Available Stops for Preferred Journey editing
      if (repo != null)
        repo.getRouteStops(direction: BookingDirection.outbound).then((res) {
          res.fold(
            onSuccess: (stops) => availableStops = stops,
            onError: (_) {},
          );
        }),
    ]);

    emit(state.copyWith(
      status: errorMsg != null && todayTrips.isEmpty && historyTrips.isEmpty
          ? PassengerTripsStatus.error
          : PassengerTripsStatus.loaded,
      todayTrips: todayTrips,
      preferredJourney: preferredJourney,
      historyTrips: historyTrips,
      upcomingTrips: upcomingTrips,
      availableStops: availableStops,
      errorMessage: errorMsg,
    ));
  }

  /// Backward-compatible method calling loadTripsHub
  Future<void> loadBookings() => loadTripsHub();

  /// Updates passenger's preferred journey
  Future<bool> updatePreferredJourney({
    required String originStopId,
    required String destinationStopId,
  }) async {
    final repo = _repo;
    if (repo == null) return false;

    final result = await repo.setMyTripPreferences(
      originStopId: originStopId,
      destinationStopId: destinationStopId,
    );

    return result.fold(
      onSuccess: (pref) {
        emit(state.copyWith(preferredJourney: pref));
        // Refresh today's trips with updated boarding stop fare if applicable
        loadTripsHub();
        return true;
      },
      onError: (err) {
        emit(state.copyWith(errorMessage: err.message));
        return false;
      },
    );
  }

  /// Cancels an existing booking before the 30-minute departure cutoff.
  Future<bool> cancelBooking(String bookingId) async {
    final repo = _repo;
    if (repo == null) return false;

    final result = await repo.cancelBooking(bookingId);
    return result.fold(
      onSuccess: (_) {
        loadTripsHub();
        return true;
      },
      onError: (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
    );
  }

  /// Changes the seat of an existing booking atomically within the 30-minute cutoff.
  Future<bool> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async {
    final repo = _repo;
    if (repo == null) return false;

    final result = await repo.changeBookingSeat(
      bookingId: bookingId,
      newSeatId: newSeatId,
    );
    return result.fold(
      onSuccess: (_) {
        loadTripsHub();
        return true;
      },
      onError: (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
    );
  }
}

