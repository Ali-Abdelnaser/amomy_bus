import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../domain/entities/booking_entities.dart';

/// Departure time selector for the RETURN leg in Round Trip booking.
class RoundTripReturnTimeSelector extends StatelessWidget {
  final List<RoundTripReturnOption> returnOptions;
  final RoundTripReturnOption? selectedReturnOption;
  final ValueChanged<RoundTripReturnOption> onOptionSelected;

  const RoundTripReturnTimeSelector({
    super.key,
    required this.returnOptions,
    required this.selectedReturnOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
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

        // Empty state if no return options
        if (returnOptions.isEmpty)
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
        else
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
                  onTap: option.isBookable
                      ? () => onOptionSelected(option)
                      : null,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReturnOptionCard extends StatelessWidget {
  final RoundTripReturnOption option;
  final bool isSelected;
  final bool isAr;
  final VoidCallback? onTap;

  const _ReturnOptionCard({
    required this.option,
    required this.isSelected,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNotBookable = !option.isBookable;
    final isFewSeats = !isNotBookable && option.availableSeats <= 5;

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
                ),
              ),

              // Selection checkmark
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: Color(0xFFD97706),
                )
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
                    isAr ? 'مغلق' : 'Closed',
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
