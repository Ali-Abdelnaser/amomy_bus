import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/app_update/domain/entities/app_update_info.dart';
import 'package:amomy_bus/features/app_update/presentation/widgets/app_update_dialog.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('ar'),
      Locale('en'),
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  group('AppUpdateDialog Widget Tests', () {
    testWidgets('renders optional update in Arabic with Later button and closes on tap', (
      tester,
    ) async {
      const updateInfo = AppUpdateInfo(
        updateAvailable: true,
        forceUpdate: false,
        latestVersion: '1.2.0',
        latestBuild: 15,
        storeUrl: 'https://example.com/store',
        message: 'ميزات وتحسينات جديدة بالكامل',
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppUpdateDialog(
                  context: context,
                  updateInfo: updateInfo,
                ),
                child: const Text('Show Update'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsOneWidget);
      expect(find.text('تحديث جديد متاح'), findsOneWidget);
      expect(find.text('الإصدار 1.2.0'), findsOneWidget);
      expect(find.text('ميزات وتحسينات جديدة بالكامل'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
      expect(find.text('لاحقًا'), findsOneWidget);

      // Tap later -> dialog dismisses
      await tester.tap(find.text('لاحقًا'));
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsNothing);
    });

    testWidgets('renders force update in Arabic without Later button and cannot pop', (
      tester,
    ) async {
      const updateInfo = AppUpdateInfo(
        updateAvailable: true,
        forceUpdate: true,
        latestVersion: '2.0.0',
        latestBuild: 20,
        storeUrl: 'https://example.com/store',
        message: 'يجب تحديث التطبيق للمتابعة',
      );

      await tester.pumpWidget(
        _buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppUpdateDialog(
                  context: context,
                  updateInfo: updateInfo,
                ),
                child: const Text('Show Force Update'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show Force Update'));
      await tester.pumpAndSettle();

      expect(find.byType(AppUpdateDialog), findsOneWidget);
      expect(find.text('تحديث جديد متاح'), findsOneWidget);
      expect(find.text('الإصدار 2.0.0'), findsOneWidget);
      expect(find.text('يجب تحديث التطبيق للمتابعة'), findsOneWidget);
      expect(find.text('تحديث الآن'), findsOneWidget);
      // "لاحقًا" must NOT exist
      expect(find.text('لاحقًا'), findsNothing);

      // Verify PopScope blocks popping
      final popScopeFinder = find.byWidgetPredicate(
        (widget) => widget is PopScope && widget.canPop == false,
      );
      expect(popScopeFinder, findsOneWidget);
    });

    testWidgets('renders optional update in English correctly', (tester) async {
      const updateInfo = AppUpdateInfo(
        updateAvailable: true,
        forceUpdate: false,
        latestVersion: '1.2.0',
        latestBuild: 15,
        storeUrl: 'https://example.com/store',
        message: 'Exciting new features available.',
      );

      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('en'),
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppUpdateDialog(
                  context: context,
                  updateInfo: updateInfo,
                ),
                child: const Text('Show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('New update available'), findsOneWidget);
      expect(find.text('Version 1.2.0'), findsOneWidget);
      expect(find.text('Exciting new features available.'), findsOneWidget);
      expect(find.text('Update now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });
  });
}
