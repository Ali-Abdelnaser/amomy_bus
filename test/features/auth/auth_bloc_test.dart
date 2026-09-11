import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_role.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
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
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
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
  ResultFuture<void> resendVerificationOtp({
    required String email,
  }) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<AppUser> signInWithGoogle({
    String? webClientId,
  }) async {
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
  ResultFuture<void> sendPasswordResetEmail({
    required String email,
  }) async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }

  @override
  ResultFuture<void> updatePassword({
    required String newPassword,
  }) async {
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

  test('emits [AuthLoading, Unauthenticated] when no session exists on AuthCheckRequested', () async {
    fakeRepo.currentUserResult = null;
    final expected = [
      const AuthLoading(),
      const Unauthenticated(),
    ];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const AuthCheckRequested());
  });

  test('emits [AuthLoading, Authenticated] when valid complete session exists', () async {
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
  });

  test('emits [AuthLoading, EmailVerificationRequired] when session email is unverified', () async {
    fakeRepo.currentUserResult = tUnverifiedUser;
    final expected = [
      const AuthLoading(),
      EmailVerificationRequired(email: tUnverifiedUser.email),
    ];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const AuthCheckRequested());
  });

  test('emits [AuthLoading, ProfileCompletionRequired] when profile fields are missing', () async {
    fakeRepo.currentUserResult = tIncompleteUser;
    final expected = [
      const AuthLoading(),
      ProfileCompletionRequired(tIncompleteUser),
    ];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const AuthCheckRequested());
  });

  test('emits [AuthLoading, AuthFailureState] when login fails with invalid credentials', () async {
    const authFailure = AuthenticationFailure(message: 'Invalid login credentials');
    fakeRepo.failure = authFailure;
    final expected = [
      const AuthLoading(),
      const AuthFailureState(authFailure),
    ];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const SignInWithEmailRequested(
      email: 'wrong@test.com',
      password: 'Password123',
    ));
  });

  test('emits [AuthLoading, Authenticated] on successful SignInWithEmailRequested', () async {
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
    authBloc.add(const SignInWithEmailRequested(
      email: 'passenger@amomy.com',
      password: 'ValidPassword123',
    ));
  });

  test('emits [AuthLoading, Unauthenticated] on SignOutRequested', () async {
    final expected = [
      const AuthLoading(),
      const Unauthenticated(),
    ];
    expectLater(authBloc.stream, emitsInOrder(expected));
    authBloc.add(const SignOutRequested());
  });
}
