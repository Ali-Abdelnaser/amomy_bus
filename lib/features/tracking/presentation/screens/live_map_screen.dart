import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/fleet_bus.dart';
import '../../domain/models/live_tracking_status.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../widgets/live_bus_map_widget.dart';

/// AMOMY Live Map Screen.
///
/// Passenger live tracking screen:
/// - waiting assignment / waiting start lifecycle
/// - live tracking
/// - stale GPS with last known position
/// - offline GPS
/// - progression syncing
/// - stop inspection
/// - bus detail sheet
/// - follow bus
class LiveMapScreen extends StatefulWidget {
  final TrackingCubit? trackingCubit;
  final String? tripId;

  const LiveMapScreen({super.key, this.trackingCubit, this.tripId});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  bool _isBusSheetOpen = false;
  FleetBus? _selectedFleetBus;
  String? _loadedExternalTripId;

  @override
  void initState() {
    super.initState();
    _loadExternalCubitIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LiveMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.trackingCubit != widget.trackingCubit ||
        oldWidget.tripId != widget.tripId) {
      _loadExternalCubitIfNeeded();
    }
  }

  void _loadExternalCubitIfNeeded() {
    final cubit = widget.trackingCubit;
    final tripId = widget.tripId;

    if (cubit == null || tripId == null || tripId.isEmpty) {
      return;
    }

    if (_loadedExternalTripId == tripId) {
      return;
    }

    _loadedExternalTripId = tripId;
    cubit.loadTrackingData(tripId: tripId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trackingCubit != null) {
      return BlocProvider.value(
        value: widget.trackingCubit!,
        child: _buildScaffold(),
      );
    }

    return BlocProvider(
      create: (_) {
        final cubit = getIt.isRegistered<TrackingCubit>()
            ? getIt<TrackingCubit>()
            : TrackingCubit(repository: getIt());

        final tripId = widget.tripId;

        cubit.loadTrackingData(tripId: tripId);

        return cubit;
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        final locale =
            Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: BlocConsumer<TrackingCubit, TrackingState>(
            listenWhen: (previous, current) {
              return current.isError &&
                  current.summary == null &&
                  current.fleetSummary == null &&
                  (!previous.isError ||
                      previous.errorMessage != current.errorMessage);
            },
            listener: (context, state) {
              AppSnackBar.showError(
                context,
                state.errorMessage ??
                    l10n?.errorOccurred ??
                    'An error occurred',
              );
            },
            builder: (context, state) {
              if (state.isLoading && state.summary == null && state.fleetSummary == null) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF8FAFC),
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              final summary = state.summary ?? state.fleetSummary?.toTrackingSummary();

              if (summary == null &&
                  !state.isFleetMode &&
                  (widget.tripId == null || widget.tripId!.isEmpty)) {
                return _buildNoTripSelectedView(context, locale);
              }

              if (state.isError && summary == null) {
                final isAr = locale.startsWith('ar');

                return Scaffold(
                  backgroundColor: const Color(0xFFF8FAFC),
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        isAr
                            ? Icons.arrow_forward_rounded
                            : Icons.arrow_back_rounded,
                        color: const Color(0xFF0F172A),
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n?.errorOccurred ?? 'An error occurred',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              final tripId = widget.tripId;

                              if (tripId != null && tripId.isNotEmpty) {
                                context.read<TrackingCubit>().loadTrackingData(
                                  tripId: tripId,
                                );
                              }
                            },
                            child: Text(l10n?.retry ?? 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (summary == null) {
                return const SizedBox.shrink();
              }

              final directionLabel =
                  summary.activeDirection == TrackingDirection.returnDirection
                  ? (locale == 'ar' ? 'رحلة العودة' : 'Return Trip')
                  : (locale == 'ar' ? 'رحلة الذهاب' : 'Outbound Trip');

              final isTripDeparted =
                  summary.tripStatus == 'departed' ||
                  summary.startedAt != null ||
                  summary.trackingEnabled == true ||
                  state.isDeparted ||
                  state.trackingEnabled;

              final isAdminDisabled =
                  state.isMapDisabled ||
                  (!state.isFleetMode &&
                      (state.trackingPhase == TrackingPhase.busHidden ||
                          summary.mapVisibilityState == 'bus_hidden' ||
                          !summary.busVisibleOnPassengerMap));

              final isTerminalLifecycle =
                  isAdminDisabled ||
                  (!state.isFleetMode &&
                      (state.trackingPhase == TrackingPhase.completed ||
                          state.trackingPhase == TrackingPhase.cancelled ||
                          state.trackingPhase == TrackingPhase.serviceDateEnded));

              final shouldShowLifecycle =
                  isTerminalLifecycle ||
                  (!state.isFleetMode && summary.routeStops.isEmpty && !isTripDeparted);

              if (shouldShowLifecycle) {
                return _buildPreTripLifecycleView(
                  context: context,
                  state: state,
                  locale: locale,
                  directionLabel: directionLabel,
                );
              }

              final selectedStop = state.selectedStop;
              final telemetry = state.latestTelemetry;

              final double centerButtonBottom;

              if (_isBusSheetOpen) {
                centerButtonBottom = 265;
              } else if (selectedStop != null) {
                centerButtonBottom = 200;
              } else {
                centerButtonBottom = 28;
              }

              return Stack(
                children: [
                  Positioned.fill(
                    child: LiveBusMapWidget(
                      telemetry: telemetry,
                      routeStops: summary.routeStops,
                      status: state.trackingStatus,
                      selectedStop: selectedStop,
                      isCompactPreview: false,
                      followBus: state.followBus && !state.isFleetMode,
                      routeGeometry: state.routeGeometry,
                      fleetBuses: state.fleetBuses,
                      onPanStart: () {
                        if (state.followBus) {
                          context.read<TrackingCubit>().toggleFollowBus(false);
                        }
                      },
                      onBusTap: () {
                        if (state.isGpsOffline) {
                          return;
                        }

                        setState(() {
                          _selectedFleetBus = null;
                          _isBusSheetOpen = true;
                        });

                        context.read<TrackingCubit>().selectStop(null);
                      },
                      onFleetBusTap: (bus) {
                        setState(() {
                          _selectedFleetBus = bus;
                          _isBusSheetOpen = true;
                        });

                        context.read<TrackingCubit>().selectStop(null);
                      },
                      onStopTap: (stop) {
                        setState(() {
                          _selectedFleetBus = null;
                          _isBusSheetOpen = false;
                        });

                        context.read<TrackingCubit>().selectStop(stop);
                      },
                    ),
                  ),

                  // Top header
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      minimum: const EdgeInsets.only(top: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: _buildTopFloatingHeader(
                          context: context,
                          directionLabel: directionLabel,
                          state: state,
                          locale: locale,
                          isAtStop: state.isAtStop,
                        ),
                      ),
                    ),
                  ),

                  // Follow bus button
                  if (!state.isGpsOffline)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      right: 16,
                      bottom: centerButtonBottom,
                      child: Material(
                        color: state.followBus
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          state.followBus ? 28 : 20,
                        ),
                        elevation: 5,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            state.followBus ? 28 : 20,
                          ),
                          onTap: () {
                            context.read<TrackingCubit>().toggleFollowBus(true);
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: state.followBus ? 12 : 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.followBus
                                      ? Icons.directions_bus_filled_rounded
                                      : Icons.near_me_rounded,
                                  color: state.followBus
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 19,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.followBus
                                      ? (locale == 'ar'
                                            ? 'تتبع مفعل'
                                            : 'Following')
                                      : (locale == 'ar'
                                            ? 'تتبع الحافلة'
                                            : 'Follow Bus'),
                                  style: TextStyle(
                                    color: state.followBus
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Stop detail
                  if (selectedStop != null)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: _buildStopDetailCard(
                        context: context,
                        stop: selectedStop,
                        locale: locale,
                        trackingState: state,
                      ),
                    ),

                  // Bus sheet
                  if (_isBusSheetOpen && !state.isGpsOffline)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildBusDetailSheet(
                        context: context,
                        state: state,
                        locale: locale,
                        directionLabel: directionLabel,
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPreTripLifecycleView({
    required BuildContext context,
    required TrackingState state,
    required String locale,
    required String directionLabel,
  }) {
    final l10n = AppLocalizations.of(context);
    final isAr = locale.startsWith('ar');

    final String title;
    final String subtitle;
    final IconData icon;
    final Color iconColor;
    final Color iconBg;

    switch (state.trackingPhase) {
      case TrackingPhase.waitingAssignment:
        title =
            l10n?.trackingConfirmedTitle ??
            (isAr ? 'تم تأكيد رحلتك' : 'Your trip is confirmed');

        subtitle =
            l10n?.trackingWaitingAssignmentSubtitle ??
            (isAr
                ? 'سيظهر التتبع المباشر عند تجهيز الحافلة للرحلة.'
                : 'Live tracking will be available when your bus is assigned.');

        icon = Icons.assignment_ind_outlined;
        iconColor = AppColors.primary;
        iconBg = AppColors.primary.withValues(alpha: 0.1);
        break;

      case TrackingPhase.waitingStart:
        title =
            l10n?.trackingReadyTitle ??
            (isAr ? 'رحلتك جاهزة' : 'Ready for your trip');

        subtitle =
            l10n?.trackingWaitingStartSubtitle ??
            (isAr
                ? 'سيبدأ التتبع المباشر عند بدء الرحلة.'
                : 'Live tracking will start when the trip starts.');

        icon = Icons.directions_bus_filled_outlined;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFE8F5E9);
        break;

      case TrackingPhase.reassignmentPending:
        title =
            l10n?.trackingUpdatingBusTitle ??
            (isAr ? 'جارٍ تحديث حافلة الرحلة' : 'Updating your bus');

        subtitle =
            l10n?.trackingReassignmentPendingSubtitle ??
            (isAr
                ? 'سيعود التتبع المباشر خلال لحظات.'
                : 'Live tracking will resume shortly.');

        icon = Icons.sync_rounded;
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        break;

      case TrackingPhase.completed:
        title = isAr
            ? 'انتهت الرحلة'
            : (l10n?.tripStatusCompleted ?? 'Trip completed');

        subtitle = isAr
            ? 'انتهت هذه الرحلة بنجاح.'
            : 'This trip has been completed.';

        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFE8F5E9);
        break;

      case TrackingPhase.cancelled:
        title =
            l10n?.tripStatusCancelled ??
            (isAr ? 'تم إلغاء الرحلة' : 'Trip cancelled');

        subtitle = isAr
            ? 'تم إلغاء هذه الرحلة.'
            : 'This trip has been cancelled.';

        icon = Icons.cancel_outlined;
        iconColor = AppColors.error;
        iconBg = const Color(0xFFFEE2E2);
        break;

      case TrackingPhase.serviceDateEnded:
        title =
            l10n?.trackingTripNotActive ??
            (isAr ? 'انتهى يوم الرحلة' : 'Trip day ended');

        subtitle = isAr
            ? 'لم يعد التتبع متاحًا لهذه الرحلة.'
            : 'Tracking is no longer available for this trip.';

        icon = Icons.event_busy_outlined;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
        break;

      case TrackingPhase.mapDisabled:
        title =
            l10n?.trackingMapDisabledTitle ??
            (isAr
                ? 'الخريطة غير متاحة حالياً'
                : 'Live map is currently unavailable');

        subtitle =
            l10n?.trackingMapDisabledSubtitle ??
            (isAr
                ? 'تم إيقاف عرض الموقع المباشر بواسطة الإدارة.'
                : 'Live location display has been disabled by the administration.');

        icon = Icons.map_outlined;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
        break;

      case TrackingPhase.busHidden:
        title =
            l10n?.trackingBusHiddenTitle ??
            (isAr
                ? 'الموقع المباشر غير متاح لهذه الرحلة'
                : 'Live location is unavailable for this trip');

        subtitle =
            l10n?.trackingBusHiddenSubtitle ??
            (isAr
                ? 'عرض موقع الحافلة متوقف حالياً.'
                : 'Live bus location display is currently turned off.');

        icon = Icons.directions_bus_outlined;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
        break;

      default:
        title =
            l10n?.trackingTripNotActive ??
            (isAr ? 'التتبع غير متاح حالياً' : 'Tracking not active');

        subtitle =
            l10n?.trackingLocationUnavailable ??
            (isAr
                ? 'الرحلة غير نشطة حالياً'
                : 'Trip tracking is not currently active');

        icon = Icons.info_outline_rounded;
        iconColor = const Color(0xFF64748B);
        iconBg = const Color(0xFFF1F5F9);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.trackingLive ?? (isAr ? 'التتبع المباشر' : 'Live Tracking'),
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              directionLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: iconColor),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoTripSelectedView(BuildContext context, String locale) {
    final l10n = AppLocalizations.of(context);
    final isAr = locale.startsWith('ar');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n?.trackingLive ?? (isAr ? 'التتبع المباشر' : 'Live Tracking'),
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n?.trackingNoTripSelectedTitle ??
                      (isAr
                          ? 'اختر رحلة لعرض التتبع'
                          : 'Select a trip to view tracking'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.trackingNoTripSelectedSubtitle ??
                      (isAr
                          ? 'يمكنك فتح التتبع المباشر من تفاصيل رحلتك.'
                          : 'You can open live tracking from your trip details.'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      context.go(RoutePaths.trips);
                    },
                    child: Text(
                      l10n?.trackingViewMyTripsAction ??
                          (isAr ? 'عرض رحلاتي' : 'View My Trips'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopFloatingHeader({
    required BuildContext context,
    required String directionLabel,
    required TrackingState state,
    required String locale,
    bool isAtStop = false,
  }) {
    final isAr = locale.startsWith('ar');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: const Color(0xFFF8FAFC),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  isAr ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                  size: 20,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'الحافلة المباشرة' : 'Live Bus',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                AppSpacing.gapH2,
                Text(
                  directionLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapW10,
          _buildHeaderStatusPill(
            context: context,
            state: state,
            locale: locale,
            isAtStop: isAtStop,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusPill({
    required BuildContext context,
    required TrackingState state,
    required String locale,
    bool isAtStop = false,
  }) {
    final l10n = AppLocalizations.of(context);

    final Color bg;
    final Color dotColor;
    final String label;

    final phase = state.trackingPhase;

    if (isAtStop &&
        phase != TrackingPhase.gpsOffline &&
        state.trackingStatus != LiveTrackingStatus.offline) {
      bg = const Color(0xFFE0F2FE);
      dotColor = const Color(0xFF0284C7);
      label = locale == 'ar' ? 'بالمحطة' : 'AT STOP';
    } else {
      switch (phase) {
        case TrackingPhase.live:
          bg = const Color(0xFFE8F5E9);
          dotColor = const Color(0xFF16A34A);
          label = l10n?.trackingLive ?? (locale == 'ar' ? 'مباشر' : 'LIVE');
          break;

        case TrackingPhase.gpsStale:
          bg = const Color(0xFFFEF3C7);
          dotColor = const Color(0xFFD97706);
          label =
              l10n?.trackingDelayedPill ??
              (locale == 'ar' ? 'مؤقتاً' : 'DELAYED');
          break;

        case TrackingPhase.gpsOffline:
          bg = const Color(0xFFF1F5F9);
          dotColor = const Color(0xFF64748B);
          label = locale == 'ar'
              ? 'موقع الحافلة غير متاح مؤقتًا'
              : (l10n?.trackingOffline ?? 'OFFLINE');
          break;

        case TrackingPhase.progressionSyncing:
          bg = const Color(0xFFFEF3C7);
          dotColor = const Color(0xFFD97706);
          label = locale == 'ar'
              ? 'جارٍ مزامنة تقدم الرحلة'
              : (l10n?.trackingSyncingPill ?? 'SYNCING');
          break;

        case TrackingPhase.waitingAssignment:
          bg = const Color(0xFFF1F5F9);
          dotColor = const Color(0xFF64748B);
          label = locale == 'ar'
              ? 'جارٍ تجهيز الرحلة'
              : (l10n?.trackingPendingPill ?? 'PENDING');
          break;

        case TrackingPhase.waitingStart:
          bg = const Color(0xFFEEF2FF);
          dotColor = const Color(0xFF4F46E5);
          label = locale == 'ar'
              ? 'الحافلة جاهزة'
              : (l10n?.trackingReadyPill ?? 'READY');
          break;

        case TrackingPhase.reassignmentPending:
          bg = const Color(0xFFFEF3C7);
          dotColor = const Color(0xFFD97706);
          label = locale == 'ar'
              ? 'جارٍ تحديث الحافلة'
              : (l10n?.trackingUpdatingPill ?? 'UPDATING');
          break;

        case TrackingPhase.completed:
          bg = const Color(0xFFF1F5F9);
          dotColor = const Color(0xFF64748B);
          label = locale == 'ar'
              ? 'انتهت الرحلة'
              : (l10n?.trackingCompletedPill ?? 'COMPLETED');
          break;

        case TrackingPhase.cancelled:
          bg = const Color(0xFFFEE2E2);
          dotColor = const Color(0xFFDC2626);
          label =
              l10n?.trackingCancelledPill ??
              (locale == 'ar' ? 'ملغية' : 'CANCELLED');
          break;

        case TrackingPhase.serviceDateEnded:
          bg = const Color(0xFFF1F5F9);
          dotColor = const Color(0xFF64748B);
          label =
              l10n?.trackingEndedPill ?? (locale == 'ar' ? 'منتهية' : 'ENDED');
          break;

        case TrackingPhase.mapDisabled:
        case TrackingPhase.busHidden:
          bg = const Color(0xFFF1F5F9);
          dotColor = const Color(0xFF64748B);
          label =
              l10n?.trackingUnavailablePill ??
              (locale == 'ar' ? 'غير متاح' : 'UNAVAILABLE');
          break;

        case TrackingPhase.unknown:
          switch (state.trackingStatus) {
            case LiveTrackingStatus.live:
            case LiveTrackingStatus.online:
              bg = const Color(0xFFE8F5E9);
              dotColor = const Color(0xFF16A34A);
              label = locale == 'ar' ? 'مباشر' : 'LIVE';
              break;

            case LiveTrackingStatus.stale:
              bg = const Color(0xFFFEF3C7);
              dotColor = const Color(0xFFD97706);
              label = locale == 'ar' ? 'مؤقتاً' : 'STALE';
              break;

            case LiveTrackingStatus.assignmentPending:
              bg = const Color(0xFFF1F5F9);
              dotColor = const Color(0xFF64748B);
              label = locale == 'ar' ? 'قيد التعيين' : 'PENDING';
              break;

            case LiveTrackingStatus.tripNotActive:
              bg = const Color(0xFFF1F5F9);
              dotColor = const Color(0xFF64748B);
              label = locale == 'ar' ? 'غير نشط' : 'INACTIVE';
              break;

            case LiveTrackingStatus.outsideTrackingWindow:
              bg = const Color(0xFFF1F5F9);
              dotColor = const Color(0xFF64748B);
              label = locale == 'ar' ? 'غير متاح' : 'OFFLINE';
              break;

            case LiveTrackingStatus.progressionUnavailable:
              bg = const Color(0xFFFEF3C7);
              dotColor = const Color(0xFFD97706);
              label = locale == 'ar' ? 'المحطات غير متاحة' : 'NO STOPS';
              break;

            case LiveTrackingStatus.betweenRuns:
              bg = const Color(0xFFEEF2FF);
              dotColor = const Color(0xFF4F46E5);
              label = locale == 'ar' ? 'بين الرحلات' : 'BETWEEN RUNS';
              break;

            case LiveTrackingStatus.qaPreview:
              bg = const Color(0xFFF3E8FF);
              dotColor = const Color(0xFF9333EA);
              label = locale == 'ar' ? 'معاينة تجريبية' : 'QA PREVIEW';
              break;

            case LiveTrackingStatus.offline:
              bg = const Color(0xFFF1F5F9);
              dotColor = const Color(0xFF64748B);
              label = locale == 'ar' ? 'غير متصل' : 'OFFLINE';
              break;
          }
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 126),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.radiusCircular,
          border: Border.all(color: dotColor.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            AppSpacing.gapW6,
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: dotColor,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopDetailCard({
    required BuildContext context,
    required BusStopModel stop,
    required String locale,
    required TrackingState trackingState,
  }) {
    final l10n = AppLocalizations.of(context);

    final hasVerifiedCoordinates = stop.hasCanonicalCoordinates;

    final isLast =
        stop.semanticState == TrackingStopSemanticState.active ||
        stop.id == trackingState.summary?.lastPassedStop?.id;

    final isNext =
        stop.semanticState == TrackingStopSemanticState.next ||
        stop.id == trackingState.nextStop?.id ||
        stop.id == trackingState.summary?.nextStopId;

    final isPassed = stop.semanticState == TrackingStopSemanticState.passed;

    final String roleBadgeText;
    final Color roleBadgeBg;
    final Color roleBadgeTextColor;

    if (!hasVerifiedCoordinates) {
      roleBadgeText = locale == 'ar' ? 'غير مؤكد' : 'UNVERIFIED';

      roleBadgeBg = const Color(0xFFF8FAFC);

      roleBadgeTextColor = const Color(0xFF64748B);
    } else if (isLast) {
      roleBadgeText = locale == 'ar' ? 'آخر محطة' : 'LAST';

      roleBadgeBg = AppColors.accentYellow.withValues(alpha: 0.25);

      roleBadgeTextColor = const Color(0xFFB45309);
    } else if (isNext) {
      roleBadgeText = locale == 'ar' ? 'المحطة التالية' : 'NEXT';

      roleBadgeBg = AppColors.primary.withValues(alpha: 0.12);

      roleBadgeTextColor = AppColors.primary;
    } else if (isPassed) {
      roleBadgeText = locale == 'ar' ? 'تم المرور' : 'PASSED';

      roleBadgeBg = AppColors.accentYellow.withValues(alpha: 0.25);

      roleBadgeTextColor = const Color(0xFFB45309);
    } else if (stop.semanticState == TrackingStopSemanticState.unknown) {
      roleBadgeText = locale == 'ar' ? 'غير معروف' : 'UNKNOWN';

      roleBadgeBg = const Color(0xFFF1F5F9);

      roleBadgeTextColor = const Color(0xFF64748B);
    } else {
      roleBadgeText = locale == 'ar' ? 'قادمة' : 'UPCOMING';

      roleBadgeBg = Colors.white;

      roleBadgeTextColor = const Color(0xFF334155);
    }

    final String timingLabel;
    final String timingValue;

    if (!hasVerifiedCoordinates) {
      timingLabel = locale == 'ar' ? 'حالة المحطة' : 'Status';

      timingValue =
          l10n?.trackingProgressUnavailable ??
          (locale == 'ar'
              ? 'تقدم المحطة غير متاح مؤقتًا'
              : 'Stop progress temporarily unavailable');
    } else if (isLast || isPassed) {
      if (stop.actualArrivalTime != null) {
        final clockStr = AppTimeFormatter.formatDepartureTime(
          departureAt: stop.actualArrivalTime!,
          locale: locale,
        );

        timingLabel = locale == 'ar' ? 'الحالة' : 'Status';

        timingValue =
            l10n?.trackingReached(clockStr) ??
            (locale == 'ar' ? 'وصل الساعة $clockStr' : 'Reached $clockStr');
      } else {
        timingLabel = locale == 'ar' ? 'الحالة' : 'Status';

        timingValue =
            l10n?.trackingUnavailable ??
            (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable');
      }
    } else if (isNext) {
      timingLabel = locale == 'ar' ? 'الوصول المتوقع' : 'Expected';

      timingValue =
          l10n?.trackingEtaUnavailable ??
          (locale == 'ar' ? 'وقت الوصول غير متاح' : 'ETA unavailable');
    } else {
      timingLabel = locale == 'ar' ? 'حالة المحطة' : 'Status';

      timingValue = stop.semanticState == TrackingStopSemanticState.unknown
          ? (l10n?.trackingProgressUnavailable ??
                (locale == 'ar'
                    ? 'تقدم المحطة غير متاح مؤقتًا'
                    : 'Stop progress temporarily unavailable'))
          : (locale == 'ar' ? 'محطة قادمة' : 'Upcoming stop');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleBadgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleBadgeText,
                  style: TextStyle(
                    color: roleBadgeTextColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${locale == 'ar' ? 'محطة' : 'Stop'} ${stop.stopOrder}',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              if (stop.farePoints > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    locale == 'ar'
                        ? '${stop.farePoints} نقطة'
                        : '${stop.farePoints} pts',
                    style: const TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              InkWell(
                onTap: () {
                  context.read<TrackingCubit>().selectStop(null);
                },
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            stop.localizedName(locale),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$timingLabel: ',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Expanded(
                  child: Text(
                    timingValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusDetailSheet({
    required BuildContext context,
    required TrackingState state,
    required String locale,
    required String directionLabel,
  }) {
    final summary = state.summary;
    final telemetry = state.latestTelemetry;
    final l10n = AppLocalizations.of(context);

    final currentStop = summary?.lastPassedStop;

    final isCurrentStopVerified = currentStop?.hasCanonicalCoordinates ?? false;

    final currentStopName =
        currentStop?.localizedName(locale) ??
        (l10n?.trackingUnavailable ??
            (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable'));

    final String currentReachedText;

    if (currentStop?.actualArrivalTime != null) {
      final clockStr = AppTimeFormatter.formatDepartureTime(
        departureAt: currentStop!.actualArrivalTime!,
        locale: locale,
      );

      currentReachedText =
          l10n?.trackingReached(clockStr) ??
          (locale == 'ar' ? 'وصل الساعة $clockStr' : 'Reached $clockStr');
    } else {
      currentReachedText =
          l10n?.trackingUnavailable ??
          (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable');
    }

    final nextStop = state.nextStop;

    final isNextStopVerified = nextStop?.hasCanonicalCoordinates ?? false;

    final nextStopName =
        nextStop?.localizedName(locale) ??
        (l10n?.trackingUnavailable ??
            (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable'));

    final nextEtaText =
        l10n?.trackingEtaUnavailable ??
        (locale == 'ar' ? 'وقت الوصول غير متاح' : 'ETA unavailable');

    final gpsRecordedAt = telemetry?.gpsRecordedAt;

    final String freshnessText;

    if (state.trackingPhase == TrackingPhase.live) {
      freshnessText = telemetry == null
          ? (l10n?.trackingUnavailable ??
                (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable'))
          : (l10n?.trackingLastUpdatedJustNow ??
                (locale == 'ar' ? 'تم التحديث الآن' : 'Updated just now'));
    } else if (state.trackingPhase == TrackingPhase.gpsStale) {
      if (gpsRecordedAt != null) {
        final diff = DateTime.now().difference(gpsRecordedAt);

        final seconds = diff.inSeconds < 0 ? 0 : diff.inSeconds;

        final minutes = seconds ~/ 60;

        if (minutes > 0) {
          freshnessText =
              l10n?.trackingLastUpdatedMinutes(minutes) ??
              (locale == 'ar'
                  ? 'آخر تحديث منذ $minutes د'
                  : 'Last updated ${minutes}m ago');
        } else {
          freshnessText =
              l10n?.trackingLastUpdatedSeconds(seconds) ??
              (locale == 'ar'
                  ? 'آخر تحديث منذ $seconds ث'
                  : 'Last updated ${seconds}s ago');
        }
      } else {
        freshnessText =
            l10n?.trackingDelayedPill ??
            (locale == 'ar' ? 'الموقع متأخر' : 'Location delayed');
      }
    } else if (state.trackingPhase == TrackingPhase.gpsOffline) {
      freshnessText =
          l10n?.trackingOffline ??
          (locale == 'ar' ? 'الموقع غير متاح' : 'Location unavailable');
    } else if (state.trackingPhase == TrackingPhase.progressionSyncing) {
      freshnessText =
          l10n?.trackingSyncingPill ??
          (locale == 'ar' ? 'جارٍ المزامنة' : 'Syncing progress');
    } else if (state.trackingPhase == TrackingPhase.waitingAssignment) {
      freshnessText =
          l10n?.trackingPendingPill ??
          (locale == 'ar' ? 'قيد التعيين' : 'Assignment pending');
    } else if (state.trackingPhase == TrackingPhase.waitingStart) {
      freshnessText =
          l10n?.trackingReadyPill ??
          (locale == 'ar' ? 'جاهز للبدء' : 'Ready for start');
    } else if (state.trackingPhase == TrackingPhase.reassignmentPending) {
      freshnessText =
          l10n?.trackingUpdatingPill ??
          (locale == 'ar' ? 'جارٍ تحديث الحافلة' : 'Updating bus');
    } else if (state.trackingPhase == TrackingPhase.completed) {
      freshnessText =
          l10n?.trackingCompletedPill ??
          (locale == 'ar' ? 'الرحلة مكتملة' : 'Trip completed');
    } else if (state.trackingPhase == TrackingPhase.cancelled) {
      freshnessText =
          l10n?.trackingCancelledPill ??
          (locale == 'ar' ? 'الرحلة ملغية' : 'Trip cancelled');
    } else {
      freshnessText =
          l10n?.trackingUnavailable ??
          (locale == 'ar' ? 'التتبع غير متاح' : 'Tracking unavailable');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    directionLabel,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildHeaderStatusPill(
                  context: context,
                  state: state,
                  locale: locale,
                  isAtStop: state.isAtStop,
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBusSheetOpen = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (state.isProgressionSyncing)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n?.trackingProgressionSyncing ??
                            (locale == 'ar'
                                ? 'جارٍ تحديث تقدم الرحلة…'
                                : 'Updating trip progress…'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStopSummaryBox(
                      title: locale == 'ar' ? 'المحطة السابقة' : 'Last Stop',
                      name: currentStopName,
                      subtitle: currentReachedText,
                      dotColor: isCurrentStopVerified
                          ? AppColors.accentYellow
                          : const Color(0xFFCBD5E1),
                      titleColor: const Color(0xFF64748B),
                      subtitleColor: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStopSummaryBox(
                      title: locale == 'ar' ? 'المحطة القادمة' : 'Next Stop',
                      name: nextStopName,
                      subtitle: nextEtaText,
                      dotColor: isNextStopVerified
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      titleColor: isNextStopVerified
                          ? AppColors.primary
                          : const Color(0xFF64748B),
                      subtitleColor: isNextStopVerified
                          ? AppColors.primaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Builder(
                  builder: (context) {
                    final safeBusName = _selectedFleetBus?.label.isNotEmpty == true
                        ? _selectedFleetBus!.label
                        : (state.visibleFleetBuses.isNotEmpty &&
                                state.visibleFleetBuses.first.label.isNotEmpty
                            ? state.visibleFleetBuses.first.label
                            : (locale == 'ar' ? 'أتوبيس عمومي' : 'AMOMY Bus'));

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_bus_rounded,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            safeBusName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          freshnessText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopSummaryBox({
    required String title,
    required String name,
    required String subtitle,
    required Color dotColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
