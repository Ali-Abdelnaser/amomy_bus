import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Centralized dimensions and helper math for AMOMY bottom sheets.
class AmomySheetDimensions {
  const AmomySheetDimensions._();

  static const double navBarHeight = 66.0;
  static const double sheetCornerRadius = 24.0;
  static const double dragHandleWidth = 40.0;
  static const double dragHandleHeight = 4.0;
  static const Color dragHandleColor = Color(0xFFD0D5DD);

  /// Computes the exact bottom clearance required so the sheet stops cleanly
  /// above the floating bottom navigation bar, or floats above the keyboard when active.
  static double computeBottomClearance(
    BuildContext context, {
    bool hasBottomNav = true,
    double extraGap = 10.0,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final keyboardInset = mediaQuery.viewInsets.bottom;

    // When virtual keyboard is open, float cleanly above the keyboard
    if (keyboardInset > 0) {
      return keyboardInset + 12.0;
    }

    // When inside the passenger shell that renders FloatingBottomNavBar
    if (hasBottomNav) {
      final navBarMargin = bottomPadding > 0 ? bottomPadding + 8.0 : 16.0;
      final navBarTotalHeight = navBarHeight + navBarMargin;
      return navBarTotalHeight + extraGap;
    }

    // Default standalone bottom padding
    return (bottomPadding > 0 ? bottomPadding : 12.0) + extraGap;
  }
}

/// Standardized single internal drag handle for all AMOMY modal bottom sheets.
class AmomyDragHandle extends StatelessWidget {
  const AmomyDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AmomySheetDimensions.dragHandleWidth,
        height: AmomySheetDimensions.dragHandleHeight,
        decoration: BoxDecoration(
          color: AmomySheetDimensions.dragHandleColor,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

/// Standardized container for AMOMY floating bottom sheets.
///
/// Features:
/// - Floating rounded card (24px radius) that ends above the floating bottom nav bar.
/// - Single centered internal drag handle.
/// - Smooth entry and dismiss animations without bounce.
/// - Dynamic keyboard inset adaptation.
class AmomySheetContainer extends StatelessWidget {
  final Widget child;
  final bool hasBottomNav;
  final double? maxHeight;
  final EdgeInsetsGeometry? padding;
  final bool showHandle;
  final double topGap;

  const AmomySheetContainer({
    super.key,
    required this.child,
    this.hasBottomNav = true,
    this.maxHeight,
    this.padding,
    this.showHandle = true,
    this.topGap = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bottomClearance = AmomySheetDimensions.computeBottomClearance(
      context,
      hasBottomNav: hasBottomNav,
    );

    Widget content = Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(AmomySheetDimensions.sheetCornerRadius),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? (MediaQuery.of(context).size.height * 0.85),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHandle) ...[
                const AmomyDragHandle(),
                SizedBox(height: topGap),
              ],
              Flexible(
                fit: FlexFit.loose,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );

    if (!disableAnimations) {
      content = content
          .animate()
          .fadeIn(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          )
          .slideY(
            begin: 0.08,
            end: 0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
    }

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: bottomClearance,
      ),
      child: content,
    );
  }
}

/// Helper function to display any modal bottom sheet with AMOMY's standard styling.
Future<T?> showAmomyModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool hasBottomNav = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => builder(ctx),
  );
}

/// Reusable modal bottom sheet wrapper following brand guidelines.
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool isScrollable;
  final bool hasBottomNav;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.isScrollable = false,
    this.hasBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    return AmomySheetContainer(
      hasBottomNav: hasBottomNav,
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
          if (isScrollable)
            Flexible(child: SingleChildScrollView(child: content))
          else
            content,
          if (actions != null && actions!.isNotEmpty) ...[
            AppSpacing.gapH24,
            ...actions!,
          ],
        ],
      ),
    );
  }
}

/// Helper function to display an AppBottomSheet
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  String? title,
  required Widget content,
  List<Widget>? actions,
  bool isScrollable = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool hasBottomNav = true,
  bool useRootNavigator = false,
}) {
  return showAmomyModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    hasBottomNav: hasBottomNav,
    useRootNavigator: useRootNavigator,
    builder: (ctx) => AppBottomSheet(
      title: title,
      content: content,
      actions: actions,
      isScrollable: isScrollable,
      hasBottomNav: hasBottomNav,
    ),
  );
}
