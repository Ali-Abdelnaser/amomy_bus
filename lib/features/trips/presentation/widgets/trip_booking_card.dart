import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/status_localizer.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import 'qr_ticket_modal.dart';

class TripBookingCard extends StatelessWidget {
  final PassengerBooking booking;

  const TripBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isFinished =
        booking.checkedInAt != null ||
        booking.status.toLowerCase() == 'finished';
    final isUpcoming =
        !isFinished &&
        (booking.status == 'confirmed' || booking.status == 'active');

    return AppCard(
      padding: AppSpacing.edgeInsetsA16,
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
                      color: isUpcoming
                          ? AppColors.primaryLight
                          : AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AmomyBusIcon(
                        size: 16,
                        color: isUpcoming
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AppSpacing.gapW8,
                  Text(
                    '${booking.originName(locale)} ${context.isRtl ? '←' : '→'} ${booking.destinationName(locale)}',
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
                  color: isFinished
                      ? const Color(0xFFF1F5F9)
                      : isUpcoming
                      ? AppColors.successLight
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: isFinished
                      ? Border.all(color: const Color(0xFFE2E8F0))
                      : null,
                ),
                child: Text(
                  StatusLocalizer.localizeBookingStatus(
                    context,
                    isFinished ? 'finished' : booking.status,
                  ),
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFinished
                        ? const Color(0xFF64748B)
                        : isUpcoming
                        ? AppColors.success
                        : AppColors.textSecondary,
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
                value: DateFormat.yMMMd(locale).format(booking.serviceDate),
              ),
              _InfoBlock(
                icon: AppIcons.clock,
                label: l10n.tripDetailsTime,
                value: AppTimeFormatter.formatPassengerBooking(
                  booking,
                  locale: locale,
                ),
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showQrModal(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
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
                ),
                AppSpacing.gapW8,
                InkWell(
                  onTap: () => _showTrackingModal(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AmomyBusIcon(size: 16, color: AppColors.primary),
                        AppSpacing.gapW6,
                        Text(
                          'تتبع الحافلة',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTrackingModal(BuildContext context) {
    context.push(
      RoutePaths.liveTracking.replaceFirst(':tripId', booking.tripId),
    );
  }

  void _showQrModal(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    QrTicketModal.show(
      context,
      departureTime: AppTimeFormatter.formatPassengerBooking(
        booking,
        locale: locale,
      ),
      originName: booking.originName(locale),
      destinationName: booking.destinationName(locale),
      seatNumber: booking.seatNumber,
      farePoints: booking.farePoints,
      qrToken: booking.qrToken,
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
