import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/booking_entities.dart';

class BookingReviewCard extends StatelessWidget {
  final TripOption trip;
  final TripSeat seat;
  final double userAvailablePoints;
  final VoidCallback onConfirm;
  final bool isConfirming;

  const BookingReviewCard({
    super.key,
    required this.trip,
    required this.seat,
    required this.userAvailablePoints,
    required this.onConfirm,
    this.isConfirming = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final hasEnoughPoints = userAvailablePoints >= trip.farePoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reviewBooking,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapH16,

        AppCard(
          padding: AppSpacing.edgeInsetsA20,
          backgroundColor: AppColors.surface,
          border: const BorderSide(color: AppColors.border),
          child: Column(
            children: [
              // Route Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.originName(locale),
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'نقطة الانطلاق',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      AppIcons.arrowForward,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trip.destinationName(locale),
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'نقطة الوصول',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppColors.border),

              // Details Grid
              _DetailRow(
                icon: AppIcons.calendar,
                label: l10n.tripDetailsDate,
                value: "${trip.departureAt.year}-${trip.departureAt.month.toString().padLeft(2, '0')}-${trip.departureAt.day.toString().padLeft(2, '0')}",
              ),
              AppSpacing.gapH12,
              _DetailRow(
                icon: AppIcons.clock,
                label: l10n.tripDetailsTime,
                value: trip.departureTime,
              ),
              AppSpacing.gapH12,
              _DetailRow(
                icon: AppIcons.seat,
                label: l10n.tripDetailsSeat,
                value: seat.seatNumber,
              ),
              const Divider(height: 32, color: AppColors.border),

              // Fare and balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.tripDetailsFare,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${trip.farePoints.toInt()} ${l10n.pointsUnit}',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              AppSpacing.gapH8,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.pointsBalanceAvailable,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${userAvailablePoints.toInt()} ${l10n.pointsUnit}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: hasEnoughPoints ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        AppSpacing.gapH24,

        if (!hasEnoughPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.insufficientPointsNotice,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        AppButton(
          label: l10n.confirmBooking,
          icon: AppIcons.check,
          isLoading: isConfirming,
          onPressed: hasEnoughPoints && !isConfirming ? onConfirm : null,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        AppSpacing.gapW8,
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
