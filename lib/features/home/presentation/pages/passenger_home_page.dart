import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/entities/home_summary.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_activity_section.dart';
import '../widgets/home_announcements_section.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_book_ride_card.dart';
import '../widgets/home_upcoming_trip_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tracking/presentation/cubit/tracking_cubit.dart';
import '../../../tracking/presentation/widgets/home_live_tracking_card.dart';
import '../../../wallet/presentation/cubit/wallet_cubit.dart';
import '../../../wallet/presentation/cubit/wallet_state.dart';

class PassengerHomePage extends StatelessWidget {
  final HomeCubit? homeCubit;
  final WalletCubit? walletCubit;
  final TrackingCubit? trackingCubit;

  const PassengerHomePage({
    super.key,
    this.homeCubit,
    this.walletCubit,
    this.trackingCubit,
  });

  static final HomeSummary _skeletonSummary = HomeSummary(
    profile: const PassengerProfileSummary(
      fullName: 'Ahmed Mohamed',
      avatarUrl: null,
    ),
    availablePoints: 1500,
    upcomingTrip: PassengerUpcomingTrip(
      bookingId: 'dummy-booking',
      tripId: 'dummy-trip',
      direction: 'outbound',
      originNameAr: 'ميت فضالة',
      originNameEn: 'Mit Fadala',
      destinationNameAr: 'المنصورة',
      destinationNameEn: 'Mansoura',
      serviceDate: DateTime.now(),
      departureAt: DateTime.now(),
      departureTime: '08:30',
      seatNumber: 'A1',
      farePoints: 30,
      bookingStatus: 'confirmed',
      qrToken: 'dummy-qr',
    ),
    activity: const PassengerActivityMetrics(
      tripsThisMonth: 4,
      completedTrips: 12,
      pointsSpentThisMonth: 120,
      missedTrips: 0,
    ),
  );

  static final List<Announcement> _skeletonAnnouncements = [
    const Announcement(
      id: 'dummy-announcement',
      titleAr: 'تنبيه الرحلات',
      titleEn: 'Trip Alert',
      descriptionAr: 'تابع مواعيد رحلاتك من التطبيق قبل التحرك.',
      descriptionEn: 'Track your trip schedules before departure.',
      type: 'announcement',
      sortOrder: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (context) =>
              homeCubit ??
              (getIt.isRegistered<HomeCubit>()
                  ? (getIt<HomeCubit>()..loadHomeData())
                  : HomeCubit.idle()),
        ),
        BlocProvider<TrackingCubit>(
          create: (context) =>
              trackingCubit ??
              (getIt.isRegistered<TrackingCubit>()
                    ? (getIt<TrackingCubit>()..loadTrackingData())
                    : TrackingCubit(repository: getIt())
                ..loadTrackingData()),
        ),
      ],
      child: AppScaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              final l10n = context.l10n;

              // Error State (if not loaded at all)
              if (state.isError && state.summary == null) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.edgeInsetsA24,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        AppSpacing.gapH16,
                        Text(
                          state.errorMessage ?? l10n.errorOccurred,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapH20,
                        AppButton(
                          label: l10n.retry,
                          onPressed: () =>
                              context.read<HomeCubit>().loadHomeData(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Loading / Skeleton State
              final isLoading = state.isLoading || state.isInitial;
              final summary = state.summary ?? _skeletonSummary;
              final announcements = state.isLoaded
                  ? state.announcements
                  : _skeletonAnnouncements;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  final futures = <Future>[
                    context.read<HomeCubit>().loadHomeData(isRefresh: true),
                    context.read<TrackingCubit>().loadTrackingData(
                      isRefresh: true,
                    ),
                  ];
                  try {
                    final cubit = walletCubit ?? context.read<WalletCubit>();
                    final authState = context.read<AuthBloc>().state;
                    final userId = authState is Authenticated
                        ? authState.user.id
                        : '';
                    if (userId.isNotEmpty) {
                      futures.add(cubit.loadWalletSummary(userId));
                    }
                  } catch (_) {}
                  await Future.wait(futures);
                },
                child: Skeletonizer(
                  enabled: isLoading,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Custom App Bar
                        HomeAppBar(
                          fullName: summary.profile.fullName,
                          avatarUrl: summary.profile.avatarUrl,
                        ),
                        AppSpacing.gapH20,

                        // 2. Announcements Carousel
                        if (announcements.isNotEmpty) ...[
                          HomeAnnouncementsSection(
                            announcements: announcements,
                          ),
                          AppSpacing.gapH20,
                        ],
                        // 4. Live Bus Tracking Card (Global for ALL passengers)
                        const HomeLiveTrackingCard(),
                        AppSpacing.gapH24,

                        // 3. Book Your Ride (Integrated with Authoritative Points Balance)
                        Builder(
                          builder: (context) {
                            final parentWalletCubit =
                                walletCubit ??
                                () {
                                  try {
                                    return context.read<WalletCubit>();
                                  } catch (_) {
                                    return null;
                                  }
                                }();

                            if (parentWalletCubit != null) {
                              return BlocBuilder<WalletCubit, WalletState>(
                                bloc: parentWalletCubit,
                                builder: (context, walletState) {
                                  final livePoints =
                                      walletState.status == WalletStatus.loaded
                                      ? walletState.summary.totalAvailablePoints
                                      : summary.availablePoints;
                                  return HomeBookRideCard(points: livePoints);
                                },
                              );
                            } else {
                              return HomeBookRideCard(
                                points: summary.availablePoints,
                              );
                            }
                          },
                        ),
                        AppSpacing.gapH24,

                        // 5. Upcoming Trip
                        HomeUpcomingTripCard(
                          upcomingTrip: summary.upcomingTrip,
                        ),
                        AppSpacing.gapH24,

                        // 6. Your Activity
                        HomeActivitySection(activity: summary.activity),
                        // Generous clearance ensuring full visibility above floating nav
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
