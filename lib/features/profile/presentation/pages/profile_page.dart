import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/localization/app_locale_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../home/presentation/widgets/home_profile_completion_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showLanguageSelector(BuildContext context) {
    final controller = AppLocaleController.instance;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      showDragHandle: false,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => AmomySheetContainer(
        hasBottomNav: true,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.language,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.gapH12,
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(AppIcons.globe, color: AppColors.primary),
              title: const Text('العربية'),
              trailing: controller.isArabic
                  ? const Icon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                if (!controller.isArabic) {
                  controller.toggleLocale();
                }
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(AppIcons.globe, color: AppColors.primary),
              title: const Text('English'),
              trailing: !controller.isArabic
                  ? const Icon(AppIcons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                if (controller.isArabic) {
                  controller.toggleLocale();
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.aboutAmomy,
      illustrationPath: AppAssets.busServiceIllustration,
      message: 'AMOMY Bus v1.0.0\nSmart, reliable bus transportation in Egypt.\n\n© 2026 AMOMY. All rights reserved.',
      buttonText: l10n.dismiss,
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.privacyPolicy,
      message: 'AMOMY respects your privacy. We securely collect only the necessary information to verify your account, ensure passenger safety, and process bookings smoothly.',
      buttonText: l10n.dismiss,
    );
  }

  void _showTerms(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.termsAndConditions,
      message: 'By using AMOMY, you agree to comply with passenger safety guidelines, accurate seat booking policies, and punctuality standards.',
      buttonText: l10n.dismiss,
    );
  }

  void _showSupportDialog(BuildContext context) {
    final l10n = context.l10n;
    showInfoDialog(
      context: context,
      title: l10n.supportDialogTitle,
      message: l10n.supportDialogDesc,
      buttonText: l10n.dismiss,
    );
  }

  void _confirmSignOut(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const SignOutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! Authenticated) {
          return const AppScaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

        return AppScaffold(
          appBar: AppAppBar(
            title: l10n.navProfile,
            showBackButton: false,
          ),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Header Card
                  AppCard(
                    padding: AppSpacing.edgeInsetsA20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
                          child: !hasAvatar
                              ? Text(
                                  user.initials,
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        AppSpacing.gapW16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : 'Commuter',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              AppSpacing.gapH4,
                              Text(
                                user.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH16,

                  // Profile Completion Section (if incomplete)
                  if (!user.isProfileComplete) ...[
                    HomeProfileCompletionCard(user: user),
                    AppSpacing.gapH16,
                  ],

                  // Menu Items Card
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ProfileMenuItem(
                          icon: AppIcons.user,
                          title: l10n.personalInfo,
                          onTap: () => context.push('/complete-profile'),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.notification,
                          title: l10n.notificationSettings,
                          onTap: () => context.push(RoutePaths.notificationSettings),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.globe,
                          title: l10n.language,
                          trailingText: AppLocaleController.instance.isArabic ? 'العربية' : 'English',
                          onTap: () => _showLanguageSelector(context),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.headphones,
                          title: l10n.support,
                          onTap: () => _showSupportDialog(context),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.info,
                          title: l10n.aboutAmomy,
                          onTap: () => _showAboutDialog(context),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.shield,
                          title: l10n.privacyPolicy,
                          onTap: () => _showPrivacyPolicy(context),
                        ),
                        const Divider(height: 1, indent: 56, color: AppColors.borderSubtle),
                        _ProfileMenuItem(
                          icon: AppIcons.fileText,
                          title: l10n.termsAndConditions,
                          onTap: () => _showTerms(context),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapH24,

                  // Destructive Sign Out Button
                  AppButton(
                    label: l10n.signOut,
                    variant: AppButtonVariant.danger,
                    icon: AppIcons.logOut,
                    isFullWidth: true,
                    onPressed: () => _confirmSignOut(context),
                  ),
                  AppSpacing.gapBottomNav,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapW8,
            ],
            const Icon(
              AppIcons.arrowForward,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
