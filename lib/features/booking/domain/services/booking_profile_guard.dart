import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Reusable profile completeness guard for trip/ticket booking.
///
/// Ensures a passenger has completed required profile fields (full name, email,
/// phone, gender, date of birth) before booking a ride.
class BookingProfileGuard {
  const BookingProfileGuard._();

  /// Returns true if the user satisfies all profile requirements for booking.
  static bool canBook(AppUser user) => user.isProfileComplete;

  /// Checks if [user] can book. If their profile is incomplete, displays a branded
  /// AMOMY modal bottom sheet with actionable guidance to complete the profile.
  ///
  /// Returns `true` if the profile is complete and booking can proceed.
  /// Returns `false` if the profile is incomplete (user may continue browsing).
  static Future<bool> checkAndPrompt({
    required BuildContext context,
    required AppUser user,
    VoidCallback? onNavigateToProfile,
  }) async {
    if (canBook(user)) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BookingProfileGuardSheet(
        user: user,
        onNavigateToProfile: onNavigateToProfile,
      ),
    );

    return result ?? false;
  }
}

class _BookingProfileGuardSheet extends StatelessWidget {
  final AppUser user;
  final VoidCallback? onNavigateToProfile;

  const _BookingProfileGuardSheet({
    required this.user,
    this.onNavigateToProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AppSpacing.gapH20,

            // Icon Badge
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.user,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            AppSpacing.gapH16,

            // Title
            Text(
              l10n.bookingGuardTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,

            // Subtitle / Explanation
            Text(
              l10n.bookingGuardSubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH20,

            // Progress Indicator
            Container(
              padding: AppSpacing.edgeInsetsA12,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.completeProfileReminderTitle,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${user.profileCompletionPercent}%',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapH8,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: user.profileCompletionPercentage,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapH24,

            // Complete Profile CTA
            AppButton(
              label: l10n.completeProfileCta,
              icon: AppIcons.arrowForward,
              isFullWidth: true,
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onNavigateToProfile != null) {
                  onNavigateToProfile!();
                } else {
                  context.push('/complete-profile');
                }
              },
            ),
            AppSpacing.gapH12,

            // Dismiss Button (Allow user to continue browsing)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.dismiss,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
