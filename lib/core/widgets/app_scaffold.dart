import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Reusable App Bar following brand guidelines with sensible defaults.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = true,
    this.backgroundColor,
    this.bottom,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton && onBackPressed != null) {
      effectiveLeading = IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 20,
          color: AppColors.textPrimary,
        ),
        onPressed: onBackPressed,
      );
    }

    return AppBar(
      scrolledUnderElevation: 0,
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                )
              : null),
      actions: actions,
      leading: effectiveLeading,
      automaticallyImplyLeading: showBackButton && automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.surface,
      elevation: elevation,

      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Reusable Scaffold providing consistent background, safe areas, and optional app bar.
class AppScaffold extends StatelessWidget {
  final String? title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool resizeToAvoidBottomInset;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    this.title,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar =
        appBar ??
        (title != null ? AppAppBar(title: title, actions: actions) : null);

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: effectiveAppBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(top: safeAreaTop, bottom: false, child: body),
    );
  }
}
