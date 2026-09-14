import 'package:flutter/material.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../booking/domain/entities/booking_entities.dart';
import 'preferred_journey_sheet.dart';

class PreferredJourneyCard extends StatelessWidget {
  final PassengerTripPreference? preference;
  final List<RouteStop> availableStops;

  const PreferredJourneyCard({
    super.key,
    required this.preference,
    required this.availableStops,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode.startsWith('ar');
    final hasPref = preference != null;

    final originName = hasPref
        ? (isAr ? preference!.originNameAr : preference!.originNameEn)
        : '';
    final destName = hasPref
        ? (isAr ? preference!.destinationNameAr : preference!.destinationNameEn)
        : '';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: Colors.white,
      border: const BorderSide(color: AppColors.border, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.repeat_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapW8,
                  Text(
                    isAr ? 'رحلتك المعتادة' : 'Your usual journey',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => PreferredJourneySheet.show(
                  context,
                  availableStops: availableStops,
                  preference: preference,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.edit,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      AppSpacing.gapW4,
                      Text(
                        isAr ? 'تعديل' : 'Edit',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH10,
          if (hasPref)
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          originName.isNotEmpty ? originName : '...',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          isAr
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.accentYellow,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          destName.isNotEmpty ? destName : '...',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Text(
              isAr
                  ? 'لم تحدد رحلتك المعتادة بعد. اضغط تعديل لاختيارها لتسهيل الحجز السريع.'
                  : 'No usual journey saved. Tap Edit to set it for faster bookings.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
