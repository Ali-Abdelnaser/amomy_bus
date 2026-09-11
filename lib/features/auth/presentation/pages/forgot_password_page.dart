import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/validation/app_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SendPasswordResetRequested(
              email: _emailController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          AppSnackBar.showError(context, state.failure.message);
        } else if (state is PasswordResetEmailSent) {
          AppSnackBar.showSuccess(context, l10n.resetEmailSentSuccess);
          context.pop();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AppLoadingOverlay(
          isLoading: isLoading,
          child: AppScaffold(
            appBar: AppAppBar(
              title: l10n.forgotPasswordTitle,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.edgeInsetsA24,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.lock,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          ).appScaleIn(),
                          AppSpacing.gapH24,

                          Text(
                            l10n.forgotPasswordTitle,
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).appFadeIn(delay: const Duration(milliseconds: 100)),
                          AppSpacing.gapH8,
                          Text(
                            l10n.forgotPasswordSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ).appFadeIn(delay: const Duration(milliseconds: 150)),
                          AppSpacing.gapH32,

                          // Email field
                          AppTextField(
                            controller: _emailController,
                            label: l10n.email,
                            hint: l10n.emailHint,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: AppIcons.email,
                            validator: (val) => AppValidators.validateEmail(
                              val,
                              requiredMessage: l10n.validationRequired,
                              invalidMessage: l10n.validationEmailInvalid,
                            ),
                          ).appSlideUp(delay: const Duration(milliseconds: 200)),
                          AppSpacing.gapH24,

                          // Send button
                          AppButton(
                            label: l10n.sendResetInstructions,
                            icon: AppIcons.arrowForward,
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _onSendResetPressed,
                          ).appSlideUp(delay: const Duration(milliseconds: 250)),
                          AppSpacing.gapH24,

                          // Back to login
                          Center(
                            child: TextButton(
                              onPressed: () => context.pop(),
                              child: Text(
                                l10n.backToLogin,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
