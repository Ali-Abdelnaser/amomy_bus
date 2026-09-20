import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Clean, selectable segmented gender selection cards for AMOMY.
class AppGenderSelector extends StatelessWidget {
  final String? label;
  final String? selectedGender;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const AppGenderSelector({
    super.key,
    this.label,
    required this.selectedGender,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FormField<String>(
      initialValue: selectedGender,
      validator: validator,
      builder: (formFieldState) {
        final currentSelection = selectedGender ?? formFieldState.value;
        final hasError = formFieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapH8,
            ],
            Row(
              children: [
                Expanded(
                  child: _GenderCard(
                    title: l10n.male,
                    icon: AppIcons.user,
                    isSelected: currentSelection?.toLowerCase() == 'male',
                    enabled: enabled,
                    onTap: () {
                      if (!enabled) return;
                      formFieldState.didChange('male');
                      onChanged('male');
                    },
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: _GenderCard(
                    title: l10n.female,
                    icon: AppIcons.user,
                    isSelected: currentSelection?.toLowerCase() == 'female',
                    enabled: enabled,
                    onTap: () {
                      if (!enabled) return;
                      formFieldState.didChange('female');
                      onChanged('female');
                    },
                  ),
                ),
              ],
            ),
            if (hasError) ...[
              AppSpacing.gapH6,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  formFieldState.errorText ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GenderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _GenderCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? AppColors.primary : AppColors.border;
    final backgroundColor = isSelected
        ? AppColors.primaryLight.withValues(alpha: 0.5)
        : AppColors.surface;
    final textColor = isSelected ? AppColors.primary : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              AppSpacing.gapW8,
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                AppSpacing.gapW6,
                const Icon(AppIcons.check, size: 14, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
