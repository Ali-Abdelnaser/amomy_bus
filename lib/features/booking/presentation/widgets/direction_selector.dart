import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/booking_entities.dart';

class DirectionSelector extends StatelessWidget {
  final BookingDirection selectedDirection;
  final ValueChanged<BookingDirection> onDirectionChanged;

  const DirectionSelector({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectDirection,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapH12,
        Row(
          children: [
            Expanded(
              child: _DirectionOptionCard(
                title: l10n.directionOutbound,
                subtitle: 'القاهرة → العاصمة',
                icon: AppIcons.arrowForward,
                isSelected: selectedDirection == BookingDirection.outbound,
                onTap: () => onDirectionChanged(BookingDirection.outbound),
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: _DirectionOptionCard(
                title: l10n.directionReturn,
                subtitle: 'العاصمة → القاهرة',
                icon: AppIcons.arrowBack,
                isSelected: selectedDirection == BookingDirection.returnTrip,
                onTap: () => onDirectionChanged(BookingDirection.returnTrip),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DirectionOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DirectionOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: AppSpacing.edgeInsetsA16,
      backgroundColor: isSelected ? AppColors.primaryLight : AppColors.surface,
      border: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 2.0 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              if (isSelected)
                const Icon(
                  AppIcons.check,
                  size: 20,
                  color: AppColors.primary,
                ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            subtitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
