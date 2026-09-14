import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/typedefs/typedefs.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/repositories/home_repository.dart';
import 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository? _homeRepository;

  HomeCubit(this._homeRepository) : super(const HomeState());

  HomeCubit.idle({HomeState? initialState})
      : _homeRepository = null,
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

      final results = await Future.wait([summaryFuture, announcementsFuture]);
      final summaryResult = results[0] as Result<HomeSummary>;
      final announcementsResult = results[1] as Result<List<Announcement>>;

      final announcements = announcementsResult.dataOrNull ?? [];

      summaryResult.fold(
        onError: (failure) {
          emit(state.copyWith(
            status: HomeStatus.error,
            errorMessage: failure.message,
            isRefreshing: false,
          ));
        },
        onSuccess: (summary) {
          emit(state.copyWith(
            status: HomeStatus.loaded,
            summary: summary,
            announcements: announcements,
            errorMessage: null,
            isRefreshing: false,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
        isRefreshing: false,
      ));
    }
  }
}
