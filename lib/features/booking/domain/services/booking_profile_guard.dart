import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
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
      useSafeArea: false,
      useRootNavigator: false,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
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

    return AmomySheetContainer(
      hasBottomNav: true,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Badge
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.user,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
            ),
            AppSpacing.gapH14,

            // Title
            Text(
              l10n.bookingGuardTitle,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH6,

            // Subtitle / Explanation
            Text(
              l10n.bookingGuardSubtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH16,

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
            AppSpacing.gapH20,

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
            AppSpacing.gapH10,

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
