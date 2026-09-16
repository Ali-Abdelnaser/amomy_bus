import 'dart:ui';

import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Centralized Dialog components and modal helper functions.
enum AppDialogVariant { info, success, warning, destructive }

class _DialogBackdrop extends StatelessWidget {
  final Widget child;

  const _DialogBackdrop({required this.child});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: child,
    );
  }
}

class AppDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const AppDialog({super.key, this.title, required this.content, this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              AppSpacing.gapH16,
            ],
            content,
            if (actions != null && actions!.isNotEmpty) ...[
              AppSpacing.gapH24,
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alert Dialog for information, warnings, or errors
class AppAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String? illustrationPath;
  final String buttonText;
  final VoidCallback? onConfirm;

  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.illustrationPath,
    this.buttonText = 'OK',
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustrationPath != null) ...[
              Image.asset(illustrationPath!, height: 120, fit: BoxFit.contain),
              AppSpacing.gapH16,
            ] else if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 28,
                ),
              ),
              AppSpacing.gapH16,
            ],
            Text(
              title,
              style: AppTextStyles.headlineSmall,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH24,
            AppButton(
              text: buttonText,
              isFullWidth: true,
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation Dialog with Confirm and Cancel buttons
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final AppDialogVariant variant;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    AppDialogVariant? variant,
    required this.onConfirm,
    this.onCancel,
  }) : variant =
           variant ??
           (isDestructive
               ? AppDialogVariant.destructive
               : AppDialogVariant.info);

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (variant) {
      AppDialogVariant.destructive => AppColors.error,
      AppDialogVariant.warning => AppColors.warning,
      AppDialogVariant.success => AppColors.success,
      AppDialogVariant.info => AppColors.primary,
    };
    final accentBg = switch (variant) {
      AppDialogVariant.destructive => AppColors.errorLight,
      AppDialogVariant.warning => AppColors.warningLight,
      AppDialogVariant.success => AppColors.successLight,
      AppDialogVariant.info => AppColors.primaryLight,
    };
    final icon = switch (variant) {
      AppDialogVariant.destructive => AppIcons.warning,
      AppDialogVariant.warning => AppIcons.warningCircle,
      AppDialogVariant.success => AppIcons.checkCircle,
      AppDialogVariant.info => AppIcons.info,
    };

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            AppSpacing.gapH16,
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH8,
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapH24,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelText,
                    variant: ButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      onCancel?.call();
                    },
                  ),
                ),
                AppSpacing.gapW12,
                Expanded(
                  child: AppButton(
                    text: confirmText,
                    variant: isDestructive
                        ? ButtonVariant.danger
                        : ButtonVariant.primary,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog helper functions
Future<T?> showAppDialog<T>({
  required BuildContext context,
  String? title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) => _DialogBackdrop(
      child: AppDialog(title: title, content: content, actions: actions),
    ),
  );
}

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  AppDialogVariant? variant,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) => _DialogBackdrop(
      child: AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        variant: variant,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    ),
  );
}

Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) => _DialogBackdrop(
      child: AppAlertDialog(
        title: title,
        message: message,
        icon: AppIcons.error,
        iconColor: AppColors.error,
        buttonText: buttonText,
      ),
    ),
  );
}

Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) => _DialogBackdrop(
      child: AppAlertDialog(
        title: title,
        message: message,
        icon: AppIcons.checkCircle,
        iconColor: AppColors.success,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    ),
  );
}

Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? illustrationPath,
  String buttonText = 'OK',
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (context) => _DialogBackdrop(
      child: AppAlertDialog(
        title: title,
        message: message,
        illustrationPath: illustrationPath,
        icon: illustrationPath == null ? AppIcons.info : null,
        iconColor: AppColors.primary,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    ),
  );
}
