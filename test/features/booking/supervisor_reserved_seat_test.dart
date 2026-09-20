import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/models/bus_seat_layout.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_visual.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/professional_bus_seat_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supervisor Reserved Seat UI & Contract Tests', () {
    const supervisorSeat = TripSeat(
      seatId: 'seat-1-uuid',
      seatNumber: '1',
      rowIndex: 0,
      columnIndex: 0,
      seatType: 'supervisor_reserved',
      status: SeatAvailabilityStatus.booked,
      isMine: false,
    );

    const normalAvailableSeat = TripSeat(
      seatId: 'seat-2-uuid',
      seatNumber: '2',
      rowIndex: 1,
      columnIndex: 0,
      seatType: 'standard',
      status: SeatAvailabilityStatus.available,
      isMine: false,
    );

    test('TripSeat entity correctly identifies supervisor_reserved', () {
      expect(supervisorSeat.isSupervisorReserved, isTrue);
      expect(supervisorSeat.isAvailable, isFalse);
      expect(supervisorSeat.isBooked, isTrue);

      expect(normalAvailableSeat.isSupervisorReserved, isFalse);
      expect(normalAvailableSeat.isAvailable, isTrue);
    });

    test(
      'BusSeatLayoutConfig.resolveVisualState prioritizes supervisorReserved over selection/isMine',
      () {
        // 1. Unselected supervisor seat resolves to supervisorReserved
        final visualState = BusSeatLayoutConfig.resolveVisualState(
          seat: supervisorSeat,
          selectedSeat: null,
        );
        expect(visualState, equals(SeatVisualState.supervisorReserved));

        // 2. Even if passed as selectedSeat (e.g. stale state), supervisor seat never resolves to selected
        final visualStateWithSelection = BusSeatLayoutConfig.resolveVisualState(
          seat: supervisorSeat,
          selectedSeat: supervisorSeat,
        );
        expect(
          visualStateWithSelection,
          equals(SeatVisualState.supervisorReserved),
        );

        // 3. Normal seats resolve accurately
        expect(
          BusSeatLayoutConfig.resolveVisualState(
            seat: normalAvailableSeat,
            selectedSeat: null,
          ),
          equals(SeatVisualState.available),
        );
        expect(
          BusSeatLayoutConfig.resolveVisualState(
            seat: normalAvailableSeat,
            selectedSeat: normalAvailableSeat,
          ),
          equals(SeatVisualState.selected),
        );
      },
    );

    testWidgets(
      'BusSeatVisual for supervisorReserved is non-tappable and does not fire onTap',
      (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: BusSeatVisual(
                  label: '1',
                  state: SeatVisualState.supervisorReserved,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Verify seat widget is in tree
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is BusSeatVisual &&
                w.state == SeatVisualState.supervisorReserved &&
                w.label == '1',
          ),
          findsOneWidget,
        );

        // Verify semantics
        expect(find.bySemanticsLabel('Seat 1'), findsOneWidget);

        // Attempt tap
        await tester.tap(find.byType(BusSeatVisual));
        await tester.pump();

        expect(
          tapped,
          isFalse,
          reason: 'Supervisor reserved seat must never trigger onTap',
        );
      },
    );

    testWidgets(
      'ProfessionalBusSeatMap renders Seat 1 beside driver and ignores taps on Seat 1',
      (tester) async {
        TripSeat? tappedSeat;

        final seats = <TripSeat>[supervisorSeat, normalAvailableSeat];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ProfessionalBusSeatMap(
                  seats: seats,
                  selectedSeat: null,
                  onSeatTap: (seat) => tappedSeat = seat,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Find Seat 1 by semantics label
        final seat1Finder = find.bySemanticsLabel('Seat 1');
        expect(
          seat1Finder,
          findsOneWidget,
          reason: 'Seat 1 must remain physically visible',
        );

        // Find Seat 2 by semantics label
        final seat2Finder = find.bySemanticsLabel('Seat 2');
        expect(seat2Finder, findsOneWidget);

        // Tap Seat 1 -> should NOT trigger onSeatTap
        await tester.tap(seat1Finder);
        await tester.pump();
        expect(
          tappedSeat,
          isNull,
          reason: 'Tapping Seat 1 must not call onSeatTap',
        );

        // Tap Seat 2 -> SHOULD trigger onSeatTap
        await tester.tap(seat2Finder);
        await tester.pump();
        expect(tappedSeat, equals(normalAvailableSeat));
      },
    );
  });
}
