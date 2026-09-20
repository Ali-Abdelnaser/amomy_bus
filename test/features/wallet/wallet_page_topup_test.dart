import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/presentation/widgets/topup_history_section.dart';

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

  group('TopUpHistorySection widget tests', () {
    testWidgets('renders empty state when no requests exist', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const TopUpHistorySection(requests: [])),
      );
      await tester.pumpAndSettle();

      expect(find.text('No top-up requests yet.'), findsOneWidget);
    });

    testWidgets(
      'renders pending, approved, and rejected request cards with details',
      (tester) async {
        final sampleRequests = [
          TopUpRequest(
            id: 'req-1',
            userId: 'u-1',
            requestedAmount: 500,
            paymentMethodCode: 'VODAFONE_CASH',
            paymentMethodNameEn: 'Vodafone Cash',
            paymentReference: 'VOD_REF_001',
            status: TopUpStatus.pending,
            createdAt: DateTime(2026, 9, 11, 14, 0),
          ),
          TopUpRequest(
            id: 'req-2',
            userId: 'u-1',
            requestedAmount: 200,
            paymentMethodCode: 'ORANGE_CASH',
            paymentMethodNameEn: 'Orange Cash',
            paymentReference: 'ORA_REF_002',
            status: TopUpStatus.approved,
            createdAt: DateTime(2026, 9, 10, 10, 0),
          ),
          TopUpRequest(
            id: 'req-3',
            userId: 'u-1',
            requestedAmount: 100,
            paymentMethodCode: 'VODAFONE_CASH',
            paymentMethodNameEn: 'Vodafone Cash',
            paymentReference: 'VOD_REF_003',
            status: TopUpStatus.rejected,
            rejectionReason: 'Invalid screenshot receipt',
            createdAt: DateTime(2026, 9, 9, 16, 0),
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(TopUpHistorySection(requests: sampleRequests)),
        );
        await tester.pumpAndSettle();

        // Amounts
        expect(find.text('500 PTS'), findsOneWidget);
        expect(find.text('200 PTS'), findsOneWidget);
        expect(find.text('100 PTS'), findsOneWidget);

        // Status badges
        expect(find.text('Under Review'), findsOneWidget);
        expect(find.text('Approved'), findsOneWidget);
        expect(find.text('Rejected'), findsOneWidget);

        // Rejection reason displayed
        expect(
          find.textContaining('Invalid screenshot receipt'),
          findsOneWidget,
        );
      },
    );

    testWidgets('renders Arabic localized statuses and labels', (tester) async {
      final sampleRequests = [
        TopUpRequest(
          id: 'req-1',
          userId: 'u-1',
          requestedAmount: 500,
          paymentMethodCode: 'VODAFONE_CASH',
          paymentMethodNameAr: 'فودافون كاش',
          status: TopUpStatus.pending,
          createdAt: DateTime(2026, 9, 11, 14, 0),
        ),
      ];

      await tester.pumpWidget(
        buildTestableWidget(
          TopUpHistorySection(requests: sampleRequests),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(find.text('500 نقطة'), findsOneWidget);
    });
  });
}
