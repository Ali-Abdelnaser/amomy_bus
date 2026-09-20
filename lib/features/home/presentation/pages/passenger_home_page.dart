import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/status_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
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

import '../../../notifications/domain/repositories/notification_repository.dart';
import '../../../notifications/presentation/cubit/notification_cubit.dart';
import '../../../notifications/presentation/cubit/notification_state.dart';
import '../../../notifications/presentation/services/notification_service.dart';

class PassengerHomePage extends StatefulWidget {
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

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

/// Keeps the existing announcement feature available while its Home experience
/// is prepared for a future product-approved redesign.
const bool homeAnnouncementsEnabled = false;

class _PassengerHomePageState extends State<PassengerHomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _refreshHomeData();
    }
  }

  void _refreshHomeData() {
    if (!mounted) return;
    try {
      context.read<HomeCubit>().loadHomeData(isRefresh: true);
      final tripId = context
          .read<HomeCubit>()
          .state
          .summary
          ?.upcomingTrip
          ?.tripId;
      if (tripId != null && tripId.isNotEmpty) {
        context.read<TrackingCubit>().loadTrackingData(
          tripId: tripId,
          isRefresh: true,
        );
      }
    } catch (_) {}
  }

  void _checkNotificationPermission() {
    if (!mounted) return;
    if (getIt.isRegistered<NotificationService>()) {
      getIt<NotificationService>().promptPermissionIfNeeded(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotificationRealtime =
        getIt.isRegistered<NotificationCubit>() ||
        getIt.isRegistered<NotificationRepository>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeCubit>(
          create: (context) =>
              widget.homeCubit ??
              (getIt.isRegistered<HomeCubit>()
                  ? (getIt<HomeCubit>()..loadHomeData())
                  : HomeCubit.idle()),
        ),
        BlocProvider<TrackingCubit>(
          create: (context) =>
              widget.trackingCubit ??
              (getIt.isRegistered<TrackingCubit>()
                  ? getIt<TrackingCubit>()
                  : TrackingCubit(repository: getIt())),
        ),
        if (hasNotificationRealtime)
          BlocProvider<NotificationCubit>(
            create: (context) =>
                getIt.isRegistered<NotificationCubit>()
                      ? (getIt<NotificationCubit>()..loadNotifications())
                      : NotificationCubit(
                          repository: getIt<NotificationRepository>(),
                          notificationService:
                              getIt.isRegistered<NotificationService>()
                              ? getIt<NotificationService>()
                              : null,
                        )
                  ..loadNotifications(),
          ),
      ],
      child: AppScaffold(
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<HomeCubit, HomeState>(
            listenWhen: (previous, current) =>
                (previous.trackableTripId ??
                    previous.summary?.upcomingTrip?.tripId) !=
                (current.trackableTripId ??
                    current.summary?.upcomingTrip?.tripId),
            listener: (context, state) {
              final tripId =
                  state.trackableTripId ?? state.summary?.upcomingTrip?.tripId;
              if (tripId != null && tripId.isNotEmpty) {
                context.read<TrackingCubit>().loadTrackingData(
                  tripId: tripId,
                  isRefresh: true,
                );
              }
            },
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
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        AppSpacing.gapH16,
                        Text(
                          StatusLocalizer.localizeError(
                            context,
                            state.errorMessage,
                          ),
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
              final summary =
                  state.summary ?? PassengerHomePage._skeletonSummary;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  final futures = <Future>[
                    context.read<HomeCubit>().loadHomeData(isRefresh: true),
                  ];
                  final trackingTripId =
                      state.trackableTripId ??
                      state.summary?.upcomingTrip?.tripId;
                  if (trackingTripId != null && trackingTripId.isNotEmpty) {
                    futures.add(
                      context.read<TrackingCubit>().loadTrackingData(
                        tripId: trackingTripId,
                        isRefresh: true,
                      ),
                    );
                  }
                  try {
                    final cubit =
                        widget.walletCubit ?? context.read<WalletCubit>();
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Custom App Bar
                        if (hasNotificationRealtime)
                          BlocBuilder<NotificationCubit, NotificationState>(
                            builder: (context, notificationState) {
                              final unreadCount =
                                  notificationState is NotificationLoaded
                                  ? notificationState.unreadCount
                                  : 0;
                              return HomeAppBar(
                                fullName: summary.profile.fullName,
                                avatarUrl: summary.profile.avatarUrl,
                                unreadNotificationsCount: unreadCount,
                              );
                            },
                          )
                        else
                          HomeAppBar(
                            fullName: summary.profile.fullName,
                            avatarUrl: summary.profile.avatarUrl,
                          ),
                        AppSpacing.gapH20,
                        // Final approved Home section order:
                        // Book Now -> Live Tracking -> Upcoming Trip -> Activity.
                        // Do not reorder without explicit product decision.
                        Builder(
                          builder: (context) {
                            final parentWalletCubit =
                                widget.walletCubit ??
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
                                  return HomeBookRideCard(
                                    points: livePoints,
                                    isBookingAvailable:
                                        state.isBookingAvailable,
                                    hasLoadedAvailability:
                                        state.hasLoadedAvailability,
                                  );
                                },
                              );
                            } else {
                              return HomeBookRideCard(
                                points: summary.availablePoints,
                                isBookingAvailable: state.isBookingAvailable,
                                hasLoadedAvailability:
                                    state.hasLoadedAvailability,
                              );
                            }
                          },
                        ),
                        AppSpacing.gapH20,
                        if (homeAnnouncementsEnabled &&
                            state.announcements.isNotEmpty) ...[
                          HomeAnnouncementsSection(
                            announcements: state.announcements,
                          ),
                          AppSpacing.gapH20,
                        ],
                        HomeLiveTrackingCard(
                          onViewMapTap:
                              (state.trackableTripId?.isNotEmpty == true ||
                                  summary.upcomingTrip?.tripId.isNotEmpty ==
                                      true)
                              ? () {
                                  final id =
                                      state.trackableTripId ??
                                      summary.upcomingTrip!.tripId;
                                  context.push(
                                    RoutePaths.liveTracking.replaceFirst(
                                      ':tripId',
                                      id,
                                    ),
                                  );
                                }
                              : null,
                        ),
                        AppSpacing.gapH24,
                        HomeUpcomingTripCard(
                          upcomingTrip: summary.upcomingTrip,
                          isBookingAvailable: state.isBookingAvailable,
                          hasLoadedAvailability: state.hasLoadedAvailability,
                          onCancelBooking: () => context.push(RoutePaths.trips),
                        ),
                        AppSpacing.gapH24,
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
