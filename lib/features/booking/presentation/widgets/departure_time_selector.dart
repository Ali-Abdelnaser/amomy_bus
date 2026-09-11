import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/booking_entities.dart';

class DepartureTimeSelector extends StatelessWidget {
  final List<TripOption> trips;
  final TripOption? selectedTrip;
  final ValueChanged<TripOption> onTripSelected;

  const DepartureTimeSelector({
    super.key,
    required this.trips,
    required this.selectedTrip,
    required this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectTime,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapH12,
        if (trips.isEmpty)
          Container(
            padding: AppSpacing.edgeInsetsA20,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                l10n.noData,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trips.length,
            separatorBuilder: (_, _) => AppSpacing.gapH12,
            itemBuilder: (context, index) {
              final trip = trips[index];
              final isSelected = selectedTrip?.tripId == trip.tripId;
              final hasSeats = trip.availableSeatsCount > 0;

              return AppCard(
                onTap: hasSeats ? () => onTripSelected(trip) : null,
                padding: AppSpacing.edgeInsetsA16,
                backgroundColor: isSelected ? AppColors.primaryLight : AppColors.surface,
                border: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
                child: Row(
                  children: [
                    // Time Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.clock,
                            size: 16,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          AppSpacing.gapW8,
                          Text(
                            trip.departureTime,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapW16,

                    // Available seats info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSeats
                                ? l10n.seatsAvailableCount(trip.availableSeatsCount)
                                : 'مكتمل الحجز',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: hasSeats ? AppColors.textPrimary : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          AppSpacing.gapH4,
                          Row(
                            children: [
                              Text(
                                '${trip.farePoints.toInt()}',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSpacing.gapW4,
                              Text(
                                l10n.pointsUnit,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Selection indicator / arrow
                    if (hasSeats)
                      Icon(
                        isSelected ? AppIcons.check : AppIcons.arrowForward,
                        color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        size: 20,
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
