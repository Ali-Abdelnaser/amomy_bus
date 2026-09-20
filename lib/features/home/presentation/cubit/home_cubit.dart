import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/error/app_error_mapper.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/domain/services/passenger_booking_availability.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository? _homeRepository;
  final BookingRepository? _bookingRepository;
  StreamSubscription<void>? _bookingUpdatesSubscription;

  HomeCubit(this._homeRepository, [this._bookingRepository])
    : super(const HomeState());

  BookingRepository? get _bookingRepo =>
      _bookingRepository ??
      (getIt.isRegistered<BookingRepository>()
          ? getIt<BookingRepository>()
          : null);

  HomeCubit.idle({HomeState? initialState})
    : _homeRepository = null,
      _bookingRepository = null,
      super(
        initialState ??
            HomeState(
              status: HomeStatus.loaded,
              summary: HomeSummary(
                profile: const PassengerProfileSummary(
                  fullName: 'Ali Commuter',
                  avatarUrl: null,
                ),
                availablePoints: 1250,
                upcomingTrip: null,
                activity: const PassengerActivityMetrics(
                  tripsThisMonth: 3,
                  completedTrips: 8,
                  pointsSpentThisMonth: 90,
                  missedTrips: 0,
                ),
              ),
              announcements: const [
                Announcement(
                  id: 'seed-1',
                  titleAr: 'تنبيه الرحلات',
                  titleEn: 'Trip Alert',
                  descriptionAr: 'تابع مواعيد رحلاتك من التطبيق قبل التحرك.',
                  descriptionEn:
                      'Track your trip schedules from the app before departure.',
                  type: 'announcement',
                ),
              ],
            ),
      );

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (_homeRepository == null) return;

    if (isRefresh) {
      emit(state.copyWith(isRefreshing: true));
    } else {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    try {
      final summaryFuture = _homeRepository.getHomeSummary();
      final announcementsFuture = _homeRepository.getActiveAnnouncements();
      final bookingRepo = _bookingRepo;
      final tripsFuture = bookingRepo?.getPassengerTodayTrips();

      final results = await Future.wait([
        summaryFuture,
        announcementsFuture,
        ?tripsFuture,
      ]);
      final summaryResult = results[0] as Result<HomeSummary>;
      final announcementsResult = results[1] as Result<List<Announcement>>;

      final announcements = announcementsResult.dataOrNull ?? [];

      bool isBookingAvailable = state.isBookingAvailable;
      bool hasLoadedAvailability = state.hasLoadedAvailability;

      String? trackableTripId;

      if (tripsFuture != null && results.length > 2) {
        final tripsResult = results[2] as Result<List<PassengerTodayTrip>>;
        tripsResult.fold(
          onSuccess: (trips) {
            hasLoadedAvailability = true;
            isBookingAvailable =
                PassengerBookingAvailability.hasAnyBookableTrip(trips);
            trackableTripId = _selectTrackableTrip(
              todayTrips: trips,
              summaryTrip: summaryResult.dataOrNull?.upcomingTrip,
            );
          },
          onError: (_) {
            // Keep previous availability and do not claim no trips on network error
            hasLoadedAvailability = false;
          },
        );
      } else {
        trackableTripId = summaryResult.dataOrNull?.upcomingTrip?.tripId;
      }

      summaryResult.fold(
        onError: (failure) {
          emit(
            state.copyWith(
              status: HomeStatus.error,
              errorMessage: AppErrorMapper.mapToString(failure),
              isRefreshing: false,
            ),
          );
        },
        onSuccess: (summary) {
          emit(
            state.copyWith(
              status: HomeStatus.loaded,
              summary: summary,
              announcements: announcements,
              isBookingAvailable: isBookingAvailable,
              hasLoadedAvailability: hasLoadedAvailability,
              trackableTripId: trackableTripId ?? summary.upcomingTrip?.tripId,
              errorMessage: null,
              isRefreshing: false,
            ),
          );
        },
      );
      _startBookingUpdatesSubscription();
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: AppErrorMapper.mapToString(e),
          isRefreshing: false,
        ),
      );
    }
  }

  void _startBookingUpdatesSubscription() {
    final bookingRepo = _bookingRepo;
    if (bookingRepo == null || _bookingUpdatesSubscription != null) return;

    _bookingUpdatesSubscription = bookingRepo
        .subscribeToPassengerBookingUpdates()
        .listen(
          (_) => loadHomeData(isRefresh: true),
          onError: (error, stackTrace) {},
          cancelOnError: false,
        );
  }

  @override
  Future<void> close() {
    _bookingUpdatesSubscription?.cancel();
    return super.close();
  }

  /// Selects the trackable trip ID strictly from the passenger's confirmed booking.
  /// No clock-window gating (08:00/13:00) is applied.
  static String? _selectTrackableTrip({
    required List<PassengerTodayTrip> todayTrips,
    PassengerUpcomingTrip? summaryTrip,
  }) {
    if (summaryTrip?.tripId.isNotEmpty == true) {
      return summaryTrip!.tripId;
    }

    final bookedTrips = todayTrips.where((t) => t.alreadyBooked).toList();
    if (bookedTrips.isNotEmpty) {
      return bookedTrips.first.tripId;
    }

    return null;
  }
}
