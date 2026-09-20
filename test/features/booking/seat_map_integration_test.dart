import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/models/bus_seat_layout.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_visual.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/professional_bus_seat_map.dart';

void main() {
  group('BusSeatLayoutConfig — 28-Seat Physical Mapping', () {
    test(
      'all 28 authoritative physical seats (1..28) resolve cleanly to 28 slots',
      () {
        final seats28 = List.generate(28, (i) {
          final seatNum = '${i + 1}';
          return TripSeat(
            seatId: 'seat-$seatNum',
            seatNumber: seatNum,
            rowIndex: i,
            columnIndex: 0,
            seatType: 'standard',
            status: SeatAvailabilityStatus.available,
            isMine: false,
          );
        });

        for (final slot in BusSeatLayoutConfig.slots28) {
          final matched = BusSeatLayoutConfig.resolveSeatForSlot(
            slot: slot,
            seats: seats28,
          );
          expect(
            matched,
            isNotNull,
            reason: 'Slot ${slot.slotKey} must match a real backend seat',
          );
        }
      },
    );

    test('exact 1..28 slot key mapping matches physical specification', () {
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['1'], 'front_single');

      // Left side
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['2'], 'left_r1_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['3'], 'left_r1_aisle');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['4'], 'left_r2_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['5'], 'left_r2_aisle');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['6'], 'left_r3_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['7'], 'left_r3_aisle');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['8'], 'left_r4_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['9'], 'left_r4_aisle');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['10'], 'left_r5_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['11'], 'left_r5_aisle');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['12'], 'left_r6_window');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['13'], 'left_r6_aisle');

      // Right side
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['14'], 'right_r1_aisle');
      expect(
        BusSeatLayoutConfig.seatNumberToSlotKey28['15'],
        'right_r1_window',
      );
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['16'], 'right_r2_aisle');
      expect(
        BusSeatLayoutConfig.seatNumberToSlotKey28['17'],
        'right_r2_window',
      );
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['18'], 'right_r3_aisle');
      expect(
        BusSeatLayoutConfig.seatNumberToSlotKey28['19'],
        'right_r3_window',
      );
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['20'], 'right_r4_aisle');
      expect(
        BusSeatLayoutConfig.seatNumberToSlotKey28['21'],
        'right_r4_window',
      );
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['22'], 'right_r5_aisle');
      expect(
        BusSeatLayoutConfig.seatNumberToSlotKey28['23'],
        'right_r5_window',
      );

      // Rear bench
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['24'], 'rear_1');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['25'], 'rear_2');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['26'], 'rear_3');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['27'], 'rear_4');
      expect(BusSeatLayoutConfig.seatNumberToSlotKey28['28'], 'rear_5');
    });

    test('legacy 14-seat mapping is retained for backwards compatibility', () {
      final legacySeats = [
        const TripSeat(
          seatId: 's1',
          seatNumber: '1A',
          rowIndex: 0,
          columnIndex: 0,
          seatType: 'standard',
          status: SeatAvailabilityStatus.available,
          isMine: false,
        ),
        const TripSeat(
          seatId: 's2',
          seatNumber: '4E',
          rowIndex: 4,
          columnIndex: 4,
          seatType: 'standard',
          status: SeatAvailabilityStatus.available,
          isMine: false,
        ),
      ];

      final frontSlot = BusSeatLayoutConfig.slots28.firstWhere(
        (s) => s.slotKey == 'front_single',
      );
      final rear5Slot = BusSeatLayoutConfig.slots28.firstWhere(
        (s) => s.slotKey == 'rear_5',
      );

      expect(
        BusSeatLayoutConfig.resolveSeatForSlot(
          slot: frontSlot,
          seats: legacySeats,
        )?.seatNumber,
        '1A',
      );
      expect(
        BusSeatLayoutConfig.resolveSeatForSlot(
          slot: rear5Slot,
          seats: legacySeats,
        )?.seatNumber,
        '4E',
      );
    });
  });

  group('BusSeatLayoutConfig — Visual State Resolution Rules', () {
    const baseSeat = TripSeat(
      seatId: 'seat-7',
      seatNumber: '7',
      rowIndex: 3,
      columnIndex: 1,
      seatType: 'standard',
      status: SeatAvailabilityStatus.available,
      isMine: false,
    );

    test('Rule A: Selected by current user resolves to selected', () {
      final state = BusSeatLayoutConfig.resolveVisualState(
        seat: baseSeat,
        selectedSeat: baseSeat,
      );
      expect(state, SeatVisualState.selected);
    });

    test('Rule B: is_mine == true AND status == held resolves to selected', () {
      const myHeldSeat = TripSeat(
        seatId: 'seat-7',
        seatNumber: '7',
        rowIndex: 3,
        columnIndex: 1,
        seatType: 'standard',
        status: SeatAvailabilityStatus.held,
        isMine: true,
      );
      final state = BusSeatLayoutConfig.resolveVisualState(
        seat: myHeldSeat,
        selectedSeat: null,
      );
      expect(state, SeatVisualState.selected);
    });

    test(
      'Rule C: status == booked AND passenger_gender == male resolves to bookedMale',
      () {
        const maleBooked = TripSeat(
          seatId: 'seat-7',
          seatNumber: '7',
          rowIndex: 3,
          columnIndex: 1,
          seatType: 'standard',
          status: SeatAvailabilityStatus.booked,
          isMine: false,
          passengerGender: 'male',
        );
        final state = BusSeatLayoutConfig.resolveVisualState(
          seat: maleBooked,
          selectedSeat: null,
        );
        expect(state, SeatVisualState.bookedMale);
      },
    );

    test(
      'Rule D: status == booked AND passenger_gender == female resolves to bookedFemale',
      () {
        const femaleBooked = TripSeat(
          seatId: 'seat-7',
          seatNumber: '7',
          rowIndex: 3,
          columnIndex: 1,
          seatType: 'standard',
          status: SeatAvailabilityStatus.booked,
          isMine: false,
          passengerGender: 'female',
        );
        final state = BusSeatLayoutConfig.resolveVisualState(
          seat: femaleBooked,
          selectedSeat: null,
        );
        expect(state, SeatVisualState.bookedFemale);
      },
    );

    test(
      'Rule E: status == booked AND passenger_gender == null resolves to unavailable',
      () {
        const unknownBooked = TripSeat(
          seatId: 'seat-7',
          seatNumber: '7',
          rowIndex: 3,
          columnIndex: 1,
          seatType: 'standard',
          status: SeatAvailabilityStatus.booked,
          isMine: false,
          passengerGender: null,
        );
        final state = BusSeatLayoutConfig.resolveVisualState(
          seat: unknownBooked,
          selectedSeat: null,
        );
        expect(state, SeatVisualState.unavailable);
      },
    );

    test('Rule F: status == held AND is_mine == false resolves to held', () {
      const otherHeld = TripSeat(
        seatId: 'seat-7',
        seatNumber: '7',
        rowIndex: 3,
        columnIndex: 1,
        seatType: 'standard',
        status: SeatAvailabilityStatus.held,
        isMine: false,
      );
      final state = BusSeatLayoutConfig.resolveVisualState(
        seat: otherHeld,
        selectedSeat: null,
      );
      expect(state, SeatVisualState.held);
    });

    test('Rule G: status == available resolves to available', () {
      final state = BusSeatLayoutConfig.resolveVisualState(
        seat: baseSeat,
        selectedSeat: null,
      );
      expect(state, SeatVisualState.available);
    });
  });

  group('BusSeatVisual Widget Tests', () {
    Widget buildFrame(Widget child) {
      return MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );
    }

    testWidgets(
      'renders available seat with correct semantics and responds to tap',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          buildFrame(
            BusSeatVisual(
              label: '7',
              state: SeatVisualState.available,
              width: 42,
              height: 48,
              onTap: () => tapped = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.bySemanticsLabel('Seat 7'), findsOneWidget);

        await tester.tap(find.byType(BusSeatVisual));
        expect(tapped, isTrue);
      },
    );

    testWidgets('renders selected seat correctly', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          const BusSeatVisual(
            label: '1',
            state: SeatVisualState.selected,
            width: 42,
            height: 48,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is BusSeatVisual &&
              w.state == SeatVisualState.selected &&
              w.label == '1',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders bookedMale seat as non-tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildFrame(
          BusSeatVisual(
            label: '14',
            state: SeatVisualState.bookedMale,
            width: 42,
            height: 48,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is BusSeatVisual && w.state == SeatVisualState.bookedMale,
        ),
        findsOneWidget,
      );

      // Booked seats are not tappable
      await tester.tap(find.byType(BusSeatVisual));
      expect(tapped, isFalse);
    });

    testWidgets('renders bookedFemale seat as non-tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildFrame(
          BusSeatVisual(
            label: '15',
            state: SeatVisualState.bookedFemale,
            width: 42,
            height: 48,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is BusSeatVisual && w.state == SeatVisualState.bookedFemale,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(BusSeatVisual));
      expect(tapped, isFalse);
    });

    testWidgets('renders held seat with non-tappable semantics', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildFrame(
          BusSeatVisual(
            label: '3',
            state: SeatVisualState.held,
            width: 42,
            height: 48,
            onTap: () => tapped = true,
          ),
        ),
      );
      // Use pump with finite duration because held seat has a repeating pulse animation
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byWidgetPredicate(
          (w) => w is BusSeatVisual && w.state == SeatVisualState.held,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(BusSeatVisual));
      expect(tapped, isFalse);
    });

    testWidgets('renders unavailable seat with null-gender correctly', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildFrame(
          BusSeatVisual(
            label: '28',
            state: SeatVisualState.unavailable,
            width: 42,
            height: 48,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is BusSeatVisual && w.state == SeatVisualState.unavailable,
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(BusSeatVisual));
      expect(tapped, isFalse);
    });
  });

  group('ProfessionalBusSeatMap Widget Tests', () {
    testWidgets('renders all 28 real seats with labels 1 through 28', (
      tester,
    ) async {
      TripSeat? tappedSeat;
      final seats28 = List.generate(28, (i) {
        final seatNum = '${i + 1}';
        return TripSeat(
          seatId: 'id-$seatNum',
          seatNumber: seatNum,
          rowIndex: i,
          columnIndex: 0,
          seatType: 'standard',
          status: SeatAvailabilityStatus.available,
          isMine: false,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfessionalBusSeatMap(
                seats: seats28,
                selectedSeat: null,
                onSeatTap: (s) => tappedSeat = s,
                showFullLayoutPreview: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // All 28 seats must render their semantics label
      for (int i = 1; i <= 28; i++) {
        expect(
          find.bySemanticsLabel('Seat $i'),
          findsOneWidget,
          reason: 'Seat $i should be rendered in 28-seat map',
        );
      }

      // Tap seat 7
      await tester.tap(find.bySemanticsLabel('Seat 7'));
      expect(tappedSeat?.seatNumber, '7');
    });
  });
}
