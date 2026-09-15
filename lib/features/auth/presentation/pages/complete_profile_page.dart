import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/validation/app_validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_date_picker_field.dart';
import '../../../../core/widgets/app_gender_selector.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/app_user.dart';
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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  String? _avatarUrl;
  bool _initialized = false;
  bool _isInitialCompletion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AuthBloc>().state;
      AppUser? user;
      if (state is Authenticated) {
        user = state.user;
      } else if (state is ProfileCompletionRequired) {
        user = state.user;
      }

      if (user != null) {
        _isInitialCompletion = !user.isProfileComplete;
        if (_fullNameController.text.isEmpty && user.fullName.isNotEmpty) {
          _fullNameController.text = user.fullName;
        }
        if (_emailController.text.isEmpty && user.email.isNotEmpty) {
          _emailController.text = user.email;
        }
        if (_phoneController.text.isEmpty && user.phone != null && user.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
        }
        if (_selectedGender == null && user.gender != null && user.gender!.isNotEmpty) {
          _selectedGender = user.gender!.toLowerCase();
        }
        if (_selectedDateOfBirth == null && user.dateOfBirth != null) {
          _selectedDateOfBirth = user.dateOfBirth;
        }
        _avatarUrl = user.avatarUrl;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
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
              gender: _selectedGender!.toLowerCase(),
              dateOfBirth: _selectedDateOfBirth!,
            ),
          );
    }
  }

  void _onBackOrCancel(BuildContext context) {
    if (!_isInitialCompletion) {
      // Edit mode: return normally without signing out
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        try {
          context.go(RoutePaths.home);
        } catch (_) {
          // In unit/widget tests without GoRouter ancestor
        }
      }
    } else {
      // Initial required completion: sign out and return cleanly to Login
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }

  String _mapProfileErrorMessage(BuildContext context, Failure failure) {
    developer.log(
      'Profile save failure: ${failure.runtimeType} [code=${failure.statusCode}]: ${failure.message}',
      name: 'PROFILE',
    );
    // Preserved friendly validation messages (e.g., duplicate phone/email)
    if (failure is ValidationFailure) {
      return failure.message;
    }
    if (failure is NetworkFailure) {
      return failure.message;
    }
    // Safe localized error message without raw database or internal exception leaks
    return context.l10n.profileUpdateFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileSaveFailure) {
          AppSnackBar.showError(context, _mapProfileErrorMessage(context, state.failure));
        } else if (state is AuthFailureState) {
          AppSnackBar.showError(context, _mapProfileErrorMessage(context, state.failure));
        } else if (state is Authenticated &&
            state is! ProfileSaving &&
            state is! ProfileSaveFailure &&
            state.user.isProfileComplete) {
          if (!_isInitialCompletion && canPop) {
            context.pop();
          } else {
            try {
              context.go(RoutePaths.home);
            } catch (_) {
              // In unit/widget tests without GoRouter ancestor
            }
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading || state is ProfileSaving;
        final pageTitle = _isInitialCompletion
            ? l10n.completeProfileTitle
            : l10n.personalInfo;

        return AppLoadingOverlay(
          isLoading: isLoading,
          child: AppScaffold(
            appBar: AppAppBar(
              title: pageTitle,
              showBackButton: true,
              onBackPressed: () => _onBackOrCancel(context),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Profile Photo / Avatar
                          Center(
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                                  ? const Icon(
                                      AppIcons.user,
                                      size: 46,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ).appScaleIn(),
                          AppSpacing.gapH16,

                          // Header Title
                          Text(
                            pageTitle,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ).appFadeIn(delay: const Duration(milliseconds: 100)),

                          if (_isInitialCompletion) ...[
                            AppSpacing.gapH6,
                            Text(
                              l10n.completeProfileSubtitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ).appFadeIn(delay: const Duration(milliseconds: 150)),
                          ],
                          AppSpacing.gapH24,

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

                          // Email (Read-only account identity)
                          AppTextField(
                            controller: _emailController,
                            label: l10n.email,
                            hint: l10n.emailHint,
                            enabled: false,
                            prefixIcon: AppIcons.email,
                          ).appSlideUp(delay: const Duration(milliseconds: 220)),
                          AppSpacing.gapH16,

                          // Phone Number
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

                          // Gender Selection Cards
                          AppGenderSelector(
                            label: l10n.gender,
                            selectedGender: _selectedGender,
                            onChanged: (gender) {
                              setState(() => _selectedGender = gender);
                            },
                            validator: (val) => AppValidators.validateGender(
                              val ?? _selectedGender,
                              requiredMessage: l10n.validationRequired,
                            ),
                          ).appSlideUp(delay: const Duration(milliseconds: 280)),
                          AppSpacing.gapH16,

                          // Date of Birth Field
                          AppDatePickerField(
                            label: l10n.dateOfBirth,
                            hint: l10n.selectDateOfBirth,
                            selectedDate: _selectedDateOfBirth,
                            initialDate: DateTime(2000, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                            prefixIcon: const Icon(
                              AppIcons.birthday,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            onDateSelected: (date) {
                              setState(() => _selectedDateOfBirth = date);
                            },
                            validator: (val) => AppValidators.validateDateOfBirth(
                              val ?? _selectedDateOfBirth,
                              requiredMessage: l10n.validationRequired,
                            ),
                          ).appSlideUp(delay: const Duration(milliseconds: 300)),
                          AppSpacing.gapH24,

                          // Primary CTA
                          AppButton(
                            label: l10n.saveAndContinue,
                            icon: AppIcons.check,
                            isFullWidth: true,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _onSavePressed,
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
