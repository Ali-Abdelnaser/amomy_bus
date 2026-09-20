import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/amomy_bus_icon.dart';
import '../../domain/entities/onboarding_item.dart';

/// Single page content for Onboarding:
/// - Hero illustration occupying 40–50% of screen height
/// - Centered Title (24–28px) with strong hierarchy
/// - Centered Subtitle with comfortable horizontal padding
class OnboardingContent extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero Illustration Section - occupies ~45-50% screen height, lower and well balanced
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: Center(
              child: Image.asset(
                item.imageAsset,
                fit: BoxFit.contain,
                width: double.infinity,
                semanticLabel: item.title,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: AmomyBusIcon(size: 80, color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Text Section: Title + Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                item.title,
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH12,
              Text(
                item.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
