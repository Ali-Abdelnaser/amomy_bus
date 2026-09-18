import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/domain/entities/user_access_status.dart';
import 'package:amomy_bus/features/auth/domain/entities/wallet_preview.dart';
import 'package:amomy_bus/features/auth/domain/repositories/auth_repository.dart';
import 'package:amomy_bus/features/auth/domain/usecases/complete_profile_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/get_wallet_preview_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/send_password_reset_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:amomy_bus/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  AppUser? currentUserResult;
  Failure? failure;

  @override
  Stream<AppUser?> get authUserStream => const Stream.empty();

  @override
  ResultFuture<AppUser?> getCurrentUser() async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult);
  }

  @override
  ResultFuture<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult!);
  }

  @override
  ResultFuture<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult!);
  }

  @override
  ResultFuture<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult!);
  }

  @override
  ResultFuture<void> resendVerificationOtp({required String email}) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<AppUser> signInWithGoogle({String? webClientId}) async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult!);
  }

  @override
  ResultFuture<AppUser> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    if (failure != null) return Error(failure!);
    return Success(currentUserResult!);
  }

  @override
  ResultFuture<void> sendPasswordResetEmail({required String email}) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<void> updatePassword({required String newPassword}) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<WalletPreview?> getWalletPreview(String userId) async {
    if (failure != null) return Error(failure!);
    return const Success(
      WalletPreview(
        id: 'w-1',
        userId: 'u-1',
        cashPoints: 100,
        subscriptionPoints: 50,
      ),
    );
  }

  @override
  ResultFuture<bool> claimActiveWelcomeGift({
    required String deviceIdentifier,
  }) async {
    if (failure != null) return Error(failure!);
    return const Success(true);
  }

  @override
  ResultFuture<DeviceAccessResult> checkDeviceAccess({
    required String deviceIdentifier,
  }) async {
    return const Success(DeviceAccessResult(allowed: true, isBlocked: false));
  }

  @override
  ResultFuture<void> registerUserInstallation({
    required String deviceIdentifier,
    required String platform,
    String? deviceName,
    String? appVersion,
  }) async {
    return const Success(null);
  }

  @override
  ResultFuture<UserAccessStatus> getMyAccessStatus({
    required String deviceIdentifier,
  }) async {
    return const Success(
      UserAccessStatus(allowed: true, accountStatus: 'active'),
    );
  }

  @override
  ResultFuture<void> recordUserActivity({
    required String eventType,
    required String deviceIdentifier,
    Map<String, dynamic>? metadata,
  }) async {
    return const Success(null);
  }

  @override
  ResultFuture<void> signOut() async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }
}

void main() {
  late FakeAuthRepository fakeRepo;
  late AuthBloc authBloc;

  final tUser = AppUser(
    id: 'test-user-id',
    email: 'passenger@amomy.com',
    fullName: 'Ali Abdelnaser',
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1995, 5, 20),
    roles: const [AppRole.passenger],
    isEmailVerified: true,
  );

  final tUnverifiedUser = AppUser(
    id: 'test-user-id-2',
    email: 'unverified@amomy.com',
    fullName: 'New Passenger',
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1998, 1, 1),
    roles: const [AppRole.passenger],
    isEmailVerified: false,
  );

  final tIncompleteUser = AppUser(
    id: 'test-user-id-3',
    email: 'googleuser@gmail.com',
    fullName: 'Google Passenger',
    roles: const [AppRole.passenger],
    isEmailVerified: true,
  );

  setUp(() {
    fakeRepo = FakeAuthRepository();
    authBloc = AuthBloc(
      getCurrentUserUseCase: GetCurrentUserUseCase(fakeRepo),
      signInWithEmailUseCase: SignInWithEmailUseCase(fakeRepo),
      signUpWithEmailUseCase: SignUpWithEmailUseCase(fakeRepo),
      verifyOtpUseCase: VerifyOtpUseCase(fakeRepo),
      resendOtpUseCase: ResendOtpUseCase(fakeRepo),
      signInWithGoogleUseCase: SignInWithGoogleUseCase(fakeRepo),
      completeProfileUseCase: CompleteProfileUseCase(fakeRepo),
      sendPasswordResetUseCase: SendPasswordResetUseCase(fakeRepo),
      updatePasswordUseCase: UpdatePasswordUseCase(fakeRepo),
      getWalletPreviewUseCase: GetWalletPreviewUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, const AuthInitial());
  });

  test(
    'emits [AuthLoading, Unauthenticated] when no session exists on AuthCheckRequested',
    () async {
      fakeRepo.currentUserResult = null;
      final expected = [const AuthLoading(), const Unauthenticated()];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    },
  );

  test(
    'emits [AuthLoading, Authenticated] when valid complete session exists',
    () async {
      fakeRepo.currentUserResult = tUser;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    },
  );

  test(
    'emits [AuthLoading, EmailVerificationRequired] when session email is unverified',
    () async {
      fakeRepo.currentUserResult = tUnverifiedUser;
      final expected = [
        const AuthLoading(),
        EmailVerificationRequired(email: tUnverifiedUser.email),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    },
  );

  test(
    'emits [AuthLoading, Authenticated] even when profile fields are missing (incomplete profile does NOT block Home)',
    () async {
      fakeRepo.currentUserResult = tIncompleteUser;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tIncompleteUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const AuthCheckRequested());
    },
  );

  test(
    'emits [AuthLoading, AuthFailureState] when login fails with invalid credentials',
    () async {
      const authFailure = AuthenticationFailure(
        message: 'Invalid login credentials',
      );
      fakeRepo.failure = authFailure;
      final expected = [
        const AuthLoading(),
        const AuthFailureState(authFailure),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const SignInWithEmailRequested(
          email: 'wrong@test.com',
          password: 'Password123',
        ),
      );
    },
  );

  test(
    'emits [AuthLoading, Authenticated] on successful SignInWithEmailRequested',
    () async {
      fakeRepo.currentUserResult = tUser;
      fakeRepo.failure = null;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const SignInWithEmailRequested(
          email: 'passenger@amomy.com',
          password: 'ValidPassword123',
        ),
      );
    },
  );

  test(
    'email registration succeeds without phone, gender, or date of birth',
    () async {
      fakeRepo.currentUserResult = tIncompleteUser;
      fakeRepo.failure = null;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tIncompleteUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const SignUpWithEmailRequested(
          email: 'test@example.com',
          password: 'ValidPassword123',
          fullName: 'Test User',
        ),
      );
    },
  );

  test(
    'emits [AuthLoading, Authenticated] on successful SignInWithGoogleRequested',
    () async {
      fakeRepo.currentUserResult = tUser;
      fakeRepo.failure = null;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const SignInWithGoogleRequested());
    },
  );

  test(
    'reverts to [AuthLoading, Unauthenticated] without error when user cancels Google Sign-In',
    () async {
      fakeRepo.failure = const AuthCancelledFailure();
      final expected = [const AuthLoading(), const Unauthenticated()];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const SignInWithGoogleRequested());
    },
  );

  test(
    'emits [AuthLoading, Authenticated] when Google user has missing profile fields (does NOT block Home)',
    () async {
      fakeRepo.currentUserResult = tIncompleteUser;
      fakeRepo.failure = null;
      final expected = [
        const AuthLoading(),
        Authenticated(
          user: tIncompleteUser,
          wallet: const WalletPreview(
            id: 'w-1',
            userId: 'u-1',
            cashPoints: 100,
            subscriptionPoints: 50,
          ),
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const SignInWithGoogleRequested());
    },
  );

  test(
    'emits [AuthLoading, AuthFailureState] when Google Sign-In encounters unexpected error (no silent Unauthenticated)',
    () async {
      const serverFailure = ServerFailure(
        message: 'Google Sign-In failed: no Supabase user session created.',
      );
      fakeRepo.failure = serverFailure;
      final expected = [
        const AuthLoading(),
        const AuthFailureState(serverFailure),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const SignInWithGoogleRequested());
    },
  );

  test('emits [AuthLoading, Unauthenticated] on SignOutRequested', () async {
    final expected = [const AuthLoading(), const Unauthenticated()];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const SignOutRequested());
  });

  test(
    'emits [AuthLoading, EmailVerificationRequired] on SignUpWithEmailRequested when user is unverified',
    () async {
      fakeRepo.currentUserResult = tUnverifiedUser;
      fakeRepo.failure = null;
      final expected = [
        const AuthLoading(),
        EmailVerificationRequired(
          email: 'unverified@amomy.com',
          infoMessage: 'Verification code sent to your email.',
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(
        const SignUpWithEmailRequested(
          email: 'unverified@amomy.com',
          password: 'ValidPassword123',
          fullName: 'New Passenger',
        ),
      );
    },
  );

  test(
    'emits [EmailVerificationRequired] with success message on successful ResendOtpRequested',
    () async {
      fakeRepo.failure = null;
      final expected = [
        const EmailVerificationRequired(
          email: 'test@example.com',
          infoMessage: 'Verification code resent successfully.',
        ),
      ];
      expectLater(authBloc.stream, emitsInOrder(expected));
      authBloc.add(const ResendOtpRequested(email: 'test@example.com'));
    },
  );

  test('emits [AuthFailureState] on failed ResendOtpRequested', () async {
    const rateLimitFailure = ServerFailure(
      message:
          'For security purposes, you can only request this once every 60 seconds',
    );
    fakeRepo.failure = rateLimitFailure;
    final expected = [const AuthFailureState(rateLimitFailure)];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const ResendOtpRequested(email: 'test@example.com'));
  });

  group('CompleteProfileRequested', () {
    test(
      'emits [ProfileSaving, ProfileSaveFailure] on profile save failure and preserves authenticated identity',
      () async {
        fakeRepo.currentUserResult = tUser;
        fakeRepo.failure = null;
        authBloc.emit(
          Authenticated(
            user: tUser,
            wallet: const WalletPreview(
              id: 'w-1',
              userId: 'u-1',
              cashPoints: 100,
              subscriptionPoints: 50,
            ),
          ),
        );

        const serverFailure = ServerFailure(
          message:
              'infinite recursion detected in policy for relation "profiles"',
        );
        fakeRepo.failure = serverFailure;

        final expected = [
          ProfileSaving(
            user: tUser,
            wallet: const WalletPreview(
              id: 'w-1',
              userId: 'u-1',
              cashPoints: 100,
              subscriptionPoints: 50,
            ),
          ),
          ProfileSaveFailure(
            user: tUser,
            failure: serverFailure,
            wallet: const WalletPreview(
              id: 'w-1',
              userId: 'u-1',
              cashPoints: 100,
              subscriptionPoints: 50,
            ),
          ),
        ];

        expectLater(authBloc.stream, emitsInOrder(expected));

        authBloc.add(
          CompleteProfileRequested(
            fullName: 'New Name',
            phone: '01012345678',
            gender: 'male',
            dateOfBirth: DateTime(1995, 1, 1),
          ),
        );
      },
    );

    test(
      'failure preserves authenticated identity and allows subsequent retry to succeed',
      () async {
        fakeRepo.currentUserResult = tUser;
        const initialWallet = WalletPreview(
          id: 'w-1',
          userId: 'u-1',
          cashPoints: 100,
          subscriptionPoints: 50,
        );
        authBloc.emit(Authenticated(user: tUser, wallet: initialWallet));

        // 1. First attempt fails
        const serverFailure = ServerFailure(message: 'Network issue');
        fakeRepo.failure = serverFailure;

        authBloc.add(
          CompleteProfileRequested(
            fullName: 'New Name',
            phone: '01012345678',
            gender: 'male',
            dateOfBirth: DateTime(1995, 1, 1),
          ),
        );

        await expectLater(
          authBloc.stream,
          emitsThrough(isA<ProfileSaveFailure>()),
        );

        // Verify that state remains an Authenticated subclass
        expect(authBloc.state, isA<Authenticated>());
        expect(authBloc.state is Unauthenticated, isFalse);
        final failureState = authBloc.state as ProfileSaveFailure;
        expect(failureState.user.id, equals(tUser.id));
        expect(failureState.wallet, equals(initialWallet));

        // 2. Retry succeeds
        final updatedUser = tUser.copyWith(fullName: 'New Name');
        fakeRepo.failure = null;
        fakeRepo.currentUserResult = updatedUser;

        authBloc.add(
          CompleteProfileRequested(
            fullName: 'New Name',
            phone: '01012345678',
            gender: 'male',
            dateOfBirth: DateTime(1995, 1, 1),
          ),
        );

        await expectLater(
          authBloc.stream,
          emitsInOrder([
            isA<ProfileSaving>(),
            isA<Authenticated>().having(
              (s) => s.user.fullName,
              'fullName',
              'New Name',
            ),
          ]),
        );
      },
    );
  });
}
