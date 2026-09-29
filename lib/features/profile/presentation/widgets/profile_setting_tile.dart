import 'package:flutter/material.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reusable profile and settings row component.
///
/// Complies with AMOMY design system:
/// - 48px minimum tap area
/// - Lucide leading icon in a soft brand container
/// - Accessible semantics and clean press feedback
/// - Automatic RTL chevron mirroring
class ProfileSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Color? titleColor;
  final bool isDestructive;

  const ProfileSettingTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.trailingWidget,
    this.onTap,
    this.showChevron = true,
    this.iconColor,
    this.iconBackgroundColor,
    this.titleColor,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final effectiveIconBgColor = iconBackgroundColor ??
        (isDestructive ? AppColors.errorLight : AppColors.primaryLight);
    final effectiveIconColor =
        iconColor ?? (isDestructive ? AppColors.error : AppColors.primary);
    final effectiveTitleColor =
        titleColor ?? (isDestructive ? AppColors.error : AppColors.textPrimary);
    final effectiveChevronColor = isDestructive
        ? AppColors.error.withValues(alpha: 0.5)
        : AppColors.textTertiary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Soft icon container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: effectiveIconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: effectiveIconColor,
                  ),
                ),
                AppSpacing.gapW14,

                // Title and optional subtitle
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: effectiveTitleColor,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDestructive
                                ? AppColors.error.withValues(alpha: 0.75)
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing text, custom widget, or chevron
                if (trailingText != null && trailingText!.isNotEmpty) ...[
                  Text(
                    trailingText!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  AppSpacing.gapW8,
                ],
                ?trailingWidget,
                if (showChevron && onTap != null)
                  Icon(
                    isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                    size: 18,
                    color: effectiveChevronColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
