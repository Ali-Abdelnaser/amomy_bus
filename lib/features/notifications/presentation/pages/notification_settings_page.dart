import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_repository.dart';
import '../cubit/notification_preferences_cubit.dart';
import '../cubit/notification_preferences_state.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';
import '../widgets/notification_debug_sheet.dart';
import '../widgets/notification_test_lab_sheet.dart';

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
    final locale = Localizations.localeOf(context);
    final isAr = locale.languageCode == 'ar';

    final pageTitle = isAr ? 'إعدادات الإشعارات' : 'Notification Settings';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(AppIcons.arrowBack, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          pageTitle,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<
            NotificationPreferencesCubit,
            NotificationPreferencesState
          >(
            builder: (context, state) {
              final isTester =
                  state is NotificationPreferencesLoaded && state.isTester;
              if (!isTester) return const SizedBox.shrink();

              return IconButton(
                key: const Key('notification_test_lab_button'),
                icon: const Icon(
                  LucideIcons.flaskConical,
                  color: AppColors.primary,
                  size: 22,
                ),
                tooltip: isAr ? 'مختبر الإشعارات' : 'Notification Test Lab',
                onPressed: () => NotificationTestLabSheet.show(context),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationPreferencesCubit, NotificationPreferencesState>(
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
                      child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // 1. OS Permission Warning Banner (if denied)
                if (state.isOsPermissionDenied) ...[
                  _buildOsWarningBanner(context, isAr),
                  const SizedBox(height: 20),
                ],

                // 2. Master Toggle Card
                _buildMasterToggleCard(context, p.allEnabled, isAr),
                const SizedBox(height: 24),

                // 3. Category Section Header
                Text(
                  isAr ? 'فئات الإشعارات' : 'Notification Categories',
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
                        title: isAr
                            ? 'تحديثات الخدمة والإشعارات العامة'
                            : 'Service & General Updates',
                        subtitle: isAr
                            ? 'إعلانات وتحديثات مهمة تخص خدمة عمومي.'
                            : 'Important AMOMY service announcements.',
                        value: p.serviceUpdates,
                        isMasterOn: isMasterOn,
                        onChanged: (val) {
                          context
                              .read<NotificationPreferencesCubit>()
                              .toggleCategory(
                                NotificationPreferenceCategory.serviceUpdates,
                                val,
                              );
                        },
                      ),
                      const Divider(height: 1, indent: 64),

                      // B. Booking Updates
                      _buildCategoryRow(
                        context: context,
                        icon: AppIcons.ticket,
                        title: isAr ? 'تحديثات الحجز' : 'Booking Updates',
                        subtitle: isAr
                            ? 'تأكيد الحجز والإلغاء وتغيير المقعد.'
                            : 'Confirmation, cancellation and seat changes.',
                        value: p.bookingUpdates,
                        isMasterOn: isMasterOn,
                        onChanged: (val) {
                          context
                              .read<NotificationPreferencesCubit>()
                              .toggleCategory(
                                NotificationPreferenceCategory.bookingUpdates,
                                val,
                              );
                        },
                      ),
                      const Divider(height: 1, indent: 64),

                      // C. Wallet & Top-up
                      _buildCategoryRow(
                        context: context,
                        icon: AppIcons.wallet,
                        title: isAr ? 'المحفظة والشحن' : 'Wallet & Top-up',
                        subtitle: isAr
                            ? 'حالة طلبات الشحن وحركات النقاط.'
                            : 'Top-up approvals, rejections and point transactions.',
                        value: p.walletUpdates,
                        isMasterOn: isMasterOn,
                        onChanged: (val) {
                          context
                              .read<NotificationPreferencesCubit>()
                              .toggleCategory(
                                NotificationPreferenceCategory.walletUpdates,
                                val,
                              );
                        },
                      ),
                      const Divider(height: 1, indent: 64),

                      // D. Trip & Bus Tracking
                      _buildCategoryRow(
                        context: context,
                        icon: AppIcons.bus,
                        title: isAr
                            ? 'الرحلات وتتبع الأتوبيس'
                            : 'Trip & Bus Tracking',
                        subtitle: isAr
                            ? 'تحديثات الرحلة وتنبيه اقتراب الأتوبيس من محطتك.'
                            : 'Trip updates and alerts when your bus is approaching.',
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

                // 5. Developer Diagnostics Section (Debug Only)
                if (kDebugMode) ...[
                  const SizedBox(height: 36),
                  _buildDebugDiagnosticsSection(context, isAr),
                ],
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOsWarningBanner(BuildContext context, bool isAr) {
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
                  isAr
                      ? 'الإشعارات متوقفة من إعدادات الجهاز'
                      : 'Notifications disabled in device settings',
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
            isAr
                ? 'يرجى السماح للإشعارات من إعدادات الهاتف لتتمكن من استلام تنبيهات الرحلات والمحفظة.'
                : 'Please enable notifications in your device settings to receive trip and wallet alerts.',
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
                isAr ? 'تفعيل من إعدادات الجهاز' : 'Enable in Device Settings',
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

  Widget _buildMasterToggleCard(
    BuildContext context,
    bool allEnabled,
    bool isAr,
  ) {
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
                  isAr ? 'كل الإشعارات' : 'All Notifications',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr
                      ? 'التحكم في وصول الإشعارات لتطبيق عمومي'
                      : 'Master toggle for all push notifications',
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

  Widget _buildDebugDiagnosticsSection(BuildContext context, bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.info, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Developer Diagnostics (Debug Only)',
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(AppIcons.info, size: 14),
                label: const Text('Notification Debug Sheet'),
                onPressed: () => NotificationDebugSheet.show(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.notification, size: 14),
                label: const Text('Test Local Notification'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final local = getIt.isRegistered<LocalNotificationService>()
                      ? getIt<LocalNotificationService>()
                      : LocalNotificationService();
                  final ok = await local.showTestLocalNotification();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Local notification shown'
                            : 'Failed to show local notification',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.refresh, size: 14),
                label: const Text('Test Push Now'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (getIt.isRegistered<NotificationService>()) {
                    final res = await getIt<NotificationService>()
                        .executeSelfTest();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          res.success
                              ? 'Push sent (${res.delivered}/${res.totalDevices})'
                              : 'Failed: ${res.error}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.clock, size: 14),
                label: const Text('Test Push (10s Delay)'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (getIt.isRegistered<NotificationService>()) {
                    final res = await getIt<NotificationService>()
                        .executeSelfTest(delaySeconds: 10);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          res.success
                              ? 'Delayed push dispatched! Background app now.'
                              : 'Failed: ${res.error}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              OutlinedButton.icon(
                icon: const Icon(AppIcons.refresh, size: 14),
                label: const Text('Sync Token'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (getIt.isRegistered<NotificationService>()) {
                    final ok = await getIt<NotificationService>()
                        .syncDeviceToken();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Token synced' : 'Token sync failed',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
