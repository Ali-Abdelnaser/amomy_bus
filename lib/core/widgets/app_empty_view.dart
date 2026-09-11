import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../localization/localization_helpers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppEmptyView extends StatelessWidget {
  final String? message;
  final IconData icon;
  final Widget? action;

  const AppEmptyView({
    super.key,
    this.message,
    this.icon = AppIcons.info,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMessage = message ?? context.l10n.noData;

    return Center(
      child: Padding(
        padding: AppSpacing.p20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.disabled,
            ),
            AppSpacing.gapH16,
            Text(
              effectiveMessage,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              AppSpacing.gapH24,
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
