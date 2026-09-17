import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/localization/status_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_floating_alert.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../cubit/passenger_trips_cubit.dart';

/// Compact overflow action button (⋮) for booked Today ticket.
///
/// Tapping it opens a bottom sheet offering:
/// - Change Seat (interactive seat map within cutoff window)
/// - Cancel Booking (atomic point refund to original batch)
///
/// If within 30 minutes of departure, options are cleanly disabled with an explanation.
class BookedTripOverflowMenu extends StatelessWidget {
  final PassengerTodayTrip trip;

  const BookedTripOverflowMenu({super.key, required this.trip});

  bool get _isCutoff {
    final cutoffTime = trip.departureAt.subtract(const Duration(minutes: 30));
    return DateTime.now().isAfter(cutoffTime);
  }

  void _showActionSheet(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final cubit = context.read<PassengerTripsCubit>();
    final isCutoff = _isCutoff;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0D5DD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Trip Summary Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.success,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'رحلة ${AppTimeFormatter.formatPassengerTodayTrip(trip, isArabic: true)} — مقعد (${trip.seatNumber ?? "—"})'
                                  : '${AppTimeFormatter.formatPassengerTodayTrip(trip, isArabic: false)} Trip — Seat (${trip.seatNumber ?? "—"})',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF101828),
                                fontSize: 16,
                              ),
                            ),
                            AppSpacing.gapH2,
                            Text(
                              '${trip.originName(Localizations.localeOf(context).languageCode)} ← ${trip.destinationName(Localizations.localeOf(context).languageCode)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFF667085),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.gapH16,

                  // Cutoff Warning Banner if past T-30 minutes
                  if (isCutoff) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF6E7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF79009).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_off_outlined,
                            color: Color(0xFFB54708),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'تم إغلاق التعديل والإلغاء (يغلق قبل 30 دقيقة من موعد الرحلة)'
                                  : 'Modifications and cancellation closed (30 mins before departure)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFFB54708),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapH12,
                  ],

                  // 1. CHANGE SEAT ACTION
                  _ActionTile(
                    icon: Icons.event_seat_outlined,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: isAr ? 'تغيير المقعد' : 'Change Seat',
                    subtitle: isCutoff
                        ? (isAr
                              ? 'غير متاح بعد موعد الإغلاق'
                              : 'Unavailable after cutoff')
                        : (isAr
                              ? 'اختر مقعدًا آخر متاحًا على نفس الحافلة'
                              : 'Choose another available seat on this bus'),
                    enabled: !isCutoff,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.push(
                        RoutePaths.changeSeat,
                        extra: {'trip': trip, 'tripsCubit': cubit},
                      );
                    },
                  ),

                  AppSpacing.gapH8,

                  // 2. CANCEL BOOKING ACTION
                  _ActionTile(
                    icon: Icons.cancel_outlined,
                    iconColor: AppColors.error,
                    iconBg: AppColors.errorLight,
                    title: isAr ? 'إلغاء الحجز' : 'Cancel Booking',
                    subtitle: isCutoff
                        ? (isAr
                              ? 'غير متاح بعد موعد الإغلاق'
                              : 'Unavailable after cutoff')
                        : (isAr
                              ? 'استرداد ${trip.farePoints.toInt()} نقطة إلى محفظتك'
                              : 'Refund ${trip.farePoints.toInt()} points to your wallet'),
                    enabled: !isCutoff,
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _confirmCancellation(context, cubit, isAr);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmCancellation(
    BuildContext context,
    PassengerTripsCubit cubit,
    bool isAr,
  ) {
    showConfirmDialog(
      context: context,
      title: isAr ? 'تأكيد إلغاء الحجز' : 'Confirm Cancellation',
      message: isAr
          ? 'هل أنت متأكد من رغبتك في إلغاء حجز المقعد (${trip.seatNumber ?? "—"}) لرحلة الساعة ${AppTimeFormatter.formatPassengerTodayTrip(trip, isArabic: true)}؟\n\nسيتم استرداد ${trip.farePoints.toInt()} نقطة بالكامل إلى محفظتك.'
          : 'Are you sure you want to cancel Seat (${trip.seatNumber ?? "—"}) for the ${AppTimeFormatter.formatPassengerTodayTrip(trip, isArabic: false)} trip?\n\n${trip.farePoints.toInt()} points will be fully refunded to your wallet.',
      cancelText: isAr ? 'الاحتفاظ بالحجز' : 'Keep Booking',
      confirmText: isAr ? 'إلغاء الحجز' : 'Cancel Booking',
      isDestructive: true,
      variant: AppDialogVariant.destructive,
      onConfirm: () async {
        if (trip.bookingId == null) return;

        final success = await cubit.cancelBooking(trip.bookingId!);
        if (!context.mounted) return;

        if (success) {
          AmomyFloatingAlert.show(
            context,
            title: isAr
                ? 'تم إلغاء الحجز واسترداد ${trip.farePoints.toInt()} نقطة بنجاح'
                : 'Booking cancelled and ${trip.farePoints.toInt()} points refunded',
            variant: AmomyAlertVariant.success,
          );
        } else {
          AmomyFloatingAlert.show(
            context,
            title: StatusLocalizer.localizeError(
              context,
              cubit.state.errorMessage,
            ),
            variant: AmomyAlertVariant.error,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showActionSheet(context),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.40),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: AppColors.success,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDestructive
                              ? AppColors.error
                              : const Color(0xFF101828),
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: const Color(0xFF98A2B3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
