import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable Card component with brand styling and subtle borders/shadows
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.radiusLg;

    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: effectiveRadius,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: AppShadows.sm,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.s16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = InkWell(onTap: onTap, borderRadius: effectiveRadius, child: card);
    }

    return card;
  }
}

/// Status / Count Badge component
class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  factory AppBadge.success({required String label, IconData? icon}) {
    return AppBadge(
      label: label,
      backgroundColor: AppColors.successLight,
      textColor: AppColors.success,
      icon: icon,
    );
  }

  factory AppBadge.warning({required String label, IconData? icon}) {
    return AppBadge(
      label: label,
      backgroundColor: AppColors.warningLight,
      textColor: AppColors.warning,
      icon: icon,
    );
  }

  factory AppBadge.error({required String label, IconData? icon}) {
    return AppBadge(
      label: label,
      backgroundColor: AppColors.errorLight,
      textColor: AppColors.error,
      icon: icon,
    );
  }

  factory AppBadge.info({required String label, IconData? icon}) {
    return AppBadge(
      label: label,
      backgroundColor: AppColors.primaryLight,
      textColor: AppColors.primary,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor ?? AppColors.textSecondary),
            AppSpacing.gapW4,
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Filter / Selection Chip component
class AppChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final Widget? icon;

  const AppChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: icon,
      labelStyle: AppTextStyles.labelMedium.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      selectedColor: AppColors.primaryLight,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.radiusSm,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      showCheckmark: false,
    );
  }
}
