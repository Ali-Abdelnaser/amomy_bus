import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/app/router/app_router.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
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
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/home/presentation/pages/passenger_home_page.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_booking_cta.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_header.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_profile_completion_card.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_upcoming_trip_section.dart';
import 'package:amomy_bus/features/home/presentation/widgets/home_wallet_card.dart';
import 'package:amomy_bus/features/profile/presentation/pages/profile_page.dart';
import 'package:amomy_bus/features/shell/presentation/widgets/floating_bottom_nav_bar.dart';
import 'package:amomy_bus/features/trips/presentation/pages/my_trips_page.dart';
import 'package:amomy_bus/features/wallet/presentation/pages/wallet_page.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

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
        cashPoints: 250,
        subscriptionPoints: 1000,
      ),
    );
  }

  @override
  ResultFuture<void> signOut() async {
    if (failure != null) return Error(failure!);
    return const Success(null);
  }
}

final _dummyRepo = FakeAuthRepository();

class MockAuthBloc extends AuthBloc {
  MockAuthBloc(AuthState initialState)
      : super(
          getCurrentUserUseCase: GetCurrentUserUseCase(_dummyRepo),
          signInWithEmailUseCase: SignInWithEmailUseCase(_dummyRepo),
          signUpWithEmailUseCase: SignUpWithEmailUseCase(_dummyRepo),
          signInWithGoogleUseCase: SignInWithGoogleUseCase(_dummyRepo),
          signOutUseCase: SignOutUseCase(_dummyRepo),
          sendPasswordResetUseCase: SendPasswordResetUseCase(_dummyRepo),
          updatePasswordUseCase: UpdatePasswordUseCase(_dummyRepo),
          completeProfileUseCase: CompleteProfileUseCase(_dummyRepo),
          verifyOtpUseCase: VerifyOtpUseCase(_dummyRepo),
          resendOtpUseCase: ResendOtpUseCase(_dummyRepo),
          getWalletPreviewUseCase: GetWalletPreviewUseCase(_dummyRepo),
        ) {
    emit(initialState);
  }
}

Widget createTestWidget({
  required Widget child,
  required AuthBloc authBloc,
  Locale locale = const Locale('en'),
}) {
  return BlocProvider<AuthBloc>.value(
    value: authBloc,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  const incompleteUser = AppUser(
    id: 'usr-1234-uuid',
    email: 'ali@example.com',
    fullName: 'Ali Abdelnaser',
    roles: [AppRole.passenger],
    isEmailVerified: true,
  );

  final completeUser = incompleteUser.copyWith(
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1995, 5, 20),
  );

  const testWallet = WalletPreview(
    id: 'w-1',
    userId: 'usr-1234-uuid',
    cashPoints: 250,
    subscriptionPoints: 1000,
    heldPoints: 0,
  );

  group('AppUser name parsing and helpers', () {
    test('firstName extracts first word cleanly', () {
      expect(incompleteUser.firstName, 'Ali');
      expect(const AppUser(id: '1', email: '', fullName: 'John Doe').firstName, 'John');
      expect(const AppUser(id: '1', email: '', fullName: '').firstName, 'Commuter');
    });

    test('initials extracts 2 initials or defaults', () {
      expect(incompleteUser.initials, 'AA');
      expect(const AppUser(id: '1', email: '', fullName: 'Mohamed').initials, 'M');
      expect(const AppUser(id: '1', email: '', fullName: '').initials, 'A');
    });
  });

  group('HomeHeader widget', () {
    testWidgets('displays user first name and initials fallback without debug info', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(body: HomeHeader(user: incompleteUser)),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      // First name with wave
      expect(find.textContaining('Ali 👋'), findsOneWidget);
      // Avatar initials
      expect(find.text('AA'), findsOneWidget);

      // Must NOT display sensitive or debug information
      expect(find.text('ali@example.com'), findsNothing);
      expect(find.text('usr-1234-uuid'), findsNothing);
      expect(find.text('passenger'), findsNothing);
    });
  });

  group('HomeProfileCompletionCard widget', () {
    testWidgets('shows when profile is incomplete with percentage', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(body: HomeProfileCompletionCard(user: incompleteUser)),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
    });

    testWidgets('is completely hidden when profile is complete', (tester) async {
      final bloc = MockAuthBloc(Authenticated(user: completeUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(body: HomeProfileCompletionCard(user: completeUser)),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Complete your profile'), findsNothing);
      expect(find.byType(HomeProfileCompletionCard), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('HomeWalletCard widget', () {
    testWidgets('displays points balance and breakdown without money symbols', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(
            body: HomeWalletCard(
              totalPoints: 1250,
              cashPoints: 250,
              subscriptionPoints: 1000,
            ),
          ),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Points Balance'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
      expect(find.textContaining('Cash points: 250'), findsOneWidget);
      expect(find.textContaining('Subscription points: 1,000'), findsOneWidget);
      expect(find.text('Add Points'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Must NOT display dollar signs, EGP or money labels as balance title
      expect(find.text('Money Balance'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });
  });

  group('PassengerHomePage production components & clean UI', () {
    testWidgets('renders all production sections and NO dev/debug elements', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const PassengerHomePage(),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      // Components present
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(HomeProfileCompletionCard), findsOneWidget);
      expect(find.byType(HomeWalletCard), findsOneWidget);
      expect(find.byType(HomeBookingCta), findsOneWidget);
      expect(find.byType(HomeUpcomingTripSection), findsOneWidget);
      expect(find.byType(HomeQuickActions), findsOneWidget);

      // Booking CTA text
      expect(find.text('Book Now'), findsOneWidget);

      // Empty upcoming trip text
      expect(find.text('No upcoming trip'), findsOneWidget);
      expect(find.text('Book a Ride'), findsOneWidget);

      // Quick actions
      expect(find.text('Subscriptions'), findsOneWidget);

      // Must NOT have dev placeholder items
      expect(find.text('Passenger Home'), findsNothing);
      expect(find.text('Active Role'), findsNothing);
      expect(find.text('Design System Gallery'), findsNothing);
      expect(find.text('Sign Out'), findsNothing); // Sign Out is strictly in Profile
      expect(find.text('Reset'), findsNothing);
    });
  });

  group('ProfilePage', () {
    testWidgets('contains user info, menu items and Sign Out button', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const ProfilePage(),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ali Abdelnaser'), findsOneWidget);
      expect(find.text('ali@example.com'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(find.text('About AMOMY'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);

      // Sign Out exists in Profile
      expect(find.text('Sign Out'), findsOneWidget);

      // Must NOT display Active Role or technical IDs
      expect(find.text('Active Role'), findsNothing);
      expect(find.text('usr-1234-uuid'), findsNothing);
    });
  });

  group('MyTripsPage and WalletPage tabs', () {
    testWidgets('MyTripsPage renders Upcoming and History tabs with empty state', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const MyTripsPage(),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('No upcoming trip'), findsOneWidget);
    });

    testWidgets('WalletPage renders balance and transactions empty state', (tester) async {
      final bloc = MockAuthBloc(const Authenticated(user: incompleteUser, wallet: testWallet));

      await tester.pumpWidget(
        createTestWidget(
          child: const WalletPage(),
          authBloc: bloc,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Points Balance'), findsOneWidget);
      expect(find.text('1,250'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Your points recharge and trip payments will show here.'), findsOneWidget);
    });
  });

  group('Passenger Shell Integration and Router Navigation', () {
    testWidgets('Authenticated user enters PassengerShell and switches tabs via bottom nav', (tester) async {
      final bloc = MockAuthBloc(Authenticated(user: completeUser, wallet: testWallet));
      final appRouter = AppRouter(bloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Starts at Home tab
      expect(find.byType(PassengerHomePage), findsOneWidget);
      expect(find.byType(HomeBookingCta), findsOneWidget);
      expect(find.byType(FloatingBottomNavBar), findsOneWidget);

      // Tap My Trips bottom nav item (index 1)
      final myTripsTab = find.byKey(const ValueKey('floating_nav_item_1'));
      await tester.tap(myTripsTab);
      await tester.pumpAndSettle();

      expect(find.byType(MyTripsPage), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // Tap Wallet bottom nav item (index 2)
      final walletTab = find.byKey(const ValueKey('floating_nav_item_2'));
      await tester.tap(walletTab);
      await tester.pumpAndSettle();

      expect(find.byType(WalletPage), findsOneWidget);
      expect(find.text('Points Balance'), findsOneWidget);

      // Tap Profile bottom nav item (index 3)
      final profileTab = find.byKey(const ValueKey('floating_nav_item_3'));
      await tester.tap(profileTab);
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Design System Gallery must NOT appear anywhere in the shell
      expect(find.text('Design System Gallery'), findsNothing);
    });

    test('designSystem route is guarded by kDebugMode in AppRouter', () {
      final bloc = MockAuthBloc(const Unauthenticated());
      final appRouter = AppRouter(bloc);
      final hasDesignSystemRoute = appRouter.router.configuration.routes.any(
        (route) => route.toString().contains('/design-system'),
      );

      expect(hasDesignSystemRoute, equals(kDebugMode));
    });
  });
}
