import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../extensions/context_extensions.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Shows the AMOMY unified premium Date Picker modal with frosted glass background blur.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  String? title,
}) {
  final now = DateTime.now();
  final effectiveFirstDate = firstDate ?? DateTime(1920, 1, 1);
  final effectiveLastDate = lastDate ?? now;

  DateTime effectiveInitial =
      initialDate ?? DateTime(now.year - 20, now.month, now.day);
  if (effectiveInitial.isBefore(effectiveFirstDate)) {
    effectiveInitial = effectiveFirstDate;
  } else if (effectiveInitial.isAfter(effectiveLastDate)) {
    effectiveInitial = effectiveLastDate;
  }

  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'AppDatePickerDismissBarrier',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return AppDatePickerModal(
        initialDate: effectiveInitial,
        firstDate: effectiveFirstDate,
        lastDate: effectiveLastDate,
        title: title,
      );
    },
    transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12.0 * curved.value,
          sigmaY: 12.0 * curved.value,
        ),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// AMOMY Custom Wheel Date Picker Modal with 3 distinct columns:
/// Day, Month (localized names), and Year with dynamic day-month calculations.
class AppDatePickerModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? title;

  const AppDatePickerModal({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title,
  });

  @override
  State<AppDatePickerModal> createState() => _AppDatePickerModalState();
}

class _AppDatePickerModalState extends State<AppDatePickerModal> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  static const double _itemExtent = 44.0;
  static const double _pickerHeight = 220.0;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _dayController = FixedExtentScrollController(
      initialItem: (_selectedDay - 1).clamp(0, 30),
    );
    _monthController = FixedExtentScrollController(
      initialItem: (_selectedMonth - 1).clamp(0, 11),
    );
    _yearController = FixedExtentScrollController(
      initialItem: (_selectedYear - widget.firstDate.year).clamp(
        0,
        totalYears - 1,
      ),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int get totalYears =>
      (widget.lastDate.year - widget.firstDate.year + 1).clamp(1, 200);

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  DateTime get _currentDate {
    final maxDays = _daysInMonth(_selectedYear, _selectedMonth);
    final day = _selectedDay.clamp(1, maxDays);
    return DateTime(_selectedYear, _selectedMonth, day);
  }

  void _onYearChanged(int index) {
    HapticFeedback.selectionClick();
    final newYear = widget.firstDate.year + index;
    setState(() {
      _selectedYear = newYear;
      final maxDays = _daysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > maxDays) {
        _selectedDay = maxDays;
        _dayController.jumpToItem(_selectedDay - 1);
      }
    });
  }

  void _onMonthChanged(int index) {
    HapticFeedback.selectionClick();
    final newMonth = index + 1;
    setState(() {
      _selectedMonth = newMonth;
      final maxDays = _daysInMonth(_selectedYear, _selectedMonth);
      if (_selectedDay > maxDays) {
        _selectedDay = maxDays;
        _dayController.jumpToItem(_selectedDay - 1);
      }
    });
  }

  void _onDayChanged(int index) {
    HapticFeedback.selectionClick();
    final maxDays = _daysInMonth(_selectedYear, _selectedMonth);
    setState(() {
      _selectedDay = (index + 1).clamp(1, maxDays);
    });
  }

  void _onConfirm() {
    HapticFeedback.mediumImpact();
    var finalDate = _currentDate;
    if (finalDate.isBefore(widget.firstDate)) {
      finalDate = widget.firstDate;
    } else if (finalDate.isAfter(widget.lastDate)) {
      finalDate = widget.lastDate;
    }
    Navigator.of(context).pop(finalDate);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxDays = _daysInMonth(_selectedYear, _selectedMonth);

    // Formatted live date badge string
    final localeName = isAr ? 'ar' : 'en';
    final formattedFullDate = DateFormat.yMMMMd(
      localeName,
    ).format(_currentDate);

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          margin: EdgeInsets.only(
            left: AppSpacing.s12,
            right: AppSpacing.s12,
            bottom: bottomInset > 0 ? bottomInset : AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpacing.gapH12,

                // Top Drag Pill
                Center(
                  child: Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                AppSpacing.gapH12,

                // Header Bar (Title & Close Button)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title ?? l10n.selectDate,
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        splashRadius: 20,
                        tooltip: l10n.cancel,
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapH12,

                // Live Formatted Date Badge
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: AppSpacing.s16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          AppIcons.calendar,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        AppSpacing.gapW8,
                        Flexible(
                          child: Text(
                            formattedFullDate,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.gapH16,

                // Column Headers (Day, Month, Year)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: Row(
                    children: _buildColumnWidgets(
                      dayWidget: _buildColumnHeader(l10n.dayColumnLabel),
                      monthWidget: _buildColumnHeader(l10n.monthColumnLabel),
                      yearWidget: _buildColumnHeader(l10n.yearColumnLabel),
                      isAr: isAr,
                    ),
                  ),
                ),

                AppSpacing.gapH8,

                // 3 Wheel Pickers Area with Central Highlight Pill & Gradient Fades
                SizedBox(
                  height: _pickerHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Unified Center Selection Capsule
                      IgnorePointer(
                        child: Container(
                          height: _itemExtent,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // 3 Interactive Scroll Wheels
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        child: Row(
                          children: _buildColumnWidgets(
                            dayWidget: _buildDayWheel(maxDays),
                            monthWidget: _buildMonthWheel(localeName),
                            yearWidget: _buildYearWheel(),
                            isAr: isAr,
                          ),
                        ),
                      ),

                      // Top Fading Gradient Overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Fading Gradient Overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapH20,

                // Primary CTA Button (Confirm Date)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            AppIcons.checkCircle,
                            size: 20,
                            color: Colors.white,
                          ),
                          AppSpacing.gapW8,
                          Text(
                            l10n.confirmDate,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                AppSpacing.gapH20,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds symmetric columns according to locale direction (Day - Month - Year).
  List<Widget> _buildColumnWidgets({
    required Widget dayWidget,
    required Widget monthWidget,
    required Widget yearWidget,
    required bool isAr,
  }) {
    // 3 Columns: Day (~26%), Month (~46%), Year (~28%)
    final dayFlex = Expanded(flex: 26, child: dayWidget);
    final monthFlex = Expanded(flex: 46, child: monthWidget);
    final yearFlex = Expanded(flex: 28, child: yearWidget);

    if (isAr) {
      // In Arabic RTL: اليوم - الشهر - السنة
      return [dayFlex, monthFlex, yearFlex];
    } else {
      // In English LTR: Day - Month - Year
      return [dayFlex, monthFlex, yearFlex];
    }
  }

  Widget _buildColumnHeader(String label) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDayWheel(int maxDays) {
    return ListWheelScrollView.useDelegate(
      controller: _dayController,
      itemExtent: _itemExtent,
      perspective: 0.003,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onDayChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: maxDays,
        builder: (context, index) {
          final day = index + 1;
          final isSelected = day == _selectedDay;

          return Center(
            child: Text(
              '$day',
              style: isSelected
                  ? AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthWheel(String localeName) {
    return ListWheelScrollView.useDelegate(
      controller: _monthController,
      itemExtent: _itemExtent,
      perspective: 0.003,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onMonthChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: 12,
        builder: (context, index) {
          final monthNumber = index + 1;
          final isSelected = monthNumber == _selectedMonth;

          // Format month name localized e.g. يناير / January
          final monthDate = DateTime(2024, monthNumber);
          final monthName = DateFormat.MMMM(localeName).format(monthDate);

          return Center(
            child: Text(
              monthName,
              style: isSelected
                  ? AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    )
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearWheel() {
    return ListWheelScrollView.useDelegate(
      controller: _yearController,
      itemExtent: _itemExtent,
      perspective: 0.003,
      diameterRatio: 1.4,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onYearChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: totalYears,
        builder: (context, index) {
          final year = widget.firstDate.year + index;
          final isSelected = year == _selectedYear;

          return Center(
            child: Text(
              '$year',
              style: isSelected
                  ? AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )
                  : AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 15,
                    ),
            ),
          );
        },
      ),
    );
  }
}
