import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/home_summary.dart';

/// A cohesive, passenger-centric mobility analytics module on Home.
/// Features a hero insight banner, a refined compact completion ring,
/// and secondary insight chips (Completed, Missed, Avg / Trip) using only real backend data.
class HomeActivitySection extends StatefulWidget {
  final PassengerActivityMetrics activity;

  const HomeActivitySection({super.key, required this.activity});

  @override
  State<HomeActivitySection> createState() => _HomeActivitySectionState();
}

class _HomeActivitySectionState extends State<HomeActivitySection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _topFadeAnimation;
  late final Animation<double> _chartProgressAnimation;
  late final Animation<double> _bottomFadeAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _topFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _chartProgressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.9, curve: Curves.easeOutCubic),
    );

    _bottomFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = AppAnimations.reduceMotion(context);
    if (reduceMotion) {
      _controller.value = 1.0;
      _hasStarted = true;
    } else if (!_hasStarted) {
      _hasStarted = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final formatter = NumberFormat('#,###');

    final totalRecorded =
        widget.activity.completedTrips + widget.activity.missedTrips;
    final completionRatio = totalRecorded == 0
        ? 0.0
        : (widget.activity.completedTrips / totalRecorded).clamp(0.0, 1.0);
    final missedRatio = totalRecorded == 0
        ? 0.0
        : (widget.activity.missedTrips / totalRecorded).clamp(0.0, 1.0);

    // Derived average points per trip from genuine backend aggregates
    final avgPoints = widget.activity.completedTrips > 0
        ? (widget.activity.pointsSpentThisMonth /
                  widget.activity.completedTrips)
              .round()
        : (widget.activity.tripsThisMonth > 0
              ? (widget.activity.pointsSpentThisMonth /
                        widget.activity.tripsThisMonth)
                    .round()
              : 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Your Activity + "This Month" Tag Pill
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.yourActivity,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      AppIcons.calendar,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    AppSpacing.gapW4,
                    Text(
                      l10n.thisMonth,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,

          // 2. HERO INSIGHT BANNER: Large Trips + Supporting Points Spent
          AnimatedBuilder(
            animation: _topFadeAnimation,
            builder: (context, child) =>
                Opacity(opacity: _topFadeAnimation.value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2F8FD), Color(0xFFE8F3FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD0E6F6)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.bus,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            AppSpacing.gapW6,
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  '${formatter.format(widget.activity.tripsThisMonth)} ${isAr ? 'رحلات' : 'Trips'}',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.primaryDarker,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH4,
                        Text(
                          l10n.tripsThisMonth,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFCCE4F5),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.warningLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.ticket,
                                size: 13,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            AppSpacing.gapW6,
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  '${formatter.format(widget.activity.pointsSpentThisMonth)} ${l10n.pointsUnit}',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: const Color(0xFFB54708),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH4,
                        Text(
                          l10n.pointsSpentThisMonth,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH16,

          // 3. MAIN VISUALIZATION + SECONDARY INSIGHTS MODULE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 280;

                // Compact refined donut widget (102x102)
                final donutWidget = AnimatedBuilder(
                  animation: _chartProgressAnimation,
                  builder: (context, _) {
                    final progress = _chartProgressAnimation.value;
                    final displayPercent = totalRecorded == 0
                        ? 0
                        : (progress * (completionRatio * 100)).round();

                    return SizedBox.square(
                      dimension: 104,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            key: const Key('home-activity-completion-ring'),
                            size: const Size.square(104),
                            painter: _RefinedCompletionDonutPainter(
                              progress: progress,
                              completionRatio: completionRatio,
                              missedRatio: missedRatio,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayPercent%',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1.1,
                                ),
                              ),
                              AppSpacing.gapH2,
                              Text(
                                l10n.completionRate,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );

                // 3 Secondary insight chips
                final secondaryChips = AnimatedBuilder(
                  animation: _bottomFadeAnimation,
                  builder: (context, child) => Opacity(
                    opacity: _bottomFadeAnimation.value,
                    child: child,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InsightChipRow(
                        color: AppColors.success,
                        label: l10n.completedTrips,
                        value: formatter.format(widget.activity.completedTrips),
                      ),
                      AppSpacing.gapH6,
                      _InsightChipRow(
                        color: AppColors.error,
                        label: l10n.missedTrips,
                        value: formatter.format(widget.activity.missedTrips),
                      ),
                      AppSpacing.gapH6,
                      _InsightChipRow(
                        color: const Color(0xFFD97706),
                        label: isAr ? 'متوسط الرحلة' : 'Avg / Trip',
                        value: '$avgPoints ${l10n.pointsUnit}',
                      ),
                    ],
                  ),
                );

                if (!isWide) {
                  return Column(
                    children: [donutWidget, AppSpacing.gapH14, secondaryChips],
                  );
                }

                return Row(
                  children: [
                    donutWidget,
                    AppSpacing.gapW16,
                    Expanded(child: secondaryChips),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ).appSlideUp(delay: const Duration(milliseconds: 80));
  }
}

/// Compact insight row with semantic indicator, descriptive label, and bold value.
class _InsightChipRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _InsightChipRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppSpacing.gapW6,
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact, refined CustomPainter for the completion donut chart (strokeWidth: 9.5).
class _RefinedCompletionDonutPainter extends CustomPainter {
  final double progress;
  final double completionRatio;
  final double missedRatio;

  const _RefinedCompletionDonutPainter({
    required this.progress,
    required this.completionRatio,
    required this.missedRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const strokeWidth = 9.5;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2; // 12 o'clock
    const fullSweep = math.pi * 2;

    // Background track
    final trackPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final currentCompletedSweep = fullSweep * completionRatio * progress;
    final currentMissedSweep = fullSweep * missedRatio * progress;

    if (completionRatio > 0 && missedRatio == 0) {
      final completedPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        rect,
        startAngle,
        currentCompletedSweep,
        false,
        completedPaint,
      );
    } else if (missedRatio > 0 && completionRatio == 0) {
      final missedPaint = Paint()
        ..color = AppColors.error
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startAngle, currentMissedSweep, false, missedPaint);
    } else if (completionRatio > 0 && missedRatio > 0) {
      const gapAngle = 0.09;
      final effectiveCompletedSweep = math.max(
        0.0,
        currentCompletedSweep - (progress >= 1.0 ? gapAngle : 0.0),
      );
      final effectiveMissedSweep = math.max(
        0.0,
        currentMissedSweep - (progress >= 1.0 ? gapAngle : 0.0),
      );

      final completedPaint = Paint()
        ..color = AppColors.success
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        rect,
        startAngle,
        effectiveCompletedSweep,
        false,
        completedPaint,
      );

      final missedPaint = Paint()
        ..color = AppColors.error
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      final missedStartAngle =
          startAngle +
          currentCompletedSweep +
          (progress >= 1.0 ? gapAngle : 0.0);
      canvas.drawArc(
        rect,
        missedStartAngle,
        effectiveMissedSweep,
        false,
        missedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RefinedCompletionDonutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.completionRatio != completionRatio ||
      oldDelegate.missedRatio != missedRatio;
}
