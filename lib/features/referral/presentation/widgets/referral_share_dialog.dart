import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class ReferralShareDialog extends StatelessWidget {
  final String code;

  const ReferralShareDialog({super.key, required this.code});

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
      builder: (_) => ReferralShareDialog(code: code),
    );
  }

  String getInviteMessage({required bool isArabic}) {
    if (isArabic) {
      return 'انضم إلى تطبيق عمومي باص واستمتع برحلات مريحة وسريعة!\n\n'
          'استخدم كود الدعوة الخاص بي:\n'
          '$code\n\n'
          'أو افتح الرابط مباشرة:\n'
          'amomy://invite?code=$code';
    }
    return 'Join AMOMY Bus for comfortable and reliable trips!\n\n'
        'Use my referral code:\n'
        '$code\n\n'
        'Or open directly via link:\n'
        'amomy://invite?code=$code';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final shareText = getInviteMessage(isArabic: isAr);

    return AmomySheetContainer(
      hasBottomNav: false,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'مشاركة كود الدعوة' : 'Share Referral Code',
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
                ? 'شارك هذه الرسالة مع أصدقائك عبر واتساب أو وسائل التواصل'
                : 'Share this message with friends via chat apps or social media',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapH16,

          // Share preview card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              shareText,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          AppSpacing.gapH20,

          // Copy Message Action
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.of(context).pop();
              AppSnackBar.showSuccess(
                context,
                isAr
                    ? 'تم نسخ رسالة الدعوة إلى الحافظة'
                    : 'Invite message copied to clipboard',
              );
            },
            icon: const Icon(AppIcons.copy, size: 18),
            label: Text(
              isAr ? 'نسخ نص الرسالة بالكامل' : 'Copy Full Message',
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
