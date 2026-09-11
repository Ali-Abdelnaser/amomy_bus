import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/usecases/create_topup_request_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/upload_topup_proof_usecase.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:amomy_bus/features/topup/presentation/pages/add_points_page.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/amount_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/payment_method_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/review_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/pending_success_step_widget.dart';
import 'topup_cubit_test.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: child,
    );
  }

  const testMethod = PaymentMethod(
    id: 'pm-1',
    code: 'VODAFONE_CASH',
    nameAr: 'فودافون كاش',
    nameEn: 'Vodafone Cash',
    accountIdentifier: '01000000000',
    instructionsAr: 'قم بالتحويل لرقم فودافون كاش أعلاه',
    instructionsEn: 'Transfer to Vodafone Cash number above',
    iconKey: 'vodafone_cash',
    isActive: true,
    sortOrder: 1,
  );

  group('Add Points UI Steps', () {
    testWidgets('AmountStepWidget displays 1:1 ratio, quick chips, and validates input', (tester) async {
      int changedAmount = 0;
      bool nextTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AmountStepWidget(
              initialAmount: 0,
              onAmountChanged: (val) => changedAmount = val,
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check ratio card
      expect(find.text('1 EGP ≈ 1 Point'), findsOneWidget);

      // Check quick chips
      expect(find.text('100 EGP'), findsOneWidget);
      expect(find.text('500 EGP'), findsOneWidget);

      // Tap quick chip 500 EGP
      await tester.tap(find.text('500 EGP'));
      await tester.pumpAndSettle();
      expect(changedAmount, equals(500));

      // Tap continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(nextTapped, isTrue);
    });

    testWidgets('PaymentMethodStepWidget displays active method and copy account button', (tester) async {
      bool nextTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: PaymentMethodStepWidget(
              methods: const [testMethod],
              selectedMethod: testMethod,
              onMethodSelected: (_) {},
              onNext: () => nextTapped = true,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vodafone Cash'), findsOneWidget);
      expect(find.text('01000000000'), findsAtLeastNWidgets(1));
      expect(find.text('Copy Number'), findsOneWidget);
      expect(find.text('Transfer to Vodafone Cash number above'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(nextTapped, isTrue);
    });

    testWidgets('ReviewStepWidget displays summary and manual review disclaimer', (tester) async {
      bool submitTapped = false;
      const validPngBytes = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: ReviewStepWidget(
              amount: 500,
              method: testMethod,
              reference: 'VOD_12345',
              proofBytes: validPngBytes,
              isSubmitting: false,
              onSubmit: () => submitTapped = true,
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('500 EGP'), findsOneWidget);
      expect(find.text('VOD_12345'), findsOneWidget);
      expect(find.text('Vodafone Cash'), findsOneWidget);
      expect(find.textContaining('not an instant gateway'), findsOneWidget);

      await tester.tap(find.text('Submit Top-Up Request'));
      await tester.pumpAndSettle();
      expect(submitTapped, isTrue);
    });

    testWidgets('PendingSuccessStepWidget displays reassurance and return CTA', (tester) async {
      bool returnTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: PendingSuccessStepWidget(
              requestId: 'req-test-12345678',
              onReturnToWallet: () => returnTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top-up request submitted'), findsOneWidget);
      expect(find.textContaining('under review'), findsOneWidget);
      expect(find.text('Return to Wallet'), findsOneWidget);

      await tester.tap(find.text('Return to Wallet'));
      await tester.pumpAndSettle();
      expect(returnTapped, isTrue);
    });

    testWidgets('Arabic RTL renders correctly in AmountStepWidget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AmountStepWidget(
              initialAmount: 200,
              onAmountChanged: (_) {},
              onNext: () {},
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المبلغ'), findsAtLeastNWidgets(1));
      expect(find.text('1 جنيه ≈ 1 نقطة'), findsOneWidget);
      expect(find.text('المتابعة'), findsOneWidget);
    });
  });

  group('AddPointsPage integration', () {
    testWidgets('renders full page with topup cubit', (tester) async {
      final fakeRepo = FakeTopUpRepository()..methods = [testMethod];
      final cubit = TopUpCubit(
        GetActivePaymentMethodsUseCase(fakeRepo),
        CreateTopUpRequestUseCase(fakeRepo),
        UploadTopUpProofUseCase(fakeRepo),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AddPointsPage(topUpCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Points'), findsOneWidget);
      expect(find.byType(AmountStepWidget), findsOneWidget);
    });
  });
}
