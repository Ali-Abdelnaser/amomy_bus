import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../localization/localization_helpers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class AppErrorView extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.icon = AppIcons.warningCircle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMessage = message ?? context.l10n.errorOccurred;

    return Center(
      child: Padding(
        padding: AppSpacing.p20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 52,
              color: AppColors.error,
            ),
            AppSpacing.gapH16,
            Text(
              effectiveMessage,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapH24,
              AppButton(
                text: context.l10n.retry,
                onPressed: onRetry,
                variant: ButtonVariant.outline,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
