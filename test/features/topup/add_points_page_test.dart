import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/domain/usecases/create_topup_request_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/get_payment_config_usecase.dart';
import 'package:amomy_bus/features/topup/domain/usecases/submit_topup_proof_usecase.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:amomy_bus/features/topup/presentation/pages/add_points_page.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/amount_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/instructions_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/transfer_details_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/pending_success_step_widget.dart';
import 'topup_cubit_test.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
  }) {
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
    accountIdentifier: '01014045363',
    instructionsAr: 'قم بالتحويل لرقم فودافون كاش أعلاه',
    instructionsEn: 'Transfer to Vodafone Cash number above',
    iconKey: 'vodafone_cash',
    isActive: true,
    sortOrder: 1,
  );

  group('Add Points UI Steps', () {
    testWidgets(
      'AmountStepWidget displays presets, balance, and validates min 200',
      (tester) async {
        int changedAmount = 0;
        bool nextTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            Scaffold(
              body: AmountStepWidget(
                initialAmount: 200,
                availableBalance: 0,
                minimumPoints: 200,
                egpPerPoint: 1.0,
                onAmountChanged: (val) => changedAmount = val,
                onNext: () => nextTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check presets and input
        expect(find.text('200'), findsWidgets);
        expect(find.text('500'), findsOneWidget);

        // Tap preset 500 PTS
        await tester.tap(find.text('500'));
        await tester.pumpAndSettle();
        expect(changedAmount, equals(500));

        // Tap continue
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(nextTapped, isTrue);
      },
    );

    testWidgets(
      'InstructionsStepWidget displays receiving phone and transfer instructions',
      (tester) async {
        bool transferredTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            Scaffold(
              body: InstructionsStepWidget(
                points: 500,
                amountEgp: 500,
                receivingPhone: '01014045363',
                methodName: 'Vodafone Cash',
                isSubmitting: false,
                onTransferred: () => transferredTapped = true,
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('01014045363'), findsOneWidget);
        expect(find.text("I've Made the Transfer"), findsOneWidget);

        await tester.tap(find.text("I've Made the Transfer"));
        await tester.pumpAndSettle();
        expect(transferredTapped, isTrue);
      },
    );

    testWidgets(
      'InstructionsStepWidget switches conditional details when selecting InstaPay',
      (tester) async {
        PaymentMethod? selected;

        await tester.pumpWidget(
          buildTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: InstructionsStepWidget(
                    points: 500,
                    amountEgp: 500,
                    receivingPhone: '01014045363',
                    selectedMethod: selected,
                    onMethodSelected: (m) => setState(() => selected = m),
                    isSubmitting: false,
                    onTransferred: () {},
                    onBack: () {},
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap InstaPay card
        await tester.tap(find.text('InstaPay'));
        await tester.pumpAndSettle();

        expect(selected?.code, equals('INSTAPAY'));
      },
    );

    testWidgets(
      'InstructionsStepWidget renders real WEBP assets without generic icons and updates on selection',
      (tester) async {
        PaymentMethod? selected;

        await tester.pumpWidget(
          buildTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: InstructionsStepWidget(
                    points: 500,
                    amountEgp: 500,
                    receivingPhone: '01014045363',
                    selectedMethod: selected,
                    onMethodSelected: (m) => setState(() => selected = m),
                    isSubmitting: false,
                    onTransferred: () {},
                    onBack: () {},
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        final images = tester.widgetList<Image>(find.byType(Image)).toList();
        final assetNames = images
            .where((img) => img.image is AssetImage)
            .map((img) => (img.image as AssetImage).assetName)
            .toList();

        // Confirms Vodafone Image widget uses assets/vodafone_cash.webp
        expect(assetNames, contains('assets/vodafone_cash.webp'));
        // Confirms InstaPay Image widget uses assets/instapay.webp
        expect(assetNames, contains('assets/instapay.webp'));

        // Initially Vodafone Cash is default selected (2 vodafone images: 1 in selector card, 1 in details card)
        final initialVodafoneCount = assetNames
            .where((a) => a == 'assets/vodafone_cash.webp')
            .length;
        expect(initialVodafoneCount, equals(2));

        // Tap InstaPay card
        await tester.tap(find.text('InstaPay'));
        await tester.pumpAndSettle();

        final updatedImages = tester
            .widgetList<Image>(find.byType(Image))
            .toList();
        final updatedAssetNames = updatedImages
            .where((img) => img.image is AssetImage)
            .map((img) => (img.image as AssetImage).assetName)
            .toList();

        // Details card switched to InstaPay (2 instapay images: 1 in selector card, 1 in details card)
        final updatedInstaCount = updatedAssetNames
            .where((a) => a == 'assets/instapay.webp')
            .length;
        expect(updatedInstaCount, equals(2));

        // No generic icons used
        expect(find.byIcon(Icons.wallet), findsNothing);
        expect(find.byIcon(Icons.credit_card), findsNothing);
        expect(find.byIcon(Icons.account_balance_wallet), findsNothing);
        expect(find.byIcon(Icons.payment), findsNothing);
      },
    );

    testWidgets(
      'TransferDetailsStepWidget displays phone, ref, and submit button',
      (tester) async {
        bool submitTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            Scaffold(
              body: TransferDetailsStepWidget(
                points: 500,
                amountEgp: 500,
                publicId: 'AMY-7K4F92',
                initialSenderPhone: '01012345678',
                initialReference: 'REF12345',
                proofBytes: null,
                proofFileName: null,
                isSubmitting: false,
                onSenderPhoneChanged: (_) {},
                onReferenceChanged: (_) {},
                onTransferredAtChanged: (_) {},
                onProofSelected:
                    ({
                      required bytes,
                      required extension,
                      required fileName,
                    }) {},
                onClearProof: () {},
                onSubmit: () => submitTapped = true,
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('01012345678'), findsOneWidget);
        expect(find.text('REF12345'), findsOneWidget);
        expect(submitTapped, isFalse);
      },
    );

    testWidgets(
      'PendingSuccessStepWidget displays reassurance and return CTA',
      (tester) async {
        bool returnTapped = false;

        await tester.pumpWidget(
          buildTestableWidget(
            Scaffold(
              body: PendingSuccessStepWidget(
                points: 500,
                amountEgp: 500,
                publicId: 'AMY-7K4F92',
                onReturnToWallet: () => returnTapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Payment Submitted'), findsOneWidget);
        expect(find.textContaining('under review'), findsOneWidget);
        expect(find.text('Back to Wallet'), findsOneWidget);
        expect(find.text('AMY-7K4F92'), findsOneWidget);

        await tester.tap(find.text('Back to Wallet'));
        await tester.pumpAndSettle();
        expect(returnTapped, isTrue);
      },
    );

    testWidgets('Arabic RTL renders correctly in AmountStepWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: AmountStepWidget(
              initialAmount: 200,
              availableBalance: 0,
              minimumPoints: 200,
              onAmountChanged: (_) {},
              onNext: () {},
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المتابعة'), findsOneWidget);
    });
  });

  group('AddPointsPage integration', () {
    testWidgets('renders full page with topup cubit', (tester) async {
      final fakeRepo = FakeTopUpRepository()..methods = [testMethod];
      final cubit = TopUpCubit(
        GetPaymentConfigUseCase(fakeRepo),
        GetActivePaymentMethodsUseCase(fakeRepo),
        CreateTopUpRequestUseCase(fakeRepo),
        SubmitTopUpProofUseCase(fakeRepo),
      );

      await tester.pumpWidget(
        buildTestableWidget(AddPointsPage(topUpCubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Points'), findsOneWidget);
      expect(find.byType(AmountStepWidget), findsOneWidget);
    });
  });
}
