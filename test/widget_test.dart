import 'package:amomy_bus/core/theme/app_theme.dart';
import 'package:amomy_bus/core/widgets/app_button.dart';
import 'package:amomy_bus/core/widgets/app_card.dart';
import 'package:amomy_bus/core/widgets/app_loading.dart';
import 'package:amomy_bus/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppTheme light theme has official brand blue #01589F', (
    tester,
  ) async {
    final theme = AppTheme.lightTheme;
    expect(theme.colorScheme.primary, const Color(0xFF01589F));
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
  });

  testWidgets('AppLoading renders correctly with message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppLoading(message: 'Loading Amomy Bus...')),
      ),
    );

    expect(find.text('Loading Amomy Bus...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppButton renders label and responds to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppButton(text: 'Confirm Seat', onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Confirm Seat'), findsOneWidget);
    await tester.tap(find.text('Confirm Seat'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('AppButton with icon does not overflow in narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: AppButton(
                text: 'Cancel Booking',
                icon: Icons.cancel_outlined,
                onPressed: null,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Cancel Booking'), findsOneWidget);
  });

  testWidgets('AppCard and AppBadge render correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: AppCard(
            child: Row(
              children: [
                const Text('Card Title'),
                AppBadge.success(label: 'Active'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Card Title'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('AppPasswordField toggles obscureText correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: AppPasswordField(label: 'Password')),
      ),
    );

    expect(find.text('Password'), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);

    // Tap visibility toggle
    await tester.tap(find.byType(IconButton));
    await tester.pump();
  });
}
