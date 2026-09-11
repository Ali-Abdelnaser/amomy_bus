import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/assets/app_assets.dart';
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
          AppSnackBar.showError(context, state.failure.message);
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
                  padding: AppSpacing.edgeInsetsA24,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Brand Logo
                            Center(
                              child: Hero(
                                tag: 'app_logo',
                                child: Image.asset(
                                  AppAssets.logoTransparent,
                                  height: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ).appFadeIn(),
                            AppSpacing.gapH24,

                            // Header
                            Text(
                              l10n.loginTitle,
                              style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ).appFadeIn(delay: const Duration(milliseconds: 100)),
                            AppSpacing.gapH8,
                            Text(
                              l10n.loginSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ).appFadeIn(delay: const Duration(milliseconds: 150)),
                            AppSpacing.gapH32,

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
                            ).appSlideUp(delay: const Duration(milliseconds: 200)),
                            AppSpacing.gapH16,

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
                            ).appSlideUp(delay: const Duration(milliseconds: 250)),
                            AppSpacing.gapH8,

                            // Forgot Password Link
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: () => context.push('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: AppSpacing.edgeInsetsH8,
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

                            // Login Button
                            AppButton(
                              label: l10n.login,
                              icon: AppIcons.arrowForward,
                              isFullWidth: true,
                              isLoading: isLoading,
                              onPressed: _onLoginPressed,
                            ).appSlideUp(delay: const Duration(milliseconds: 300)),
                            AppSpacing.gapH24,

                            // Divider: OR
                            Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: AppSpacing.edgeInsetsH16,
                                  child: Text(
                                    l10n.orDivider,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: AppColors.border)),
                              ],
                            ),
                            AppSpacing.gapH24,

                            // Google Sign-In Button
                            GoogleSignInButton(
                              label: l10n.continueWithGoogle,
                              isLoading: isLoading,
                              onPressed: _onGooglePressed,
                            ).appSlideUp(delay: const Duration(milliseconds: 350)),
                            AppSpacing.gapH32,

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
