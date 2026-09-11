import 'package:flutter/material.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Standardized Brand Header for Auth Screens (Login, Register, Forgot Password, Verify Email, etc.)
class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double logoHeight;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.logoHeight = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Brand Logo
        Center(
          child: Hero(
            tag: 'app_logo',
            child: Image.asset(
              AppAssets.logoTransparent,
              height: logoHeight,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Title (Right below logo with compact spacing)
        Text(
          title,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        if (subtitle != null) ...[
          AppSpacing.gapH4,
          Text(
            subtitle!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
