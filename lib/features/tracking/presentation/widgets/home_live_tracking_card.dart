import 'package:amomy_bus/core/localization/app_time_formatter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/live_tracking_status.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import 'live_bus_map_widget.dart';

/// AMOMY Home Live Tracking Card (Phase T2 — Staff-Started Trip Tracking).
///
/// Features:
/// - Lifecycle-driven: Opens live tracking ONLY after Staff starts trip.
/// - Pre-trip calm cards for confirmed booking (waiting_assignment, waiting_start).
/// - Graceful handling of reassignment_pending, gps_stale, gps_offline, progression_syncing.
/// - Hidden automatically when no booking exists or trip is completed/cancelled.
/// - No clock-based window restrictions (08:00/13:00 gating removed).
class HomeLiveTrackingCard extends StatelessWidget {
  static const bool debugDisableHomeMap = false;

  final VoidCallback? onViewMapTap;

  const HomeLiveTrackingCard({super.key, this.onViewMapTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = context.l10n;

    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        final summary = state.summary;
        if (summary == null) {
          if (state.isLoading) {
            return _buildSkeletonCard();
          }
          return const SizedBox.shrink();
        }

        final phase = state.trackingPhase;
        final isAr = locale.startsWith('ar');

        final directionLabel =
            summary.activeDirection == TrackingDirection.returnDirection
            ? (isAr ? 'رحلة العودة' : 'Return Trip')
            : (isAr ? 'رحلة الذهاب' : 'Outbound Trip');

        // Post-trip and terminal states remain visible as persistent calm cards
        if (phase == TrackingPhase.completed ||
            summary.tripStatus == 'completed') {
          return _buildPreTripCard(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF64748B),
            title: isAr ? 'انتهت الرحلة' : 'Trip Completed',
            subtitle: isAr
                ? 'وصلت الحافلة إلى المحطة الأخيرة.'
                : 'The bus has arrived at the final stop.',
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(
              TrackingPhase.completed,
              state.trackingStatus,
              context,
            ),
          );
        }

        if (phase == TrackingPhase.cancelled ||
            summary.tripStatus == 'cancelled') {
          return _buildPreTripCard(
            context: context,
            icon: Icons.cancel_outlined,
            iconColor: AppColors.error,
            title: isAr ? 'تم إلغاء الرحلة' : 'Trip Cancelled',
            subtitle: isAr
                ? 'تم إلغاء تشغيل هذه الرحلة.'
                : 'This trip was cancelled.',
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(
              TrackingPhase.cancelled,
              state.trackingStatus,
              context,
            ),
          );
        }

        if (phase == TrackingPhase.serviceDateEnded) {
          return _buildPreTripCard(
            context: context,
            icon: Icons.event_busy_outlined,
            iconColor: const Color(0xFF64748B),
            title: isAr ? 'انتهى موعد الرحلة' : 'Service Day Concluded',
            subtitle: isAr
                ? 'انتهى وقت تشغيل هذه الرحلة لليوم.'
                : 'Trip service hours for today have ended.',
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(
              TrackingPhase.serviceDateEnded,
              state.trackingStatus,
              context,
            ),
          );
        }

        final isTripDeparted =
            summary.tripStatus == 'departed' ||
            summary.startedAt != null ||
            summary.trackingEnabled ||
            state.isDeparted;

        // B. Confirmed booking + waiting_assignment (pre-trip only)
        if (!isTripDeparted &&
            (phase == TrackingPhase.waitingAssignment ||
                (phase == TrackingPhase.unknown &&
                    state.trackingStatus ==
                        LiveTrackingStatus.assignmentPending))) {
          return _buildPreTripCard(
            context: context,
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.primary,
            title: isAr ? 'جارٍ تجهيز الرحلة' : l10n.trackingConfirmedTitle,
            subtitle: isAr
                ? 'سيظهر موقع الحافلة بعد تجهيز الرحلة.'
                : l10n.trackingWaitingAssignmentSubtitle,
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(phase, state.trackingStatus, context),
          );
        }

        // C. Confirmed booking + waiting_start (bus assigned, waiting for start - pre-trip only)
        if (!isTripDeparted && phase == TrackingPhase.waitingStart) {
          return _buildPreTripCard(
            context: context,
            icon: Icons.directions_bus_filled_outlined,
            iconColor: AppColors.primary,
            title: isAr ? 'الحافلة جاهزة' : l10n.trackingReadyTitle,
            subtitle: isAr
                ? 'يبدأ التتبع المباشر عند بدء الرحلة.'
                : l10n.trackingWaitingStartSubtitle,
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(phase, state.trackingStatus, context),
          );
        }

        // D. Reassignment pending (assignment released mid-trip, waiting for replacement)
        if (phase == TrackingPhase.reassignmentPending) {
          return _buildPreTripCard(
            context: context,
            icon: Icons.sync_rounded,
            iconColor: const Color(0xFFD97706),
            title: isAr ? 'جارٍ تحديث الحافلة' : l10n.trackingUpdatingBusTitle,
            subtitle: isAr
                ? 'سيتم استئناف التتبع تلقائيًا.'
                : l10n.trackingReassignmentPendingSubtitle,
            directionLabel: directionLabel,
            statusPill: _buildStatusPill(phase, state.trackingStatus, context),
          );
        }

        // Operational states: live, gps_stale, gps_offline, progression_syncing
        return _buildActiveTrackingCard(
          context: context,
          state: state,
          summary: summary,
          directionLabel: directionLabel,
          locale: locale,
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.md,
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }

  /// Calm state card for pre-trip and reassignment states (no map, no bus marker, no error styling)
  Widget _buildPreTripCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String directionLabel,
    required Widget statusPill,
  }) {
    final locale = Localizations.localeOf(context).languageCode;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.radiusXl,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale == 'ar' ? 'تتبع الحافلة' : 'Bus Tracking',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            height: 1.35,
                          ),
                        ),
                        AppSpacing.gapH2,
                        Text(
                          directionLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapW10,
                  statusPill,
                ],
              ),
            ),

            // Content Container
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: AppRadius.radiusLg,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrackingCard({
    required BuildContext context,
    required TrackingState state,
    required dynamic summary,
    required String directionLabel,
    required String locale,
  }) {
    final l10n = context.l10n;
    final phase = state.trackingPhase;
    final telemetry = state.latestTelemetry;
    final trackingStatus = state.trackingStatus;

    final isGpsOffline = phase == TrackingPhase.gpsOffline;
    final isGpsStale = phase == TrackingPhase.gpsStale || state.isStale;
    final isProgressionSyncing = phase == TrackingPhase.progressionSyncing;

    final isLiveMapAvailable =
        (state.isLive || isGpsStale || isGpsOffline || isProgressionSyncing);
    final isActionDisabled = !isLiveMapAvailable;

    final lastStop = summary?.lastPassedStop;
    final nextStop = state.nextStop;
    final isLastStopVerified = lastStop?.hasCanonicalCoordinates ?? false;
    final isNextStopVerified = nextStop?.hasCanonicalCoordinates ?? false;

    final currentStopLabel = l10n.trackingLastStop;
    final currentStopName =
        lastStop?.localizedName(locale) ??
        (isProgressionSyncing
            ? l10n.trackingProgressionSyncing
            : l10n.trackingUnavailable);
    final actualArrival = lastStop?.actualArrivalTime;
    final currentStopTimingText = actualArrival == null
        ? ''
        : l10n.trackingReached(
            AppTimeFormatter.formatDepartureTime(
              departureAt: actualArrival,
              locale: locale,
            ),
          );

    final nextStopLabel = l10n.trackingNextStop;
    final nextStopName =
        nextStop?.localizedName(locale) ??
        (isProgressionSyncing
            ? l10n.trackingProgressionSyncing
            : l10n.trackingUnavailable);
    final nextStopTimingText = l10n.trackingEtaUnavailable;

    final isTripDeparted =
        summary.tripStatus == 'departed' ||
        summary.startedAt != null ||
        summary.trackingEnabled == true ||
        state.isDeparted;

    // Subtitle text for status
    final String lastUpdatedText;
    if (isGpsStale) {
      final relative = _formatRelativeTime(
        context,
        telemetry?.ageSeconds ?? 90,
        locale,
      );
      final warning = locale == 'ar'
          ? 'تحديث موقع الحافلة متأخر'
          : l10n.trackingGpsStaleTitle;
      lastUpdatedText = '$warning · $relative';
    } else if (isGpsOffline) {
      lastUpdatedText = locale == 'ar'
          ? 'موقع الحافلة غير متاح مؤقتًا'
          : (isTripDeparted
                ? 'Bus location currently unavailable'
                : l10n.trackingGpsOfflineTitle);
    } else if (isProgressionSyncing) {
      lastUpdatedText = locale == 'ar'
          ? 'جارٍ مزامنة تقدم الرحلة'
          : l10n.trackingProgressionSyncing;
    } else if (state.isLive && telemetry != null) {
      lastUpdatedText = locale == 'ar'
          ? 'تتبع مباشر'
          : _formatRelativeTime(context, telemetry.ageSeconds, locale);
    } else if (!isTripDeparted &&
        (state.trackingStatus == LiveTrackingStatus.offline ||
            summary.status == LiveTrackingStatus.offline ||
            summary.isInServiceWindow == false)) {
      lastUpdatedText = summary.nextWindowIsTomorrow == true
          ? l10n.trackingResumesTomorrow
          : (summary.nextWindowStartTime == '13:00'
                ? l10n.trackingResumesMidday
                : summary.localizedNextWindowMessage(locale));
    } else {
      lastUpdatedText = l10n.trackingLive;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final mapHeight = isNarrow ? 204.0 : 220.0;

        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.radiusXl,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: AppShadows.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    isNarrow ? AppSpacing.s12 : 14,
                    AppSpacing.s16,
                    AppSpacing.s12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTripDeparted
                                  ? (locale == 'ar'
                                        ? 'بدأت الرحلة'
                                        : 'Trip Started')
                                  : (locale == 'ar'
                                        ? 'تتبع الحافلة'
                                        : 'Bus Tracking'),
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.35,
                              ),
                            ),
                            AppSpacing.gapH2,
                            Text(
                              '$directionLabel · $lastUpdatedText',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isGpsStale
                                    ? const Color(0xFFD97706)
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapW10,
                      _buildStatusPill(
                        phase,
                        trackingStatus,
                        context,
                        isAtStop: state.isAtStop,
                      ),
                    ],
                  ),
                ),

                // 2. Interactive Mini Map Preview
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    height: mapHeight,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusLg,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.radiusLg,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (kDebugMode &&
                              defaultTargetPlatform == TargetPlatform.iOS &&
                              debugDisableHomeMap) ...[
                            Container(
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.center,
                              child: Text(
                                locale == 'ar'
                                    ? 'تم تعطيل الخريطة للاختبار التشخيصي'
                                    : 'Map disabled for diagnostic test',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else ...[
                            LiveBusMapWidget(
                              telemetry: isGpsOffline ? null : telemetry,
                              routeStops: summary.routeStops,
                              status: isGpsOffline
                                  ? LiveTrackingStatus.offline
                                  : isGpsStale
                                  ? LiveTrackingStatus.stale
                                  : trackingStatus,
                              isCompactPreview: true,
                              followBus: !isGpsOffline,
                              routeGeometry: state.routeGeometry,
                            ),
                          ],
                          if ((isGpsOffline && telemetry == null) ||
                              (!isTripDeparted &&
                                  (state.trackingStatus ==
                                          LiveTrackingStatus.offline ||
                                      summary.status ==
                                          LiveTrackingStatus.offline ||
                                      summary.isInServiceWindow == false))) ...[
                            Container(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: AppRadius.radiusLg,
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0F172A,
                                        ).withValues(alpha: 0.08),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_off_rounded,
                                        size: 24,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        isGpsOffline
                                            ? l10n.trackingGpsOfflineTitle
                                            : (isTripDeparted
                                                  ? (locale == 'ar'
                                                        ? 'بدأت الرحلة، لكن موقع الحافلة غير متاح حاليًا'
                                                        : 'Trip started, but bus location is unavailable')
                                                  : l10n.trackingUnavailable),
                                        style: AppTextStyles.titleSmall
                                            .copyWith(
                                              color: const Color(0xFF1E293B),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isGpsOffline
                                            ? l10n.trackingGpsOfflineSubtitle
                                            : (isTripDeparted
                                                  ? (locale == 'ar'
                                                        ? 'جاري محاولة استعادة الاتصال بموقع الحافلة...'
                                                        : 'Attempting to reconnect bus location...')
                                                  : (summary.nextWindowIsTomorrow ==
                                                            true
                                                        ? l10n.trackingResumesTomorrow
                                                        : (summary.nextWindowStartTime ==
                                                                  '13:00'
                                                              ? l10n.trackingResumesMidday
                                                              : summary
                                                                    .localizedNextWindowMessage(
                                                                      locale,
                                                                    )))),
                                        style: AppTextStyles.caption.copyWith(
                                          color: const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (isGpsStale) ...[
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFEF3C7,
                                  ).withValues(alpha: 0.92),
                                  borderRadius: AppRadius.radiusMd,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 14,
                                      color: Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        l10n.trackingLastKnownLocation,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: const Color(0xFF92400E),
                                              fontWeight: FontWeight.w700,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                AppSpacing.gapH12,

                // 3. Last Stop & Next Stop Information Cells
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // Last Stop Cell
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isLastStopVerified
                                          ? AppColors.accentYellow
                                          : const Color(0xFFCBD5E1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentStopLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: isLastStopVerified
                                          ? AppColors.textSecondary
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapH4,
                              Text(
                                currentStopName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                              if (currentStopTimingText.isNotEmpty) ...[
                                AppSpacing.gapH2,
                                Text(
                                  currentStopTimingText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Next Stop Cell
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: AppRadius.radiusMd,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isNextStopVerified
                                          ? AppColors.primary
                                          : const Color(0xFFCBD5E1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    nextStopLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11,
                                      color: isNextStopVerified
                                          ? AppColors.primaryDark
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              AppSpacing.gapH4,
                              Text(
                                nextStopName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                              if (nextStopTimingText.isNotEmpty) ...[
                                AppSpacing.gapH2,
                                Text(
                                  nextStopTimingText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isNextStopVerified
                                        ? AppColors.primary
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapH10,

                // 4. Action Button: View Live Map
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: InkWell(
                    onTap: isActionDisabled || onViewMapTap == null
                        ? null
                        : () {
                            onViewMapTap!();
                          },
                    borderRadius: AppRadius.radiusMd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: isActionDisabled
                            ? const Color(0xFFE2E8F0)
                            : AppColors.primary,
                        borderRadius: AppRadius.radiusMd,
                        boxShadow: isActionDisabled
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: isActionDisabled
                                ? const Color(0xFF94A3B8)
                                : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.viewLiveMap,
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: isActionDisabled
                                  ? const Color(0xFF94A3B8)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: isActionDisabled
                                ? const Color(0xFF94A3B8)
                                : Colors.white,
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRelativeTime(
    BuildContext context,
    int ageSeconds,
    String locale,
  ) {
    final l10n = context.l10n;
    if (ageSeconds < 30) {
      return l10n.trackingLastUpdatedJustNow;
    }
    if (ageSeconds < 120) {
      return l10n.trackingLastUpdatedSeconds(ageSeconds);
    }
    final mins = (ageSeconds / 60).floor();
    return l10n.trackingLastUpdatedMinutes(mins);
  }

  Widget _buildStatusPill(
    TrackingPhase phase,
    LiveTrackingStatus status,
    BuildContext context, {
    bool isAtStop = false,
  }) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final Color bg;
    final Color dotColor;
    final isAr = locale.startsWith('ar');
    final String label;

    if (isAtStop &&
        (phase == TrackingPhase.live || status == LiveTrackingStatus.live)) {
      bg = const Color(0xFFE0F2FE);
      dotColor = const Color(0xFF0284C7);
      label = isAr ? 'بالمحطة' : 'AT STOP';
    } else if (phase == TrackingPhase.waitingAssignment ||
        status == LiveTrackingStatus.assignmentPending) {
      bg = const Color(0xFFF1F5F9);
      dotColor = const Color(0xFF64748B);
      label = isAr ? 'جارٍ تجهيز الرحلة' : l10n.trackingPendingPill;
    } else if (phase == TrackingPhase.waitingStart) {
      bg = const Color(0xFFEFF6FF);
      dotColor = AppColors.primary;
      label = isAr ? 'الحافلة جاهزة' : l10n.trackingReadyPill;
    } else if (phase == TrackingPhase.reassignmentPending) {
      bg = const Color(0xFFFEF3C7);
      dotColor = const Color(0xFFD97706);
      label = isAr ? 'جارٍ تحديث الحافلة' : l10n.trackingUpdatingPill;
    } else if (phase == TrackingPhase.gpsStale ||
        status == LiveTrackingStatus.stale) {
      bg = const Color(0xFFFEF3C7);
      dotColor = const Color(0xFFD97706);
      label = isAr ? 'تحديث موقع الحافلة متأخر' : l10n.trackingDelayedPill;
    } else if (phase == TrackingPhase.gpsOffline ||
        status == LiveTrackingStatus.offline) {
      bg = const Color(0xFFF1F5F9);
      dotColor = const Color(0xFF64748B);
      label = isAr ? 'موقع الحافلة غير متاح مؤقتًا' : l10n.trackingOffline;
    } else if (phase == TrackingPhase.progressionSyncing ||
        status == LiveTrackingStatus.progressionUnavailable) {
      bg = const Color(0xFFFEF3C7);
      dotColor = const Color(0xFFD97706);
      label = isAr ? 'جارٍ مزامنة تقدم الرحلة' : l10n.trackingSyncingPill;
    } else if (phase == TrackingPhase.completed) {
      bg = const Color(0xFFF1F5F9);
      dotColor = const Color(0xFF64748B);
      label = isAr ? 'انتهت الرحلة' : l10n.trackingCompletedPill;
    } else if (phase == TrackingPhase.cancelled) {
      bg = const Color(0xFFFEE2E2);
      dotColor = const Color(0xFFDC2626);
      label = isAr ? 'تم إلغاء الرحلة' : l10n.trackingCancelledPill;
    } else if (phase == TrackingPhase.serviceDateEnded) {
      bg = const Color(0xFFF1F5F9);
      dotColor = const Color(0xFF64748B);
      label = isAr ? 'انتهى موعد الرحلة' : l10n.trackingEndedPill;
    } else if (phase == TrackingPhase.live ||
        status == LiveTrackingStatus.live ||
        status == LiveTrackingStatus.online) {
      bg = const Color(0xFFE8F5E9);
      dotColor = const Color(0xFF16A34A);
      label = isAr ? 'تتبع مباشر' : l10n.trackingLive;
    } else {
      bg = const Color(0xFFF1F5F9);
      dotColor = const Color(0xFF64748B);
      label = l10n.trackingOffline;
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
}
