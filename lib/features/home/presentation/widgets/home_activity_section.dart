import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../domain/entities/home_summary.dart';

/// Data analytics activity widget with a circular progress indicator
/// and structured transit performance metrics.
class HomeActivitySection extends StatelessWidget {
  final PassengerActivityMetrics activity;

  const HomeActivitySection({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatter = NumberFormat('#,###');

    // Calculate completion rate
    final totalTrips = activity.completedTrips + activity.missedTrips;
    final double completionRatio = totalTrips > 0
        ? (activity.completedTrips / totalTrips).clamp(0.0, 1.0)
        : (activity.tripsThisMonth > 0 ? 1.0 : 1.0);
    final int completionPercentage = (completionRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Title & Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.yourActivity,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.clock,
                    size: 11,
                    color: AppColors.primary,
                  ),
                  AppSpacing.gapW4,
                  Text(
                    l10n.thisMonth,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        AppSpacing.gapH12,

        // Unified Analytics Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Circular Data Indicator
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background track
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        // Foreground animated arc
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: completionRatio,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        // Center Stat
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$completionPercentage%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryDarker,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              l10n.completedTrips,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapW16,

                  // Vertical subtle separator
                  Container(
                    width: 1,
                    height: 84,
                    color: AppColors.borderSubtle,
                  ),
                  AppSpacing.gapW16,

                  // 2. Analytical Breakdown Metrics
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MetricRow(
                          iconWidget: const AmomyBusIcon(
                            size: 12,
                            color: AppColors.primary,
                          ),
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          label: l10n.tripsThisMonth,
                          value: formatter.format(activity.tripsThisMonth),
                        ),
                        const Divider(height: 12, color: AppColors.borderSubtle),
                        _MetricRow(
                          icon: AppIcons.ticket,
                          iconBg: AppColors.primaryLight,
                          iconColor: AppColors.primary,
                          label: l10n.pointsSpentThisMonth,
                          value: formatter.format(activity.pointsSpentThisMonth),
                        ),
                        const Divider(height: 12, color: AppColors.borderSubtle),
                        _MetricRow(
                          icon: activity.missedTrips > 0
                              ? AppIcons.clock
                              : AppIcons.checkCircle,
                          iconBg: activity.missedTrips > 0
                              ? AppColors.errorLight
                              : AppColors.successLight,
                          iconColor: activity.missedTrips > 0
                              ? AppColors.error
                              : AppColors.success,
                          label: l10n.missedTrips,
                          value: formatter.format(activity.missedTrips),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Positive feedback banner if no missed trips
              if (activity.missedTrips == 0) ...[
                AppSpacing.gapH14,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.checkCircle,
                        size: 15,
                        color: AppColors.success,
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          l10n.noMissedTripsMessage,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricRow({
    this.icon,
    this.iconWidget,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon,
                      size: 12,
                      color: iconColor,
                    ),
              ),
            ),
            AppSpacing.gapW8,
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
