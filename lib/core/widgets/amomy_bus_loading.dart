import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AmomyLoadingSize {
  small(width: 48, height: 36),
  medium(width: 80, height: 60),
  large(width: 120, height: 90);

  final double width;
  final double height;

  const AmomyLoadingSize({required this.width, required this.height});
}

/// Official AMOMY branded bus loading animation widget
class AmomyBusLoading extends StatelessWidget {
  final AmomyLoadingSize size;
  final String? message;

  const AmomyBusLoading({
    super.key,
    this.size = AmomyLoadingSize.medium,
    this.message,
  });

  const AmomyBusLoading.small({
    super.key,
    this.message,
  }) : size = AmomyLoadingSize.small;

  const AmomyBusLoading.medium({
    super.key,
    this.message,
  }) : size = AmomyLoadingSize.medium;

  const AmomyBusLoading.large({
    super.key,
    this.message,
  }) : size = AmomyLoadingSize.large;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.p16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/animations/bus_loading.gif',
              width: size.width,
              height: size.height,
              fit: BoxFit.contain,
            ),
            if (message != null) ...[
              AppSpacing.gapH12,
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
