import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';

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
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16.0), child: child),
        ),
      ),
    );
  }

  final sampleTrip = TripOption(
    tripId: 'trip-1',
    routeId: 'route-1',
    direction: BookingDirection.outbound,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    departureTime: '08:00',
    departureAt: DateTime(2026, 9, 16, 8, 0),
    farePoints: 30.0,
    availableSeatsCount: 10,
    status: 'scheduled',
  );

  const sampleStop = RouteStop(
    routeStopId: 'rs-1',
    stopId: 'stop-1',
    stopOrder: 1,
    stopNameAr: 'كوبرى عزت',
    stopNameEn: 'Ezzat Bridge',
    localityAr: 'ميت فضالة',
    localityEn: 'Mit Fadala',
    fareZoneId: 'zone-30',
    farePoints: 30.0,
  );

  const sampleDestStop = RouteStop(
    routeStopId: 'rs-2',
    stopId: 'stop-2',
    stopOrder: 2,
    stopNameAr: 'بوابة توشكى',
    stopNameEn: 'Toshka Gate',
    localityAr: 'المنصورة',
    localityEn: 'Mansoura',
    fareZoneId: 'zone-30',
    farePoints: 30.0,
  );

  const sampleSeat = TripSeat(
    seatId: 'seat-7',
    seatNumber: '7',
    rowIndex: 3,
    columnIndex: 1,
    seatType: 'standard',
    status: SeatAvailabilityStatus.held,
    isMine: true,
  );

  group('BookingReviewCard Widget Tests', () {
    testWidgets('renders trip direction, departure time, stops, and seat', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            routeStop: sampleStop,
            destinationRouteStop: sampleDestStop,
            userAvailablePoints: 100.0,
            onConfirm: () {},
          ),
        ),
      );
      await tester.pump();

      // Trip Direction and Time
      expect(find.text('Outbound'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);

      // Canonical Stops (no separate localities)
      expect(find.text('Ezzat Bridge'), findsOneWidget);
      expect(find.text('Toshka Gate'), findsOneWidget);
      expect(find.text('Mit Fadala'), findsNothing);
      expect(find.text('Mansoura'), findsNothing);

      // Seat number
      expect(find.text('7'), findsOneWidget);

      // Fares & Balances
      expect(find.text('30 Points'), findsNWidgets(2)); // Trip fare and Total
      expect(find.text('100 Points'), findsOneWidget); // Available balance
      expect(find.text('70 Points'), findsOneWidget); // Balance after booking

      // Reassurance note
      expect(
        find.text('You can review your ticket in My Trips after booking.'),
        findsOneWidget,
      );

      // Confirm Button
      expect(find.text('Confirm Booking'), findsOneWidget);
    });

    testWidgets('renders Return direction styling in Arabic RTL', (
      tester,
    ) async {
      final returnTrip = TripOption(
        tripId: 'trip-2',
        routeId: 'route-1',
        direction: BookingDirection.returnTrip,
        originNameAr: 'بوابة توشكى',
        originNameEn: 'Toshka Gate',
        destinationNameAr: 'كوبرى عزت',
        destinationNameEn: 'Ezzat Bridge',
        departureTime: '16:30',
        departureAt: DateTime(2026, 9, 16, 16, 30),
        farePoints: 30.0,
        availableSeatsCount: 15,
        status: 'scheduled',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: returnTrip,
            seat: sampleSeat,
            routeStop: sampleDestStop,
            destinationRouteStop: sampleStop,
            userAvailablePoints: 50.0,
            onConfirm: () {},
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.text('عودة'), findsOneWidget);
      expect(find.text('4:30 م'), findsOneWidget);
      expect(find.text('بوابة توشكى'), findsOneWidget);
      expect(find.text('كوبرى عزت'), findsOneWidget);
      expect(find.text('تأكيد الحجز'), findsOneWidget);
      expect(find.text('ملخص الحجز'), findsOneWidget);
    });

    testWidgets('renders active hold countdown', (tester) async {
      final futureExpiry = DateTime.now().add(
        const Duration(minutes: 4, seconds: 32),
      );
      final seatWithExpiry = TripSeat(
        seatId: 'seat-7',
        seatNumber: '7',
        rowIndex: 3,
        columnIndex: 1,
        seatType: 'standard',
        status: SeatAvailabilityStatus.held,
        isMine: true,
        heldExpiresAt: futureExpiry,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: seatWithExpiry,
            userAvailablePoints: 100.0,
            onConfirm: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Seat held for'), findsOneWidget);
    });

    testWidgets(
      'expired hold disables Confirm button and shows choose seat again',
      (tester) async {
        bool chooseSeatAgainCalled = false;
        final pastExpiry = DateTime.now().subtract(const Duration(seconds: 10));
        final expiredSeat = TripSeat(
          seatId: 'seat-7',
          seatNumber: '7',
          rowIndex: 3,
          columnIndex: 1,
          seatType: 'standard',
          status: SeatAvailabilityStatus.held,
          isMine: true,
          heldExpiresAt: pastExpiry,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            BookingReviewCard(
              trip: sampleTrip,
              seat: expiredSeat,
              userAvailablePoints: 100.0,
              onConfirm: () {},
              onChooseSeatAgain: () => chooseSeatAgainCalled = true,
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text('Your seat hold has expired. Please choose a seat again.'),
          findsOneWidget,
        );
        expect(find.text('Choose Seat Again'), findsOneWidget);

        await tester.tap(find.text('Choose Seat Again'));
        expect(chooseSeatAgainCalled, isTrue);

        // Confirm button should be disabled
        final confirmFinder = find.widgetWithText(
          ElevatedButton,
          'Confirm Booking',
        );
        if (confirmFinder.evaluate().isNotEmpty) {
          final btn = tester.widget<ElevatedButton>(confirmFinder);
          expect(btn.onPressed, isNull);
        }
      },
    );

    testWidgets(
      'insufficient points disables Confirm button and shows deficit warning',
      (tester) async {
        bool confirmCalled = false;
        await tester.pumpWidget(
          buildTestableWidget(
            BookingReviewCard(
              trip: sampleTrip,
              seat: sampleSeat,
              userAvailablePoints: 10.0, // Needs 30, deficit is 20
              onConfirm: () => confirmCalled = true,
            ),
          ),
        );
        await tester.pump();

        expect(
          find.text(
            'Not enough points. You need 20 more points to complete this booking.',
          ),
          findsOneWidget,
        );

        // Try tapping Confirm Booking (disabled when insufficient points)
        await tester.tap(find.text('Confirm Booking'), warnIfMissed: false);
        expect(confirmCalled, isFalse);
      },
    );

    testWidgets('loading state displays indicator and disables button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            userAvailablePoints: 100.0,
            isConfirming: true,
            onConfirm: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'A. Server returns remaining_seconds = 231 -> UI starts at 3:51',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            BookingReviewCard(
              trip: sampleTrip,
              seat: sampleSeat,
              userAvailablePoints: 100.0,
              initialHoldSecondsRemaining: 231,
              onConfirm: () {},
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Seat held for 3:51'), findsOneWidget);
      },
    );

    testWidgets('F. Rebuild/re-enter Review -> no reset to 5:00', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            userAvailablePoints: 100.0,
            initialHoldSecondsRemaining: 180,
            onConfirm: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Seat held for 3:00'), findsOneWidget);
      expect(find.text('Seat held for 5:00'), findsNothing);

      // Rebuild with next Cubit second (179)
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            userAvailablePoints: 100.0,
            initialHoldSecondsRemaining: 179,
            onConfirm: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Seat held for 2:59'), findsOneWidget);
      expect(find.text('Seat held for 5:00'), findsNothing);
    });

    testWidgets('Confirm button: remaining > 0 + valid hold -> enabled', (
      tester,
    ) async {
      bool confirmTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            userAvailablePoints: 100.0,
            initialHoldSecondsRemaining: 150,
            onConfirm: () => confirmTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Confirm Booking'));
      expect(confirmTapped, isTrue);
    });

    testWidgets('Confirm button: remaining = 0 / hold expired -> disabled', (
      tester,
    ) async {
      bool confirmTapped = false;
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeat,
            userAvailablePoints: 100.0,
            initialHoldSecondsRemaining: 0,
            onConfirm: () => confirmTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Confirm Booking'), warnIfMissed: false);
      expect(confirmTapped, isFalse);
      expect(
        find.text('Your seat hold has expired. Please choose a seat again.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Active hold (60 balance before hold, 20 fare -> 40 available after hold) enables confirm, shows 60 before and 40 after',
      (tester) async {
        bool confirmTapped = false;
        final returnTrip = TripOption(
          tripId: 'return-trip-1',
          routeId: 'route-return-1',
          direction: BookingDirection.returnTrip,
          originNameAr: 'بوابة توشكى',
          originNameEn: 'Toshka Gate',
          destinationNameAr: 'كوبرى عزت',
          destinationNameEn: 'Ezzat Bridge',
          departureTime: '16:00',
          departureAt: DateTime(2026, 9, 16, 16, 0),
          farePoints: 20.0,
          availableSeatsCount: 5,
          status: 'scheduled',
        );

        final now = DateTime.now();
        final activeHold = BookingHold(
          holdId: 'hold-123',
          tripId: returnTrip.tripId,
          seatId: 'seat-5',
          seatNumber: '5',
          farePoints: 20.0,
          initialRemainingSeconds: 300,
          serverTime: now,
          expiresAt: now.add(const Duration(minutes: 5)),
        );

        await tester.pumpWidget(
          buildTestableWidget(
            BookingReviewCard(
              trip: returnTrip,
              seat: sampleSeat,
              activeHold: activeHold,
              userAvailablePoints: 40.0, // 60 total before hold - 20 held = 40 remaining
              initialHoldSecondsRemaining: 300,
              onConfirm: () => confirmTapped = true,
            ),
          ),
        );
        await tester.pump();

        // 1. Available balance displayed must be 60 points (40 + 20)
        expect(find.text('60 Points'), findsOneWidget);
        // 2. Balance after booking must be 40 points
        expect(find.text('40 Points'), findsOneWidget);
        // 3. Total fare is 20 points (shown in journey card badge and total fare hero)
        expect(find.text('20 Points'), findsNWidgets(2));
        // 4. Must not show insufficient points warning
        expect(find.textContaining('Not enough points'), findsNothing);

        // 5. Confirm button is enabled and taps successfully
        await tester.tap(find.text('Confirm Booking'));
        expect(confirmTapped, isTrue);
      },
    );
  });
}
