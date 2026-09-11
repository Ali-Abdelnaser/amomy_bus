import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class PendingSuccessStepWidget extends StatelessWidget {
  final String? requestId;
  final VoidCallback onReturnToWallet;

  const PendingSuccessStepWidget({
    super.key,
    this.requestId,
    required this.onReturnToWallet,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        // Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Icon(
              AppIcons.clock,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        AppSpacing.gapH24,

        // Title
        Text(
          l10n.topUpPendingSuccessTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        AppSpacing.gapH12,

        // Message
        Text(
          l10n.topUpPendingSuccessDesc,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        AppSpacing.gapH20,

        if (requestId != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'ID: ${requestId!.substring(0, 8)}...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],

        const Spacer(),

        // CTA
        AppButton(
          label: l10n.topUpBackToWallet,
          onPressed: onReturnToWallet,
          isFullWidth: true,
        ),
        AppSpacing.gapH16,
      ],
    );
  }
}
