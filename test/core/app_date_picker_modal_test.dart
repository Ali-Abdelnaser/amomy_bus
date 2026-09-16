import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/widgets/app_date_picker_modal.dart';
import 'package:amomy_bus/core/widgets/app_date_picker_field.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

Widget buildTestApp({
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
    supportedLocales: const [Locale('ar'), Locale('en')],
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDatePickerModal Widget Tests', () {
    testWidgets(
      'renders modal with backdrop blur, 3 columns, and live date badge',
      (tester) async {
        DateTime? pickedDate;

        await tester.pumpWidget(
          buildTestApp(
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    pickedDate = await showAppDatePicker(
                      context: context,
                      initialDate: DateTime(2000, 5, 15),
                      firstDate: DateTime(1950, 1, 1),
                      lastDate: DateTime(2025, 12, 31),
                      title: 'تحديد تاريخ الميلاد',
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        );

        // Open the date picker modal
        await tester.tap(find.text('Open Picker'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // 1. Verify BackdropFilter (Background Blur) is present
        final backdropFinder = find.byType(BackdropFilter);
        expect(backdropFinder, findsWidgets);

        // 2. Verify Title and Live Date Badge are rendered
        expect(find.text('تحديد تاريخ الميلاد'), findsOneWidget);
        expect(find.textContaining('٢٠٠٠'), findsWidgets);

        // 3. Verify Column Headers: Day, Month, Year (اليوم، الشهر، السنة)
        expect(find.text('اليوم'), findsOneWidget);
        expect(find.text('الشهر'), findsOneWidget);
        expect(find.text('السنة'), findsOneWidget);

        // 4. Verify 3 ListWheelScrollView wheels exist
        final wheelsFinder = find.byType(ListWheelScrollView);
        expect(wheelsFinder, findsNWidgets(3));

        // 5. Verify Confirm Button is rendered
        final confirmBtn = find.text('تأكيد التاريخ');
        expect(confirmBtn, findsOneWidget);

        // Tap Confirm Button
        await tester.tap(confirmBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Modal dismissed and returned date matches initial selection
        expect(pickedDate, isNotNull);
        expect(pickedDate?.year, equals(2000));
        expect(pickedDate?.month, equals(5));
        expect(pickedDate?.day, equals(15));
      },
    );

    testWidgets(
      'renders in English LTR with localized headers and returns picked date',
      (tester) async {
        DateTime? pickedDate;

        await tester.pumpWidget(
          buildTestApp(
            locale: const Locale('en'),
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    pickedDate = await showAppDatePicker(
                      context: context,
                      initialDate: DateTime(2010, 8, 20),
                      firstDate: DateTime(1980, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                    );
                  },
                  child: const Text('Open Picker EN'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Picker EN'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Column Headers in English
        expect(find.text('Day'), findsOneWidget);
        expect(find.text('Month'), findsOneWidget);
        expect(find.text('Year'), findsOneWidget);
        expect(find.text('Select Date'), findsOneWidget);
        expect(find.text('Confirm Date'), findsOneWidget);

        // Tap confirm
        await tester.tap(find.text('Confirm Date'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(pickedDate, equals(DateTime(2010, 8, 20)));
      },
    );

    testWidgets('close icon dismisses modal without returning a date', (
      tester,
    ) async {
      DateTime? pickedDate;

      await tester.pumpWidget(
        buildTestApp(
          child: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  pickedDate = await showAppDatePicker(
                    context: context,
                    initialDate: DateTime(2000, 1, 1),
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Find close button (Icons.close_rounded)
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);

      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(pickedDate, isNull);
      expect(find.byType(AppDatePickerModal), findsNothing);
    });

    testWidgets(
      'AppDatePickerField integrates with AppDatePickerModal seamlessly',
      (tester) async {
        DateTime? selectedDateValue = DateTime(1995, 3, 10);

        await tester.pumpWidget(
          buildTestApp(
            child: StatefulBuilder(
              builder: (context, setState) {
                return AppDatePickerField(
                  label: 'تاريخ الميلاد',
                  hint: 'اختر تاريخ الميلاد',
                  selectedDate: selectedDateValue,
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                  onDateSelected: (newDate) {
                    setState(() => selectedDateValue = newDate);
                  },
                );
              },
            ),
          ),
        );

        // Verify field label is displayed
        expect(find.text('تاريخ الميلاد'), findsOneWidget);

        // Tap the field to trigger custom date picker modal
        await tester.tap(find.byType(InkWell));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Verify custom modal appeared with 3 columns and blur
        expect(find.byType(AppDatePickerModal), findsOneWidget);
        expect(find.byType(BackdropFilter), findsWidgets);

        // Tap confirm
        await tester.tap(find.text('تأكيد التاريخ'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Modal dismissed
        expect(find.byType(AppDatePickerModal), findsNothing);
        expect(selectedDateValue, equals(DateTime(1995, 3, 10)));
      },
    );
  });
}
