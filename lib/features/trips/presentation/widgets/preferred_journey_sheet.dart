import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import '../../../booking/presentation/widgets/route_stop_selector.dart';
import '../cubit/passenger_trips_cubit.dart';

/// Compact, elegant Preferred Journey Settings Bottom Sheet.
///
/// UX Architecture:
/// - Opened with [useRootNavigator: false] inside the shell route navigator.
/// - The outer [FloatingBottomNavBar] remains visually visible and unaffected.
/// - The bottom padding is dynamically offset by [navBarTotalHeight] + safe area,
///   or [keyboardInset] when virtual keyboard is engaged.
/// - The card floats directly above the floating bottom navigation bar.
class PreferredJourneySheet extends StatefulWidget {
  final List<RouteStop> availableStops;
  final PassengerTripPreference? preference;

  const PreferredJourneySheet({
    super.key,
    required this.availableStops,
    this.preference,
  });

  static Future<void> show(
    BuildContext context, {
    required List<RouteStop> availableStops,
    PassengerTripPreference? preference,
  }) {
    if (availableStops.isEmpty) {
      AppSnackBar.showInfo(
        context,
        Localizations.localeOf(context).languageCode.startsWith('ar')
            ? 'جاري تحميل المحطات، يرجى المحاولة بعد لحظات'
            : 'Loading stops, please try again in a moment',
      );
      return Future.value();
    }

    final cubit = context.read<PassengerTripsCubit>();
    return showModalBottomSheet(
      context: context,
      useSafeArea: false,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.40),
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: PreferredJourneySheet(
          availableStops: availableStops,
          preference: preference,
        ),
      ),
    );
  }

  @override
  State<PreferredJourneySheet> createState() => _PreferredJourneySheetState();
}

class _PreferredJourneySheetState extends State<PreferredJourneySheet> {
  RouteStop? _originStop;
  RouteStop? _destStop;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.preference?.originStopId != null) {
      _originStop = widget.availableStops.cast<RouteStop?>().firstWhere(
        (s) => s?.stopId == widget.preference!.originStopId,
        orElse: () => null,
      );
    }
    _originStop ??= widget.availableStops.isNotEmpty
        ? widget.availableStops.first
        : null;

    if (widget.preference?.destinationStopId != null) {
      _destStop = widget.availableStops.cast<RouteStop?>().firstWhere(
        (s) =>
            s?.stopId == widget.preference!.destinationStopId &&
            (_originStop == null || s!.stopOrder > _originStop!.stopOrder),
        orElse: () => null,
      );
    }
    _destStop ??= widget.availableStops.length > 1
        ? widget.availableStops.last
        : null;
  }

  List<RouteStop> get _validDestStops {
    if (_originStop == null) return widget.availableStops;
    return widget.availableStops
        .where((s) => s.stopOrder > _originStop!.stopOrder)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale.startsWith('ar');
    final mediaQuery = MediaQuery.of(context);
    final disableAnimations = mediaQuery.disableAnimations;

    final hasCurrent = widget.preference != null;
    final currentOrigin = hasCurrent
        ? (isAr
              ? widget.preference!.originNameAr
              : widget.preference!.originNameEn)
        : null;
    final currentDest = hasCurrent
        ? (isAr
              ? widget.preference!.destinationNameAr
              : widget.preference!.destinationNameEn)
        : null;

    final bottomSafeArea = mediaQuery.padding.bottom;

    Widget sheetPanel = Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AmomySheetDimensions.sheetCornerRadius),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomSafeArea),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Single subtle drag handle
              const AmomyDragHandle(),
              AppSpacing.gapH14,

              // Sheet Header: Icon + Title + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      AppSpacing.gapW10,
                      Text(
                        isAr ? 'رحلتك المعتادة' : 'Preferred Journey',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),

              // Current saved journey badge (if set)
              if (hasCurrent &&
                  currentOrigin != null &&
                  currentDest != null) ...[
                AppSpacing.gapH10,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        isAr ? 'المحفوظة حالياً: ' : 'Current: ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$currentOrigin  →  $currentDest',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              AppSpacing.gapH16,

              // ORIGIN PICKER (FROM / من)
              Text(
                isAr ? 'محطة الانطلاق (من)' : 'Departure Stop (FROM)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH8,
              Material(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    RouteStopSelector.openStopPickerSheet(
                      context: context,
                      isOrigin: true,
                      title: isAr ? 'اختر محطة الركوب' : 'Select boarding stop',
                      helperText: isAr
                          ? 'حدد المحطة التي ستصعد منها للحافلة'
                          : 'Choose your pickup point along the route',
                      stops: widget.availableStops,
                      selectedStop: _originStop,
                      showFare: false,
                      onSelected: (newStop) {
                        setState(() {
                          _originStop = newStop;
                          if (_destStop != null &&
                              _destStop!.stopOrder <= newStop.stopOrder) {
                            final valids = widget.availableStops
                                .where((s) => s.stopOrder > newStop.stopOrder)
                                .toList();
                            _destStop = valids.isNotEmpty ? valids.last : null;
                          }
                        });
                      },
                      locale: locale,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _originStop != null
                                    ? _originStop!.stopName(locale)
                                    : (isAr
                                          ? 'اختر محطة الانطلاق'
                                          : 'Select departure stop'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _originStop != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_originStop != null &&
                                  _originStop!.locality(locale).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _originStop!.locality(locale),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH16,

              // DESTINATION PICKER (TO / إلى)
              Text(
                isAr ? 'محطة الوصول (إلى)' : 'Destination Stop (TO)',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppSpacing.gapH8,
              Material(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    if (_validDestStops.isEmpty) {
                      AppSnackBar.showWarning(
                        context,
                        isAr
                            ? 'لا توجد محطات وصول متاحة بعد محطة الانطلاق المحددة'
                            : 'No destination stops available after selected departure',
                      );
                      return;
                    }
                    RouteStopSelector.openStopPickerSheet(
                      context: context,
                      isOrigin: false,
                      title: isAr ? 'اختر محطة النزول' : 'Select destination',
                      helperText: isAr
                          ? 'المحطات المتاحة بعد محطة الركوب'
                          : 'Valid drop-off stops downstream from your origin',
                      stops: _validDestStops,
                      selectedStop: _destStop,
                      showFare: false,
                      onSelected: (newStop) {
                        setState(() => _destStop = newStop);
                      },
                      locale: locale,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFC928,
                            ).withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFFD49B00,
                              ).withValues(alpha: 0.30),
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Color(0xFFD49B00),
                          ),
                        ),
                        AppSpacing.gapW12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _destStop != null
                                    ? _destStop!.stopName(locale)
                                    : (isAr
                                          ? 'اختر محطة الوصول'
                                          : 'Select destination stop'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _destStop != null
                                      ? AppColors.textPrimary
                                      : AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_destStop != null &&
                                  _destStop!.locality(locale).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _destStop!.locality(locale),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppSpacing.gapH24,

              // SAVE BUTTON
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      (_originStop != null &&
                          _destStop != null &&
                          _originStop!.stopId != _destStop!.stopId &&
                          !_isSaving)
                      ? () => _handleSave(context, isAr)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          isAr ? 'حفظ التفضيل' : 'Save Preference',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!disableAnimations) {
      sheetPanel = sheetPanel
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .slideY(
            begin: 0.10,
            end: 0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: sheetPanel,
    );
  }

  Future<void> _handleSave(BuildContext ctx, bool isAr) async {
    setState(() => _isSaving = true);
    final cubit = ctx.read<PassengerTripsCubit>();
    final nav = Navigator.of(ctx);

    final success = await cubit.updatePreferredJourney(
      originStopId: _originStop!.stopId,
      destinationStopId: _destStop!.stopId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      nav.pop();
      AppSnackBar.showSuccess(
        context,
        isAr
            ? 'تم حفظ رحلتك المعتادة بنجاح'
            : 'Preferred journey updated successfully',
      );
    }
  }
}
