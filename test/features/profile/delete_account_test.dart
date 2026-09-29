import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:amomy_bus/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:amomy_bus/features/profile/domain/repositories/profile_repository.dart';
import 'package:amomy_bus/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:amomy_bus/features/profile/presentation/pages/profile_page.dart';
import 'package:amomy_bus/features/profile/presentation/widgets/delete_account_bottom_sheet.dart';
import 'package:amomy_bus/features/referral/domain/entities/referral_entities.dart';
import 'package:amomy_bus/features/referral/domain/repositories/referral_repository.dart';
import 'package:amomy_bus/features/referral/domain/usecases/referral_usecases.dart';
import 'package:amomy_bus/features/referral/presentation/cubit/referral_cubit.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  String? lastConfirmedEmail;
  String? lastAuthorizationCode;
  Exception? throwError;
  bool appleUser = true;

  @override
  bool get isAppleUser => appleUser;

  @override
  Future<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async => 'https://example.com/avatar.jpg';

  @override
  Future<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {}

  @override
  Future<void> deleteAccount({required String confirmationEmail}) async {
    lastConfirmedEmail = confirmationEmail;
    if (throwError != null) throw throwError!;
  }

  @override
  Future<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  }) async {
    lastConfirmedEmail = confirmationEmail;
    lastAuthorizationCode = authorizationCode;
    if (throwError != null) throw throwError!;
  }
}

class MockAuthBloc extends Bloc<AuthEvent, AuthState>
    with WidgetsBindingObserver
    implements AuthBloc {
  final List<AuthEvent> dispatchedEvents = [];

  MockAuthBloc(super.initialState) : super() {
    on<SignOutRequested>((event, emit) {
      emit(const Unauthenticated());
    });
  }

  @override
  void add(AuthEvent event) {
    dispatchedEvents.add(event);
    if (event is SignOutRequested) {
      emit(const Unauthenticated());
    } else {
      super.add(event);
    }
  }
}

class TestProfileRepository implements ProfileRepository {
  bool deleteCalled = false;
  bool deleteAppleCalled = false;
  String? lastConfirmedEmail;
  String? lastAppleAuthCode;
  Failure? deleteFailure;
  bool isApple = false;

  @override
  bool get isAppleUser => isApple;

  @override
  ResultFuture<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    return const Success('https://example.com/avatar.jpg');
  }

  @override
  ResultFuture<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {
    return const Success(null);
  }

  @override
  ResultFuture<void> deleteAccount({
    required String confirmationEmail,
  }) {
    deleteCalled = true;
    lastConfirmedEmail = confirmationEmail;
    if (deleteFailure != null) {
      return Future.value(Error(deleteFailure!));
    }
    return Future.value(const Success(null));
  }

  @override
  ResultFuture<void> deleteAppleAccount({
    required String confirmationEmail,
    required String authorizationCode,
  }) {
    deleteAppleCalled = true;
    lastConfirmedEmail = confirmationEmail;
    lastAppleAuthCode = authorizationCode;
    if (deleteFailure != null) {
      return Future.value(Error(deleteFailure!));
    }
    return Future.value(const Success(null));
  }
}

class FakeReferralRepo implements ReferralRepository {
  @override
  ResultFuture<ReferralDashboard> getMyReferralDashboard() async {
    return const Success(
      ReferralDashboard(
        program: ReferralProgramSettings(
          enabled: false,
          monthlyInviteLimit: 5,
          milestoneTripCount: 3,
          inviterFirstRewardPoints: 20,
          inviteeFirstRewardPoints: 5,
          inviterMilestoneRewardPoints: 30,
        ),
        myCode: 'TEST12',
        inviterStats: InviterStats(
          acceptedThisMonth: 0,
          remainingThisMonth: 5,
          totalInvited: 0,
          totalRewardPointsEarned: 0,
        ),
      ),
    );
  }

  @override
  ResultFuture<ReferralCodePreview> previewReferralCode(String code) async {
    return const Success(
      ReferralCodePreview(
        valid: true,
        programEnabled: false,
      ),
    );
  }

  @override
  ResultFuture<BindReferralResult> bindReferralCode({
    required String code,
    required String source,
  }) async {
    return const Success(
      BindReferralResult(
        success: true,
        referralId: 'r1',
        inviterUserId: 'u1',
        inviterName: 'Ali',
        inviteeFirstRewardPoints: 5,
        milestoneTripCount: 3,
      ),
    );
  }

  @override
  Stream<void> subscribeToReferralSettingsUpdates() => const Stream.empty();

  @override
  Stream<void> subscribeToReferralDashboardUpdates() => const Stream.empty();
}

Widget createTestApp({
  required AuthBloc authBloc,
  required ProfileBloc profileBloc,
  required Widget child,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc),
      BlocProvider<ProfileBloc>.value(value: profileBloc),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  const testUser = AppUser(
    id: 'user-001',
    email: 'passenger@amomy.com',
    fullName: 'أحمد علي',
    phone: '01012345678',
    avatarUrl: null,
  );

  group('Delete Account Flow & Rules', () {
    late MockAuthBloc authBloc;
    late TestProfileRepository profileRepo;
    late ProfileBloc profileBloc;

    setUp(() {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository();
      profileBloc = ProfileBloc(repository: profileRepo);
    });

    testWidgets('1. wrong email cannot delete (button stays disabled)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: const DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter mismatching email
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'wrong@amomy.com');
      await tester.pumpAndSettle();

      // Find Delete button
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      expect(deleteBtnFinder, findsOneWidget);
      final deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
      expect(deleteBtn.onPressed, isNull);
    });

    testWidgets('2. matching email enables delete (case-insensitive and trimmed)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: const DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      // Type matching email with whitespace and mixed casing
      await tester.enterText(textField, '  PASSENGER@AMOMY.COM  ');
      await tester.pumpAndSettle();

      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      final deleteBtn = tester.widget<ElevatedButton>(deleteBtnFinder);
      expect(deleteBtn.onPressed, isNotNull);
    });

    testWidgets('3. cancellation does nothing (dialog dismissed, no RPC, no signout)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: const DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete button to open confirmation dialog
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Final confirmation dialog is visible
      expect(find.text('هل أنت متأكد من حذف حسابك نهائيًا؟'), findsOneWidget);

      // Tap Cancel in dialog
      final cancelDialogBtn = find.widgetWithText(TextButton, 'إلغاء');
      await tester.tap(cancelDialogBtn);
      await tester.pumpAndSettle();

      // Dialog closed, no RPC called, no sign out
      expect(find.text('هل أنت متأكد من حذف حسابك نهائيًا؟'), findsNothing);
      expect(profileRepo.deleteCalled, isFalse);
      expect(authBloc.dispatchedEvents, isEmpty);
      expect(authBloc.state, isA<Authenticated>());
    });

    testWidgets('4. success leaves authenticated app (calls RPC, signs out)', (
      tester,
    ) async {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository();
      profileBloc = ProfileBloc(repository: profileRepo);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: const DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete button
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm in dialog
      final confirmBtn = find.widgetWithText(ElevatedButton, 'تأكيد الحذف');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle(); // Dialog finishes popping
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // RPC was called with trimmed email
      expect(profileRepo.deleteCalled, isTrue);
      expect(profileRepo.lastConfirmedEmail, 'passenger@amomy.com');

      // SignOutRequested dispatched to AuthBloc, leaving authenticated state
      expect(authBloc.dispatchedEvents, contains(isA<SignOutRequested>()));
      expect(authBloc.state, isA<Unauthenticated>());
    });

    testWidgets('5. RPC failure keeps account/session safely intact', (
      tester,
    ) async {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository();
      profileBloc = ProfileBloc(repository: profileRepo);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      profileRepo.deleteFailure = const PermissionFailure(
        message: 'PROTECTED_OPERATIONAL_ACCOUNT',
      );

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: const DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف'));
      await tester.pumpAndSettle(); // Dialog finishes popping
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300)); // SnackBar enters

      // RPC was called
      expect(profileRepo.deleteCalled, isTrue);

      // SignOut was NOT dispatched; session remains safely intact
      expect(authBloc.dispatchedEvents, isEmpty);
      expect(authBloc.state, isA<Authenticated>());

      // Error message shown to user
      expect(
        find.text('لا يمكن حذف الحسابات التشغيلية أو الإدارية المحمية من التطبيق.'),
        findsOneWidget,
      );
    });

    testWidgets('6. ProfilePage renders Delete Account tile in Account settings and opens sheet', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final refRepo = FakeReferralRepo();
      final refCubit = ReferralCubit(
        getDashboardUseCase: GetMyReferralDashboardUseCase(refRepo),
        previewCodeUseCase: PreviewReferralCodeUseCase(refRepo),
        bindCodeUseCase: BindReferralCodeUseCase(refRepo),
      );

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: ProfilePage(
            profileBloc: profileBloc,
            referralCubit: refCubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Arabic locale, find 'حذف الحساب' tile
      final deleteTile = find.text('حذف الحساب');
      expect(deleteTile, findsOneWidget);

      // Tap tile to open bottom sheet
      await tester.ensureVisible(deleteTile);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      // Bottom sheet is now open
      expect(find.byType(DeleteAccountBottomSheet), findsOneWidget);
      expect(find.text('البريد الإلكتروني الحالي للحساب:'), findsOneWidget);
      expect(find.text('passenger@amomy.com'), findsAtLeast(1));
    });

    testWidgets('7. Apple user: cancellation does NOT delete account or sign out', (
      tester,
    ) async {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository()..isApple = true;
      profileBloc = ProfileBloc(repository: profileRepo);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
            appleReauthProvider: () async {
              throw const SignInWithAppleAuthorizationException(
                code: AuthorizationErrorCode.canceled,
                message: 'canceled',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));

      // Re-auth cancelled -> do NOT delete account, do NOT sign out, session intact
      expect(profileRepo.deleteAppleCalled, isFalse);
      expect(profileRepo.deleteCalled, isFalse);
      expect(authBloc.dispatchedEvents, isEmpty);
      expect(authBloc.state, isA<Authenticated>());

      // Clean warning snackbar shown
      expect(
        find.text('تم إلغاء التحقق بواسطة Apple ولم يتم حذف الحساب.'),
        findsOneWidget,
      );
    });

    testWidgets('8. Apple user: successful re-auth calls deleteAppleAccount and signs out', (
      tester,
    ) async {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository()..isApple = true;
      profileBloc = ProfileBloc(repository: profileRepo);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
            appleReauthProvider: () async => 'fresh-auth-code-apple-xyz',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete button
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // deleteAppleAccount was called with fresh auth code and confirmation email
      expect(profileRepo.deleteAppleCalled, isTrue);
      expect(profileRepo.lastConfirmedEmail, 'passenger@amomy.com');
      expect(profileRepo.lastAppleAuthCode, 'fresh-auth-code-apple-xyz');
      expect(profileRepo.deleteCalled, isFalse); // Non-Apple RPC not called

      // Signed out and cleared local session
      expect(authBloc.dispatchedEvents, contains(isA<SignOutRequested>()));
      expect(authBloc.state, isA<Unauthenticated>());
    });

    testWidgets('9. Apple user: backend failure keeps session intact and shows clean error', (
      tester,
    ) async {
      authBloc = MockAuthBloc(const Authenticated(user: testUser));
      profileRepo = TestProfileRepository()
        ..isApple = true
        ..deleteFailure = const ValidationFailure(
          message: 'APPLE_IDENTITY_MISMATCH',
        );
      profileBloc = ProfileBloc(repository: profileRepo);

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: DeleteAccountBottomSheet(
            currentEmail: 'passenger@amomy.com',
            appleReauthProvider: () async => 'auth-code-mismatch',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'passenger@amomy.com');
      await tester.pumpAndSettle();

      // Tap delete
      final deleteBtnFinder = find.widgetWithText(ElevatedButton, 'حذف الحساب');
      await tester.ensureVisible(deleteBtnFinder);
      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Confirm in dialog
      await tester.tap(find.widgetWithText(ElevatedButton, 'تأكيد الحذف'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // deleteAppleAccount was called
      expect(profileRepo.deleteAppleCalled, isTrue);

      // SignOut was NOT dispatched; session remains safely intact
      expect(authBloc.dispatchedEvents, isEmpty);
      expect(authBloc.state, isA<Authenticated>());

      // Error message shown to user
      expect(
        find.text('حساب Apple المستخدم لا يطابق الحساب المرتبط بهذا المستخدم.'),
        findsOneWidget,
      );
    });

    test('10. ProfileRepositoryImpl correctly maps all required Apple error codes', () async {
      final fakeRemote = FakeProfileRemoteDataSource();
      final repo = ProfileRepositoryImpl(remoteDataSource: fakeRemote);

      final errorCodes = [
        'APPLE_AUTHORIZATION_CODE_REQUIRED',
        'APPLE_IDENTITY_NOT_LINKED',
        'APPLE_IDENTITY_MISMATCH',
        'APPLE_TOKEN_EXCHANGE_FAILED',
        'APPLE_TOKEN_REVOKE_FAILED',
        'APPLE_REVOKE_TOKEN_MISSING',
      ];

      for (final code in errorCodes) {
        fakeRemote.throwError = FunctionException(
          status: 400,
          details: {'error': code},
          reasonPhrase: code,
        );

        final result = await repo.deleteAppleAccount(
          confirmationEmail: 'test@example.com',
          authorizationCode: 'code',
        );

        expect(result.isError, isTrue);
        expect(result.failureOrNull?.message, code);
      }
    });
  });
}
