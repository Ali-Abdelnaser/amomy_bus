import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/live_tracking_status.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import 'live_bus_map_widget.dart';

/// Redesigned Home Live Tracking Card (Phase 5).
/// Features a spacious interactive mini-map (225px) centered around the bus and nearby stops,
/// rich authoritative Last Stop (actual reached time) and Next Stop (estimated arrival ETA),
/// robust offline behavior without fake progression, and clean Impeccable styling.
class HomeLiveTrackingCard extends StatelessWidget {
  /// TEMPORARY DIAGNOSTIC SWITCH FOR IOS CRASH INVESTIGATION (TEST C)
  /// Set to true to isolate Google Maps / native map preview on iOS completely.
  /// When true on iOS DEBUG:
  /// - GoogleMap widget is NEVER constructed
  /// - Native map platform view / controller is NEVER initialized
  /// - Replaced with a clean static placeholder Container
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
        final trackingStatus = state.trackingStatus;
        final telemetry = state.latestTelemetry;
        final isLiveMapAvailable =
            (state.isLive || state.isProgressionUnavailable) &&
            telemetry?.hasValidCoordinates == true;
        final isActionDisabled = !state.isLive;

        final directionLabel =
            summary?.activeDirection == TrackingDirection.returnDirection
            ? (locale == 'ar' ? 'رحلة العودة' : 'Return Trip')
            : (locale == 'ar' ? 'رحلة الذهاب' : 'Outbound Trip');

        final lastStop = summary?.lastPassedStop;
        final nextStop = state.nextStop;
        final isLastStopVerified = lastStop?.hasCanonicalCoordinates ?? false;
        final isNextStopVerified = nextStop?.hasCanonicalCoordinates ?? false;
        final currentStopLabel = l10n.trackingLastStop;
        final currentStopName =
            lastStop?.localizedName(locale) ?? l10n.trackingUnavailable;
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
            nextStop?.localizedName(locale) ?? l10n.trackingUnavailable;
        final nextStopTimingText = l10n.trackingEtaUnavailable;

        // Last updated subtitle
        final String lastUpdatedText = switch (trackingStatus) {
          LiveTrackingStatus.live || LiveTrackingStatus.online =>
            telemetry != null
                ? (() {
                    final age = telemetry.ageSeconds;
                    if (age < 30) {
                      return locale == 'ar'
                          ? 'تم التحديث الآن'
                          : 'Updated just now';
                    }
                    if (age < 120) {
                      return locale == 'ar'
                          ? 'آخر تحديث منذ $age ثانية'
                          : 'Updated $age seconds ago';
                    }
                    final mins = (age / 60).floor();
                    return locale == 'ar'
                        ? 'آخر تحديث منذ $mins دقيقة'
                        : 'Last updated $mins min ago';
                  })()
                : l10n.trackingUnavailable,
          LiveTrackingStatus.assignmentPending =>
            l10n.trackingAssignmentPending,
          LiveTrackingStatus.stale => l10n.trackingLocationUnavailable,
          LiveTrackingStatus.progressionUnavailable =>
            l10n.trackingProgressUnavailable,
          LiveTrackingStatus.tripNotActive => l10n.trackingTripNotActive,
          LiveTrackingStatus.outsideTrackingWindow ||
          LiveTrackingStatus.offline => l10n.trackingOffline,
          LiveTrackingStatus.betweenRuns => l10n.trackingUnavailable,
          LiveTrackingStatus.qaPreview => l10n.trackingUnavailable,
        };

        final String offlineResumeText;
        if (summary?.nextWindowIsTomorrow == true) {
          offlineResumeText = l10n.trackingResumesTomorrow;
        } else if (summary?.nextWindowStartTime == '13:00' ||
            summary?.serviceWindow == 'afternoon') {
          offlineResumeText = l10n.trackingResumesMidday;
        } else if (summary?.localizedNextWindowMessage(locale) != null &&
            summary!.localizedNextWindowMessage(locale).isNotEmpty) {
          offlineResumeText = summary.localizedNextWindowMessage(locale);
        } else {
          offlineResumeText = locale == 'ar'
              ? 'يستأنف التتبع الساعة 8:00 ص'
              : 'Tracking resumes at 8:00 AM';
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
                    // 1. Header: Bus Icon, Title, Direction & Status Pill
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
                                  locale == 'ar'
                                      ? 'تتبع الحافلة'
                                      : 'Bus Tracking',
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
                                    color: AppColors.textSecondary,
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
                          // Status Pill
                          _buildStatusPill(
                            trackingStatus,
                            locale,
                            isAtStop: state.isAtStop,
                            offlineLabel: l10n.trackingOffline,
                          ),
                        ],
                      ),
                    ),

                    // 2. Large Interactive Mini Map Preview (Height: 225px, Rounded: 18px)
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
                            children: [
                              if (!isLiveMapAvailable) ...[
                                Container(
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE2E8F0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.location_off_rounded,
                                          size: 22,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        lastUpdatedText,
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              color: const Color(0xFF334155),
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                              fontSize: 14,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trackingStatus ==
                                                    LiveTrackingStatus
                                                        .outsideTrackingWindow ||
                                                trackingStatus ==
                                                    LiveTrackingStatus.offline
                                            ? offlineResumeText
                                            : l10n.trackingUnavailable,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: const Color(0xFF64748B),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (kDebugMode &&
                                  defaultTargetPlatform == TargetPlatform.iOS &&
                                  debugDisableHomeMap) ...[
                                Container(
                                  color: const Color(0xFFF1F5F9),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.map_outlined,
                                        size: 32,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        locale == 'ar'
                                            ? 'تم تعطيل الخريطة للاختبار التشخيصي'
                                            : 'Map disabled for diagnostic test',
                                        style: AppTextStyles.caption.copyWith(
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                LiveBusMapWidget(
                                  telemetry: telemetry,
                                  routeStops: summary?.routeStops ?? const [],
                                  status: trackingStatus,
                                  isCompactPreview: true,
                                  followBus: true,
                                  routeGeometry: state.routeGeometry,
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
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                        color: Color(0xFF64748B),
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
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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

                    AppSpacing.gapH8,

                    // 4. Last updated subtitle line
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_rounded,
                            size: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              lastUpdatedText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.gapH10,

                    // 5. Action Button: View Live Map
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
                                locale == 'ar'
                                    ? Icons.arrow_back_ios_rounded
                                    : Icons.arrow_forward_ios_rounded,
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
      },
    );
  }

  Widget _buildStatusPill(
    LiveTrackingStatus status,
    String locale, {
    bool isAtStop = false,
    required String offlineLabel,
  }) {
    final Color bg;
    final Color dotColor;
    final String label;

    if (isAtStop && status != LiveTrackingStatus.offline) {
      bg = const Color(0xFFE0F2FE);
      dotColor = const Color(0xFF0284C7);
      label = locale == 'ar' ? 'بالمحطة' : 'AT STOP';
    } else {
      switch (status) {
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
          label = offlineLabel;
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
          label = offlineLabel;
          break;
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
}
