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
import '../widgets/auth_header_widget.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignUpWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
        ),
      );
    }
  }

  void _onGooglePressed() {
    context.read<AuthBloc>().add(const SignInWithGoogleRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          AppSnackBar.showError(context, state.failure.message);
        } else if (state is EmailVerificationRequired) {
          context.go('/verify-email', extra: state.email);
        } else if (state is Authenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AppLoadingOverlay(
          isLoading: isLoading,
          child: AppScaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Standardized Brand Header
                            AuthHeaderWidget(
                              title: l10n.registerTitle,
                              subtitle: l10n.registerSubtitle,
                              logoHeight: 200,
                            ).appFadeIn(),
                            AppSpacing.gapH20,

                            // Full Name
                            AppTextField(
                              controller: _fullNameController,
                              label: l10n.fullName,
                              hint: l10n.fullNameHint,
                              prefixIcon: AppIcons.user,
                              autofillHints: const [AutofillHints.name],
                              validator: (val) =>
                                  AppValidators.validateFullName(
                                    val,
                                    requiredMessage: l10n.validationRequired,
                                    minLengthMessage: l10n.validationRequired,
                                  ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 100),
                            ),
                            AppSpacing.gapH12,

                            // Email
                            AppTextField(
                              controller: _emailController,
                              label: l10n.email,
                              hint: l10n.emailHint,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: AppIcons.email,
                              autofillHints: const [AutofillHints.email],
                              validator: (val) => AppValidators.validateEmail(
                                val,
                                requiredMessage: l10n.validationRequired,
                                invalidMessage: l10n.validationEmailInvalid,
                              ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 150),
                            ),
                            AppSpacing.gapH12,

                            // Password
                            AppPasswordField(
                              controller: _passwordController,
                              label: l10n.password,
                              hint: l10n.passwordHint,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (val) =>
                                  AppValidators.validatePassword(
                                    val,
                                    requiredMessage: l10n.validationRequired,
                                    minLengthMessage:
                                        l10n.validationPasswordLength,
                                    complexityMessage:
                                        l10n.validationPasswordComplexity,
                                  ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 200),
                            ),
                            AppSpacing.gapH12,

                            // Confirm Password
                            AppPasswordField(
                              controller: _confirmPasswordController,
                              label: l10n.confirmPassword,
                              hint: l10n.confirmPasswordHint,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: (val) =>
                                  AppValidators.validateConfirmPassword(
                                    val,
                                    _passwordController.text,
                                    requiredMessage: l10n.validationRequired,
                                    mismatchMessage:
                                        l10n.validationPasswordMismatch,
                                  ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 250),
                            ),
                            AppSpacing.gapH20,

                            // Create Account Button
                            AppButton(
                              label: l10n.createAccount,
                              icon: AppIcons.check,
                              isFullWidth: true,
                              isLoading: isLoading,
                              onPressed: _onRegisterPressed,
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 300),
                            ),
                            AppSpacing.gapH16,

                            // "Or Continue With" Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                                Padding(
                                  padding: AppSpacing.edgeInsetsH16,
                                  child: Text(
                                    l10n.orDivider,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppColors.border),
                                ),
                              ],
                            ),
                            AppSpacing.gapH12,

                            // Google Sign-In Button
                            GoogleSignInButton(
                              label: l10n.continueWithGoogle,
                              isLoading: isLoading,
                              onPressed: _onGooglePressed,
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 350),
                            ),
                            AppSpacing.gapH16,

                            // Already have account? Sign in
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.alreadyHaveAccount,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: Text(
                                    l10n.signInNow,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
