import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
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

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUpdatePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        UpdatePasswordRequested(newPassword: _newPasswordController.text),
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
        } else if (state is PasswordUpdatedSuccessfully) {
          AppSnackBar.showSuccess(context, l10n.passwordUpdatedSuccess);
          context.go('/login');
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
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Standardized Brand Header
                          AuthHeaderWidget(
                            title: l10n.resetPasswordTitle,
                            subtitle: l10n.resetPasswordSubtitle,
                            logoHeight: 280,
                          ).appFadeIn(),
                          AppSpacing.gapH20,

                          // New Password
                          AppPasswordField(
                            controller: _newPasswordController,
                            label: l10n.newPassword,
                            hint: l10n.passwordHint,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (val) => AppValidators.validatePassword(
                              val,
                              requiredMessage: l10n.validationRequired,
                              minLengthMessage: l10n.validationPasswordLength,
                              complexityMessage:
                                  l10n.validationPasswordComplexity,
                            ),
                          ).appSlideUp(
                            delay: const Duration(milliseconds: 200),
                          ),
                          AppSpacing.gapH16,

                          // Confirm Password
                          AppPasswordField(
                            controller: _confirmPasswordController,
                            label: l10n.confirmPassword,
                            hint: l10n.confirmPasswordHint,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: (val) =>
                                AppValidators.validateConfirmPassword(
                                  val,
                                  _newPasswordController.text,
                                  requiredMessage: l10n.validationRequired,
                                  mismatchMessage:
                                      l10n.validationPasswordMismatch,
                                ),
                          ).appSlideUp(
                            delay: const Duration(milliseconds: 250),
                          ),
                          AppSpacing.gapH24,

                          // Update Button
                          AppButton(
                            label: l10n.updatePassword,
                            icon: AppIcons.check,
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _onUpdatePressed,
                          ).appSlideUp(
                            delay: const Duration(milliseconds: 300),
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
