// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
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
    final result = await _signInWithGoogleUseCase(
      webClientId: event.webClientId,
    );
    await result.fold(
      onError: (failure) async => emit(AuthFailureState(failure)),
      onSuccess: (user) async => _routeUser(user, emit),
    );
  }

  Future<void> _onCompleteProfileRequested(
    CompleteProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = state is ProfileCompletionRequired
        ? (state as ProfileCompletionRequired).user
        : null;

    if (currentUser == null) {
      emit(const Unauthenticated());
      return;
    }

    emit(const AuthLoading());
    final result = await _completeProfileUseCase(
      userId: currentUser.id,
      fullName: event.fullName,
      phone: event.phone,
      gender: event.gender,
      dateOfBirth: event.dateOfBirth,
    );
    await result.fold(
      onError: (failure) async => emit(AuthFailureState(failure)),
      onSuccess: (user) async => _routeUser(user, emit),
    );
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
    await _signOutUseCase();
    emit(const Unauthenticated());
  }

  Future<void> _onAuthUserChangedInternal(
    AuthUserChangedInternal event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
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

    if (!user.isProfileComplete) {
      emit(ProfileCompletionRequired(user));
      return;
    }

    // Fetch wallet to prove RLS and backend trigger integrity
    WalletPreview? wallet;
    final walletResult = await _getWalletPreviewUseCase(user.id);
    wallet = walletResult.dataOrNull;

    emit(Authenticated(
      user: user,
      wallet: wallet,
    ));
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
