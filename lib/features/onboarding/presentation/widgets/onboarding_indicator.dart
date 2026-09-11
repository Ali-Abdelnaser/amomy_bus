import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Clean animated page indicator following AMOMY Design System.
/// Active pill width ~24px with primary color #01589F.
/// Inactive dot width 8px with light neutral color.
class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsetsDirectional.only(end: 8),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
