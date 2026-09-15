// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/wallet_preview.dart';
import '../../domain/usecases/complete_profile_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/get_wallet_preview_usecase.dart';
import '../../domain/usecases/resend_otp_usecase.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/sign_in_with_email_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_with_email_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../app/di/injection.dart';
import '../../../notifications/presentation/services/notification_service.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignInWithEmailUseCase _signInWithEmailUseCase;
  final SignUpWithEmailUseCase _signUpWithEmailUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final CompleteProfileUseCase _completeProfileUseCase;
  final SendPasswordResetUseCase _sendPasswordResetUseCase;
  final UpdatePasswordUseCase _updatePasswordUseCase;
  final GetWalletPreviewUseCase _getWalletPreviewUseCase;
  final SignOutUseCase _signOutUseCase;

  StreamSubscription<AppUser?>? _userSubscription;

  AuthBloc({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignInWithEmailUseCase signInWithEmailUseCase,
    required SignUpWithEmailUseCase signUpWithEmailUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required CompleteProfileUseCase completeProfileUseCase,
    required SendPasswordResetUseCase sendPasswordResetUseCase,
    required UpdatePasswordUseCase updatePasswordUseCase,
    required GetWalletPreviewUseCase getWalletPreviewUseCase,
    required SignOutUseCase signOutUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _signInWithEmailUseCase = signInWithEmailUseCase,
        _signUpWithEmailUseCase = signUpWithEmailUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _completeProfileUseCase = completeProfileUseCase,
        _sendPasswordResetUseCase = sendPasswordResetUseCase,
        _updatePasswordUseCase = updatePasswordUseCase,
        _getWalletPreviewUseCase = getWalletPreviewUseCase,
        _signOutUseCase = signOutUseCase,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInWithEmailRequested>(_onSignInWithEmailRequested);
    on<SignUpWithEmailRequested>(_onSignUpWithEmailRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
    on<ResendOtpRequested>(_onResendOtpRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<CompleteProfileRequested>(_onCompleteProfileRequested);
    on<SendPasswordResetRequested>(_onSendPasswordResetRequested);
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<AuthUserChangedInternal>(_onAuthUserChangedInternal);

    _userSubscription = _getCurrentUserUseCase.userStream.listen((user) {
      add(AuthUserChangedInternal(user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _getCurrentUserUseCase();
    await result.fold(
      onError: (failure) async => emit(const Unauthenticated()),
      onSuccess: (user) async {
        if (user == null) {
          emit(const Unauthenticated());
        } else {
          await _routeUser(user, emit);
        }
      },
    );
  }

  Future<void> _onSignInWithEmailRequested(
    SignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signInWithEmailUseCase(
      email: event.email,
      password: event.password,
    );
    await result.fold(
      onError: (failure) async => emit(AuthFailureState(failure)),
      onSuccess: (user) async => _routeUser(user, emit),
    );
  }

  Future<void> _onSignUpWithEmailRequested(
    SignUpWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _signUpWithEmailUseCase(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
      phone: event.phone,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
    );
    await result.fold(
      onError: (failure) async => emit(AuthFailureState(failure)),
      onSuccess: (user) async {
        if (!user.isEmailVerified) {
          emit(EmailVerificationRequired(
            email: event.email,
            infoMessage: 'Verification code sent to your email.',
          ));
        } else {
          await _routeUser(user, emit);
        }
      },
    );
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _verifyOtpUseCase(
      email: event.email,
      token: event.token,
    );
    await result.fold(
      onError: (failure) async => emit(AuthFailureState(failure)),
      onSuccess: (user) async => _routeUser(user, emit),
    );
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _resendOtpUseCase(email: event.email);
    result.fold(
      onError: (failure) => emit(AuthFailureState(failure)),
      onSuccess: (_) => emit(EmailVerificationRequired(
        email: event.email,
        infoMessage: 'Verification code resent successfully.',
      )),
    );
  }

  Future<void> _onSignInWithGoogleRequested(
    SignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    developer.log('AuthBloc: Starting Google Sign-In flow', name: 'AUTH');
    final result = await _signInWithGoogleUseCase(
      webClientId: event.webClientId,
    );
    await result.fold(
      onError: (failure) async {
        developer.log(
          'AuthBloc: Google Sign-In failed: ${failure.runtimeType} (${failure.message})',
          name: 'AUTH',
        );
        if (failure is AuthCancelledFailure) {
          // User cancelled/closed Google account selector - return to Unauthenticated cleanly
          emit(const Unauthenticated());
        } else {
          emit(AuthFailureState(failure));
        }
      },
      onSuccess: (user) async {
        developer.log(
          'AuthBloc: Google Sign-In successful for user ${user.id} (${user.email})',
          name: 'AUTH',
        );
        await _routeUser(user, emit);
      },
    );
  }

  Future<void> _onCompleteProfileRequested(
    CompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = switch (state) {
      Authenticated(:final user) => user,
      ProfileCompletionRequired(:final user) => user,
      _ => null,
    };
    final currentWallet = switch (state) {
      Authenticated(:final wallet) => wallet,
      _ => null,
    };

    if (currentUser == null) {
      developer.log(
        'AuthBloc: CompleteProfileRequested with no active user session',
        name: 'AUTH',
      );
      emit(const Unauthenticated());
      return;
    }

    emit(ProfileSaving(user: currentUser, wallet: currentWallet));
    final result = await _completeProfileUseCase(
      userId: currentUser.id,
      fullName: event.fullName,
      phone: event.phone,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
    );
    if (result.isError) {
      final failure = result.failureOrNull!;
      developer.log(
        'AuthBloc: CompleteProfileRequested failed for user ${currentUser.id}: ${failure.message}',
        name: 'AUTH',
      );
      emit(ProfileSaveFailure(
        user: currentUser,
        failure: failure,
        wallet: currentWallet,
      ));
    } else {
      await _routeUser(result.dataOrNull!, emit);
    }
  }

  Future<void> _onSendPasswordResetRequested(
    SendPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _sendPasswordResetUseCase(email: event.email);
    result.fold(
      onError: (failure) => emit(AuthFailureState(failure)),
      onSuccess: (_) => emit(PasswordResetEmailSent(event.email)),
    );
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _updatePasswordUseCase(newPassword: event.newPassword);
    result.fold(
      onError: (failure) => emit(AuthFailureState(failure)),
      onSuccess: (_) => emit(const PasswordUpdatedSuccessfully()),
    );
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    if (getIt.isRegistered<NotificationService>()) {
      try {
        await getIt<NotificationService>().deactivateCurrentToken();
      } catch (_) {}
    }
    await _signOutUseCase();
    emit(const Unauthenticated());
  }

  Future<void> _onAuthUserChangedInternal(
    AuthUserChangedInternal event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      // If a login/auth operation or profile saving is actively loading, do NOT cancel it with Unauthenticated
      if (state is AuthLoading || state is ProfileSaving) {
        developer.log(
          'AuthBloc: Received null auth stream event while in AuthLoading/ProfileSaving - preserving active auth flow',
          name: 'AUTH',
        );
        return;
      }
      if (state is! Unauthenticated && state is! AuthInitial) {
        emit(const Unauthenticated());
      }
    } else {
      await _routeUser(user, emit);
    }
  }

  Future<void> _routeUser(AppUser user, Emitter<AuthState> emit) async {
    if (!user.isEmailVerified) {
      emit(EmailVerificationRequired(email: user.email));
      return;
    }

    // Profile completion is no longer a blocking startup state.
    // Incomplete users enter Home directly, and profile completion is guarded before booking.
    WalletPreview? wallet;
    final walletResult = await _getWalletPreviewUseCase(user.id);
    wallet = walletResult.dataOrNull;

    emit(Authenticated(
      user: user,
      wallet: wallet,
    ));

    if (getIt.isRegistered<NotificationService>()) {
      unawaited(getIt<NotificationService>().syncDeviceToken());
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
