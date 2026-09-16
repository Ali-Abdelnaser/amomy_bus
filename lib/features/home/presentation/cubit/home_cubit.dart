import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../app/di/injection.dart';
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

      if (tripsFuture != null && results.length > 2) {
        final tripsResult = results[2] as Result<List<PassengerTodayTrip>>;
        tripsResult.fold(
          onSuccess: (trips) {
            hasLoadedAvailability = true;
            isBookingAvailable =
                PassengerBookingAvailability.hasAnyBookableTrip(trips);
          },
          onError: (_) {
            // Keep previous availability and do not claim no trips on network error
            hasLoadedAvailability = false;
          },
        );
      }

      summaryResult.fold(
        onError: (failure) {
          emit(
            state.copyWith(
              status: HomeStatus.error,
              errorMessage: failure.message,
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
              errorMessage: null,
              isRefreshing: false,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }
}
