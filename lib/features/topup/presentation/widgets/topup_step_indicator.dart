import 'package:flutter/material.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../cubit/topup_state.dart';

class TopUpStepIndicator extends StatelessWidget {
  final TopUpStep currentStep;

  const TopUpStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep == TopUpStep.pendingSuccess) {
      return const SizedBox.shrink();
    }

    final steps = [
      TopUpStep.amount,
      TopUpStep.paymentMethod,
      TopUpStep.transferDetails,
      TopUpStep.review,
    ];

    final currentIndex = steps.indexOf(currentStep);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            final isCompleted = lineIndex < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? AppColors.primary : AppColors.border,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;

          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.primary
                  : (isCurrent ? AppColors.primaryLight : AppColors.surfaceSoft),
              border: Border.all(
                color: isCompleted || isCurrent ? AppColors.primary : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(AppIcons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isCurrent ? AppColors.primary : AppColors.textTertiary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }
}
