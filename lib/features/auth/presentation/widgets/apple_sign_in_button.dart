import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Reusable Apple Sign-In button:
/// - Background: Pure Black (Color(0xFF000000))
/// - Uses existing project SVG asset assets/apple.svg
/// - Text EXACTLY: 'Sign in with Apple' (or localized equivalent)
/// - Text color: White
/// - Same 48dp height, corner radius, padding, icon size (20dp), and loading state as Google button
class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? label;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF333333),
          disabledForegroundColor: Colors.white54,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
          padding: AppSpacing.edgeInsetsH16,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/apple.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  AppSpacing.gapW12,
                  Text(
                    label ?? 'Continue with Apple',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
