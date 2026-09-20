import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/topup_state.dart';

class TopUpStepIndicator extends StatelessWidget {
  final TopUpStep currentStep;

  const TopUpStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    if (currentStep == TopUpStep.pendingReview) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;

    final steps = [
      (step: TopUpStep.amount, title: l10n.stepPoints),
      (step: TopUpStep.instructions, title: l10n.stepPayment),
      (step: TopUpStep.details, title: l10n.stepConfirm),
    ];

    final currentIndex = steps.indexWhere((s) => s.step == currentStep);
    final activeIndex = currentIndex == -1 ? 0 : currentIndex;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _StepItem(
                stepNumber: i + 1,
                title: steps[i].title,
                isCompleted: i < activeIndex,
                isActive: i == activeIndex,
              ),
            ),
            if (i < steps.length - 1)
              _StepConnector(isCompleted: i < activeIndex),
          ],
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int stepNumber;
  final String title;
  final bool isCompleted;
  final bool isActive;

  const _StepItem({
    required this.stepNumber,
    required this.title,
    required this.isCompleted,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFF10B981)
                : (isActive ? AppColors.primary : const Color(0xFFF1F5F9)),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF10B981)
                  : (isActive ? AppColors.primary : const Color(0xFFCBD5E1)),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 5),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isActive
                ? FontWeight.w800
                : (isCompleted ? FontWeight.w600 : FontWeight.w500),
            color: isActive
                ? AppColors.primary
                : (isCompleted
                      ? AppColors.textPrimary
                      : const Color(0xFF94A3B8)),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: Text(title),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool isCompleted;

  const _StepConnector({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 2.5,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
