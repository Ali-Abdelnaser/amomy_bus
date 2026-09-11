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

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AuthBloc>().state;
      if (state is ProfileCompletionRequired) {
        final user = state.user;
        _fullNameController.text = user.fullName;
        if (user.phone != null && user.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
        }
        if (user.gender != null && user.gender!.isNotEmpty) {
          _selectedGender = user.gender;
        }
        if (user.dateOfBirth != null) {
          _selectedDateOfBirth = user.dateOfBirth;
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
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
            CompleteProfileRequested(
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
              title: l10n.completeProfileTitle,
              showBackButton: false,
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
                          // Top Icon Badge
                          Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.user,
                                size: 36,
                                color: AppColors.primary,
                              ),
                            ),
                          ).appScaleIn(),
                          AppSpacing.gapH24,

                          Text(
                            l10n.completeProfileTitle,
                            style: AppTextStyles.headlineLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).appFadeIn(delay: const Duration(milliseconds: 100)),
                          AppSpacing.gapH8,
                          Text(
                            l10n.completeProfileSubtitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ).appFadeIn(delay: const Duration(milliseconds: 150)),
                          AppSpacing.gapH32,

                          // Full Name
                          AppTextField(
                            controller: _fullNameController,
                            label: l10n.fullName,
                            hint: l10n.fullNameHint,
                            prefixIcon: AppIcons.user,
                            validator: (val) => AppValidators.validateFullName(
                              val,
                              requiredMessage: l10n.validationRequired,
                            ),
                          ).appSlideUp(delay: const Duration(milliseconds: 200)),
                          AppSpacing.gapH16,

                          // Phone
                          AppTextField(
                            controller: _phoneController,
                            label: l10n.phone,
                            hint: l10n.phoneHint,
                            keyboardType: TextInputType.phone,
                            prefixIcon: AppIcons.phone,
                            validator: (val) => AppValidators.validatePhone(
                              val,
                              requiredMessage: l10n.validationRequired,
                              invalidMessage: l10n.validationPhoneInvalid,
                            ),
                          ).appSlideUp(delay: const Duration(milliseconds: 250)),
                          AppSpacing.gapH16,

                          // Gender & Date of Birth Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gender
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
                                  validator: (val) => AppValidators.validateGender(
                                    val,
                                    requiredMessage: l10n.validationRequired,
                                  ),
                                ),
                              ),
                              AppSpacing.gapW12,

                              // Date of Birth
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
                                    setState(() => _selectedDateOfBirth = date);
                                  },
                                  validator: (val) => AppValidators.validateDateOfBirth(
                                    val,
                                    requiredMessage: l10n.validationRequired,
                                  ),
                                ),
                              ),
                            ],
                          ).appSlideUp(delay: const Duration(milliseconds: 300)),
                          AppSpacing.gapH32,

                          // Submit Button
                          AppButton(
                            label: l10n.saveAndContinue,
                            icon: AppIcons.arrowForward,
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: _onSavePressed,
                          ).appSlideUp(delay: const Duration(milliseconds: 350)),
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
