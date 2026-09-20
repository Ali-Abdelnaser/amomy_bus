import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_entities.dart';

/// Segmented Booking Mode Selector ("ذهاب فقط" / "ذهاب وعودة - خصم 15%").
/// Only shown when outbound direction is selected.
class BookingModeToggle extends StatelessWidget {
  final BookingMode mode;
  final ValueChanged<BookingMode> onModeChanged;

  const BookingModeToggle({
    super.key,
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSingle = mode == BookingMode.single;
    final isRoundTrip = mode == BookingMode.roundTrip;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    const pillHeight = 46.0;
    const cornerRadius = 14.0;

    return Container(
      height: pillHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
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
                    : const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: isSingle
                    ? AlignmentDirectional.centerStart
                    : AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    width: halfWidth,
                    height: pillHeight - 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cornerRadius - 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Interactive Touch Options
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SINGLE TRIP
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSingle
                            ? null
                            : () => onModeChanged(BookingMode.single),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: Center(
                          child: Text(
                            l10n.singleTrip,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSingle
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSingle
                                  ? AppColors.primary
                                  : const Color(0xFF64748B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ROUND TRIP
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isRoundTrip
                            ? null
                            : () => onModeChanged(BookingMode.roundTrip),
                        borderRadius: BorderRadius.circular(cornerRadius),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.roundTrip,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: isRoundTrip
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isRoundTrip
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF86EFAC),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  l10n.roundTripDiscountBadge,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
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
