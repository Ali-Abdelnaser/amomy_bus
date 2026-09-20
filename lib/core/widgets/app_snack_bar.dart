import 'package:flutter/material.dart';
import '../error/app_error_mapper.dart';
import '../icons/app_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Supported types for AppSnackBar
enum AppSnackbarType {
  success,
  error,
  warning,
  info,
}

/// Centralized SnackBar manager for Amomy Bus following brand guidelines.
abstract final class AppSnackBar {
  /// Shows a generic AppSnackBar based on [type].
  static void show(
    BuildContext context, {
    required dynamic message,
    AppSnackbarType type = AppSnackbarType.info,
  }) {
    switch (type) {
      case AppSnackbarType.success:
        showSuccess(context, message.toString());
      case AppSnackbarType.error:
        showError(context, message);
      case AppSnackbarType.warning:
        showWarning(context, message.toString());
      case AppSnackbarType.info:
        showInfo(context, message.toString());
    }
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.success,
      icon: AppIcons.checkCircle,
    );
  }

  /// Shows an error snackbar. Maps technical errors / backend codes / exceptions
  /// through [AppErrorMapper] to ensure no raw technical message is shown to users.
  static void showError(BuildContext context, dynamic errorOrMessage) {
    final localizedMessage = AppErrorMapper.map(context, errorOrMessage);
    _show(
      context: context,
      message: localizedMessage,
      backgroundColor: AppColors.error,
      icon: AppIcons.error,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: AppIcons.warningCircle,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.primary,
      icon: AppIcons.info,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          margin: const EdgeInsets.all(AppSpacing.s16),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              AppSpacing.gapW12,
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Convenience function for showAppSnackBar
void showAppSnackBar(
  BuildContext context, {
  required dynamic message,
  AppSnackbarType type = AppSnackbarType.info,
}) {
  AppSnackBar.show(context, message: message, type: type);
}

