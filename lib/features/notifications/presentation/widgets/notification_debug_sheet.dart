import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/notification_diagnostic_data.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

class NotificationDebugSheet extends StatefulWidget {
  const NotificationDebugSheet({super.key});

  static Future<void> show(BuildContext context) {
    if (!kDebugMode) return Future.value();
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationDebugSheet(),
    );
  }

  @override
  State<NotificationDebugSheet> createState() => _NotificationDebugSheetState();
}

class _NotificationDebugSheetState extends State<NotificationDebugSheet> {
  NotificationDiagnosticData? _diagnostics;
  bool _isLoading = true;
  String? _actionMessage;
  bool _isActionRunning = false;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (getIt.isRegistered<NotificationService>()) {
      final data = await getIt<NotificationService>().getDiagnostics();
      if (mounted) {
        setState(() {
          _diagnostics = data;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runAction(String label, Future<void> Function() action) async {
    if (_isActionRunning) return;
    setState(() {
      _isActionRunning = true;
      _actionMessage = 'Running $label...';
    });

    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _actionMessage = 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isActionRunning = false);
        await _refreshDiagnostics();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _diagnostics;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(AppIcons.info, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Notification Diagnostics',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(AppIcons.refresh, size: 20),
                  onPressed: _refreshDiagnostics,
                  tooltip: 'Refresh Status',
                ),
                IconButton(
                  icon: const Icon(AppIcons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Action Message banner
          if (_actionMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primaryLight,
              child: Row(
                children: [
                  if (_isActionRunning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(AppIcons.checkCircle, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _actionMessage!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

          // Body
          Expanded(
            child: _isLoading && d == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Diagnostics Action Buttons
                      Text(
                        'Direct Test Actions',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // 1. Direct Local Notification Test
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            icon: const Icon(AppIcons.notification, size: 16),
                            label: const Text('Test Local Notification'),
                            onPressed: () => _runAction('Local Test', () async {
                              final local = getIt.isRegistered<LocalNotificationService>()
                                  ? getIt<LocalNotificationService>()
                                  : LocalNotificationService();
                              final ok = await local.showTestLocalNotification();
                              if (mounted) {
                                setState(() => _actionMessage =
                                    ok ? 'Local notification displayed successfully' : 'Failed to display local notification');
                              }
                            }),
                          ),

                          // 2. Test Push Now (Self-test backend)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            icon: const Icon(AppIcons.refresh, size: 16),
                            label: const Text('Test Push Now'),
                            onPressed: () => _runAction('Push Now', () async {
                              if (getIt.isRegistered<NotificationService>()) {
                                final res = await getIt<NotificationService>().executeSelfTest();
                                if (mounted) {
                                  setState(() => _actionMessage = res.success
                                      ? 'Push sent (delivered: ${res.delivered}/${res.totalDevices})'
                                      : 'Push failed: ${res.error ?? res.message}');
                                }
                              }
                            }),
                          ),

                          // 3. Test Push in 10s (Background testing)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            icon: const Icon(AppIcons.clock, size: 16),
                            label: const Text('Test Push (10s Delay)'),
                            onPressed: () => _runAction('10s Delayed Push', () async {
                              if (getIt.isRegistered<NotificationService>()) {
                                final res = await getIt<NotificationService>()
                                    .executeSelfTest(delaySeconds: 10);
                                if (mounted) {
                                  setState(() => _actionMessage = res.success
                                      ? 'Delayed push dispatched! Background app now to test.'
                                      : 'Delayed push failed: ${res.error ?? res.message}');
                                }
                              }
                            }),
                          ),

                          // 4. Force Request Permission
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            icon: const Icon(AppIcons.checkCircle, size: 16),
                            label: const Text('Request Permission'),
                            onPressed: () => _runAction('Request Permission', () async {
                              if (getIt.isRegistered<NotificationService>()) {
                                final settings = await getIt<NotificationService>()
                                    .requestPermission(isManual: true);
                                if (mounted) {
                                  setState(() => _actionMessage =
                                      'Permission result: ${settings?.authorizationStatus.name ?? "null"}');
                                }
                              }
                            }),
                          ),

                          // 5. Force Sync Device Token
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: AppTextStyles.labelSmall,
                            ),
                            icon: const Icon(AppIcons.refresh, size: 16),
                            label: const Text('Sync Token'),
                            onPressed: () => _runAction('Sync Token', () async {
                              if (getIt.isRegistered<NotificationService>()) {
                                final ok = await getIt<NotificationService>().syncDeviceToken();
                                if (mounted) {
                                  setState(() => _actionMessage =
                                      ok ? 'Token synced successfully' : 'Token sync failed');
                                }
                              }
                            }),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      Text(
                        'System Diagnostic Status',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (d != null) ...[
                        _buildDiagnosticRow(
                          'Firebase initialized',
                          '${d.firebaseInitialized}',
                          isPositive: d.firebaseInitialized,
                        ),
                        _buildDiagnosticRow(
                          'Notification permission',
                          d.notificationPermission,
                          isPositive: d.notificationPermission == 'authorized' ||
                              d.notificationPermission == 'provisional',
                        ),
                        _buildDiagnosticRow(
                          'Android POST_NOTIFICATIONS',
                          d.androidPostNotifications,
                          isPositive: d.androidPostNotifications == 'granted' ||
                              d.androidPostNotifications == 'notRequired',
                        ),
                        _buildDiagnosticRow(
                          'FCM token',
                          d.fcmTokenAvailable ? 'available' : 'missing',
                          isPositive: d.fcmTokenAvailable,
                        ),
                        _buildDiagnosticRow(
                          'FCM token length',
                          '${d.fcmTokenLength}',
                        ),
                        _buildDiagnosticRow(
                          'FCM token suffix',
                          d.fcmTokenSuffix,
                        ),
                        _buildDiagnosticRow(
                          'Token registered in Supabase',
                          d.tokenRegisteredInSupabase,
                          isPositive: d.tokenRegisteredInSupabase == 'true',
                        ),
                        _buildDiagnosticRow(
                          'Active token row',
                          d.activeTokenRow,
                          isPositive: d.activeTokenRow == 'true',
                        ),
                        _buildDiagnosticRow(
                          'Local notification service initialized',
                          '${d.localNotificationServiceInitialized}',
                          isPositive: d.localNotificationServiceInitialized,
                        ),
                        _buildDiagnosticRow(
                          'Android notification channel',
                          d.androidNotificationChannel,
                          isPositive: d.androidNotificationChannel == 'created',
                        ),
                        _buildDiagnosticRow(
                          'Channel ID',
                          d.channelId,
                        ),
                        _buildDiagnosticRow(
                          'Foreground listener attached',
                          '${d.foregroundListenerAttached}',
                          isPositive: d.foregroundListenerAttached,
                        ),
                        _buildDiagnosticRow(
                          'Background handler registered',
                          '${d.backgroundHandlerRegistered}',
                          isPositive: d.backgroundHandlerRegistered,
                        ),
                        _buildDiagnosticRow(
                          'Last foreground FCM message',
                          d.lastForegroundFcmMessage,
                        ),
                        _buildDiagnosticRow(
                          'Last local notification show attempt',
                          d.lastLocalNotificationShowAttempt,
                        ),
                        _buildDiagnosticRow(
                          'Last local notification result',
                          d.lastLocalNotificationResult,
                          isPositive: d.lastLocalNotificationResult == 'success',
                        ),
                        _buildDiagnosticRow(
                          'Last self-test request',
                          d.lastSelfTestRequest,
                        ),
                        _buildDiagnosticRow(
                          'Last self-test backend result',
                          d.lastSelfTestBackendResult,
                          isPositive: d.lastSelfTestBackendResult == 'success',
                        ),
                        _buildDiagnosticRow(
                          'Last FCM provider result',
                          d.lastFcmProviderResult,
                          isPositive: d.lastFcmProviderResult == 'success',
                        ),
                        _buildDiagnosticRow(
                          'Last inbox refresh',
                          d.lastInboxRefresh,
                        ),
                        _buildDiagnosticRow(
                          'Unread count',
                          d.unreadCount,
                        ),
                        _buildDiagnosticRow(
                          'Current lifecycle',
                          d.currentLifecycle,
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Diagnostics unavailable (Service not registered)'),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow(String label, String value, {bool? isPositive}) {
    Color badgeColor = AppColors.surfaceSoft;
    Color textColor = AppColors.textPrimary;

    if (isPositive == true) {
      badgeColor = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
    } else if (isPositive == false && value != 'none' && value != 'unknown') {
      badgeColor = AppColors.error.withValues(alpha: 0.15);
      textColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
