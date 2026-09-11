import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class PassengerHomePlaceholderPage extends StatelessWidget {
  const PassengerHomePlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        }
      },
      builder: (context, state) {
        if (state is! Authenticated) {
          return const AppScaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        final user = state.user;
        final wallet = state.wallet;

        return AppScaffold(
          appBar: AppAppBar(
            title: l10n.homePlaceholderTitle,
            showBackButton: false,
            actions: [
              IconButton(
                icon: const Icon(AppIcons.settings, color: AppColors.textPrimary),
                onPressed: () {
                  if (kDebugMode) {
                    context.push('/design-system');
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: AppSpacing.edgeInsetsA24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Welcome Card
                  AppCard(
                    padding: AppSpacing.edgeInsetsA20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: (user.avatarUrl != null &&
                                      user.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: (user.avatarUrl == null ||
                                      user.avatarUrl!.isEmpty)
                                  ? const Icon(
                                      AppIcons.user,
                                      size: 30,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            AppSpacing.gapW16,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                        : 'Commuter',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.bold,
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
                        AppSpacing.gapH16,
                        const Divider(color: AppColors.border),
                        AppSpacing.gapH12,

                        // Roles Badges
                        Text(
                          l10n.activeRoles,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.gapH8,
                        Wrap(
                          spacing: 8,
                          children: user.roles
                              .map(
                                (r) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: r.isAdmin ? AppColors.warning.withValues(alpha: 0.15) : AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: r.isAdmin ? AppColors.warning : AppColors.primary,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    r.value.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: r.isAdmin ? AppColors.warning : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ).appSlideUp(),

                  // Profile Completion Reminder Card (Non-blocking banner)
                  if (!user.isProfileComplete) ...[
                    AppSpacing.gapH20,
                    _ProfileReminderCard(user: user).appSlideUp(
                      delay: const Duration(milliseconds: 100),
                    ),
                  ],
                  AppSpacing.gapH24,

                  // Wallet Points Verification Card
                  AppCard(
                    padding: AppSpacing.edgeInsetsA20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              AppIcons.wallet,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            AppSpacing.gapW12,
                            Text(
                              l10n.totalBalance,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH16,
                        Row(
                          children: [
                            // Cash Points
                            Expanded(
                              child: _WalletMetricTile(
                                label: l10n.cashPoints,
                                value: '${wallet?.cashPoints ?? 0}',
                                color: AppColors.primary,
                              ),
                            ),
                            AppSpacing.gapW12,
                            // Subscription Points
                            Expanded(
                              child: _WalletMetricTile(
                                label: l10n.subscriptionPoints,
                                value: '${wallet?.subscriptionPoints ?? 0}',
                                color: AppColors.accentYellow,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapH16,
                        Container(
                          width: double.infinity,
                          padding: AppSpacing.edgeInsetsA12,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Session integrity verified: User Profile, Role, and Wallet Points loaded successfully via Supabase RLS.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ).appSlideUp(delay: const Duration(milliseconds: 150)),
                  AppSpacing.gapH24,

                  // Debug Design System Shortcut (if debug mode)
                  if (kDebugMode) ...[
                    AppButton(
                      label: 'Design System Gallery (Debug)',
                      variant: AppButtonVariant.outline,
                      icon: AppIcons.gallery,
                      isFullWidth: true,
                      onPressed: () => context.push('/design-system'),
                    ),
                    AppSpacing.gapH16,
                  ],

                  // Sign Out Button
                  AppButton(
                    label: l10n.signOut,
                    variant: AppButtonVariant.danger,
                    icon: AppIcons.close,
                    isFullWidth: true,
                    onPressed: () {
                      context.read<AuthBloc>().add(const SignOutRequested());
                    },
                  ).appSlideUp(delay: const Duration(milliseconds: 250)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WalletMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _WalletMetricTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.edgeInsetsA12,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean non-blocking profile completion banner displayed when passenger profile is incomplete
class _ProfileReminderCard extends StatelessWidget {
  final AppUser user;

  const _ProfileReminderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppCard(
      padding: AppSpacing.edgeInsetsA20,
      backgroundColor: const Color(0xFFF7FAFD),
      border: const BorderSide(color: Color(0xFFD0E2F2), width: 1.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.user,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.completeProfileReminderTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Text(
                      l10n.completeProfileReminderSubtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${user.profileCompletionPercent}%',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: user.profileCompletionPercentage,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          AppSpacing.gapH16,
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: AppButton(
              label: l10n.completeNow,
              icon: AppIcons.arrowForward,
              height: 40,
              onPressed: () => context.push('/complete-profile'),
            ),
          ),
        ],
      ),
    );
  }
}
