import 'package:amomy_bus/core/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('destructive confirm dialog uses AMOMY surface and confirms', (
    tester,
  ) async {
    var confirmed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showConfirmDialog(
                      context: context,
                      title: 'Confirm Cancellation',
                      message:
                          'Are you sure you want to cancel Seat (1) for the 08:00 trip?\n\n20 Points will be fully refunded to your wallet.',
                      cancelText: 'Keep Booking',
                      confirmText: 'Cancel Booking',
                      isDestructive: true,
                      variant: AppDialogVariant.destructive,
                      onConfirm: () => confirmed = true,
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Confirm Cancellation'), findsOneWidget);
    expect(find.textContaining('20 Points'), findsOneWidget);
    expect(find.text('Keep Booking'), findsOneWidget);
    expect(find.text('Cancel Booking'), findsOneWidget);

    await tester.tap(find.text('Cancel Booking'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(Dialog), findsNothing);
  });
}
