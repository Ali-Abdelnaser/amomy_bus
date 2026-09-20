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
import 'package:amomy_bus/features/topup/presentation/widgets/transfer_details_step_widget.dart';
import 'package:amomy_bus/features/topup/presentation/pages/add_points_page.dart';
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('Top-Up Resubmit Flow Tests', () {
    final rejectedRequest = TopUpRequest(
      id: 'req-resubmit-1',
      publicId: 'REQ-2026-0913-001',
      userId: 'u-1',
      requestedAmount: 500,
      expectedAmountEgp: 500,
      paymentMethodCode: 'VODAFONE_CASH',
      paymentMethodNameEn: 'Vodafone Cash',
      receivingPhone: '01012345678',
      senderPhone: '01098765432',
      paymentReference: 'OLD_REF_123',
      status: TopUpStatus.rejected,
      rejectionReason: 'The screenshot could not be verified.',
      createdAt: DateTime(2026, 9, 13, 10, 0),
    );

    testWidgets(
      'TransferDetailsStepWidget displays rejection banner and Resubmit for Review CTA',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            TransferDetailsStepWidget(
              points: 500,
              amountEgp: 500,
              initialSenderPhone: rejectedRequest.senderPhone ?? '',
              initialReference: rejectedRequest.paymentReference ?? '',
              proofBytes: null,
              proofFileName: null,
              isSubmitting: false,
              isResubmit: true,
              rejectionReason: rejectedRequest.rejectionReason,
              onSenderPhoneChanged: (_) {},
              onReferenceChanged: (_) {},
              onTransferredAtChanged: (_) {},
              onProofSelected:
                  ({required bytes, required extension, required fileName}) {},
              onClearProof: () {},
              onSubmit: () {},
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rejection banner
        expect(
          find.text('The screenshot could not be verified.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

        // Resubmit CTA
        expect(find.text('Resubmit for Review'), findsOneWidget);
        expect(find.text('Submit Details'), findsNothing);
      },
    );

    testWidgets(
      'Resubmit flow pre-fills original request details while freezing requested amount',
      (tester) async {
        final fakeRepo = FakeTopUpRepository();
        final cubit = TopUpCubit(
          GetPaymentConfigUseCase(fakeRepo),
          GetActivePaymentMethodsUseCase(fakeRepo),
          CreateTopUpRequestUseCase(fakeRepo),
          SubmitTopUpProofUseCase(fakeRepo),
        );

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: AddPointsPage(
              topUpCubit: cubit,
              resubmitRequest: rejectedRequest,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Resubmit Page Title
        expect(find.text('Resubmit Payment'), findsOneWidget);

        // Frozen requested points & EGP banner
        expect(find.textContaining('500 PTS'), findsOneWidget);
        expect(find.textContaining('EGP 500'), findsOneWidget);

        // Rejection Reason visible
        expect(
          find.text('The screenshot could not be verified.'),
          findsOneWidget,
        );

        // Sender Phone pre-filled
        expect(find.text('01098765432'), findsOneWidget);

        // Transfer Reference pre-filled
        expect(find.text('OLD_REF_123'), findsOneWidget);

        // CTA is Resubmit for Review
        expect(find.text('Resubmit for Review'), findsOneWidget);

        // Step indicator is hidden in resubmit flow
        expect(find.text('Step 1'), findsNothing);
        expect(find.text('Select Amount'), findsNothing);
      },
    );
  });
}
