import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/services/stop_eta_engine.dart';
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

    return BlocBuilder<TrackingCubit, TrackingState>(
      builder: (context, state) {
        final summary = state.summary;
        final trackingStatus = state.trackingStatus;
        final telemetry = state.latestTelemetry;
        final isOffline = state.isOffline;
        final isQaPreview = state.isQaPreview;

        final directionLabel =
            summary?.activeDirection == TrackingDirection.returnDirection
            ? (locale == 'ar' ? 'رحلة العودة' : 'Return Trip')
            : (locale == 'ar' ? 'رحلة الذهاب' : 'Outbound Trip');

        // Current / Last Stop Information
        final currentStop = state.currentStop;
        final currentTiming = state.currentStopTiming;

        final String currentStopLabel;
        final String currentStopName;
        final String currentStopTimingText;

        if (isOffline) {
          currentStopLabel = locale == 'ar' ? 'آخر محطة' : 'Last';
          currentStopName =
              currentStop?.localizedName(locale) ??
              (locale == 'ar' ? 'نهاية الخط' : 'Route Terminal');
          currentStopTimingText = '';
        } else if (state.isAtStop) {
          currentStopLabel = locale == 'ar' ? 'آخر محطة' : 'Last';
          currentStopName =
              currentStop?.localizedName(locale) ??
              (locale == 'ar' ? 'بالمحطة' : 'At Stop');
          if (currentTiming?.actualArrivalTime != null) {
            final clockStr = StopEtaEngine.formatClockTime(
              currentTiming!.actualArrivalTime!,
              locale,
            );
            currentStopTimingText = locale == 'ar'
                ? 'وصل الساعة $clockStr'
                : 'Arrived at $clockStr';
          } else {
            currentStopTimingText = locale == 'ar' ? 'صعود الركاب' : 'Boarding';
          }
        } else {
          currentStopLabel = locale == 'ar' ? 'آخر محطة' : 'Last';
          currentStopName =
              currentStop?.localizedName(locale) ??
              (locale == 'ar' ? 'جاري التحديد...' : 'Locating...');
          if (currentTiming?.actualArrivalTime != null) {
            final clockStr = StopEtaEngine.formatClockTime(
              currentTiming!.actualArrivalTime!,
              locale,
            );
            currentStopTimingText = locale == 'ar'
                ? 'وصل الساعة $clockStr'
                : 'Arrived at $clockStr';
          } else {
            currentStopTimingText = locale == 'ar'
                ? 'وقت الوصول غير متاح'
                : 'Arrival time unavailable';
          }
        }

        // Next Stop Information
        final nextStop = state.nextStop;
        final nextTiming = state.nextStopTiming;

        final String nextStopLabel;
        final String nextStopName;
        final String nextStopTimingText;

        if (isOffline) {
          nextStopLabel = locale == 'ar' ? 'المحطة التالية' : 'Next';
          nextStopName = summary?.nextWindowStartTime != null
              ? (locale == 'ar'
                    ? 'الساعة ${summary!.nextWindowStartTime}'
                    : summary!.nextWindowStartTime!)
              : (locale == 'ar' ? '08:00 صباحاً' : '08:00 AM');
          nextStopTimingText = '';
        } else {
          nextStopLabel = locale == 'ar' ? 'المحطة التالية' : 'Next';
          nextStopName =
              nextStop?.localizedName(locale) ??
              (locale == 'ar' ? 'جاري التحديد...' : 'Locating...');
          if (nextTiming?.estimatedArrivalTime != null &&
              (!nextStop!.isTemporaryQa || isQaPreview)) {
            final remainingStr = StopEtaEngine.formatRemainingMinutes(
              nextTiming!.estimatedArrivalTime!,
              locale,
            );
            nextStopTimingText = remainingStr;
          } else if (nextStop?.isTemporaryQa == true && !isQaPreview) {
            nextStopTimingText = locale == 'ar'
                ? 'قيد التدقيق'
                : 'Pending verification';
          } else {
            nextStopTimingText = locale == 'ar' ? 'قيد الحساب' : 'Estimating';
          }
        }

        // Last updated subtitle
        final String lastUpdatedText;
        if (isQaPreview) {
          lastUpdatedText = locale == 'ar'
              ? 'معاينة تجريبية مباشرة لمسار الحافلة'
              : 'Live QA route simulation preview';
        } else if (isOffline) {
          lastUpdatedText = locale == 'ar'
              ? 'الخدمة متوقفة حالياً'
              : 'Service currently inactive';
        } else if (telemetry != null) {
          final age = telemetry.ageSeconds;
          if (age < 30) {
            lastUpdatedText = locale == 'ar'
                ? 'تم التحديث الآن'
                : 'Updated just now';
          } else if (age < 120) {
            lastUpdatedText = locale == 'ar'
                ? 'آخر تحديث منذ $age ثانية'
                : 'Updated $age seconds ago';
          } else {
            final mins = (age / 60).floor();
            lastUpdatedText = locale == 'ar'
                ? 'آخر تحديث منذ $mins دقيقة'
                : 'Last updated $mins min ago';
          }
        } else {
          lastUpdatedText = locale == 'ar'
              ? 'في انتظار الإشارة'
              : 'Waiting for signal';
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
                              if (kDebugMode &&
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

                              // Offline subtle frosted bottom bar
                              if (isOffline)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            summary?.localizedNextWindowMessage(
                                                  locale,
                                                ) ??
                                                (locale == 'ar'
                                                    ? 'يستأنف التتبع الساعة 08:00 صباحاً'
                                                    : 'Tracking resumes at 08:00 AM'),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                          color: isQaPreview
                                              ? const Color(0xFF818CF8)
                                              : AppColors.accentYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentStopLabel,
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
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
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        nextStopLabel,
                                        style: AppTextStyles.caption.copyWith(
                                          fontSize: 11,
                                          color: AppColors.primaryDark,
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
                                        color: AppColors.primary,
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
                            isQaPreview
                                ? Icons.auto_awesome_rounded
                                : Icons.sync_rounded,
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
                        onTap: () {
                          if (onViewMapTap != null) {
                            onViewMapTap!();
                          } else {
                            context.push(
                              RoutePaths.liveTracking.replaceFirst(
                                ':tripId',
                                'active',
                              ),
                            );
                          }
                        },
                        borderRadius: AppRadius.radiusMd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppRadius.radiusMd,
                            boxShadow: [
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
                              const Icon(
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                locale == 'ar'
                                    ? 'عرض الخريطة الحية'
                                    : 'View Live Map',
                                style: AppTextStyles.buttonMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
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
        case LiveTrackingStatus.online:
          bg = const Color(0xFFE8F5E9);
          dotColor = const Color(0xFF16A34A);
          label = locale == 'ar' ? 'مباشر' : 'LIVE';
          break;
        case LiveTrackingStatus.stale:
          bg = const Color(0xFFFEF3C7);
          dotColor = const Color(0xFFD97706);
          label = locale == 'ar' ? 'إشارة ضعيفة' : 'RECONNECTING';
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
