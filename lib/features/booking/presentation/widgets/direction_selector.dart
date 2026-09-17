import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_entities.dart';

/// Premium sliding capsule direction selector (Outbound / Return).
/// Features a smooth sliding selection pill between Outbound (#01589F) and Return (#FFC928).
class DirectionSelector extends StatelessWidget {
  final BookingDirection selectedDirection;
  final ValueChanged<BookingDirection> onDirectionChanged;

  const DirectionSelector({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAr = context.isArabic;
    final isOutbound = selectedDirection == BookingDirection.outbound;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final outboundLabel = l10n.directionOutbound;
    final returnLabel = l10n.directionReturn;

    const pillHeight = 50.0;
    const cornerRadius = 16.0;

    return Container(
      height: pillHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final halfWidth = (constraints.maxWidth - 6) / 2;

          return Stack(
            children: [
              // 1. Sliding Selected Capsule Pill
              AnimatedAlign(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment: isOutbound
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    width: halfWidth,
                    height: pillHeight - 6,
                    decoration: BoxDecoration(
                      color: isOutbound
                          ? AppColors.primary
                          : const Color(0xFFFFC928),
                      borderRadius: BorderRadius.circular(cornerRadius - 3),
                      boxShadow: [
                        BoxShadow(
                          color: isOutbound
                              ? AppColors.primary.withValues(alpha: 0.28)
                              : const Color(0xFFFFC928).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Interactive Touch Labels
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // OUTBOUND
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isOutbound
                            ? null
                            : () =>
                                  onDirectionChanged(BookingDirection.outbound),
                        borderRadius: BorderRadius.horizontal(
                          left: isAr
                              ? Radius.zero
                              : const Radius.circular(cornerRadius),
                          right: isAr
                              ? const Radius.circular(cornerRadius)
                              : Radius.zero,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAr
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: isOutbound
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                outboundLabel,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isOutbound
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isOutbound
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // RETURN
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: !isOutbound
                            ? null
                            : () => onDirectionChanged(
                                BookingDirection.returnTrip,
                              ),
                        borderRadius: BorderRadius.horizontal(
                          left: isAr
                              ? const Radius.circular(cornerRadius)
                              : Radius.zero,
                          right: isAr
                              ? Radius.zero
                              : const Radius.circular(cornerRadius),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isAr
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                size: 16,
                                color: !isOutbound
                                    ? const Color(0xFF101828)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                returnLabel,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: !isOutbound
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: !isOutbound
                                      ? const Color(0xFF101828)
                                      : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
