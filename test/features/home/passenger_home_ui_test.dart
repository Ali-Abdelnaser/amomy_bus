import 'package:amomy_bus/features/home/presentation/widgets/home_app_bar.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(HomeAppBar appBar) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Scaffold(body: appBar),
    );
  }

  testWidgets('notification badge keeps its compact 10-plus display', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const HomeAppBar(
          fullName: 'Ali Commuter',
          unreadNotificationsCount: 10,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9+'), findsOneWidget);
  });
}
