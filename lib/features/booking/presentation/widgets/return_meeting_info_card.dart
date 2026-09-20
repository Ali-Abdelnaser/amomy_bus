import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_time_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/booking_entities.dart';

/// Informational card displaying return trip meeting point and grace period.
///
/// Authoritative Passenger Guidance:
/// - Meeting point: "أمام بوابة توشكى – حي الجامعة"
/// - Grace period: "15 دقيقة بعد الموعد المحدد"
/// - Movement notice: "يبدأ تحرك الحافلة بعد 15 دقيقة من موعد التجمع."
///
/// Used identically for:
/// 1. Return-only booking (Single Return mode)
/// 2. Round Trip booking (Return Departure section)
class ReturnMeetingInfoCard extends StatelessWidget {
  final DateTime? selectedDepartureAt;
  final String? selectedDepartureTime;
  final TripOption? selectedTrip;
  final RoundTripReturnOption? selectedReturnOption;

  const ReturnMeetingInfoCard({
    super.key,
    this.selectedDepartureAt,
    this.selectedDepartureTime,
    this.selectedTrip,
    this.selectedReturnOption,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = context.isArabic;

    // Resolve departure times for display guidance if provided
    final depAt =
        selectedDepartureAt ??
        selectedReturnOption?.departureAt ??
        selectedTrip?.departureAt;
    final depTimeStr =
        selectedDepartureTime ??
        selectedReturnOption?.departureTime ??
        selectedTrip?.departureTime;

    String? formattedMeetingTime;
    String? formattedMovementTime;

    if (depAt != null) {
      formattedMeetingTime = AppTimeFormatter.formatDepartureTime(
        departureAt: depAt,
        departureTime: depTimeStr,
        isArabic: isAr,
      );
      final movementAt = depAt.add(const Duration(minutes: 15));
      formattedMovementTime = AppTimeFormatter.formatDepartureTime(
        departureAt: movementAt,
        isArabic: isAr,
      );
    } else if (depTimeStr != null && depTimeStr.trim().isNotEmpty) {
      formattedMeetingTime = AppTimeFormatter.formatDepartureTime(
        departureTime: depTimeStr,
        isArabic: isAr,
      );
      final parts = depTimeStr.trim().split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]);
        final m = parts.length > 1
            ? int.tryParse(parts[1].split(' ').first) ?? 0
            : 0;
        if (h != null) {
          final totalM = (h * 60 + m + 15) % (24 * 60);
          final newH = totalM ~/ 60;
          final newM = totalM % 60;
          final movementStr =
              '${newH.toString().padLeft(2, '0')}:${newM.toString().padLeft(2, '0')}';
          formattedMovementTime = AppTimeFormatter.formatDepartureTime(
            departureTime: movementStr,
            isArabic: isAr,
          );
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Meeting Point Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  AppIcons.location,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'مكان التجمع' : 'Meeting Point',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr
                          ? 'أمام بوابة توشكى – حي الجامعة'
                          : 'In front of Toshka Gate – University District',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0)),
          ),

          // 2. Grace Period Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  AppIcons.clock,
                  size: 15,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isAr ? 'فترة السماح' : 'Grace Period',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isAr
                                ? '15 دقيقة بعد الموعد المحدد'
                                : '15 mins after scheduled time',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedMeetingTime != null &&
                              formattedMovementTime != null
                          ? (isAr
                                ? 'موعد التجمع $formattedMeetingTime — يبدأ التحرك $formattedMovementTime'
                                : 'Meeting at $formattedMeetingTime — Movement begins at $formattedMovementTime')
                          : (isAr
                                ? 'يبدأ تحرك الحافلة بعد 15 دقيقة من موعد التجمع.'
                                : 'Bus departure begins 15 minutes after the meeting time.'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
