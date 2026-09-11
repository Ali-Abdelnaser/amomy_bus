import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable generic dropdown form field with brand styling and validation.
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final T? selectedValue;
  final List<DropdownMenuItem<T>>? items;
  final List<T>? rawItems;
  final String Function(T)? itemLabel;
  final Widget? prefixIcon;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.selectedValue,
    this.items,
    this.rawItems,
    this.itemLabel,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value ?? selectedValue;
    final effectiveItems = items ??
        (rawItems?.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel != null ? itemLabel!(item) : item.toString()),
              ),
            ).toList() ??
            []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          ),
          AppSpacing.gapH8,
        ],
        DropdownButtonFormField<T>(
          initialValue: effectiveValue,
          items: effectiveItems,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            enabled: enabled,
          ),
        ),
      ],
    );
  }
}
