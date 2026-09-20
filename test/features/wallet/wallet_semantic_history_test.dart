import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_history_event.dart';
import 'package:amomy_bus/features/wallet/data/models/wallet_history_event_model.dart';
import 'package:amomy_bus/features/wallet/presentation/widgets/wallet_history_event_tile.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_cubit.dart';
import 'package:amomy_bus/features/wallet/presentation/cubit/wallet_state.dart';
import 'package:amomy_bus/features/wallet/domain/entities/wallet_summary.dart';
import 'package:amomy_bus/features/wallet/presentation/pages/wallet_page.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/topup/presentation/cubit/topup_history_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FakeTestWalletCubit extends Cubit<WalletState> implements WalletCubit {
  bool loadMoreCalled = false;

  FakeTestWalletCubit(super.initialState);

  @override
  Future<void> loadWalletSummary(String userId) async {}

  @override
  Future<void> loadMoreHistory() async {
    loadMoreCalled = true;
  }
}

class FakeTestAuthBloc extends Cubit<AuthState> implements AuthBloc {
  FakeTestAuthBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildWidget(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: Scaffold(body: child),
    );
  }

  group('Phase 5C Semantic Wallet History Tests', () {
    testWidgets('A. trip_booking renders "Trip Booking" and negative amount', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-1',
        semanticType: WalletSemanticType.tripBooking,
        signedAmount: -25,
        createdAt: DateTime(2026, 9, 16, 8, 0),
        tripDirection: 'outbound',
        departureAt: DateTime(2026, 9, 16, 8, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip Booking'), findsOneWidget);
      expect(find.text('-25 PTS'), findsOneWidget);
      expect(find.textContaining('Outbound'), findsOneWidget);
    });

    testWidgets('B. extra_seat renders "Extra Seat" and negative amount', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-2',
        semanticType: WalletSemanticType.extraSeat,
        signedAmount: -25,
        createdAt: DateTime(2026, 9, 16, 8, 0),
        tripDirection: 'outbound',
        seatNumber: '12',
        departureAt: DateTime(2026, 9, 16, 8, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Extra Seat'), findsOneWidget);
      expect(find.text('-25 PTS'), findsOneWidget);
      expect(find.textContaining('Seat 12'), findsOneWidget);
    });

    testWidgets('C. refund renders "Refund" and positive amount', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-3',
        semanticType: WalletSemanticType.refund,
        signedAmount: 25,
        createdAt: DateTime(2026, 9, 16, 12, 0),
        tripDirection: 'return',
        departureAt: DateTime(2026, 9, 16, 13, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('+25 PTS'), findsOneWidget);
    });

    testWidgets('D. points_topup renders "Points Top-up" and positive amount', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-4',
        semanticType: WalletSemanticType.pointsTopup,
        signedAmount: 200,
        createdAt: DateTime(2026, 9, 16, 10, 30),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Points Top-up'), findsOneWidget);
      expect(find.text('+200 PTS'), findsOneWidget);
    });

    testWidgets('E. extra_points renders "Extra Points" and positive amount', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-5',
        semanticType: WalletSemanticType.extraPoints,
        signedAmount: 50,
        createdAt: DateTime(2026, 9, 16, 11, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Extra Points'), findsOneWidget);
      expect(find.text('+50 PTS'), findsOneWidget);
    });

    testWidgets(
      'F. points_expired renders "Points Expired" and negative amount',
      (tester) async {
        final event = WalletHistoryEvent(
          eventId: 'evt-6',
          semanticType: WalletSemanticType.pointsExpired,
          signedAmount: -30,
          createdAt: DateTime(2026, 9, 16, 0, 0),
        );

        await tester.pumpWidget(
          buildWidget(WalletHistoryEventTile(event: event)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Points Expired'), findsOneWidget);
        expect(find.text('-30 PTS'), findsOneWidget);
      },
    );

    testWidgets('G. balance_adjustment respects backend sign (+ or -)', (
      tester,
    ) async {
      final creditAdj = WalletHistoryEvent(
        eventId: 'evt-7a',
        semanticType: WalletSemanticType.balanceAdjustment,
        signedAmount: 15,
        createdAt: DateTime(2026, 9, 16, 14, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: creditAdj)),
      );
      await tester.pumpAndSettle();
      expect(find.text('+15 PTS'), findsOneWidget);
      expect(find.text('Balance Adjustment'), findsOneWidget);

      final debitAdj = WalletHistoryEvent(
        eventId: 'evt-7b',
        semanticType: WalletSemanticType.balanceAdjustment,
        signedAmount: -10,
        createdAt: DateTime(2026, 9, 16, 14, 5),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: debitAdj)),
      );
      await tester.pumpAndSettle();
      expect(find.text('-10 PTS'), findsOneWidget);
    });

    testWidgets('H. null signed_amount renders neutral safe presentation "—"', (
      tester,
    ) async {
      final event = WalletHistoryEvent(
        eventId: 'evt-8',
        semanticType: WalletSemanticType.balanceAdjustment,
        signedAmount: null,
        createdAt: DateTime(2026, 9, 16, 15, 0),
      );

      await tester.pumpWidget(
        buildWidget(WalletHistoryEventTile(event: event)),
      );
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets(
      'I. unknown semantic_type displays neutral Transaction / معاملة and never Balance Adjustment',
      (tester) async {
        final event = WalletHistoryEvent(
          eventId: 'evt-9',
          semanticType: WalletSemanticType.fromString('some_future_new_type'),
          signedAmount: 40,
          createdAt: DateTime(2026, 9, 16, 16, 0),
        );

        // English
        await tester.pumpWidget(
          buildWidget(WalletHistoryEventTile(event: event)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Transaction'), findsOneWidget);
        expect(find.text('Balance Adjustment'), findsNothing);
        expect(find.text('Points Adjustment'), findsNothing);
        expect(find.text('+40 PTS'), findsOneWidget);

        // Arabic
        await tester.pumpWidget(
          buildWidget(
            WalletHistoryEventTile(event: event),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('معاملة'), findsOneWidget);
        expect(find.text('تعديل رصيد'), findsNothing);
        expect(find.text('تعديل نقاط'), findsNothing);
      },
    );

    testWidgets(
      'J. round_trip_booking renders "حجز ذهاب وعودة" in Arabic and signed amount',
      (tester) async {
        final json = {
          'event_id': 'rt-evt-1',
          'semantic_type': 'round_trip_booking',
          'signed_amount': -34,
          'created_at': '2026-09-21T13:24:43.308087+00:00',
          'bundle_id': '020e0892-3bd5-4bf4-9059-ebd46b7a2e9d',
          'outbound_departure_at': '2026-09-21T05:00:00+00:00',
          'return_departure_at': '2026-09-21T13:00:00+00:00',
          'outbound_seat_number': '2',
          'return_seat_number': '2',
          'total_paid_points': 34,
        };
        final event = WalletHistoryEventModel.fromJson(json);
        expect(event.semanticType, WalletSemanticType.roundTripBooking);
        expect(event.signedAmount, -34);
        expect(event.bundleId, '020e0892-3bd5-4bf4-9059-ebd46b7a2e9d');

        // Arabic
        await tester.pumpWidget(
          buildWidget(
            WalletHistoryEventTile(event: event),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('حجز ذهاب وعودة'), findsOneWidget);
        expect(find.text('تعديل رصيد'), findsNothing);
        expect(find.text('-34 نقطة'), findsOneWidget);

        // English
        await tester.pumpWidget(
          buildWidget(
            WalletHistoryEventTile(event: event),
            locale: const Locale('en'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Round Trip Booking'), findsOneWidget);
        expect(find.text('Balance Adjustment'), findsNothing);
        expect(find.text('-34 PTS'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 5C.1: invalid or missing created_at never displays a fabricated current timestamp and omits date/time',
      (tester) async {
        // Missing created_at
        final jsonMissing = {
          'event_id': 'evt-no-date',
          'semantic_type': 'points_topup',
          'signed_amount': 50,
        };
        final eventMissing = WalletHistoryEventModel.fromJson(jsonMissing);
        expect(eventMissing.createdAt, isNull);

        // Invalid string created_at
        final jsonInvalid = {
          'event_id': 'evt-invalid-date',
          'semantic_type': 'points_topup',
          'signed_amount': 50,
          'created_at': 'not-a-valid-date-format',
        };
        final eventInvalid = WalletHistoryEventModel.fromJson(jsonInvalid);
        expect(eventInvalid.createdAt, isNull);

        // Render widget with null createdAt
        await tester.pumpWidget(
          buildWidget(WalletHistoryEventTile(event: eventMissing)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Points Top-up'), findsOneWidget);
        expect(find.text('+50 PTS'), findsOneWidget);

        // Verify no date or time text widget is rendered
        final nowYear = DateTime.now().year.toString();
        expect(find.textContaining(nowYear), findsNothing);
        // Only Title and Amount exist (subtitle is omitted)
        expect(find.byType(Text), findsNWidgets(2));
      },
    );

    testWidgets(
      'Phase 5C.1: balance_adjustment still displays its own correct label in EN and AR',
      (tester) async {
        final adjEvent = WalletHistoryEvent(
          eventId: 'evt-adj',
          semanticType: WalletSemanticType.balanceAdjustment,
          signedAmount: 15,
          createdAt: DateTime(2026, 9, 16, 12, 0),
        );

        // English
        await tester.pumpWidget(
          buildWidget(WalletHistoryEventTile(event: adjEvent)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Balance Adjustment'), findsOneWidget);

        // Arabic
        await tester.pumpWidget(
          buildWidget(
            WalletHistoryEventTile(event: adjEvent),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('تعديل رصيد'), findsOneWidget);
      },
    );

    testWidgets('J & K & L. Pagination: renders Load More and preserves list', (
      tester,
    ) async {
      final page1Event = WalletHistoryEvent(
        eventId: 'evt-p1',
        semanticType: WalletSemanticType.tripBooking,
        signedAmount: -25,
        createdAt: DateTime(2026, 9, 16, 8, 0),
      );

      final fakeCubit = FakeTestWalletCubit(
        WalletState(
          status: WalletStatus.loaded,
          summary: const WalletSummary(
            totalAvailablePoints: 500,
            cashPoints: 500,
            subscriptionPoints: 0,
          ),
          historyEvents: [page1Event],
          hasMoreHistory: true,
          nextCursor: const WalletHistoryCursor(
            createdAt: '2026-09-16T08:00:00Z',
            eventId: 'evt-p1',
          ),
        ),
      );

      final fakeAuth = FakeTestAuthBloc(
        const Authenticated(
          user: AppUser(
            id: 'user-1',
            email: 'user@example.com',
            phone: '01014045363',
            fullName: 'Test User',
          ),
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
            value: fakeAuth,
            child: WalletPage(
              walletCubit: fakeCubit,
              topUpHistoryCubit: TopUpHistoryCubit.idle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Load older transactions'), findsOneWidget);
      await tester.ensureVisible(find.text('Load older transactions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load older transactions'));
      await tester.pump();

      expect(fakeCubit.loadMoreCalled, isTrue);
    });

    testWidgets(
      'M. legacy event with missing optional trip fields does not crash',
      (tester) async {
        final legacyEvent = WalletHistoryEvent(
          eventId: 'evt-legacy',
          semanticType: WalletSemanticType.tripBooking,
          signedAmount: -20,
          createdAt: DateTime(2026, 9, 15, 8, 0),
          // No trip_direction, departure_at, seat_number, stop names
        );

        await tester.pumpWidget(
          buildWidget(WalletHistoryEventTile(event: legacyEvent)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Trip Booking'), findsOneWidget);
        expect(find.text('-20 PTS'), findsOneWidget);
      },
    );

    testWidgets(
      'N. RTL Arabic transaction row renders symmetrically without overflow',
      (tester) async {
        final arEvent = WalletHistoryEvent(
          eventId: 'evt-ar',
          semanticType: WalletSemanticType.extraSeat,
          signedAmount: -25,
          createdAt: DateTime(2026, 9, 16, 9, 0),
          tripDirection: 'outbound',
          departureAt: DateTime(2026, 9, 16, 9, 0),
          seatNumber: '4',
        );

        await tester.pumpWidget(
          buildWidget(
            WalletHistoryEventTile(event: arEvent),
            locale: const Locale('ar'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('مقعد إضافي'), findsOneWidget);
        expect(find.text('-25 نقطة'), findsOneWidget);
        expect(find.textContaining('مقعد 4'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
