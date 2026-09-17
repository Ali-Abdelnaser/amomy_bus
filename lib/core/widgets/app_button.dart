import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outline, text, danger }

typedef AppButtonVariant = ButtonVariant;

/// Production-ready button supporting primary, secondary, outline, text, danger variants,
/// loading states, icons, full width, and responsive minimum dimensions.
class AppButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonVariant variant;
  final dynamic icon;
  final double? width;
  final double height;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    this.label,
    this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 48.0,
    this.isFullWidth = false,
    this.textStyle,
    this.padding,
  }) : assert(
         label != null || text != null,
         'Either label or text must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final displayLabel = label ?? text ?? '';

    Widget? iconWidget;
    if (icon is Widget) {
      iconWidget = icon as Widget;
    } else if (icon is IconData) {
      iconWidget = Icon(icon as IconData, size: 20);
    }

    Color progressColor;
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.danger:
        progressColor = Colors.white;
        break;
      case ButtonVariant.outline:
      case ButtonVariant.text:
        progressColor = AppColors.primary;
        break;
    }

    final childWidget = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconWidget != null) ...[iconWidget, AppSpacing.gapW8],
              Flexible(
                child: Text(
                  displayLabel,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledBackgroundColor: AppColors.disabledBackground,
            disabledForegroundColor: AppColors.disabled,
            textStyle: AppTextStyles.labelLarge,
            padding: padding,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusLg,
            ),
            elevation: 0,
          ),
          child: childWidget,
        );
        break;
      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.disabledBackground,
            disabledForegroundColor: AppColors.disabled,
            textStyle: AppTextStyles.labelLarge,
            padding: padding,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            elevation: 0,
          ),
          child: childWidget,
        );
        break;
      case ButtonVariant.outline:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.disabled,
            side: const BorderSide(color: AppColors.border, width: 1.5),
            textStyle: AppTextStyles.labelLarge,
            padding: padding,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
          ),
          child: childWidget,
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.disabled,
            textStyle: AppTextStyles.labelLarge,
            padding: padding,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusSm,
            ),
          ),
          child: childWidget,
        );
        break;
      case ButtonVariant.danger:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.disabledBackground,
            disabledForegroundColor: AppColors.disabled,
            textStyle: AppTextStyles.labelLarge,
            padding: padding,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.radiusMd,
            ),
            elevation: 0,
          ),
          child: childWidget,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: height, child: button);
    }

    if (width != null) {
      return SizedBox(width: width, height: height, child: button);
    }

    return SizedBox(height: height, child: button);
  }
}

/// Reusable icon button following brand styling
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon, size: size, color: color ?? AppColors.textPrimary),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 24,
    );

    if (backgroundColor != null) {
      button = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: button,
      );
    }

    return button;
  }
}
