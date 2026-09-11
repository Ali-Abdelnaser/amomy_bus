import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../booking/domain/usecases/booking_usecases.dart';
import 'passenger_trips_state.dart';

@injectable
class PassengerTripsCubit extends Cubit<PassengerTripsState> {
  final GetPassengerBookingsUseCase? _getPassengerBookingsUseCase;

  PassengerTripsCubit(this._getPassengerBookingsUseCase)
      : super(const PassengerTripsState());

  PassengerTripsCubit.idle()
      : _getPassengerBookingsUseCase = null,
        super(const PassengerTripsState());

  Future<void> loadBookings() async {
    if (_getPassengerBookingsUseCase == null) return;
    emit(state.copyWith(status: PassengerTripsStatus.loading));

    final result = await _getPassengerBookingsUseCase();

    result.fold(
      onSuccess: (bookings) {
        final now = DateTime.now();
        final upcoming = bookings
            .where((b) => b.status == 'confirmed' && b.departureAt.isAfter(now))
            .toList()
          ..sort((a, b) => a.departureAt.compareTo(b.departureAt));

        final past = bookings
            .where((b) => b.status != 'confirmed' || !b.departureAt.isAfter(now))
            .toList()
          ..sort((a, b) => b.departureAt.compareTo(a.departureAt));

        emit(state.copyWith(
          status: PassengerTripsStatus.loaded,
          upcomingTrips: upcoming,
          pastTrips: past,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          status: PassengerTripsStatus.error,
          errorMessage: failure.message,
        ));
      },
    );
  }
}
