import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ServiceDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const ServiceDateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectDate,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapH12,
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, _) => AppSpacing.gapW8,
            itemBuilder: (context, index) {
              final date = today.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);

              return _DateCard(
                date: date,
                isSelected: isSelected,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = _getDayName(date, context);
    final dayNumber = date.day.toString();
    final monthName = _getMonthName(date, context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            AppSpacing.gapH4,
            Text(
              dayNumber,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              monthName,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(DateTime date, BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const arDays = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = date.weekday - 1;
    return isArabic ? arDays[weekday] : enDays[weekday];
  }

  String _getMonthName(DateTime date, BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const arMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const enMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return isArabic ? arMonths[date.month - 1] : enMonths[date.month - 1];
  }
}
