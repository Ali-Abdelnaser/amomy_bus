import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_header_widget.dart';

class EmailVerificationPage extends StatefulWidget {
  final String? email;

  const EmailVerificationPage({
    super.key,
    this.email,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  String _otpCode = '';
  int _countdownSeconds = 60;
  Timer? _countdownTimer;
  late String _cachedEmail;

  @override
  void initState() {
    super.initState();
    _cachedEmail = widget.email ?? '';
    _startCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachedEmail.isEmpty) {
      final state = context.read<AuthBloc>().state;
      if (state is EmailVerificationRequired && state.email.isNotEmpty) {
        _cachedEmail = state.email;
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownSeconds = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        if (mounted) {
          setState(() => _countdownSeconds--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  String get _effectiveEmail {
    if (widget.email != null && widget.email!.isNotEmpty) {
      return widget.email!;
    }
    if (_cachedEmail.isNotEmpty) {
      return _cachedEmail;
    }
    final state = context.read<AuthBloc>().state;
    if (state is EmailVerificationRequired && state.email.isNotEmpty) {
      _cachedEmail = state.email;
      return state.email;
    }
    return '';
  }

  void _onVerifyPressed() {
    if (_otpCode.length != 6) {
      AppSnackBar.showWarning(context, context.l10n.validationOtpInvalid);
      return;
    }

    context.read<AuthBloc>().add(
          VerifyOtpRequested(
            email: _effectiveEmail,
            token: _otpCode,
          ),
        );
  }

  void _onResendPressed() {
    if (_countdownSeconds > 0) return;

    final targetEmail = _effectiveEmail;
    if (targetEmail.isEmpty) {
      AppSnackBar.showError(context, context.l10n.validationEmailInvalid);
      return;
    }

    context.read<AuthBloc>().add(
          ResendOtpRequested(email: targetEmail),
        );
    _startCountdown();
  }

  void _navigateBackToLogin(BuildContext context) {
    context.read<AuthBloc>().add(const SignOutRequested());
    try {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.login);
      }
    } catch (_) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          AppSnackBar.showError(context, state.failure.message);
        } else if (state is EmailVerificationRequired && state.infoMessage != null) {
          AppSnackBar.showSuccess(context, state.infoMessage!);
        } else if (state is ProfileCompletionRequired) {
          context.go(RoutePaths.completeProfile);
        } else if (state is Authenticated) {
          context.go(RoutePaths.home);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return AppLoadingOverlay(
          isLoading: isLoading,
          child: AppScaffold(
            appBar: AppAppBar(
              showBackButton: true,
              onBackPressed: () => _navigateBackToLogin(context),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Standardized Brand Header
                        AuthHeaderWidget(
                          title: l10n.verifyEmailTitle,
                          logoHeight: 180,
                        ).appFadeIn(),
                        AppSpacing.gapH8,

                        // Subtitle with Email
                        Text(
                          l10n.verifyEmailSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ).appFadeIn(delay: const Duration(milliseconds: 150)),
                        AppSpacing.gapH4,
                        if (_effectiveEmail.isNotEmpty)
                          Text(
                            _effectiveEmail,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                          ).appFadeIn(delay: const Duration(milliseconds: 200)),
                        AppSpacing.gapH24,

                        // 6-digit OTP Field
                        AppOtpField(
                          length: 6,
                          onChanged: (code) => setState(() => _otpCode = code),
                          onCompleted: (code) {
                            _otpCode = code;
                            _onVerifyPressed();
                          },
                        ).appSlideUp(delay: const Duration(milliseconds: 250)),
                        AppSpacing.gapH20,

                        // Verify Button
                        AppButton(
                          label: l10n.verifyButton,
                          icon: AppIcons.check,
                          isFullWidth: true,
                          isLoading: isLoading,
                          onPressed: _otpCode.length == 6 ? _onVerifyPressed : null,
                        ).appSlideUp(delay: const Duration(milliseconds: 300)),
                        AppSpacing.gapH20,

                        // Resend Code with Countdown
                        Center(
                          child: _countdownSeconds > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        AppIcons.clock,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      AppSpacing.gapW8,
                                      Text(
                                        l10n.resendIn(_countdownSeconds),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : TextButton(
                                  onPressed: isLoading ? null : _onResendPressed,
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(AppIcons.refresh, size: 18),
                                      AppSpacing.gapW8,
                                      Text(
                                        l10n.resendCode,
                                        style: AppTextStyles.labelLarge.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        AppSpacing.gapH20,

                        // Explicit Return to Login Button
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateBackToLogin(context),
                            icon: const Icon(AppIcons.arrowBack, size: 18),
                            label: Text(
                              l10n.backToLogin,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }
}

