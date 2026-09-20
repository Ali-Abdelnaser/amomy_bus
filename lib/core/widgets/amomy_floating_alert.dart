import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AmomyAlertVariant { success, info, warning, error }

class AmomyFloatingAlert extends StatelessWidget {
  final String title;
  final String? message;
  final AmomyAlertVariant variant;
  final VoidCallback? onDismiss;

  const AmomyFloatingAlert({
    super.key,
    required this.title,
    this.message,
    this.variant = AmomyAlertVariant.info,
    this.onDismiss,
  });

  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    String? message,
    AmomyAlertVariant variant = AmomyAlertVariant.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove previous alert if active
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FloatingAlertHost(
        title: title,
        message: message,
        variant: variant,
        duration: duration,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final (bgBase, borderColor, iconColor, iconData) = switch (variant) {
      AmomyAlertVariant.success => (
        AppColors.successLight.withValues(alpha: 0.92),
        AppColors.success.withValues(alpha: 0.3),
        AppColors.success,
        Icons.check_circle_rounded,
      ),
      AmomyAlertVariant.info => (
        AppColors.infoLight.withValues(alpha: 0.92),
        AppColors.primary.withValues(alpha: 0.3),
        AppColors.primary,
        Icons.info_rounded,
      ),
      AmomyAlertVariant.warning => (
        AppColors.warningLight.withValues(alpha: 0.94),
        AppColors.warning.withValues(alpha: 0.35),
        AppColors.warning,
        Icons.warning_amber_rounded,
      ),
      AmomyAlertVariant.error => (
        AppColors.errorLight.withValues(alpha: 0.94),
        AppColors.error.withValues(alpha: 0.35),
        AppColors.error,
        Icons.error_outline_rounded,
      ),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgBase,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(iconData, size: 18, color: iconColor),
                ),
              ),
              AppSpacing.gapW10,
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (message != null && message!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onDismiss != null) ...[
                AppSpacing.gapW8,
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingAlertHost extends StatefulWidget {
  final String title;
  final String? message;
  final AmomyAlertVariant variant;
  final Duration duration;
  final VoidCallback onDismiss;

  const _FloatingAlertHost({
    required this.title,
    this.message,
    required this.variant,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_FloatingAlertHost> createState() => _FloatingAlertHostState();
}

class _FloatingAlertHostState extends State<_FloatingAlertHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90 + MediaQuery.paddingOf(context).bottom,
      left: 20,
      right: 20,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _offsetAnimation,
            child: Material(
              color: Colors.transparent,
              child: AmomyFloatingAlert(
                title: widget.title,
                message: widget.message,
                variant: widget.variant,
                onDismiss: _dismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
