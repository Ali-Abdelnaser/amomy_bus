import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';

class TripBookingCard extends StatelessWidget {
  final PassengerBooking booking;

  const TripBookingCard({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isUpcoming = booking.isUpcoming;

    return AppCard(
      padding: AppSpacing.edgeInsetsA16,
      backgroundColor: Colors.white,
      border: const BorderSide(color: AppColors.border),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Direction + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isUpcoming ? AppColors.primaryLight : AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppIcons.bus,
                      size: 16,
                      color: isUpcoming ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.gapW8,
                  Text(
                    '${booking.originName(locale)} → ${booking.destinationName(locale)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUpcoming ? AppColors.successLight : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUpcoming ? l10n.bookingStatusConfirmed : 'منتهية',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUpcoming ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoBlock(
                icon: AppIcons.calendar,
                label: l10n.tripDetailsDate,
                value: "${booking.serviceDate.year}-${booking.serviceDate.month.toString().padLeft(2, '0')}-${booking.serviceDate.day.toString().padLeft(2, '0')}",
              ),
              _InfoBlock(
                icon: AppIcons.clock,
                label: l10n.tripDetailsTime,
                value: booking.departureTime,
              ),
              _InfoBlock(
                icon: AppIcons.seat,
                label: l10n.tripDetailsSeat,
                value: booking.seatNumber,
              ),
            ],
          ),

          if (isUpcoming) ...[
            AppSpacing.gapH16,
            InkWell(
              onTap: () => _showQrModal(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.qrCode,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    AppSpacing.gapW8,
                    Text(
                      'عرض رمز الصعود (QR)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppSpacing.gapH20,
                Text(
                  'تذكرة الصعود للحافلة',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapH16,
                AppQrTicketWidget(
                  data: booking.qrToken,
                  size: 200,
                ),
                AppSpacing.gapH12,
                Text(
                  'المقعد: ${booking.seatNumber} | الموعد: ${booking.departureTime}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AppSpacing.gapH20,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            AppSpacing.gapW4,
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        AppSpacing.gapH4,
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
