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
                    if (state.isTester) ...[
                      const SizedBox(height: 24),
                      _NotificationTestLab(
                        notificationService:
                            getIt.isRegistered<NotificationService>()
                            ? getIt<NotificationService>()
                            : null,
                      ),
                    ],
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

class _NotificationTestLab extends StatefulWidget {
  final NotificationService? notificationService;

  const _NotificationTestLab({required this.notificationService});

  @override
  State<_NotificationTestLab> createState() => _NotificationTestLabState();
}

class _NotificationTestLabState extends State<_NotificationTestLab> {
  bool _isSendingLocal = false;
  bool _isRequestingRemote = false;

  Future<void> _sendLocalTest() async {
    final service = widget.notificationService;
    if (service == null) return;

    setState(() => _isSendingLocal = true);
    final shown = await service.localNotifications.showForegroundNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: context.l10n.notificationTestLabLocalTitle,
      body: context.l10n.notificationTestLabLocalSubtitle,
      payload: const {'screen': 'notifications', 'type': 'system'},
    );
    if (!mounted) return;
    setState(() => _isSendingLocal = false);
    _showMessage(
      shown
          ? context.l10n.notificationTestLabLocalShown
          : context.l10n.notificationTestLabRequestFailed,
    );
  }

  Future<void> _requestRemotePush() async {
    final service = widget.notificationService;
    if (service == null) return;

    setState(() => _isRequestingRemote = true);
    final result = await service.executeSelfTest(delaySeconds: 10);
    if (!mounted) return;
    setState(() => _isRequestingRemote = false);
    _showMessage(
      result.requestAccepted
          ? context.l10n.notificationTestLabRemoteRequested
          : context.l10n.notificationTestLabRequestFailed,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canTest = widget.notificationService != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.notificationTestLabTitle,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _TestLabAction(
            icon: AppIcons.notification,
            title: l10n.notificationTestLabLocalTitle,
            subtitle: l10n.notificationTestLabLocalSubtitle,
            label: l10n.notificationTestLabLocalButton,
            isLoading: _isSendingLocal,
            onPressed: canTest && !_isRequestingRemote ? _sendLocalTest : null,
          ),
          const SizedBox(height: 12),
          _TestLabAction(
            icon: AppIcons.phone,
            title: l10n.notificationTestLabRemoteTitle,
            subtitle: l10n.notificationTestLabRemoteSubtitle,
            label: l10n.notificationTestLabRemoteButton,
            isLoading: _isRequestingRemote,
            onPressed: canTest && !_isSendingLocal ? _requestRemotePush : null,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

class _TestLabAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const _TestLabAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: isPrimary
                    ? ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: _TestLabButtonLabel(
                          label: label,
                          isLoading: isLoading,
                          color: Colors.white,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: onPressed,
                        child: _TestLabButtonLabel(
                          label: label,
                          isLoading: isLoading,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TestLabButtonLabel extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Color color;

  const _TestLabButtonLabel({
    required this.label,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    }
    return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
