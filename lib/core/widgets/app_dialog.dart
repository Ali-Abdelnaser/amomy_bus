import 'package:flutter/material.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Centralized Dialog components and modal helper functions.
class AppDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  const AppDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
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
  final String buttonText;
  final VoidCallback? onConfirm;

  const AppAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
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
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
              ),
              AppSpacing.gapH16,
            ],
            Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            AppSpacing.gapH8,
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
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
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
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
            Text(title, style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
            AppSpacing.gapH8,
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            AppSpacing.gapH24,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelText,
                    variant: ButtonVariant.outline,
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
                    variant: isDestructive ? ButtonVariant.danger : ButtonVariant.primary,
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
    builder: (context) => AppDialog(
      title: title,
      content: content,
      actions: actions,
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
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      onConfirm: onConfirm,
      onCancel: onCancel,
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
    builder: (context) => AppAlertDialog(
      title: title,
      message: message,
      icon: AppIcons.error,
      iconColor: AppColors.error,
      buttonText: buttonText,
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
    builder: (context) => AppAlertDialog(
      title: title,
      message: message,
      icon: AppIcons.checkCircle,
      iconColor: AppColors.success,
      buttonText: buttonText,
      onConfirm: onConfirm,
    ),
  );
}

Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
  String buttonText = 'OK',
  VoidCallback? onConfirm,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AppAlertDialog(
      title: title,
      message: message,
      icon: AppIcons.info,
      iconColor: AppColors.primary,
      buttonText: buttonText,
      onConfirm: onConfirm,
    ),
  );
}
