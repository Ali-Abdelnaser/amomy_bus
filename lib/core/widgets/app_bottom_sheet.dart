import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Reusable modal bottom sheet wrapper following brand guidelines.
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool isScrollable;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
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
          AppSpacing.gapH20,
        ],
      ),
    );

    return SafeArea(child: body);
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
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollable,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadius.topXxl,
    ),
    builder: (context) => AppBottomSheet(
      title: title,
      content: content,
      actions: actions,
      isScrollable: isScrollable,
    ),
  );
}
