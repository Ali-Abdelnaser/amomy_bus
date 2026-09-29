import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/app_update_info.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
  });

  Future<void> _openStoreUrl(BuildContext context) async {
    final rawUrl = updateInfo.storeUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) return;

    try {
      final uri = Uri.parse(rawUrl.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      developer.log('Failed to launch store URL: $e', name: 'APP_UPDATE');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isForce = updateInfo.forceUpdate;
    final messageText = (updateInfo.message != null &&
            updateInfo.message!.trim().isNotEmpty)
        ? updateInfo.message!.trim()
        : (isForce ? l10n.forceUpdateMessage : l10n.defaultUpdateMessage);

    return PopScope(
      canPop: !isForce,
      onPopInvokedWithResult: (didPop, result) {},
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Dialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Update badge / icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.arrowUpCircle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                AppSpacing.gapH16,

                // Title
                Text(
                  l10n.newUpdateAvailable,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Version Chip (if provided)
                if (updateInfo.latestVersion != null &&
                    updateInfo.latestVersion!.trim().isNotEmpty) ...[
                  AppSpacing.gapH8,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12,
                      vertical: AppSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.radiusCircular,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      l10n.appVersionLabel(updateInfo.latestVersion!.trim()),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],

                AppSpacing.gapH12,

                // Message
                Text(
                  messageText,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),

                AppSpacing.gapH24,

                // Action Buttons
                if (isForce) ...[
                  AppButton(
                    text: l10n.updateNow,
                    isFullWidth: true,
                    variant: ButtonVariant.primary,
                    onPressed: () => _openStoreUrl(context),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: l10n.updateLater,
                          variant: ButtonVariant.secondary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      AppSpacing.gapW12,
                      Expanded(
                        child: AppButton(
                          text: l10n.updateNow,
                          variant: ButtonVariant.primary,
                          onPressed: () => _openStoreUrl(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAppUpdateDialog({
  required BuildContext context,
  required AppUpdateInfo updateInfo,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !updateInfo.forceUpdate,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (dialogContext) => AppUpdateDialog(updateInfo: updateInfo),
  );
}
