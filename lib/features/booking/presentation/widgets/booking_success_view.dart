import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/booking_entities.dart';
import 'app_qr_ticket_widget.dart';

class BookingSuccessView extends StatelessWidget {
  final PassengerBooking booking;

  const BookingSuccessView({
    super.key,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;

    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsA20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Success badge icon
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.check,
                size: 38,
                color: AppColors.success,
              ),
            ),
          ),
          AppSpacing.gapH16,

          // 2. Title & Subtitle
          Text(
            l10n.bookingSuccessTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH8,
          Text(
            l10n.bookingSuccessSubtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH24,

          // 3. QR Ticket Card
          AppCard(
            padding: AppSpacing.edgeInsetsA20,
            backgroundColor: Colors.white,
            border: const BorderSide(color: AppColors.border),
            child: Column(
              children: [
                // Direction / Route
                Text(
                  '${booking.originName(locale)} → ${booking.destinationName(locale)}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                AppSpacing.gapH12,

                // QR Code
                Center(
                  child: AppQrTicketWidget(
                    data: booking.qrToken,
                    size: 180,
                  ),
                ),
                AppSpacing.gapH12,
                Text(
                  l10n.qrTicketInstruction,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 28, color: AppColors.border),

                // Trip metadata row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetaColumn(
                      label: l10n.tripDetailsTime,
                      value: booking.departureTime,
                    ),
                    _MetaColumn(
                      label: l10n.tripDetailsSeat,
                      value: booking.seatNumber,
                    ),
                    _MetaColumn(
                      label: l10n.tripDetailsFare,
                      value: '${booking.farePoints.toInt()} ${l10n.pointsUnit}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.gapH24,

          // 4. Action Buttons
          AppButton(
            label: l10n.viewMyTrips,
            icon: AppIcons.ticket,
            onPressed: () => context.go('/trips'),
          ),
          AppSpacing.gapH12,
          AppButton(
            label: l10n.navHome,
            icon: AppIcons.home,
            variant: AppButtonVariant.outline,
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _MetaColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapH4,
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
