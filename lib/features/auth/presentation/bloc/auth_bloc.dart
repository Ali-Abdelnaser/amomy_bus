// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';

import '../../domain/entities/wallet_preview.dart';
import '../../../../core/services/device_identity_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/claim_welcome_gift_usecase.dart';
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
import '../../../wallet/presentation/cubit/wallet_cubit.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> with WidgetsBindingObserver {
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
  final ClaimWelcomeGiftUseCase? _claimWelcomeGiftUseCase;
  final DeviceIdentityService? _deviceIdentityService;
  final AuthRepository? _authRepository;
  final SignOutUseCase _signOutUseCase;

  StreamSubscription<AppUser?>? _userSubscription;
  bool _hasAttemptedSessionWelcomeGift = false;
  bool _hasRegisteredInstallation = false;

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
    ClaimWelcomeGiftUseCase? claimWelcomeGiftUseCase,
    DeviceIdentityService? deviceIdentityService,
    AuthRepository? authRepository,
    required SignOutUseCase signOutUseCase,
  }) : _getCurrentUserUseCase = getCurrentUserUseCase,
       _signInWithEmailUseCase = signInWithEmailUseCase,
       _signUpWithEmailUseCase = signUpWithEmailUseCase,
       _verifyOtpUseCase = verifyOtpUseCase,
       _resendOtpUseCase = resendOtpUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _completeProfileUseCase = completeProfileUseCase,
       _sendPasswordResetUseCase = sendPasswordResetUseCase,
       _updatePasswordUseCase = updatePasswordUseCase,
       _getWalletPreviewUseCase = getWalletPreviewUseCase,
       _claimWelcomeGiftUseCase = claimWelcomeGiftUseCase,
       _deviceIdentityService = deviceIdentityService,
       _authRepository = authRepository,
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
    on<AppResumedRequested>(_onAppResumedRequested);

    _userSubscription = _getCurrentUserUseCase.userStream.listen((user) {
      add(AuthUserChangedInternal(user));
    });

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      add(const AppResumedRequested());
    }
  }

  AuthRepository? get _effectiveRepository {
    if (_authRepository != null) return _authRepository;
    if (getIt.isRegistered<AuthRepository>()) return getIt<AuthRepository>();
    return null;
  }

  DeviceIdentityService? get _effectiveIdentityService {
    if (_deviceIdentityService != null) return _deviceIdentityService;
    if (getIt.isRegistered<DeviceIdentityService>()) {
      return getIt<DeviceIdentityService>();
    }
    return null;
  }

  Future<String?> _getDeviceIdentifier() async {
    try {
      final service = _effectiveIdentityService;
      if (service == null) return null;
      return await service.getDeviceIdentifier();
    } catch (_) {
      return null;
    }
  }

  Future<bool> _enforceAccountAccessAndRegister({
    required Emitter<AuthState> emit,
    bool isColdStart = false,
    bool isLogin = false,
  }) async {
    final repo = _effectiveRepository;
    final deviceId = await _getDeviceIdentifier();
    if (repo == null || deviceId == null || deviceId.isEmpty) return true;

    try {
      final statusResult = await repo.getMyAccessStatus(
        deviceIdentifier: deviceId,
      );
      if (statusResult.isSuccess) {
        final status = statusResult.dataOrNull!;
        if (!status.allowed) {
          if (status.isTemporaryBan) {
            emit(
              AccessBlockedState(
                type: AccessBlockedType.temporaryBan,
                bannedUntil: status.bannedUntil,
              ),
            );
          } else if (status.isPermanentBan) {
            emit(
              const AccessBlockedState(type: AccessBlockedType.permanentBan),
            );
          } else {
            emit(
              const AccessBlockedState(type: AccessBlockedType.deviceBlocked),
            );
          }
          return false;
        }
      }

      // Register installation once per session
      if (!_hasRegisteredInstallation) {
        _hasRegisteredInstallation = true;
        final platform = kIsWeb
            ? 'web'
            : (Platform.isAndroid
                  ? 'android'
                  : (Platform.isIOS ? 'ios' : 'mobile'));
        unawaited(
          repo.registerUserInstallation(
            deviceIdentifier: deviceId,
            platform: platform,
            deviceName: kIsWeb
                ? 'Web'
                : (Platform.isAndroid ? 'Android' : 'iOS'),
            appVersion: '1.0.0',
          ),
        );
      }

      // Operational activity tracking
      if (isColdStart) {
        unawaited(
          repo.recordUserActivity(
            eventType: 'session_start',
            deviceIdentifier: deviceId,
          ),
        );
      } else if (isLogin) {
        unawaited(
          repo.recordUserActivity(
            eventType: 'login_success',
            deviceIdentifier: deviceId,
          ),
        );
      }

      return true;
    } catch (e) {
      developer.log('AuthBloc: Access check error: $e', name: 'AUTH');
      return true; // Fallback: allow progress on transient network check failure if session is valid
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    // 1. Pre-auth device check (unauthenticated check)
    final repo = _effectiveRepository;
    final deviceId = await _getDeviceIdentifier();
    if (repo != null && deviceId != null && deviceId.isNotEmpty) {
      try {
        final deviceResult = await repo.checkDeviceAccess(
          deviceIdentifier: deviceId,
        );
        if (deviceResult.isSuccess) {
          final deviceAccess = deviceResult.dataOrNull!;
          if (!deviceAccess.allowed || deviceAccess.isBlocked) {
            emit(
              const AccessBlockedState(type: AccessBlockedType.deviceBlocked),
            );
            return;
          }
        }
      } catch (e) {
        developer.log(
          'AuthBloc: Pre-auth device check error: $e',
          name: 'AUTH',
        );
      }
    }

    // 2. Retrieve user session
    final result = await _getCurrentUserUseCase();
    await result.fold(
      onError: (failure) async => emit(const Unauthenticated()),
      onSuccess: (user) async {
        if (user == null) {
          emit(const Unauthenticated());
        } else {
          final isAllowed = await _enforceAccountAccessAndRegister(
            emit: emit,
            isColdStart: true,
          );
          if (!isAllowed) return;
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
      onSuccess: (user) async {
        final isAllowed = await _enforceAccountAccessAndRegister(
          emit: emit,
          isLogin: true,
        );
        if (!isAllowed) return;
        await _routeUser(user, emit);
      },
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
          emit(
            EmailVerificationRequired(
              email: event.email,
              infoMessage: 'Verification code sent to your email.',
            ),
          );
        } else {
          final isAllowed = await _enforceAccountAccessAndRegister(
            emit: emit,
            isLogin: true,
          );
          if (!isAllowed) return;
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
    if (result.isError) {
      emit(AuthFailureState(result.failureOrNull!));
    } else {
      final isAllowed = await _enforceAccountAccessAndRegister(
        emit: emit,
        isLogin: true,
      );
      if (!isAllowed) return;
      await _routeUser(result.dataOrNull!, emit);
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _resendOtpUseCase(email: event.email);
    result.fold(
      onError: (failure) => emit(AuthFailureState(failure)),
      onSuccess: (_) => emit(
        EmailVerificationRequired(
          email: event.email,
          infoMessage: 'Verification code resent successfully.',
        ),
      ),
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
        final isAllowed = await _enforceAccountAccessAndRegister(
          emit: emit,
          isLogin: true,
        );
        if (!isAllowed) return;
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
      emit(
        ProfileSaveFailure(
          user: currentUser,
          failure: failure,
          wallet: currentWallet,
        ),
      );
    } else {
      final updatedUser = result.dataOrNull!;
      final deviceId = await _getDeviceIdentifier();
      if (deviceId != null && deviceId.isNotEmpty) {
        unawaited(
          _effectiveRepository?.recordUserActivity(
            eventType: 'profile_updated',
            deviceIdentifier: deviceId,
          ),
        );
      }
      // Silently attempt Welcome Gift claim immediately upon successful profile completion
      await _triggerSilentWelcomeGiftClaim(updatedUser);
      await _routeUser(updatedUser, emit);
    }
  }

  Future<void> _triggerSilentWelcomeGiftClaim(AppUser user) async {
    if (user.phone == null || user.phone!.trim().isEmpty) return;

    try {
      final identityService = _effectiveIdentityService;
      final claimUseCase =
          _claimWelcomeGiftUseCase ??
          (getIt.isRegistered<ClaimWelcomeGiftUseCase>()
              ? getIt<ClaimWelcomeGiftUseCase>()
              : null);

      if (identityService == null || claimUseCase == null) return;

      final deviceIdentifier = await identityService.getDeviceIdentifier();
      if (deviceIdentifier.isEmpty) return;

      final claimResult = await claimUseCase(
        deviceIdentifier: deviceIdentifier,
      );

      final granted = claimResult.dataOrNull ?? false;
      if (granted) {
        developer.log(
          'AuthBloc: Welcome gift successfully claimed for user ${user.id}',
          name: 'AUTH',
        );
        if (getIt.isRegistered<WalletCubit>()) {
          unawaited(getIt<WalletCubit>().loadWalletSummary(user.id));
        }
      }
    } catch (e) {
      developer.log(
        'AuthBloc: Silent welcome gift claim error: $e',
        name: 'AUTH',
      );
    }
  }

  Future<void> _onAppResumedRequested(
    AppResumedRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = switch (state) {
      Authenticated(:final user) => user,
      ProfileCompletionRequired(:final user) => user,
      _ => null,
    };

    if (currentUser == null) return;

    final repo = _effectiveRepository;
    final deviceId = await _getDeviceIdentifier();
    if (repo == null || deviceId == null || deviceId.isEmpty) return;

    try {
      final statusResult = await repo.getMyAccessStatus(
        deviceIdentifier: deviceId,
      );
      if (statusResult.isSuccess) {
        final status = statusResult.dataOrNull!;
        if (!status.allowed) {
          if (status.isTemporaryBan) {
            emit(
              AccessBlockedState(
                type: AccessBlockedType.temporaryBan,
                bannedUntil: status.bannedUntil,
              ),
            );
          } else if (status.isPermanentBan) {
            emit(
              const AccessBlockedState(type: AccessBlockedType.permanentBan),
            );
          } else {
            emit(
              const AccessBlockedState(type: AccessBlockedType.deviceBlocked),
            );
          }
          return;
        }
      }

      unawaited(
        repo.recordUserActivity(
          eventType: 'app_open',
          deviceIdentifier: deviceId,
        ),
      );
    } catch (e) {
      developer.log(
        'AuthBloc: App resumed access check error: $e',
        name: 'AUTH',
      );
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
    // ignore: avoid_print
    print(
      'DEBUG: _onSignOutRequested started! service=$_effectiveIdentityService',
    );
    emit(const AuthLoading());
    _hasAttemptedSessionWelcomeGift = false;
    _hasRegisteredInstallation = false;

    final service = _effectiveIdentityService;
    if (service != null) {
      final deviceId = await _getDeviceIdentifier();
      if (deviceId != null && deviceId.isNotEmpty) {
        try {
          await _effectiveRepository?.recordUserActivity(
            eventType: 'logout',
            deviceIdentifier: deviceId,
          );
        } catch (_) {}
      }
    }

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
      if (state is AuthLoading || state is ProfileSaving) {
        developer.log(
          'AuthBloc: Received null auth stream event while in AuthLoading/ProfileSaving - preserving active auth flow',
          name: 'AUTH',
        );
        return;
      }
      if (state is! Unauthenticated &&
          state is! AuthInitial &&
          state is! AccessBlockedState) {
        emit(const Unauthenticated());
      }
    } else {
      if (state is AccessBlockedState) {
        // Already blocked - do not override with Authenticated
        return;
      }
      final isAllowed = await _enforceAccountAccessAndRegister(
        emit: emit,
        isColdStart: false,
      );
      if (!isAllowed) return;
      await _routeUser(user, emit);
    }
  }

  Future<void> _routeUser(AppUser user, Emitter<AuthState> emit) async {
    if (!user.isEmailVerified) {
      emit(EmailVerificationRequired(email: user.email));
      return;
    }

    if (!_hasAttemptedSessionWelcomeGift &&
        user.isProfileComplete &&
        user.phone != null &&
        user.phone!.trim().isNotEmpty) {
      _hasAttemptedSessionWelcomeGift = true;
      unawaited(_triggerSilentWelcomeGiftClaim(user));
    }

    WalletPreview? wallet;
    final walletResult = await _getWalletPreviewUseCase(user.id);
    wallet = walletResult.dataOrNull;

    emit(Authenticated(user: user, wallet: wallet));

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      if (getIt.isRegistered<NotificationService>()) {
        unawaited(getIt<NotificationService>().syncDeviceToken());
      }
    }
  }

  @override
  Future<void> close() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _userSubscription?.cancel();
    return super.close();
  }
}
