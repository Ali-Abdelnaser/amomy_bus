<<<<<<< HEAD
import 'package:flutter/foundation.dart';
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../domain/entities/booking_entities.dart';
<<<<<<< HEAD
import 'return_meeting_info_card.dart';
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad

/// Departure time selector for the RETURN leg in Round Trip booking.
class RoundTripReturnTimeSelector extends StatelessWidget {
  final List<RoundTripReturnOption> returnOptions;
  final RoundTripReturnOption? selectedReturnOption;
<<<<<<< HEAD
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
  final ValueChanged<RoundTripReturnOption> onOptionSelected;

  const RoundTripReturnTimeSelector({
    super.key,
    required this.returnOptions,
    required this.selectedReturnOption,
<<<<<<< HEAD
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    if (kDebugMode) {
      debugPrint(
        'ROUND_TRIP_DEBUG selector received options count ${returnOptions.length}',
      );
    }
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    final l10n = context.l10n;
    final isAr = context.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.returnDepartureTimeTitle,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.replay_rounded,
                    size: 12,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.directionReturn,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

<<<<<<< HEAD
        // 1. Loading State: Skeleton Placeholders (when no options are loaded yet)
        if (isLoading && returnOptions.isEmpty)
          Column(
            children: List.generate(
              2,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        // 2. Error State with Retry CTA (when options are empty)
        else if (errorMessage != null && returnOptions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 20,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isAr ? 'إعادة المحاولة' : 'Retry',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else if (!isLoading && returnOptions.isEmpty)
=======
        // Empty state if no return options
        if (returnOptions.isEmpty)
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isAr
                        ? 'لا توجد رحلات عودة متاحة بعد موعد الذهاب المختار.'
                        : 'No return trips available after selected outbound time.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          )
<<<<<<< HEAD
        // 4. Return options list + Meeting Info Card
        else if (returnOptions.isNotEmpty) ...[
          if (errorMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isAr ? 'إعادة المحاولة' : 'Retry',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
=======
        else
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
          Column(
            children: returnOptions.map((option) {
              final isSelected =
                  selectedReturnOption?.returnTripId == option.returnTripId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReturnOptionCard(
                  option: option,
                  isSelected: isSelected,
                  isAr: isAr,
<<<<<<< HEAD
                  isLoading: isLoading,
                  onTap: (!isLoading && option.isBookable)
=======
                  onTap: option.isBookable
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
                      ? () => onOptionSelected(option)
                      : null,
                ),
              );
            }).toList(),
          ),
<<<<<<< HEAD
          const SizedBox(height: 12),
          ReturnMeetingInfoCard(selectedReturnOption: selectedReturnOption),
        ],
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
      ],
    );
  }
}

class _ReturnOptionCard extends StatelessWidget {
  final RoundTripReturnOption option;
  final bool isSelected;
  final bool isAr;
<<<<<<< HEAD
  final bool isLoading;
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
  final VoidCallback? onTap;

  const _ReturnOptionCard({
    required this.option,
    required this.isSelected,
    required this.isAr,
<<<<<<< HEAD
    this.isLoading = false,
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNotBookable = !option.isBookable;
<<<<<<< HEAD
=======
    final isFewSeats = !isNotBookable && option.availableSeats <= 5;
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad

    final formattedTime = AppTimeFormatter.formatDepartureTime(
      departureAt: option.departureAt,
      departureTime: option.departureTime,
      isArabic: isAr,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFFBEB)
                : (isNotBookable ? const Color(0xFFF8FAFC) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD97706)
                  : (isNotBookable
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFFCBD5E1)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Radio Indicator
              _ReturnRadioIndicator(
                isSelected: isSelected,
                isNotBookable: isNotBookable,
              ),

              const SizedBox(width: 14),

<<<<<<< HEAD
              // Time only (no subtitle/helper text inside card)
              Expanded(
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? const Color(0xFF92400E)
                        : (isNotBookable
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF101828)),
                    letterSpacing: -0.3,
                  ),
=======
              // Time & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: isSelected
                            ? FontWeight.w900
                            : FontWeight.w700,
                        color: isSelected
                            ? const Color(0xFF92400E)
                            : (isNotBookable
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF101828)),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isNotBookable
                          ? (isAr ? 'غير متاح للحجز' : 'Unavailable')
                          : (isFewSeats
                                ? (isAr ? 'مقاعد محدودة' : 'Few seats left')
                                : (isAr ? 'متاح للحجز' : 'Available')),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFB45309)
                            : (isNotBookable
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
                ),
              ),

              // Selection checkmark
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                )
<<<<<<< HEAD
              else if (isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isAr ? 'جارٍ التحقق' : 'Verifying',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
=======
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
              else if (isNotBookable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
<<<<<<< HEAD
                    isAr ? 'غير متاح ضمن حجز ذهاب وعودة' : 'Unavailable',
=======
                    isAr ? 'مغلق' : 'Closed',
>>>>>>> 4232577aea98e0382a26228c8365eacbdfa1ccad
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReturnRadioIndicator extends StatelessWidget {
  final bool isSelected;
  final bool isNotBookable;

  const _ReturnRadioIndicator({
    required this.isSelected,
    required this.isNotBookable,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD97706), width: 2.0),
          color: Colors.white,
        ),
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD97706),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isNotBookable
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        color: Colors.transparent,
      ),
    );
  }
}
