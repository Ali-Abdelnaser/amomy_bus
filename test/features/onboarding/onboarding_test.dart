import 'package:amomy_bus/app/di/injection.dart';
import 'package:amomy_bus/core/constants/storage_keys.dart';
import 'package:amomy_bus/core/services/storage_service.dart';
import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/features/onboarding/data/onboarding_local_data_source.dart';
import 'package:amomy_bus/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:amomy_bus/features/onboarding/presentation/widgets/onboarding_content.dart';
import 'package:amomy_bus/features/onboarding/presentation/widgets/onboarding_indicator.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStorageService implements StorageService {
  final Map<String, dynamic> data = {};

  @override
  bool? getBool(String key) => data[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => data[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    data[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => data[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    data.clear();
    return true;
  }
}

Widget createTestableWidget({
  required Widget child,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  late FakeStorageService fakeStorageService;
  late OnboardingLocalDataSource onboardingLocalDataSource;

  setUp(() {
    fakeStorageService = FakeStorageService();
    onboardingLocalDataSource = OnboardingLocalDataSourceImpl(fakeStorageService);

    if (getIt.isRegistered<OnboardingLocalDataSource>()) {
      getIt.unregister<OnboardingLocalDataSource>();
    }
    getIt.registerSingleton<OnboardingLocalDataSource>(onboardingLocalDataSource);
  });

  tearDown(() {
    if (getIt.isRegistered<OnboardingLocalDataSource>()) {
      getIt.unregister<OnboardingLocalDataSource>();
    }
  });

  group('OnboardingLocalDataSource Unit Tests', () {
    test('initially returns false for isOnboardingCompleted', () async {
      final isCompleted = await onboardingLocalDataSource.isOnboardingCompleted();
      expect(isCompleted, isFalse);
    });

    test('setOnboardingCompleted persists true with correct key', () async {
      await onboardingLocalDataSource.setOnboardingCompleted();
      expect(fakeStorageService.getBool(StorageKeys.onboardingCompleted), isTrue);
      final isCompleted = await onboardingLocalDataSource.isOnboardingCompleted();
      expect(isCompleted, isTrue);
    });

    test('resetOnboarding clears persisted completion key', () async {
      await onboardingLocalDataSource.setOnboardingCompleted();
      expect(await onboardingLocalDataSource.isOnboardingCompleted(), isTrue);

      await onboardingLocalDataSource.resetOnboarding();
      expect(await onboardingLocalDataSource.isOnboardingCompleted(), isFalse);
      expect(fakeStorageService.getBool(StorageKeys.onboardingCompleted), isNull);
    });
  });

  group('Onboarding Page and Widgets UI Tests', () {
    testWidgets('renders OnboardingPage with initial slide and indicator', (tester) async {
      await tester.pumpWidget(createTestableWidget(child: const OnboardingPage()));
      await tester.pumpAndSettle();

      // Verify OnboardingContent is present
      expect(find.byType(OnboardingContent), findsOneWidget);
      expect(find.byType(OnboardingIndicator), findsOneWidget);

      // Verify Skip button and Next button exist
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_next_button')), findsOneWidget);

      // Verify page 1 title
      expect(find.text('احجز رحلتك بسهولة'), findsOneWidget);
    });

    testWidgets('renders in English LTR correctly', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          child: const OnboardingPage(),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book Your Ride Easily'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('tapping next advances through slides to last slide', (tester) async {
      await tester.pumpWidget(createTestableWidget(child: const OnboardingPage()));
      await tester.pumpAndSettle();

      // Page 1
      expect(find.text('احجز رحلتك بسهولة'), findsOneWidget);

      // Tap Next to advance to Page 2
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('تابع رحلتك لحظة بلحظة'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);

      // Tap Next to advance to Page 3
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('اركب بسرعة وأمان'), findsOneWidget);
      // On page 3, Skip is hidden and CTA says "ابدأ الآن"
      expect(find.byKey(const Key('onboarding_skip_button')), findsNothing);
      expect(find.text('ابدأ الآن'), findsOneWidget);
    });

    testWidgets('Skip button persists onboarding completion', (tester) async {
      await tester.pumpWidget(createTestableWidget(child: const OnboardingPage()));
      await tester.pumpAndSettle();

      expect(await onboardingLocalDataSource.isOnboardingCompleted(), isFalse);

      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      expect(await onboardingLocalDataSource.isOnboardingCompleted(), isTrue);
    });

    testWidgets('Get Started on last page persists onboarding completion', (tester) async {
      await tester.pumpWidget(createTestableWidget(child: const OnboardingPage()));
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      // Go to page 3
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pumpAndSettle();

      expect(await onboardingLocalDataSource.isOnboardingCompleted(), isTrue);
    });
  });
}
