import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/localization/localization_helpers.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/profile/data/models/profile_configs.dart';
import 'package:amomy_bus/features/profile/domain/repositories/profile_repository.dart';
import 'package:amomy_bus/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:amomy_bus/features/profile/presentation/pages/about_app_page.dart';
import 'package:amomy_bus/features/profile/presentation/pages/privacy_policy_page.dart';
import 'package:amomy_bus/features/profile/presentation/pages/profile_page.dart';
import 'package:amomy_bus/features/profile/presentation/pages/support_center_page.dart';
import 'package:amomy_bus/features/profile/presentation/pages/terms_and_conditions_page.dart';
import 'package:amomy_bus/features/profile/presentation/widgets/profile_identity_header.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  final List<AuthEvent> dispatchedEvents = [];

  MockAuthBloc(super.initialState) {
    on<AuthEvent>((event, emit) {
      dispatchedEvents.add(event);
    });
  }
}

class FakeProfileRepository implements ProfileRepository {
  bool uploadCalled = false;
  bool removeCalled = false;
  String? returnUrl = 'https://example.com/new_avatar.jpg';

  @override
  ResultFuture<String> uploadAvatar({
    required String userId,
    required List<int> imageBytes,
    required String fileExtension,
  }) async {
    uploadCalled = true;
    return Success(returnUrl!);
  }

  @override
  ResultFuture<void> removeAvatar({
    required String userId,
    String? currentAvatarUrl,
  }) async {
    removeCalled = true;
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUserWithAvatar = AppUser(
    id: 'user-profile-101',
    email: 'passenger@amomy.com',
    fullName: 'Mohamed Ahmed',
    phone: '01012345678',
    gender: 'male',
    dateOfBirth: DateTime(1995, 5, 20),
    avatarUrl: 'https://amomy.com/avatar.jpg',
    isEmailVerified: true,
  );

  final testUserWithoutAvatar = AppUser(
    id: 'user-profile-102',
    email: 'fatima@amomy.com',
    fullName: 'Fatima Hassan',
    phone: '01123456789',
    gender: 'female',
    dateOfBirth: DateTime(1998, 10, 15),
    avatarUrl: null,
    isEmailVerified: true,
  );

  Widget createTestWidget({
    required Widget child,
    required AuthBloc authBloc,
    ProfileBloc? profileBloc,
    Locale locale = const Locale('en'),
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        if (profileBloc != null)
          BlocProvider<ProfileBloc>.value(value: profileBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: LocalizationHelper.supportedLocales,
        home: child,
      ),
    );
  }

  group('ProfileIdentityHeader Widget', () {
    testWidgets('renders avatar initials fallback when avatarUrl is null', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: Scaffold(
            body: ProfileIdentityHeader(user: testUserWithoutAvatar),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initials for Fatima Hassan should be FH
      expect(find.text('FH'), findsOneWidget);
      expect(find.text('Fatima Hassan'), findsOneWidget);
      expect(find.text('fatima@amomy.com'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile_camera_badge')), findsOneWidget);
    });

    testWidgets('camera badge opens bottom sheet with options without Remove Photo when no avatar', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: Scaffold(
            body: ProfileIdentityHeader(user: testUserWithoutAvatar),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap camera badge
      await tester.tap(find.byKey(const ValueKey('profile_camera_badge')));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Photos'), findsOneWidget);
      // Remove photo must NOT be shown when no avatar exists
      expect(find.text('Remove Photo'), findsNothing);
    });

    testWidgets('camera badge bottom sheet includes Remove Photo when avatar exists', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: Scaffold(
            body: ProfileIdentityHeader(user: testUserWithAvatar),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap camera badge
      await tester.tap(find.byKey(const ValueKey('profile_camera_badge')));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Photos'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
    });
  });

  group('ProfilePage hierarchy, sections and sign-out', () {
    testWidgets('renders all four sections and all setting tiles', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: ProfilePage(profileBloc: profileBloc),
        ),
      );
      await tester.pumpAndSettle();

      // Identity
      expect(find.text('Fatima Hassan'), findsOneWidget);
      expect(find.text('fatima@amomy.com'), findsOneWidget);

      // Section titles
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('HELP & SUPPORT'), findsOneWidget);
      expect(find.text('ABOUT & LEGAL'), findsOneWidget);

      // Tiles
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Support Center'), findsOneWidget);
      expect(find.text('About AMOMY App'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);

      // Sign out action
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('tapping Sign Out shows confirmation sheet with AMOMY blue action', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: ProfilePage(profileBloc: profileBloc),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Sign Out button is visible and tap it
      await tester.ensureVisible(find.text('Sign Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      // Modal appears
      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Are you sure you want to sign out of your account?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Sign Out confirmation in modal
      final confirmButton = find.widgetWithText(ElevatedButton, 'Sign Out');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Dispatches SignOutRequested
      expect(authBloc.dispatchedEvents, contains(const SignOutRequested()));
    });
  });

  group('Language selection modal bottom sheet', () {
    testWidgets('opens bottom sheet and shows Arabic and English options', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));
      final fakeRepo = FakeProfileRepository();
      final profileBloc = ProfileBloc(repository: fakeRepo);

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          profileBloc: profileBloc,
          child: ProfilePage(profileBloc: profileBloc),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Language tile
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Bottom sheet is visible
      expect(find.text('العربية'), findsAtLeastNWidgets(1));
      expect(find.text('English'), findsAtLeastNWidgets(1));
    });
  });

  group('Dedicated Profile Sub-Pages', () {
    testWidgets('SupportCenterPage renders contact channels and FAQ', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          child: const SupportCenterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Support Center'), findsOneWidget);
      expect(find.text('How can we help?'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Call Us'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Working Hours'), findsOneWidget);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
      expect(find.text('How do I book a seat on a bus?'), findsOneWidget);
    });

    testWidgets('AboutAppPage renders app info and developer placeholder section', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          child: const AboutAppPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About AMOMY App'), findsOneWidget);
      expect(find.text('AMOMY Bus'), findsOneWidget);
      expect(find.text('DEVELOPER'), findsOneWidget);
      expect(find.text(ProfilePlaceholderConfig.developer.developerName), findsOneWidget);
      expect(find.text(ProfilePlaceholderConfig.developer.developerEmail), findsOneWidget);
    });

    testWidgets('PrivacyPolicyPage renders authoritative AMOMY policy sections', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          child: const PrivacyPolicyPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('AMOMY Bus Privacy Policy'), findsOneWidget);
      expect(find.text('1. Information You Provide'), findsOneWidget);
      expect(find.text('4. Bus Tracking & Location Clarification'), findsOneWidget);
    });

    testWidgets('TermsAndConditionsPage renders authoritative AMOMY terms sections', (tester) async {
      final authBloc = MockAuthBloc(Authenticated(user: testUserWithoutAvatar));

      await tester.pumpWidget(
        createTestWidget(
          authBloc: authBloc,
          child: const TermsAndConditionsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('AMOMY Bus Terms & Conditions'), findsOneWidget);
      expect(find.text('1. Service Description'), findsOneWidget);
      expect(find.text('4. Points Wallet, Top-Ups & Refunds'), findsOneWidget);
    });
  });
}
