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
import 'package:amomy_bus/features/auth/presentation/pages/email_verification_page.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  List<String> calls = [];

  @override
  Stream<AppUser?> get authUserStream => const Stream.empty();

  @override
  ResultFuture<AppUser?> getCurrentUser() async => const Success(null);

  @override
  ResultFuture<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      Success(AppUser(
        id: 'u1',
        email: email,
        fullName: 'Test User',
        roles: const [AppRole.passenger],
      ));

  @override
  ResultFuture<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async =>
      Success(AppUser(
        id: 'u1',
        email: email,
        fullName: fullName,
        roles: const [AppRole.passenger],
        isEmailVerified: false,
      ));

  @override
  ResultFuture<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    calls.add('verifyEmailOtp:$email:$token');
    return Success(AppUser(
      id: 'u1',
      email: email,
      fullName: 'Test User',
      roles: const [AppRole.passenger],
      isEmailVerified: true,
    ));
  }

  @override
  ResultFuture<void> resendVerificationOtp({required String email}) async {
    calls.add('resendVerificationOtp:$email');
    return const Success(null);
  }

  @override
  ResultFuture<AppUser> signInWithGoogle({String? webClientId}) async =>
      Success(AppUser(
        id: 'u1',
        email: 'google@test.com',
        fullName: 'Google User',
        roles: const [AppRole.passenger],
      ));

  @override
  ResultFuture<AppUser> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async =>
      Success(AppUser(
        id: userId,
        email: 'test@test.com',
        fullName: fullName,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        roles: const [AppRole.passenger],
      ));

  @override
  ResultFuture<void> sendPasswordResetEmail({required String email}) async =>
      const Success(null);

  @override
  ResultFuture<void> updatePassword({required String newPassword}) async =>
      const Success(null);

  @override
  ResultFuture<WalletPreview?> getWalletPreview(String userId) async =>
      const Success(null);

  @override
  ResultFuture<void> signOut() async {
    calls.add('signOut');
    return const Success(null);
  }
}

void main() {
  late _FakeAuthRepository fakeRepo;
  late AuthBloc authBloc;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
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

  Widget buildTestPage({String email = 'testuser@example.com'}) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: EmailVerificationPage(email: email),
      ),
    );
  }

  testWidgets('renders EmailVerificationPage with email, otp input, and actions', (tester) async {
    await tester.pumpWidget(buildTestPage(email: 'testuser@example.com'));
    await tester.pumpAndSettle();

    expect(find.text('Verify Your Email'), findsOneWidget);
    expect(find.text('testuser@example.com'), findsOneWidget);
    expect(find.text('Verify Code'), findsOneWidget);
    expect(find.text('Back to Sign In'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('tapping Back to Sign In invokes SignOutRequested on AuthBloc', (tester) async {
    await tester.pumpWidget(buildTestPage(email: 'testuser@example.com'));
    await tester.pumpAndSettle();

    final backToLoginBtn = find.text('Back to Sign In');
    expect(backToLoginBtn, findsOneWidget);

    await tester.ensureVisible(backToLoginBtn);
    await tester.tap(backToLoginBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.calls, contains('signOut'));
  });

  testWidgets('tapping AppBar back button invokes SignOutRequested on AuthBloc', (tester) async {
    await tester.pumpWidget(buildTestPage(email: 'testuser@example.com'));
    await tester.pumpAndSettle();

    final backBtn = find.byType(IconButton);
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.calls, contains('signOut'));
  });
}
