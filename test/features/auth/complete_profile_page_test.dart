import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? currentUserResult;
  Failure? failure;
  bool signOutCalled = false;

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
    return const Success(null);
  }

  @override
  ResultFuture<bool> claimActiveWelcomeGift({
    required String deviceIdentifier,
  }) async {
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
    signOutCalled = true;
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

  Widget buildTestWidget({required AuthBloc bloc}) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ar', '')],
      locale: const Locale('en', ''),
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const CompleteProfilePage(),
      ),
    );
  }

  testWidgets(
    'CompleteProfilePage in initial mode renders header and pre-fills user details',
    (tester) async {
      const incompleteUser = AppUser(
        id: 'test-user-id',
        email: 'test@amomy.com',
        fullName: 'Google User',
        roles: [AppRole.passenger],
        isEmailVerified: true,
      );

      fakeRepo.currentUserResult = incompleteUser;
      authBloc.emit(const Authenticated(user: incompleteUser));

      await tester.pumpWidget(buildTestWidget(bloc: authBloc));
      await tester.pumpAndSettle();

      expect(find.text('Complete Your Profile'), findsWidgets);
      expect(find.text('Google User'), findsOneWidget);
      expect(find.text('test@amomy.com'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Save & Continue'), findsOneWidget);

      // In initial completion mode, back button must NOT be rendered (cannot go back)
      expect(find.byType(IconButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    },
  );

  testWidgets(
    'CompleteProfilePage in edit mode renders Personal Information header and does not sign out on back',
    (tester) async {
      final completeUser = AppUser(
        id: 'test-user-id-2',
        email: 'complete@amomy.com',
        fullName: 'Existing Commuter',
        phone: '01012345678',
        gender: 'male',
        dateOfBirth: DateTime(1996, 4, 15),
        roles: const [AppRole.passenger],
        isEmailVerified: true,
      );

      fakeRepo.currentUserResult = completeUser;
      authBloc.emit(Authenticated(user: completeUser));

      await tester.pumpWidget(buildTestWidget(bloc: authBloc));
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsWidgets);
      expect(find.text('Existing Commuter'), findsWidgets);
      expect(find.text('01012345678'), findsWidgets);

      // Tapping back button in edit mode does NOT sign out
      final backButton = find.byType(IconButton).first;
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.signOutCalled, isFalse);
    },
  );

  testWidgets(
    'failed profile edit preserves input form values, shows friendly error, and allows retry',
    (tester) async {
      final completeUser = AppUser(
        id: 'test-user-id-2',
        email: 'complete@amomy.com',
        fullName: 'Existing Commuter',
        phone: '01012345678',
        gender: 'male',
        dateOfBirth: DateTime(1996, 4, 15),
        roles: const [AppRole.passenger],
        isEmailVerified: true,
      );

      fakeRepo.currentUserResult = completeUser;
      authBloc.emit(Authenticated(user: completeUser));

      await tester.pumpWidget(buildTestWidget(bloc: authBloc));
      await tester.pumpAndSettle();

      // 1. User modifies full name
      final fullNameField = find.widgetWithText(
        TextFormField,
        'Existing Commuter',
      );
      expect(fullNameField, findsOneWidget);
      await tester.enterText(fullNameField, 'Updated Commuter Name');
      await tester.pumpAndSettle();

      // 2. Set repository failure (simulating database recursion or server failure)
      fakeRepo.failure = const ServerFailure(
        message:
            'infinite recursion detected in policy for relation "profiles"',
      );

      // 3. Tap Save button and wait for ProfileSaveFailure emission
      final saveButton = find.text('Save & Continue');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump(); // process tap, bloc starts handler
      // Let the full async chain resolve (bloc → use case → repo → emit)
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(); // rebuild with ProfileSaveFailure state
      await tester.pump(const Duration(milliseconds: 300)); // render snackbar

      // 4. Verify state in AuthBloc is ProfileSaveFailure (preserving Authenticated)
      expect(authBloc.state, isA<ProfileSaveFailure>());
      expect(authBloc.state is Unauthenticated, isFalse);

      // 5. Verify friendly error is shown without internal DB leaks
      expect(
        find.text("Couldn't save your changes. Please try again."),
        findsOneWidget,
      );
      expect(find.textContaining('infinite recursion'), findsNothing);

      // 6. Verify form values remain preserved in the form
      expect(find.text('Updated Commuter Name'), findsOneWidget);
      expect(find.text('01012345678'), findsWidgets);

      // 7. Verify user remains on the page
      expect(find.text('Personal Information'), findsWidgets);

      // 8. Fix repository and retry
      fakeRepo.failure = null;
      fakeRepo.currentUserResult = completeUser.copyWith(
        fullName: 'Updated Commuter Name',
      );

      // Dismiss the SnackBar so it doesn't intercept pointer hit tests
      ScaffoldMessenger.of(
        tester.element(find.byType(CompleteProfilePage)),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      final retrySaveButton = find.text('Save & Continue');
      await tester.ensureVisible(retrySaveButton);
      await tester.tap(retrySaveButton);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 9. Verify success
      expect(authBloc.state, isA<Authenticated>());
      expect(
        (authBloc.state as Authenticated).user.fullName,
        equals('Updated Commuter Name'),
      );
    },
  );

  testWidgets(
    'duplicate phone validation error displays friendly specific message',
    (tester) async {
      final completeUser = AppUser(
        id: 'test-user-id-2',
        email: 'complete@amomy.com',
        fullName: 'Existing Commuter',
        phone: '01012345678',
        gender: 'male',
        dateOfBirth: DateTime(1996, 4, 15),
        roles: const [AppRole.passenger],
        isEmailVerified: true,
      );

      fakeRepo.currentUserResult = completeUser;
      authBloc.emit(Authenticated(user: completeUser));

      await tester.pumpWidget(buildTestWidget(bloc: authBloc));
      await tester.pumpAndSettle();

      fakeRepo.failure = const ValidationFailure(
        message:
            'The entered details (phone or email) are already in use by another account.',
        statusCode: 409,
      );

      final saveButton = find.text('Save & Continue');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(authBloc.state, isA<ProfileSaveFailure>());
      expect(
        find.text(
          'The entered details (phone or email) are already in use by another account.',
        ),
        findsOneWidget,
      );
    },
  );
}
