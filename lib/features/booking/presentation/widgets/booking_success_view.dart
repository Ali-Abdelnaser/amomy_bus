import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../trips/presentation/widgets/qr_ticket_modal.dart';
import '../../domain/entities/booking_entities.dart';
import 'app_qr_ticket_widget.dart';

/// Clean digital boarding pass shown after a successful booking confirmation.
class BookingSuccessView extends StatelessWidget {
  final PassengerBooking booking;

  const BookingSuccessView({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s16,
          AppSpacing.s20,
          math.max(AppSpacing.s24, bottomInset + AppSpacing.s16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ConfirmationHeader(isAr: isAr),
            AppSpacing.gapH20,
            _TripSummaryCard(booking: booking, isAr: isAr),
            AppSpacing.gapH16,
            _QrBoardingCard(booking: booking, isAr: isAr),
            AppSpacing.gapH20,
            _SuccessActions(isAr: isAr),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationHeader extends StatelessWidget {
  final bool isAr;

  const _ConfirmationHeader({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: const Icon(AppIcons.check, color: AppColors.success, size: 30),
        ),
        AppSpacing.gapH12,
        Text(
          isAr ? 'تم تأكيد الحجز' : 'Booking Confirmed',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.gapH4,
        Text(
          isAr
              ? 'تم حجز مقعدك بنجاح.'
              : 'Your seat has been successfully reserved.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final PassengerBooking booking;
  final bool isAr;

  const _TripSummaryCard({required this.booking, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final direction = booking.direction == BookingDirection.outbound
        ? (isAr ? 'رحلة الذهاب' : 'Outbound Trip')
        : (isAr ? 'رحلة العودة' : 'Return Trip');
    final origin = booking.stopName ?? booking.originName(locale);
    final destination = booking.destinationName(locale);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      AppIcons.bus,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    AppSpacing.gapW8,
                    Expanded(
                      child: Text(
                        direction,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  booking.departureTime,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          _RouteLine(
            from: origin,
            locality: booking.locality,
            to: destination,
            isAr: isAr,
          ),
          AppSpacing.gapH16,
          _DetailsGrid(booking: booking, isAr: isAr),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String from;
  final String? locality;
  final String to;
  final bool isAr;

  const _RouteLine({
    required this.from,
    required this.locality,
    required this.to,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _RouteDot(
              icon: AppIcons.location,
              color: AppColors.primary,
              backgroundColor: AppColors.primaryLight,
            ),
            Container(
              width: 2,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            _RouteDot(
              icon: AppIcons.location,
              color: const Color(0xFFD49B00),
              backgroundColor: AppColors.warningLight,
            ),
          ],
        ),
        AppSpacing.gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RouteStop(
                label: isAr ? 'من' : 'From',
                name: from,
                supportingText: locality,
              ),
              AppSpacing.gapH16,
              _RouteStop(label: isAr ? 'إلى' : 'To', name: to),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteDot extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _RouteDot({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _RouteStop extends StatelessWidget {
  final String label;
  final String name;
  final String? supportingText;

  const _RouteStop({
    required this.label,
    required this.name,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    final hasSupportingText =
        supportingText != null && supportingText!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        AppSpacing.gapH2,
        Text(
          name,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasSupportingText) ...[
          AppSpacing.gapH2,
          Text(
            supportingText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final PassengerBooking booking;
  final bool isAr;

  const _DetailsGrid({required this.booking, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final details = [
      _DetailItemData(
        icon: AppIcons.calendar,
        label: isAr ? 'التاريخ' : 'Date',
        value: _formatDate(booking.serviceDate),
      ),
      _DetailItemData(
        icon: AppIcons.seat,
        label: isAr ? 'المقعد' : 'Seat',
        value: booking.seatNumber,
        highlight: true,
      ),
      _DetailItemData(
        icon: AppIcons.ticket,
        label: isAr ? 'الأجرة' : 'Fare',
        value: '${booking.farePoints.toInt()} ${l10n.pointsUnit}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 320;
        return Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final detail in details)
              SizedBox(
                width: useTwoColumns
                    ? (constraints.maxWidth - AppSpacing.s8) / 2
                    : constraints.maxWidth,
                child: _DetailItem(data: detail),
              ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${enMonths[(date.month - 1).clamp(0, 11)]}';
  }
}

class _DetailItemData {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _DetailItemData({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });
}

class _DetailItem extends StatelessWidget {
  final _DetailItemData data;

  const _DetailItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.highlight ? AppColors.primary : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: data.highlight ? AppColors.primaryLight : AppColors.surfaceSoft,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        children: [
          Icon(
            data.icon,
            size: 18,
            color: data.highlight ? AppColors.primary : AppColors.textSecondary,
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AppSpacing.gapH2,
                Text(
                  data.value,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrBoardingCard extends StatelessWidget {
  final PassengerBooking booking;
  final bool isAr;

  const _QrBoardingCard({required this.booking, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final origin = booking.stopName ?? booking.originName(locale);
    final destination = booking.destinationName(locale);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(AppIcons.qrCode, size: 20, color: AppColors.primary),
              AppSpacing.gapW8,
              Expanded(
                child: Text(
                  isAr ? 'امسح للصعود' : 'Scan to board',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH14,
          LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = constraints.maxWidth.clamp(132.0, 172.0);
              return InkWell(
                borderRadius: AppRadius.radiusLg,
                onTap: () {
                  QrTicketModal.show(
                    context,
                    departureTime: booking.departureTime,
                    originName: origin,
                    destinationName: destination,
                    seatNumber: booking.seatNumber,
                    farePoints: booking.farePoints,
                    qrToken: booking.qrToken,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.radiusLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: AppQrTicketWidget(data: booking.qrToken, size: qrSize),
                ),
              );
            },
          ),
          AppSpacing.gapH12,
          Text(
            isAr ? 'مقعد ${booking.seatNumber}' : 'Seat ${booking.seatNumber}',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapH6,
          Text(
            isAr
                ? 'استخدم بطاقة NFC أو رمز QR عند الصعود.'
                : 'Use your NFC card or this QR code when boarding.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SuccessActions extends StatelessWidget {
  final bool isAr;

  const _SuccessActions({required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: context.l10n.viewMyTrips,
            icon: const Icon(AppIcons.bus, size: 18, color: Colors.white),
            height: 48,
            isFullWidth: true,
            onPressed: () => context.go('/trips'),
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: AppButton(
            label: isAr ? 'العودة للرئيسية' : 'Back to Home',
            icon: const Icon(AppIcons.home, size: 18),
            variant: ButtonVariant.outline,
            height: 48,
            isFullWidth: true,
            onPressed: () => context.go('/home'),
          ),
        ),
      ],
    );
  }
}
