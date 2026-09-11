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
import '../../../../core/widgets/app_date_picker_field.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null) {
        AppSnackBar.showWarning(context, context.l10n.selectGender);
        return;
      }
      if (_selectedDateOfBirth == null) {
        AppSnackBar.showWarning(context, context.l10n.selectDateOfBirth);
        return;
      }

      context.read<AuthBloc>().add(
        SignUpWithEmailRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: AppValidators.normalizeEgyptianPhone(_phoneController.text),
          gender: _selectedGender!,
          dateOfBirth: _selectedDateOfBirth!,
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
            appBar: AppAppBar(
              title: l10n.registerTitle,
              showBackButton: true,
              onBackPressed: () => context.pop(),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: AppSpacing.edgeInsetsA24,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.registerSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ).appFadeIn(),
                            AppSpacing.gapH24,

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
                            AppSpacing.gapH16,

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
                            AppSpacing.gapH16,

                            // Phone
                            AppTextField(
                              controller: _phoneController,
                              label: l10n.phone,
                              hint: l10n.phoneHint,
                              keyboardType: TextInputType.phone,
                              prefixIcon: AppIcons.phone,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              validator: (val) => AppValidators.validatePhone(
                                val,
                                requiredMessage: l10n.validationRequired,
                                invalidMessage: l10n.validationPhoneInvalid,
                              ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 200),
                            ),
                            AppSpacing.gapH16,

                            // Gender & Date of Birth Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gender Dropdown
                                Expanded(
                                  flex: 5,
                                  child: AppDropdown<String>(
                                    label: l10n.gender,
                                    hint: l10n.selectGender,
                                    selectedValue: _selectedGender,
                                    rawItems: const ['male', 'female'],
                                    itemLabel: (val) =>
                                        val == 'male' ? l10n.male : l10n.female,
                                    prefixIcon: const Icon(AppIcons.gender, color: AppColors.textSecondary, size: 20),
                                    onChanged: (val) {
                                      setState(() => _selectedGender = val);
                                    },
                                    validator: (val) =>
                                        AppValidators.validateGender(
                                          val,
                                          requiredMessage:
                                              l10n.validationRequired,
                                        ),
                                  ),
                                ),
                                AppSpacing.gapW12,

                                // Date of Birth Picker
                                Expanded(
                                  flex: 6,
                                  child: AppDatePickerField(
                                    label: l10n.dateOfBirth,
                                    hint: l10n.selectDateOfBirth,
                                    selectedDate: _selectedDateOfBirth,
                                    initialDate: DateTime(2000, 1, 1),
                                    firstDate: DateTime(1920),
                                    lastDate: DateTime.now(),
                                    prefixIcon: const Icon(AppIcons.birthday, color: AppColors.textSecondary, size: 20),
                                    onDateSelected: (date) {
                                      setState(
                                        () => _selectedDateOfBirth = date,
                                      );
                                    },
                                    validator: (val) =>
                                        AppValidators.validateDateOfBirth(
                                          val,
                                          requiredMessage:
                                              l10n.validationRequired,
                                        ),
                                  ),
                                ),
                              ],
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 250),
                            ),
                            AppSpacing.gapH16,

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
                              delay: const Duration(milliseconds: 300),
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
                                    _passwordController.text,
                                    requiredMessage: l10n.validationRequired,
                                    mismatchMessage:
                                        l10n.validationPasswordMismatch,
                                  ),
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 350),
                            ),
                            AppSpacing.gapH24,

                            // Create Account Button
                            AppButton(
                              label: l10n.createAccount,
                              icon: AppIcons.check,
                              isFullWidth: true,
                              isLoading: isLoading,
                              onPressed: _onRegisterPressed,
                            ).appSlideUp(
                              delay: const Duration(milliseconds: 400),
                            ),
                            AppSpacing.gapH24,

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
                                  onPressed: () => context.pop(),
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
