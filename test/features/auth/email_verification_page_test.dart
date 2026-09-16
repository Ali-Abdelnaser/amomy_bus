import 'dart:io';
import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/core/widgets/app_button.dart';
import 'package:amomy_bus/core/widgets/app_text_field.dart';
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
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/auth/presentation/pages/email_verification_page.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAuthRepository implements AuthRepository {
  List<String> calls = [];
  Failure? verifyFailure;
  AppUser? verifySuccessUser;

  @override
  Stream<AppUser?> get authUserStream => const Stream.empty();

  @override
  ResultFuture<AppUser?> getCurrentUser() async => const Success(null);

  @override
  ResultFuture<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async => Success(
    AppUser(
      id: 'u1',
      email: email,
      fullName: 'Test User',
      roles: const [AppRole.passenger],
    ),
  );

  @override
  ResultFuture<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async => Success(
    AppUser(
      id: 'u1',
      email: email,
      fullName: fullName,
      roles: const [AppRole.passenger],
      isEmailVerified: false,
    ),
  );

  @override
  ResultFuture<AppUser> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    calls.add('verifyEmailOtp:$email:$token');
    if (verifyFailure != null) {
      return Future.value(Error(verifyFailure!));
    }
    return Future.value(
      Success(
        verifySuccessUser ??
            AppUser(
              id: 'u1',
              email: email,
              fullName: 'Test User',
              roles: const [AppRole.passenger],
              isEmailVerified: true,
            ),
      ),
    );
  }

  @override
  ResultFuture<void> resendVerificationOtp({required String email}) async {
    calls.add('resendVerificationOtp:$email');
    return const Success(null);
  }

  @override
  ResultFuture<AppUser> signInWithGoogle({String? webClientId}) async =>
      Success(
        AppUser(
          id: 'u1',
          email: 'google@test.com',
          fullName: 'Google User',
          roles: const [AppRole.passenger],
        ),
      );

  @override
  ResultFuture<AppUser> completeProfile({
    required String userId,
    required String fullName,
    required String phone,
    required String gender,
    required DateTime dateOfBirth,
  }) async => Success(
    AppUser(
      id: userId,
      email: 'test@test.com',
      fullName: fullName,
      phone: phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
      roles: const [AppRole.passenger],
    ),
  );

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

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget buildTestRouter({
    String email = 'testuser@example.com',
    List<String>? navigatedRoutes,
  }) {
    final router = GoRouter(
      initialLocation: RoutePaths.emailVerification,
      routes: [
        GoRoute(
          path: RoutePaths.emailVerification,
          builder: (context, state) => EmailVerificationPage(email: email),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) {
            navigatedRoutes?.add(RoutePaths.register);
            return const Scaffold(body: Text('Register Route'));
          },
        ),
        GoRoute(
          path: RoutePaths.completeProfile,
          builder: (context, state) {
            navigatedRoutes?.add(RoutePaths.completeProfile);
            return const Scaffold(body: Text('Complete Profile Route'));
          },
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) {
            navigatedRoutes?.add(RoutePaths.home);
            return const Scaffold(body: Text('Home Route'));
          },
        ),
      ],
    );

    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp.router(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  group('EmailVerificationPage UI & Layout Redesign', () {
    testWidgets(
      'renders redesigned layout without top back arrow or Back to Sign In',
      (tester) async {
        setTestViewport(tester);
        await tester.pumpWidget(buildTestRouter(email: 'passenger@amomy.com'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Header and Title
        expect(find.text('Verify Your Email'), findsOneWidget);
        expect(find.text('passenger@amomy.com'), findsOneWidget);
        expect(find.text('Verify Code'), findsOneWidget);

        // Verify removal of top AppBar back arrow
        expect(find.byType(AppBar), findsNothing);
        expect(find.byType(BackButton), findsNothing);

        // Verify removal of old "Back to Sign In"
        expect(find.text('Back to Sign In'), findsNothing);

        // Verify new "Wrong email? Change email" action
        expect(find.text('Wrong email?'), findsOneWidget);
        expect(find.text('Change email'), findsOneWidget);
      },
    );

    testWidgets('authoritative OTP digit count is exactly 6', (tester) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildTestRouter());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final otpFieldFinder = find.byType(AppOtpField);
      expect(otpFieldFinder, findsOneWidget);

      final otpField = tester.widget<AppOtpField>(otpFieldFinder);
      expect(otpField.length, equals(6));
    });
  });

  group('Change Email Action', () {
    testWidgets(
      'tapping Change email calls signOut and navigates to Register route (not Login)',
      (tester) async {
        setTestViewport(tester);
        final routes = <String>[];
        await tester.pumpWidget(buildTestRouter(navigatedRoutes: routes));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final changeEmailBtn = find.text('Change email');
        expect(changeEmailBtn, findsOneWidget);

        await tester.ensureVisible(changeEmailBtn);
        await tester.tap(changeEmailBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify session/verification state reset
        expect(fakeRepo.calls, contains('signOut'));

        // Verify navigation to register route
        expect(routes, contains(RoutePaths.register));
        expect(find.text('Register Route'), findsOneWidget);
      },
    );
  });

  group('OTP Input, Button-Only Validation & Animation', () {
    testWidgets(
      'entering 6 digits does NOT verify automatically, only enables button',
      (tester) async {
        setTestViewport(tester);
        await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final buttonFinder = find.widgetWithText(AppButton, 'Verify Code');
        expect(buttonFinder, findsOneWidget);

        // Button is initially disabled (0 digits entered)
        final initialButton = tester.widget<AppButton>(buttonFinder);
        expect(initialButton.onPressed, isNull);

        // Enter 5 digits
        final textFieldFinder = find.byType(TextField);
        await tester.enterText(textFieldFinder, '12345');
        await tester.pump();

        // Button is still disabled at 5 digits
        final btn5 = tester.widget<AppButton>(buttonFinder);
        expect(btn5.onPressed, isNull);
        expect(
          fakeRepo.calls.where((c) => c.startsWith('verifyEmailOtp')),
          isEmpty,
        );

        // Enter 6th digit
        await tester.enterText(textFieldFinder, '123456');
        await tester.pump();

        // NO verification triggered automatically!
        expect(
          fakeRepo.calls.where((c) => c.startsWith('verifyEmailOtp')),
          isEmpty,
        );

        // Button is now enabled
        final btn6 = tester.widget<AppButton>(buttonFinder);
        expect(btn6.onPressed, isNotNull);
      },
    );

    testWidgets(
      'pasting 6 digits does NOT call verifyOtp, only enables button',
      (tester) async {
        setTestViewport(tester);
        await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final textFieldFinder = find.byType(TextField);
        await tester.enterText(textFieldFinder, '987654');
        await tester.pump();

        // No verification call triggered automatically
        expect(
          fakeRepo.calls.where((c) => c.startsWith('verifyEmailOtp')),
          isEmpty,
        );

        // Button is enabled
        final btn = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Verify Code'),
        );
        expect(btn.onPressed, isNotNull);
      },
    );

    testWidgets('backspace drops length to 5 and disables button', (
      tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '123456');
      await tester.pump();

      final btnEnabled = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Verify Code'),
      );
      expect(btnEnabled.onPressed, isNotNull);

      // Backspace: drop to 5 digits
      await tester.enterText(textFieldFinder, '12345');
      await tester.pump();

      final btnDisabled = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Verify Code'),
      );
      expect(btnDisabled.onPressed, isNull);
      expect(
        fakeRepo.calls.where((c) => c.startsWith('verifyEmailOtp')),
        isEmpty,
      );
    });

    testWidgets('button tap calls verifyOtp exactly once', (tester) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '582914');
      await tester.pump();

      expect(
        fakeRepo.calls.where((c) => c.startsWith('verifyEmailOtp')),
        isEmpty,
      );

      // Explicitly tap the Verify Code button
      final buttonFinder = find.widgetWithText(AppButton, 'Verify Code');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.calls, contains('verifyEmailOtp:user@amomy.com:582914'));
      final verifyCalls = fakeRepo.calls
          .where((c) => c.startsWith('verifyEmailOtp'))
          .toList();
      expect(verifyCalls.length, equals(1));
    });

    testWidgets('duplicate button taps while loading are ignored', (
      tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '123456');
      await tester.pump();

      final buttonFinder = find.byType(AppButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      // Attempting to tap again while submitting does not trigger additional calls
      await tester.tap(buttonFinder, warnIfMissed: false);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      // Should only call verifyEmailOtp once
      final verifyCalls = fakeRepo.calls
          .where((c) => c.startsWith('verifyEmailOtp'))
          .toList();
      expect(verifyCalls.length, equals(1));
    });

    testWidgets(
      'invalid OTP leaves digits visible and shows error while remaining editable',
      (tester) async {
        setTestViewport(tester);
        fakeRepo.verifyFailure = const AuthenticationFailure(
          message: 'The verification code is incorrect.',
        );

        await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final textFieldFinder = find.byType(TextField);
        await tester.enterText(textFieldFinder, '000000');
        await tester.pump();

        // Explicit tap to verify
        final buttonFinder = find.byType(AppButton);
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(authBloc.state, isA<AuthFailureState>());
        expect(
          find.text('The verification code is incorrect.'),
          findsOneWidget,
        );

        // Digits MUST NOT be cleared and remain visible
        expect(find.text('0'), findsNWidgets(6));
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.controller?.text, equals('000000'));
      },
    );

    testWidgets('expired OTP leaves digits visible and shows error', (
      tester,
    ) async {
      setTestViewport(tester);
      fakeRepo.verifyFailure = const AuthenticationFailure(
        message: 'This code has expired. Request a new one.',
      );

      await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, '999999');
      await tester.pump();

      final buttonFinder = find.byType(AppButton);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('This code has expired. Request a new one.'),
        findsOneWidget,
      );

      // Digits remain visible
      expect(find.text('9'), findsNWidgets(6));
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, equals('999999'));
    });
  });

  group('Resend OTP Flow', () {
    testWidgets('resend starts in cooldown and becomes active at zero', (
      tester,
    ) async {
      setTestViewport(tester);
      await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
      await tester.pump();

      // Initially in cooldown: Resend in 60s
      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(find.text('Didn\'t receive the code?'), findsOneWidget);

      // Advance timer by 61 seconds
      await tester.pump(const Duration(seconds: 61));

      // Cooldown ended: "Resend Code" becomes tappable
      final resendCodeBtn = find.text('Resend Code');
      expect(resendCodeBtn, findsOneWidget);

      await tester.ensureVisible(resendCodeBtn);
      await tester.tap(resendCodeBtn);
      await tester.pump();

      expect(fakeRepo.calls, contains('resendVerificationOtp:user@amomy.com'));

      // Cooldown restarts immediately
      expect(find.textContaining('Resend in'), findsOneWidget);
    });

    testWidgets(
      'resend success shows AppSnackBar and does not duplicate on rebuild',
      (tester) async {
        setTestViewport(tester);
        await tester.pumpWidget(buildTestRouter(email: 'user@amomy.com'));
        await tester.pump();

        // Fast forward past cooldown
        await tester.pump(const Duration(seconds: 61));

        final resendCodeBtn = find.text('Resend Code');
        await tester.ensureVisible(resendCodeBtn);
        await tester.tap(resendCodeBtn);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Check AppSnackBar is shown
        expect(
          find.text('Verification code resent successfully.'),
          findsOneWidget,
        );

        // Rebuilding the widget does not trigger another duplicate snackbar
        await tester.pump();
        expect(
          find.text('Verification code resent successfully.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Success Routing Flow', () {
    testWidgets(
      'successful verify with incomplete profile routes to /complete-profile after success delay',
      (tester) async {
        setTestViewport(tester);
        final routes = <String>[];
        fakeRepo.verifySuccessUser = const AppUser(
          id: 'u1',
          email: 'user@amomy.com',
          fullName: 'New User',
          roles: [AppRole.passenger],
          phone: null, // incomplete profile
          isEmailVerified: true,
        );

        await tester.pumpWidget(
          buildTestRouter(email: 'user@amomy.com', navigatedRoutes: routes),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        // Tap button
        final buttonFinder = find.byType(AppButton);
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();

        // Wait 450ms for staggered success animation
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();

        expect(routes, contains(RoutePaths.completeProfile));
        expect(find.text('Complete Profile Route'), findsOneWidget);
      },
    );

    testWidgets(
      'successful verify with complete profile routes to /home after success delay',
      (tester) async {
        setTestViewport(tester);
        final routes = <String>[];
        fakeRepo.verifySuccessUser = AppUser(
          id: 'u1',
          email: 'user@amomy.com',
          fullName: 'Complete User',
          roles: const [AppRole.passenger],
          phone: '01012345678',
          gender: 'male',
          dateOfBirth: DateTime(1995, 5, 10),
          isEmailVerified: true,
        );

        await tester.pumpWidget(
          buildTestRouter(email: 'user@amomy.com', navigatedRoutes: routes),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.enterText(find.byType(TextField), '123456');
        await tester.pump();

        final buttonFinder = find.byType(AppButton);
        await tester.ensureVisible(buttonFinder);
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();

        // Wait 450ms for staggered success animation
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();

        expect(routes, contains(RoutePaths.home));
        expect(find.text('Home Route'), findsOneWidget);
      },
    );
  });

  group('Auth Email Templates Verification', () {
    test(
      'all 5 email templates exist and include {{ .Token }} without broken image dependencies',
      () {
        final templateNames = [
          'confirm_signup.html',
          'reset_password.html',
          'change_email.html',
          'reauthentication.html',
          'magic_link.html',
        ];

        for (final name in templateNames) {
          final file = File('docs/email_templates/$name');
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Template $name must exist in docs/email_templates/',
          );

          final content = file.readAsStringSync();
          expect(
            content,
            contains('{{ .Token }}'),
            reason: 'Template $name must contain {{ .Token }}',
          );
          expect(
            content,
            isNot(contains('file:///')),
            reason: 'Template $name must not contain local file paths',
          );
          expect(
            content,
            isNot(contains('assets/')),
            reason: 'Template $name must not contain local asset paths',
          );
          expect(
            content,
            isNot(contains('localhost')),
            reason: 'Template $name must not contain localhost',
          );
          expect(
            content,
            isNot(contains('127.0.0.1:3000')),
            reason: 'Template $name must not contain hardcoded 127.0.0.1:3000',
          );
        }

        // Specifically check that confirm_signup.html does NOT contain ConfirmationURL
        // to prevent email scanner prefetch consumption of the one-time signup OTP
        final confirmFile = File('docs/email_templates/confirm_signup.html');
        final confirmContent = confirmFile.readAsStringSync();
        expect(
          confirmContent,
          isNot(contains('ConfirmationURL')),
          reason:
              'confirm_signup.html must not contain ConfirmationURL to prevent link prefetching',
        );
      },
    );
  });
}
