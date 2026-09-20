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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignInWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
          AppSnackBar.showError(context, state.failure);
        } else if (state is EmailVerificationRequired) {
          context.go('/verify-email', extra: state.email);
        } else if (state is ProfileCompletionRequired) {
          context.go('/complete-profile');
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Standardized Brand Header
                            AuthHeaderWidget(
                              title: l10n.loginTitle,
                              subtitle: l10n.loginSubtitle,
                              logoHeight: 280,
                            ).appFadeIn(),
                            AppSpacing.gapH20,

                            // Email Field
                            AppTextField(
                              controller: _emailController,
                              label: l10n.email,
                              hint: l10n.emailHint,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.email,
                                AutofillHints.username,
                              ],
                              prefixIcon: AppIcons.email,
                              validator: (val) => AppValidators.validateEmail(
                                val,
                                requiredMessage: l10n.validationRequired,
                                invalidMessage: l10n.validationEmailInvalid,
                              ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 200),
                            ),
                            AppSpacing.gapH12,

                            // Password Field
                            AppPasswordField(
                              controller: _passwordController,
                              label: l10n.password,
                              hint: l10n.passwordHint,
                              autofillHints: const [AutofillHints.password],
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return l10n.validationRequired;
                                }
                                return null;
                              },
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 250),
                            ),

                            AppSpacing.gapH12,
                            // Forgot Password Link
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: Text(
                                  l10n.forgotPassword,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            AppSpacing.gapH16,

                            // Login Button (no arrow, larger text)
                            AppButton(
                              label: l10n.login,
                              isFullWidth: true,
                              height: 50,
                              textStyle: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.textOnPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              isLoading: isLoading,
                              onPressed: _onLoginPressed,
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 300),
                            ),
                            AppSpacing.gapH12,

                            // Divider: OR
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
                            AppSpacing.gapH12,

                            // Don't have an account? Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.dontHaveAccount,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: Text(
                                    l10n.registerNow,
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
