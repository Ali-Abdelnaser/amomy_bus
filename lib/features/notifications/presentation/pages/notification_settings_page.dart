import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../cubit/notification_preferences_cubit.dart';
import '../cubit/notification_preferences_state.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationPreferencesCubit(
        repository: getIt<NotificationRepository>(),
        notificationService: getIt.isRegistered<NotificationService>()
            ? getIt<NotificationService>()
            : null,
      )..loadPreferences(),
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const BackButtonIcon(),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          l10n.notificationSettingsTitle,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body:
          BlocBuilder<
            NotificationPreferencesCubit,
            NotificationPreferencesState
          >(
            builder: (context, state) {
              if (state is NotificationPreferencesLoading ||
                  state is NotificationPreferencesInitial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NotificationPreferencesError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.warningCircle,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<NotificationPreferencesCubit>()
                              .loadPreferences(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is NotificationPreferencesLoaded) {
                final p = state.preferences;
                final isMasterOn = p.allEnabled;

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  children: [
                    // 1. OS Permission Warning Banner (if denied)
                    if (state.isOsPermissionDenied) ...[
                      _buildOsWarningBanner(context),
                      const SizedBox(height: 20),
                    ],

                    // 2. Master Toggle Card
                    _buildMasterToggleCard(context, p.allEnabled),
                    const SizedBox(height: 24),

                    // 3. Category Section Header
                    Text(
                      l10n.notificationCategories,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. Categories Card List
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // A. Service & General Updates
                          _buildCategoryRow(
                            context: context,
                            icon: AppIcons.notification,
                            title: l10n.serviceUpdatesTitle,
                            subtitle: l10n.serviceUpdatesDescription,
                            value: p.serviceUpdates,
                            isMasterOn: isMasterOn,
                            onChanged: (val) {
                              context
                                  .read<NotificationPreferencesCubit>()
                                  .toggleCategory(
                                    NotificationPreferenceCategory
                                        .serviceUpdates,
                                    val,
                                  );
                            },
                          ),
                          const Divider(height: 1, indent: 64),

                          // B. Booking Updates
                          _buildCategoryRow(
                            context: context,
                            icon: AppIcons.ticket,
                            title: l10n.bookingUpdatesTitle,
                            subtitle: l10n.bookingUpdatesDescription,
                            value: p.bookingUpdates,
                            isMasterOn: isMasterOn,
                            onChanged: (val) {
                              context
                                  .read<NotificationPreferencesCubit>()
                                  .toggleCategory(
                                    NotificationPreferenceCategory
                                        .bookingUpdates,
                                    val,
                                  );
                            },
                          ),
                          const Divider(height: 1, indent: 64),

                          // C. Wallet & Top-up
                          _buildCategoryRow(
                            context: context,
                            icon: AppIcons.wallet,
                            title: l10n.walletUpdatesTitle,
                            subtitle: l10n.walletUpdatesDesc,
                            value: p.walletUpdates,
                            isMasterOn: isMasterOn,
                            onChanged: (val) {
                              context
                                  .read<NotificationPreferencesCubit>()
                                  .toggleCategory(
                                    NotificationPreferenceCategory
                                        .walletUpdates,
                                    val,
                                  );
                            },
                          ),
                          const Divider(height: 1, indent: 64),

                          // D. Trip & Bus Tracking
                          _buildCategoryRow(
                            context: context,
                            icon: AppIcons.bus,
                            title: l10n.tripUpdatesTitle,
                            subtitle: l10n.tripUpdatesDesc,
                            value: p.tripUpdates,
                            isMasterOn: isMasterOn,
                            onChanged: (val) {
                              context
                                  .read<NotificationPreferencesCubit>()
                                  .toggleCategory(
                                    NotificationPreferenceCategory.tripUpdates,
                                    val,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
    );
  }

  Widget _buildOsWarningBanner(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.warningCircle,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.notificationsDisabledInDevice,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.notificationsDisabledInDeviceDescription,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.warning,
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(AppIcons.settings, size: 16),
              label: Text(
                l10n.enableInDeviceSettings,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () {
                context
                    .read<NotificationPreferencesCubit>()
                    .requestDevicePermission();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggleCard(BuildContext context, bool allEnabled) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: const Icon(
              AppIcons.notification,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.allNotifications,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.allNotificationsDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: allEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              context.read<NotificationPreferencesCubit>().toggleMaster(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool isMasterOn,
    required ValueChanged<bool> onChanged,
  }) {
    final effectiveValue = isMasterOn ? value : false;
    final iconColor = isMasterOn ? AppColors.primary : AppColors.textTertiary;
    final titleColor = isMasterOn
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMasterOn
                  ? AppColors.primaryLight
                  : AppColors.surfaceSoft,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: effectiveValue,
            activeTrackColor: AppColors.primary,
            onChanged: isMasterOn ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
