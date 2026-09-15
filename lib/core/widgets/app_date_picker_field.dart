import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Adaptive Date Picker Form Field (used for Date of Birth during registration)
class AppDatePickerField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTime? selectedDate;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Widget? prefixIcon;
  final void Function(DateTime) onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const AppDatePickerField({
    super.key,
    this.label,
    this.hint,
    this.selectedDate,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.prefixIcon,
    required this.onDateSelected,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFirstDate = firstDate ?? DateTime(1920);
    final effectiveLastDate = lastDate ?? DateTime.now();

    final formattedText = selectedDate != null
        ? DateFormat.yMMMd().format(selectedDate!)
        : null;

    return FormField<DateTime>(
      initialValue: selectedDate,
      validator: validator,
      builder: (formFieldState) {
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
            InkWell(
              onTap: enabled
                  ? () async {
                      final initial = selectedDate ??
                          DateTime(
                            DateTime.now().year - 20,
                            DateTime.now().month,
                            DateTime.now().day,
                          );
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: initial.isBefore(effectiveFirstDate)
                            ? effectiveFirstDate
                            : (initial.isAfter(effectiveLastDate)
                                ? effectiveLastDate
                                : initial),
                        firstDate: effectiveFirstDate,
                        lastDate: effectiveLastDate,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (picked != null) {
                        formFieldState.didChange(picked);
                        onDateSelected(picked);
                      }
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  hintText: hint ?? 'Select date',
                  prefixIcon: prefixIcon ??
                      const Icon(AppIcons.birthday, color: AppColors.textSecondary, size: 20),
                  suffixIcon:
                      const Icon(AppIcons.calendar, color: AppColors.textSecondary, size: 20),
                  enabled: enabled,
                  errorText: formFieldState.errorText,
                ),
                child: Text(
                  formattedText ?? (hint ?? 'Select date'),
                  style: formattedText != null
                      ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)
                      : AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
