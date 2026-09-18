import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/wallet/domain/entities/point_transaction.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_summary.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_card_widget.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_pending_points_section.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_points_summary_card.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_transaction_tile.dart';
import 'package:amomy_bus/features/topup/domain/entities/topup_entities.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_history_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/pages/wallet_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_event.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';

class FakeWalletCubit extends Cubit<WalletState> implements WalletCubit {
  FakeWalletCubit(super.initialState);

  @override
  Future<void> loadWalletSummary(String userId) async {}

  @override
  Future<void> loadMoreHistory() async {}
}

class FakeAuthBloc extends Bloc<AuthEvent, AuthState>
    with WidgetsBindingObserver
    implements AuthBloc {
  FakeAuthBloc(super.initialState);
}

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

  group('WalletCardWidget tests', () {
    testWidgets('renders hero card with contactless icon and no clutter', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const WalletCardWidget()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.contactless_rounded), findsOneWidget);
      // Verify no numbers or plus button clutter on the card
      expect(find.text('Available Points'), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });
  });

  group('WalletPointsSummaryCard tests', () {
    testWidgets('renders available points, unit PTS and add points button', (
      tester,
    ) async {
      bool addTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          WalletPointsSummaryCard(
            points: 1340,
            onAddPoints: () => addTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1,340'), findsOneWidget);
      expect(find.text('PTS'), findsOneWidget);
      expect(find.text('Available Points'), findsOneWidget);
      expect(find.text('Add Points'), findsOneWidget);

      await tester.tap(find.text('Add Points'));
      expect(addTapped, isTrue);
    });

    testWidgets('renders localized points summary in Arabic', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          WalletPointsSummaryCard(points: 0, onAddPoints: () {}),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('نقطة'), findsOneWidget);
      expect(find.text('النقاط المتاحة'), findsOneWidget);
      expect(find.text('شحن النقاط'), findsOneWidget);
    });
  });

  group('WalletTransactionTile tests', () {
    testWidgets('renders Trip debit with minus sign', (tester) async {
      final tx = PointTransaction(
        id: 'tx-1',
        userId: 'u-1',
        walletId: 'w-1',
        transactionType: PointTransactionType.debit,
        amount: 30,
        referenceType: 'booking',
        description: 'Trip Booking',
        createdAt: DateTime(2026, 9, 13, 8, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(WalletTransactionTile(transaction: tx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip Booking'), findsOneWidget);
      expect(find.text('-30 PTS'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus_rounded), findsOneWidget);
    });

    testWidgets('renders Points Top-up credit with plus sign', (tester) async {
      final tx = PointTransaction(
        id: 'tx-2',
        userId: 'u-1',
        walletId: 'w-1',
        transactionType: PointTransactionType.credit,
        amount: 500,
        referenceType: 'topup',
        createdAt: DateTime(2026, 9, 13, 11, 42),
      );

      await tester.pumpWidget(
        buildTestableWidget(WalletTransactionTile(transaction: tx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Points Top-up'), findsOneWidget);
      expect(find.text('+500 PTS'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('renders Booking Refund in Arabic', (tester) async {
      final tx = PointTransaction(
        id: 'tx-3',
        userId: 'u-1',
        walletId: 'w-1',
        transactionType: PointTransactionType.credit,
        amount: 30,
        referenceType: 'booking_cancellation',
        createdAt: DateTime(2026, 9, 13, 12, 10),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WalletTransactionTile(transaction: tx),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('استرداد'), findsOneWidget);
      expect(find.text('+30 نقطة'), findsOneWidget);
    });

    testWidgets('renders Bonus for reference_type bonus', (tester) async {
      final tx = PointTransaction(
        id: 'tx-bonus',
        userId: 'u-1',
        walletId: 'w-1',
        transactionType: PointTransactionType.credit,
        amount: 50,
        referenceType: 'bonus',
        createdAt: DateTime(2026, 9, 13, 10, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(WalletTransactionTile(transaction: tx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bonus'), findsOneWidget);
      expect(find.text('+50 PTS'), findsOneWidget);
    });

    testWidgets('renders Gift for reference_type gift', (tester) async {
      final tx = PointTransaction(
        id: 'tx-gift',
        userId: 'u-1',
        walletId: 'w-1',
        transactionType: PointTransactionType.credit,
        amount: 100,
        referenceType: 'gift',
        createdAt: DateTime(2026, 9, 13, 10, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(WalletTransactionTile(transaction: tx)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gift'), findsOneWidget);
      expect(find.text('+100 PTS'), findsOneWidget);
    });

    testWidgets(
      'renders Balance Adjustment for reference_type admin_adjustment',
      (tester) async {
        final tx = PointTransaction(
          id: 'tx-adj',
          userId: 'u-1',
          walletId: 'w-1',
          transactionType: PointTransactionType.credit,
          amount: 25,
          referenceType: 'admin_adjustment',
          createdAt: DateTime(2026, 9, 13, 10, 0),
        );

        await tester.pumpWidget(
          buildTestableWidget(WalletTransactionTile(transaction: tx)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Balance Adjustment'), findsOneWidget);
        expect(find.text('+25 PTS'), findsOneWidget);
      },
    );

    testWidgets(
      'renders Points Adjustment (NEVER Bonus) for unknown reference_type',
      (tester) async {
        final tx = PointTransaction(
          id: 'tx-unknown',
          userId: 'u-1',
          walletId: 'w-1',
          transactionType: PointTransactionType.credit,
          amount: 15,
          referenceType: 'custom_referral_promo',
          createdAt: DateTime(2026, 9, 13, 10, 0),
        );

        await tester.pumpWidget(
          buildTestableWidget(WalletTransactionTile(transaction: tx)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Points Adjustment'), findsOneWidget);
        expect(find.text('Bonus'), findsNothing);
        expect(find.text('+15 PTS'), findsOneWidget);
      },
    );
  });

  group('WalletPendingPointsSection tests', () {
    testWidgets(
      'renders pending top-up with visually dominant points and under review pill',
      (tester) async {
        final request = TopUpRequest(
          id: 'req-pending-1',
          userId: 'u-1',
          requestedAmount: 500,
          expectedAmountEgp: 500,
          paymentMethodCode: 'VODAFONE_CASH',
          paymentMethodNameEn: 'Vodafone Cash',
          status: TopUpStatus.pending,
          submittedAt: DateTime(2026, 9, 13, 14, 32),
          createdAt: DateTime(2026, 9, 13, 14, 30),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            WalletPendingPointsSection(requests: [request], onResubmit: (_) {}),
          ),
        );
        await tester.pumpAndSettle();

        // Heading
        expect(find.text('Pending Points'), findsOneWidget);

        // Dominant points amount
        expect(find.text('500 PTS'), findsOneWidget);

        // Under Review status pill
        expect(find.text('Under Review'), findsOneWidget);
      },
    );

    testWidgets('does not render approved requests in pending section', (
      tester,
    ) async {
      final request = TopUpRequest(
        id: 'req-approved-1',
        userId: 'u-1',
        requestedAmount: 500,
        expectedAmountEgp: 500,
        paymentMethodCode: 'VODAFONE_CASH',
        paymentMethodNameEn: 'Vodafone Cash',
        status: TopUpStatus.approved,
        createdAt: DateTime(2026, 9, 13, 10, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WalletPendingPointsSection(requests: [request], onResubmit: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pending Points'), findsNothing);
      expect(find.text('500 PTS'), findsNothing);
    });

    testWidgets('renders rejected card with friendly reason and Resubmit CTA', (
      tester,
    ) async {
      TopUpRequest? resubmitted;
      final request = TopUpRequest(
        id: 'req-rejected-1',
        userId: 'u-1',
        requestedAmount: 500,
        expectedAmountEgp: 500,
        paymentMethodCode: 'VODAFONE_CASH',
        paymentMethodNameEn: 'Vodafone Cash',
        status: TopUpStatus.rejected,
        rejectionReason: 'The screenshot could not be verified.',
        createdAt: DateTime(2026, 9, 13, 11, 0),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          WalletPendingPointsSection(
            requests: [request],
            onResubmit: (req) => resubmitted = req,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dominant points
      expect(find.text('500 PTS'), findsOneWidget);

      // Rejected status pill
      expect(find.text('Rejected'), findsOneWidget);

      // Friendly rejection message
      expect(
        find.text('The screenshot could not be verified.'),
        findsOneWidget,
      );

      // Resubmit CTA
      expect(find.text('Resubmit'), findsOneWidget);

      await tester.tap(find.text('Resubmit'));
      expect(resubmitted?.id, equals('req-rejected-1'));
    });
  });

  group('WalletPage single points & transactions integration', () {
    const testUser = AppUser(
      id: 'test-user-id',
      email: 'passenger@amomy.com',
      fullName: 'Passenger One',
    );

    testWidgets('renders My Trips style header, hero card, and points summary', (
      tester,
    ) async {
      final fakeAuthBloc = FakeAuthBloc(const Authenticated(user: testUser));
      final fakeWalletCubit = FakeWalletCubit(
        WalletState(
          status: WalletStatus.loaded,
          summary: const WalletSummary(
            totalAvailablePoints: 1340,
            cashPoints: 1000,
            subscriptionPoints: 340,
          ),
          transactions: [
            PointTransaction(
              id: 'tx-1',
              userId: 'test-user-id',
              walletId: 'w-1',
              transactionType: PointTransactionType.debit,
              amount: 30,
              referenceType: 'booking',
              createdAt: DateTime(2026, 9, 13, 8, 0),
            ),
          ],
        ),
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
          home: BlocProvider<AuthBloc>.value(
            value: fakeAuthBloc,
            child: WalletPage(
              walletCubit: fakeWalletCubit,
              topUpHistoryCubit: TopUpHistoryCubit.idle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Centered Title
      expect(find.text('Wallet'), findsOneWidget);

      // Card Add points button
      expect(find.text('Add Points'), findsOneWidget);

      // Hero Card has NFC icon
      expect(find.byIcon(Icons.contactless_rounded), findsOneWidget);

      // Summary Card has points balance
      expect(find.text('1,340'), findsOneWidget);
      expect(find.text('PTS'), findsWidgets);

      // Verify Cash Points and Subscription Points labels are NOT rendered in passenger UI
      expect(find.text('Cash points'), findsNothing);
      expect(find.text('Subscription points'), findsNothing);

      // Verify Recent Transactions header and items
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('Trip Booking'), findsOneWidget);
      expect(find.text('-30 PTS'), findsOneWidget);
    });

    testWidgets(
      'renders 0 PTS and clean empty state when test account has zero balance & transactions',
      (tester) async {
        final fakeAuthBloc = FakeAuthBloc(const Authenticated(user: testUser));
        final fakeWalletCubit = FakeWalletCubit(
          const WalletState(
            status: WalletStatus.loaded,
            summary: WalletSummary(
              totalAvailablePoints: 0,
              cashPoints: 0,
              subscriptionPoints: 0,
            ),
            transactions: [],
          ),
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
            home: BlocProvider<AuthBloc>.value(
              value: fakeAuthBloc,
              child: WalletPage(
                walletCubit: fakeWalletCubit,
                topUpHistoryCubit: TopUpHistoryCubit.idle(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Zero Points
        expect(find.text('0'), findsOneWidget);
        expect(find.text('PTS'), findsWidgets);

        // Empty State
        expect(find.text('No transactions yet'), findsOneWidget);
        expect(
          find.text('Your points activity will appear here.'),
          findsOneWidget,
        );
      },
    );
  });
}
