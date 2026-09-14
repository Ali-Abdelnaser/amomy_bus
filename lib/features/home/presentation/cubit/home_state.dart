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

  const HomeState({
    this.status = HomeStatus.initial,
    this.summary,
    this.announcements = const [],
    this.errorMessage,
    this.isRefreshing = false,
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
  }) {
    return HomeState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      announcements: announcements ?? this.announcements,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        announcements,
        errorMessage,
        isRefreshing,
      ];
}
