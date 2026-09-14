import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/bus_stop_model.dart';
import '../../domain/models/live_tracking_status.dart';
import '../../domain/services/stop_eta_engine.dart';
import '../cubit/tracking_cubit.dart';
import '../cubit/tracking_state.dart';
import '../widgets/live_bus_map_widget.dart';

/// AMOMY Live Map Screen (Phase 5).
/// Truly map-first: edge-to-edge behind the status bar, floating top surface,
/// hidden bottom sheet by default, tap-to-inspect bus detail sheet, tap-to-inspect
/// stop card with actual/estimated timings, and a smart center-on-bus button
/// that automatically moves upward above any active sheet.
class LiveMapScreen extends StatefulWidget {
  final TrackingCubit? trackingCubit;

  const LiveMapScreen({super.key, this.trackingCubit});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  bool _isBusSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

    final scaffold = Scaffold(
      extendBodyBehindAppBar: true,
      body: BlocConsumer<TrackingCubit, TrackingState>(
        listener: (context, state) {
          if (state.isError && state.summary == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ??
                      l10n?.errorOccurred ??
                      'An error occurred',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final summary = state.summary;
          final trackingStatus = state.trackingStatus;
          final selectedStop = state.selectedStop;
          final telemetry = state.latestTelemetry;

          final directionLabel =
              summary?.activeDirection == TrackingDirection.returnDirection
              ? (locale == 'ar' ? 'رحلة العودة' : 'Return Trip')
              : (locale == 'ar' ? 'رحلة الذهاب' : 'Outbound Trip');

          // Dynamic bottom offset for the Center-on-Bus button so it is NEVER hidden
          final double centerButtonBottom;
          if (_isBusSheetOpen) {
            centerButtonBottom = 265.0;
          } else if (selectedStop != null) {
            centerButtonBottom = 200.0;
          } else {
            centerButtonBottom = 28.0;
          }

          return Stack(
            children: [
              // 1. Primary Full-Screen Map (Edge-to-Edge behind status bar)
              Positioned.fill(
                child: LiveBusMapWidget(
                  telemetry: telemetry,
                  routeStops: summary?.routeStops ?? const [],
                  status: trackingStatus,
                  selectedStop: selectedStop,
                  isCompactPreview: false,
                  followBus: state.followBus,
                  routeGeometry: state.routeGeometry,
                  onPanStart: () {
                    if (state.followBus) {
                      context.read<TrackingCubit>().toggleFollowBus(false);
                    }
                  },
                  onBusTap: () {
                    setState(() {
                      _isBusSheetOpen = true;
                    });
                    context.read<TrackingCubit>().selectStop(null);
                  },
                  onStopTap: (stop) {
                    setState(() {
                      _isBusSheetOpen = false;
                    });
                    context.read<TrackingCubit>().selectStop(stop);
                  },
                ),
              ),

              // 2. Top Floating Navigation Header (Inside SafeArea)
              Positioned(
                top: 0,
                left: 0,
                right: 0,

                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildTopFloatingHeader(
                      context: context,
                      directionLabel: directionLabel,
                      status: trackingStatus,
                      isAtStop: state.isAtStop,
                      locale: locale,
                    ),
                  ),
                ),
              ),

              // 3. Center-on-Bus / Follow Bus Button (Smoothly animated above any sheet)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: centerButtonBottom,
                child: Material(
                  color: state.followBus ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(state.followBus ? 28 : 20),
                  elevation: 5,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(state.followBus ? 28 : 20),
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
                                ? (locale == 'ar' ? 'تتبع مفعل' : 'Following')
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

              // 4. Compact Stop Detail Floating Card (Visible only when a stop is tapped)
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
                    timing: state.stopTimings[selectedStop.id],
                    locale: locale,
                    isQaPreview: state.isQaPreview,
                    trackingState: state,
                  ),
                ),

              // 5. Bus Detail Bottom Sheet (Visible ONLY when Bus Marker is tapped)
              if (_isBusSheetOpen)
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

    if (widget.trackingCubit != null) {
      return BlocProvider.value(value: widget.trackingCubit!, child: scaffold);
    }

    return BlocProvider(
      create: (context) =>
          (getIt.isRegistered<TrackingCubit>()
                ? getIt<TrackingCubit>()
                : TrackingCubit(repository: getIt()))
            ..loadTrackingData(),
      child: scaffold,
    );
  }

  /// One premium floating white surface with blur/elevation, back button, title, and status pill.
  Widget _buildTopFloatingHeader({
    required BuildContext context,
    required String directionLabel,
    required LiveTrackingStatus status,
    required String locale,
    bool isAtStop = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: const Color(0xFFF8FAFC),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 20,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & direction
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locale == 'ar' ? 'الحافلة المباشرة' : 'Live Bus',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  directionLabel,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status Pill
          _buildHeaderStatusPill(status, locale, isAtStop: isAtStop),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusPill(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dotColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: dotColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Stop Detail Card (Sections 9 & 11)
  Widget _buildStopDetailCard({
    required BuildContext context,
    required BusStopModel stop,
    required StopTimingInfo? timing,
    required String locale,
    required bool isQaPreview,
    required TrackingState trackingState,
  }) {
    final telemetry = trackingState.latestTelemetry;
    final currentStopId = telemetry?.currentStopId ?? trackingState.summary?.currentStopId;
    final nextStopId = telemetry?.nextStopId ?? trackingState.summary?.nextStopId;
    final currentStopOrder = telemetry?.currentStopOrder ?? trackingState.currentStop?.stopOrder;

    final isLast = (currentStopId != null && stop.id == currentStopId) ||
        (timing?.isCurrent ?? false);
    final isNext = (nextStopId != null && stop.id == nextStopId) ||
        (timing?.isNext ?? false);
    final isPassed = !isLast && !isNext &&
        ((currentStopOrder != null && stop.stopOrder < currentStopOrder) ||
            (timing?.isPassed ?? false));

    final String roleBadgeText;
    final Color roleBadgeBg;
    final Color roleBadgeTextColor;

    if (isLast) {
      roleBadgeText = locale == 'ar' ? 'آخر محطة' : 'LAST';
      roleBadgeBg = AppColors.accentYellow.withValues(alpha: 0.25);
      roleBadgeTextColor = const Color(0xFFB45309);
    } else if (isNext) {
      roleBadgeText = locale == 'ar' ? 'المحطة التالية' : 'NEXT';
      roleBadgeBg = AppColors.primary.withValues(alpha: 0.12);
      roleBadgeTextColor = AppColors.primary;
    } else if (isPassed) {
      roleBadgeText = locale == 'ar' ? 'تم المرور' : 'PASSED';
      roleBadgeBg = const Color(0xFFF1F5F9);
      roleBadgeTextColor = const Color(0xFF64748B);
    } else {
      roleBadgeText = locale == 'ar' ? 'قادمة' : 'UPCOMING';
      roleBadgeBg = const Color(0xFFF1F5F9);
      roleBadgeTextColor = const Color(0xFF334155);
    }

    // Determine Timing description text
    final String timingLabel;
    final String timingValue;

    if (stop.stopOrder == 1 && timing?.scheduledDepartureTime != null && !isPassed && !isLast) {
      timingLabel = locale == 'ar'
          ? 'موعد الانطلاق'
          : 'Departure';
      timingValue = timing!.scheduledDepartureTime!;
    } else if (isLast || isPassed) {
      if (timing?.actualArrivalTime != null) {
        final clockStr = StopEtaEngine.formatClockTime(
          timing!.actualArrivalTime!,
          locale,
        );
        timingLabel = locale == 'ar' ? 'الحالة' : 'Status';
        timingValue = locale == 'ar' ? 'وصل الساعة $clockStr' : 'Arrived at $clockStr';
      } else {
        timingLabel = locale == 'ar' ? 'الحالة' : 'Status';
        timingValue = locale == 'ar' ? 'وقت الوصول غير متاح' : 'Arrival time unavailable';
      }
    } else if (isNext) {
      if (timing?.estimatedArrivalTime != null && (!stop.isTemporaryQa || isQaPreview)) {
        final clockStr = StopEtaEngine.formatClockTime(
          timing!.estimatedArrivalTime!,
          locale,
        );
        final countStr = StopEtaEngine.formatRemainingMinutes(
          timing.estimatedArrivalTime!,
          locale,
        );
        timingLabel = locale == 'ar' ? 'الوصول المتوقع' : 'Expected';
        timingValue = '$clockStr ($countStr)';
      } else if (stop.isTemporaryQa && !isQaPreview) {
        timingLabel = locale == 'ar' ? 'حالة المحطة' : 'Status';
        timingValue = locale == 'ar'
            ? 'قيد التدقيق (QA)'
            : 'Pending verification';
      } else {
        timingLabel = locale == 'ar' ? 'الوصول المتوقع' : 'Expected';
        timingValue = locale == 'ar' ? 'قيد الحساب...' : 'Calculating...';
      }
    } else {
      // Future Stop
      if (timing?.estimatedArrivalTime != null && (!stop.isTemporaryQa || isQaPreview)) {
        final clockStr = StopEtaEngine.formatClockTime(
          timing!.estimatedArrivalTime!,
          locale,
        );
        timingLabel = locale == 'ar' ? 'الوصول المتوقع' : 'Expected';
        timingValue = clockStr;
      } else if (stop.isTemporaryQa && !isQaPreview) {
        timingLabel = locale == 'ar' ? 'حالة المحطة' : 'Status';
        timingValue = locale == 'ar'
            ? 'قيد التدقيق (QA)'
            : 'Pending verification';
      } else {
        timingLabel = locale == 'ar' ? 'حالة المحطة' : 'Status';
        timingValue = locale == 'ar' ? 'محطة قادمة' : 'Upcoming stop';
      }
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
          // Header line: Role badge + Stop Order pill + Fare badge + Close button
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  padding: EdgeInsets.all(4.0),
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

          // Stop name and locality
          Text(
            stop.localizedName(locale),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          if (stop.localizedLocality(locale).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              stop.localizedLocality(locale),
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Expected / actual arrival line
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

  /// Compact Bus Detail Sheet (Sections 5 & 6)
  /// Visible ONLY when the bus marker is tapped.
  Widget _buildBusDetailSheet({
    required BuildContext context,
    required TrackingState state,
    required String locale,
    required String directionLabel,
  }) {
    final summary = state.summary;
    final telemetry = state.latestTelemetry;
    final isOffline = state.isOffline;
    final isBetweenRuns = state.isBetweenRuns;

    // Current / Last Stop logic
    final currentStop = state.currentStop;
    final currentTiming = state.currentStopTiming;
    final currentStopName =
        currentStop?.localizedName(locale) ??
        (isOffline
            ? (locale == 'ar' ? 'نهاية الخط' : 'Route Terminal')
            : (locale == 'ar' ? 'جاري التحديد...' : 'Locating...'));

    final String currentReachedText;
    if (currentTiming?.actualArrivalTime != null) {
      final clockStr = StopEtaEngine.formatClockTime(
        currentTiming!.actualArrivalTime!,
        locale,
      );
      currentReachedText = locale == 'ar'
          ? 'وصل الساعة $clockStr'
          : 'Arrived at $clockStr';
    } else if (isOffline) {
      currentReachedText = locale == 'ar' ? 'آخر موقع مسجل' : 'Last recorded';
    } else {
      currentReachedText = locale == 'ar' ? 'وقت الوصول غير متاح' : 'Arrival time unavailable';
    }

    // Next Stop logic
    final nextStop = state.nextStop;
    final nextTiming = state.nextStopTiming;
    final nextStopName =
        nextStop?.localizedName(locale) ??
        (isOffline
            ? (summary?.nextWindowStartTime != null
                  ? (locale == 'ar'
                        ? 'الساعة ${summary!.nextWindowStartTime}'
                        : summary!.nextWindowStartTime!)
                  : (locale == 'ar' ? '08:00 صباحاً' : '08:00 AM'))
            : (locale == 'ar' ? 'جاري التحديد...' : 'Locating...'));

    final String nextEtaText;
    if (nextTiming?.estimatedArrivalTime != null && !isOffline) {
      final remainingStr = StopEtaEngine.formatRemainingMinutes(
        nextTiming!.estimatedArrivalTime!,
        locale,
      );
      nextEtaText = remainingStr;
    } else if (isOffline) {
      nextEtaText = locale == 'ar' ? 'استئناف الخدمة' : 'Service resumes';
    } else if (isBetweenRuns) {
      nextEtaText = locale == 'ar' ? 'الرحلة التالية' : 'Next Run';
    } else {
      nextEtaText = locale == 'ar' ? 'قيد التقدير' : 'Estimating';
    }

    // Speed display
    final speedValue = telemetry != null && telemetry.speedKmh > 0
        ? '${telemetry.speedKmh.toStringAsFixed(0)} ${locale == 'ar' ? 'كم/س' : 'km/h'}'
        : '0 ${locale == 'ar' ? 'كم/س' : 'km/h'}';

    // Freshness text
    final String freshnessText;
    if (telemetry != null) {
      final age = telemetry.ageSeconds;
      if (age < 30) {
        freshnessText = locale == 'ar' ? 'منذ لحظات' : 'Just now';
      } else if (age < 120) {
        freshnessText = locale == 'ar' ? 'منذ $age ث' : '$age sec ago';
      } else {
        final m = (age / 60).floor();
        freshnessText = locale == 'ar' ? 'منذ $m د' : '$m min ago';
      }
    } else {
      freshnessText = locale == 'ar' ? 'غير متصل' : 'Offline';
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
            // Drag handle pill
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

            // Top Header Line: Direction Badge + Status + Close Button
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
                _buildHeaderStatusPill(state.trackingStatus, locale,
                    isAtStop: state.isAtStop),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isBusSheetOpen = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
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

            // Current / Last Stop & Next Stop Cards
            Row(
              children: [
                // Last Stop
                Expanded(
                  child: Container(
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
                              decoration: const BoxDecoration(
                                color: AppColors.accentYellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale == 'ar' ? 'المحطة السابقة' : 'Last Stop',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStopName,
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
                          currentReachedText,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Next Stop
                Expanded(
                  child: Container(
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
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locale == 'ar' ? 'المحطة القادمة' : 'Next Stop',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nextStopName,
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
                          nextEtaText,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Telemetry stats row: Speed + Last Updated
            Row(
              children: [
                Container(
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
                        Icons.speed_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${locale == 'ar' ? 'السرعة: ' : 'Speed: '}$speedValue',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${locale == 'ar' ? 'آخر تحديث: ' : 'Updated: '}$freshnessText',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
