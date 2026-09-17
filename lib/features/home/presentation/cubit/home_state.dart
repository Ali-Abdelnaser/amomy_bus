import 'package:equatable/equatable.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/home_summary.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final HomeSummary? summary;
  final List<Announcement> announcements;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isBookingAvailable;
  final bool hasLoadedAvailability;
  final String? trackableTripId;

  const HomeState({
    this.status = HomeStatus.initial,
    this.summary,
    this.announcements = const [],
    this.errorMessage,
    this.isRefreshing = false,
    this.isBookingAvailable = true,
    this.hasLoadedAvailability = false,
    this.trackableTripId,
  });

  bool get isInitial => status == HomeStatus.initial;
  bool get isLoading => status == HomeStatus.loading;
  bool get isLoaded => status == HomeStatus.loaded;
  bool get isError => status == HomeStatus.error;

  HomeState copyWith({
    HomeStatus? status,
    HomeSummary? summary,
    List<Announcement>? announcements,
    String? errorMessage,
    bool? isRefreshing,
    bool? isBookingAvailable,
    bool? hasLoadedAvailability,
    String? trackableTripId,
    bool clearTrackableTripId = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isBookingAvailable: isBookingAvailable ?? this.isBookingAvailable,
      hasLoadedAvailability:
          hasLoadedAvailability ?? this.hasLoadedAvailability,
      trackableTripId: clearTrackableTripId
          ? null
          : (trackableTripId ?? this.trackableTripId),
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    announcements,
    errorMessage,
    isRefreshing,
    isBookingAvailable,
    hasLoadedAvailability,
    trackableTripId,
  ];
}
