import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_paths.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/extensions/context_extensions.dart';
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

  const EmailVerificationPage({super.key, this.email});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  String _otpCode = '';
  int _countdownSeconds = 60;
  Timer? _countdownTimer;
  late String _cachedEmail;
  bool _hasError = false;
  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _lastShownInfoMessage;

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
    if (_isSubmitting || _isSuccess || _otpCode.length != 6) return;

    setState(() {
      _isSubmitting = true;
      _hasError = false;
    });

    context.read<AuthBloc>().add(
      VerifyOtpRequested(email: _effectiveEmail, token: _otpCode),
    );
  }

  void _onResendPressed() {
    if (_countdownSeconds > 0 || _isSubmitting || _isSuccess) return;

    final targetEmail = _effectiveEmail;
    if (targetEmail.isEmpty) {
      AppSnackBar.showError(context, context.l10n.validationEmailInvalid);
      return;
    }

    setState(() => _hasError = false);
    _lastShownInfoMessage = null;
    context.read<AuthBloc>().add(ResendOtpRequested(email: targetEmail));
    _startCountdown();
  }

  void _onChangeEmailPressed(BuildContext context) {
    if (_isSubmitting || _isSuccess) return;

    // 1. Cleanly reset pending verification/auth state and sign out pending session
    context.read<AuthBloc>().add(const SignOutRequested());

    // 2. Navigate to existing Sign Up / Register route
    context.go(RoutePaths.register);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailureState) {
          setState(() {
            _hasError = true;
            _isSubmitting = false;
          });
          AppSnackBar.showError(context, state.failure.message);
        } else if (state is EmailVerificationRequired &&
            state.infoMessage != null) {
          setState(() => _isSubmitting = false);
          if (_lastShownInfoMessage != state.infoMessage) {
            _lastShownInfoMessage = state.infoMessage;
            AppSnackBar.showSuccess(context, state.infoMessage!);
          }
        } else if (state is ProfileCompletionRequired) {
          setState(() {
            _isSubmitting = false;
            _isSuccess = true;
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!context.mounted) return;
            context.go(RoutePaths.completeProfile);
          });
        } else if (state is Authenticated) {
          setState(() {
            _isSubmitting = false;
            _isSuccess = true;
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!context.mounted) return;
            if (!state.user.isProfileComplete) {
              context.go(RoutePaths.completeProfile);
            } else {
              context.go(RoutePaths.home);
            }
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading || _isSubmitting;

        return AppLoadingOverlay(
          isLoading: isLoading,
          child: AppScaffold(
            // No top back button: user exits verification only via explicit Change Email
            appBar: null,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSpacing.gapH12,
                        AuthHeaderWidget(
                          title: l10n.verifyEmailTitle,
                          subtitle: l10n.verifyEmailSubtitle,
                          logoHeight: 280,
                        ).appFadeIn(),

                        if (_effectiveEmail.isNotEmpty) ...[
                          AppSpacing.gapH4,
                          Text(
                            _effectiveEmail,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                          ).appFadeIn(delay: const Duration(milliseconds: 200)),
                        ],

                        AppSpacing.gapH32,

                        // 6-digit OTP Field with iOS AutoFill, paste, haptics, shake on error, and success animation
                        AppOtpField(
                          length: 6,
                          hasError: _hasError,
                          isSuccess: _isSuccess,
                          autoFocus: true,
                          onChanged: (code) {
                            setState(() {
                              _otpCode = code;
                              if (_hasError) {
                                _hasError = false;
                              }
                            });
                          },
                        ).appSlideUp(delay: const Duration(milliseconds: 250)),

                        AppSpacing.gapH24,

                        // Primary Verify Code Button
                        AppButton(
                          label: l10n.verifyButton,
                          isFullWidth: true,
                          isLoading: isLoading,
                          onPressed:
                              (_otpCode.length == 6 &&
                                  !isLoading &&
                                  !_isSuccess)
                              ? _onVerifyPressed
                              : null,
                        ).appSlideUp(delay: const Duration(milliseconds: 300)),

                        AppSpacing.gapH8,

                        // Resend Countdown / Trigger
                        Center(
                          child: _countdownSeconds > 0
                              ? Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      l10n.didntReceiveCode,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      l10n.resendIn(_countdownSeconds),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                )
                              : Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      l10n.didntReceiveCode,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: isLoading
                                          ? null
                                          : _onResendPressed,
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          l10n.resendCode,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),

                        AppSpacing.gapH4,

                        // Change Email Action (Subtle inline text, no bordered pill)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                l10n.wrongEmailPrompt,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              InkWell(
                                onTap: () => _onChangeEmailPressed(context),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    l10n.changeEmailAction,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        AppSpacing.gapH12,
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
