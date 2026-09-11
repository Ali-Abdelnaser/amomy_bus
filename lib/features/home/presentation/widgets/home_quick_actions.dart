import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dialog.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  void _showSupportDialog(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.supportDialogTitle,
      message: l10n.supportDialogDesc,
      buttonText: l10n.dismiss,
    );
  }

  void _showSubscriptionsDialog(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.actionSubscriptions,
      message: l10n.subscriptionsComingSoonDesc,
      buttonText: l10n.dismiss,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapH12,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionTile(
              label: l10n.actionAddPoints,
              icon: AppIcons.add,
              color: AppColors.primary,
              onTap: () => context.go('/wallet'),
            ),
            _QuickActionTile(
              label: l10n.actionMyTrips,
              icon: AppIcons.bus,
              color: AppColors.primaryDark,
              onTap: () => context.go('/trips'),
            ),
            _QuickActionTile(
              label: l10n.actionSubscriptions,
              icon: AppIcons.repeat,
              color: AppColors.accentYellow,
              iconColor: const Color(0xFF9A6700),
              onTap: () => _showSubscriptionsDialog(context),
            ),
            _QuickActionTile(
              label: l10n.actionSupport,
              icon: AppIcons.headphones,
              color: AppColors.success,
              onTap: () => _showSupportDialog(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.label,
    required this.icon,
    required this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? color,
                    ),
                  ),
                  AppSpacing.gapH8,
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
