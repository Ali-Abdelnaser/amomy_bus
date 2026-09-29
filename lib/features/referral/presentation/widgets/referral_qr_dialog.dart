import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../booking/presentation/widgets/app_qr_ticket_widget.dart';

class ReferralQrDialog extends StatelessWidget {
  final String code;

  const ReferralQrDialog({super.key, required this.code});

  static void show(BuildContext context, {required String code}) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => ReferralQrDialog(code: code),
    );
  }

  String get _inviteLink => 'amomy://invite?code=$code';

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return AmomySheetContainer(
      hasBottomNav: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'رمز QR للدعوة' : 'Invite QR Code',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(AppIcons.close, size: 20),
                color: AppColors.textSecondary,
                splashRadius: 20,
              ),
            ],
          ),
          AppSpacing.gapH8,
          Text(
            isAr
                ? 'امسح الرمز أو شارك الرابط لدعوة أصدقائك مباشرة'
                : 'Scan the code or share the link to invite your friends directly',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapH20,

          // QR Code Card
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppQrTicketWidget(
                    data: _inviteLink,
                    size: 200,
                  ),
                  AppSpacing.gapH12,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      code,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AppSpacing.gapH24,

          // Copy link action button
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _inviteLink));
              AppSnackBar.showSuccess(
                context,
                isAr
                    ? 'تم نسخ رابط الدعوة إلى الحافظة'
                    : 'Invite link copied to clipboard',
              );
            },
            icon: const Icon(AppIcons.copy, size: 18),
            label: Text(
              isAr ? 'نسخ رابط الدعوة' : 'Copy Invite Link',
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.radiusMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
