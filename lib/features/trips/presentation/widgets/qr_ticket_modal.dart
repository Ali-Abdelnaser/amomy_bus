import 'package:flutter/material.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';

class QrTicketModal extends StatelessWidget {
  final String departureTime;
  final String originName;
  final String destinationName;
  final String seatNumber;
  final double farePoints;
  final String qrToken;

  const QrTicketModal({
    super.key,
    required this.departureTime,
    required this.originName,
    required this.destinationName,
    required this.seatNumber,
    required this.farePoints,
    required this.qrToken,
  });

  static void show(
    BuildContext context, {
    required String departureTime,
    required String originName,
    required String destinationName,
    required String seatNumber,
    required double farePoints,
    required String qrToken,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (modalContext) => QrTicketModal(
        departureTime: departureTime,
        originName: originName,
        destinationName: destinationName,
        seatNumber: seatNumber,
        farePoints: farePoints,
        qrToken: qrToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');

    return AmomySheetContainer(
      hasBottomNav: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row: Title + Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAr ? 'تذكرة الصعود الإلكترونية' : 'Digital Boarding Ticket',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.gapH12,

            // QR Ticket Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  AppQrTicketWidget(
                    data: qrToken,
                    size: 180,
                  ),
                  AppSpacing.gapH12,
                  Text(
                    isAr
                        ? 'أظهر هذا الرمز للسائق عند الصعود'
                        : 'Show this QR code to the driver upon boarding',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            AppSpacing.gapH14,

            // Trip Details Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TicketDetailItem(
                  icon: AppIcons.clock,
                  label: isAr ? 'الموعد' : 'Time',
                  value: departureTime,
                ),
                _TicketDetailItem(
                  icon: AppIcons.seat,
                  label: isAr ? 'المقعد' : 'Seat',
                  value: seatNumber,
                ),
                _TicketDetailItem(
                  icon: AppIcons.ticket,
                  label: isAr ? 'القيمة' : 'Fare',
                  value: '${farePoints.toInt()} ${isAr ? "نقطة" : "pts"}',
                ),
              ],
            ),
            AppSpacing.gapH12,

            // From -> To Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      originName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      isAr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      destinationName,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TicketDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
