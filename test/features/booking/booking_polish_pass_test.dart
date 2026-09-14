import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/domain/repositories/booking_repository.dart';
import 'package:amomy_bus/features/booking/domain/usecases/booking_usecases.dart';
import 'package:amomy_bus/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_map_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_visual.dart';
import 'package:amomy_bus/features/booking/domain/models/bus_seat_layout.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class _FakeBookingRepository implements BookingRepository {
  List<RouteStop> routeStops = [];
  List<TripOption> trips = [];
  List<TripSeat> seats = [];
  List<PassengerBooking> passengerBookings = [];
  BookingHold? hold;
  PassengerBooking? confirmedBooking;

  @override
  ResultFuture<List<RouteStop>> getRouteStops({
    required BookingDirection direction,
  }) async =>
      Success(routeStops);

  @override
  ResultFuture<List<TripOption>> getAvailableTrips({
    required BookingDirection direction,
    DateTime? date,
    String? routeStopId,
  }) async =>
      Success(trips);

  @override
  ResultFuture<List<TripSeat>> getTripSeatMap({required String tripId}) async =>
      Success(seats);

  @override
  ResultFuture<BookingHold> createBookingHold({
    required String tripId,
    required String seatId,
    String? routeStopId,
    String? destinationRouteStopId,
  }) async =>
      Success(hold!);

  @override
  ResultFuture<void> releaseBookingHold({required String holdId}) async =>
      const Success(null);

  @override
  ResultFuture<PassengerBooking> confirmBooking({required String holdId}) async =>
      Success(confirmedBooking!);

  @override
  ResultFuture<List<PassengerBooking>> getPassengerBookings() async =>
      Success(passengerBookings);

  @override
  ResultFuture<List<PassengerTodayTrip>> getPassengerTodayTrips({
    String? direction,
    String? originRouteStopId,
  }) async =>
      const Success([]);

  @override
  ResultFuture<PassengerTripPreference?> getMyTripPreferences() async =>
      const Success(null);

  @override
  ResultFuture<PassengerTripPreference> setMyTripPreferences({
    required String originStopId,
    required String destinationStopId,
  }) async =>
      throw UnimplementedError();

  @override
  Stream<void> subscribeToTripSeatUpdates(String tripId) =>
      const Stream.empty();

  @override
  ResultFuture<void> cancelBooking(String bookingId) async =>
      const Success(null);

  @override
  ResultFuture<void> changeBookingSeat({
    required String bookingId,
    required String newSeatId,
  }) async =>
      const Success(null);
}

void main() {
  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
  }) {
    return MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  final sampleTrip1 = TripOption(
    tripId: 'trip-0800',
    routeId: 'route-outbound',
    direction: BookingDirection.outbound,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(hours: 1)),
    farePoints: 25.0,
    availableSeatsCount: 15,
    status: 'scheduled',
  );

  final sampleTrip2 = TripOption(
    tripId: 'trip-0900',
    routeId: 'route-outbound',
    direction: BookingDirection.outbound,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    departureTime: '09:00',
    departureAt: DateTime.now().add(const Duration(hours: 2)),
    farePoints: 25.0,
    availableSeatsCount: 4, // few seats left
    status: 'scheduled',
  );

  final sampleTripReturn = TripOption(
    tripId: 'trip-1400',
    routeId: 'route-return',
    direction: BookingDirection.returnTrip,
    originNameAr: 'بوابة توشكى',
    originNameEn: 'Toshka Gate',
    destinationNameAr: 'كوبرى عزت',
    destinationNameEn: 'Ezzat Bridge',
    departureTime: '14:00',
    departureAt: DateTime.now().add(const Duration(hours: 5)),
    farePoints: 25.0,
    availableSeatsCount: 20,
    status: 'scheduled',
  );

  final sampleSeatAvailable = const TripSeat(
    seatId: 'seat-1',
    seatNumber: '1',
    rowIndex: 0,
    columnIndex: 0,
    seatType: 'standard',
    status: SeatAvailabilityStatus.available,
    isMine: false,
  );

  final sampleSeatHeld = const TripSeat(
    seatId: 'seat-4',
    seatNumber: '4',
    rowIndex: 1,
    columnIndex: 0,
    seatType: 'standard',
    status: SeatAvailabilityStatus.held,
    isMine: false,
  );

  group('DEPARTURE TIME REDESIGN & FILTERING TESTS', () {
    // 1. departure options render vertically
    testWidgets('1. departure options render vertically in a column', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DepartureTimeSelector(
            trips: [sampleTrip1, sampleTrip2],
            selectedTrip: null,
            direction: BookingDirection.outbound,
            onTripSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstFinder = find.text('08:00');
      final secondFinder = find.text('09:00');

      expect(firstFinder, findsOneWidget);
      expect(secondFinder, findsOneWidget);

      final firstY = tester.getTopLeft(firstFinder).dy;
      final secondY = tester.getTopLeft(secondFinder).dy;

      // Vertical stacking: second item is strictly below the first
      expect(secondY, greaterThan(firstY));
    });

    // 2. only one option selected at a time
    testWidgets('2. only one option selected at a time with radio behavior', (tester) async {
      TripOption? selected;
      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return DepartureTimeSelector(
                trips: [sampleTrip1, sampleTrip2],
                selectedTrip: selected,
                direction: BookingDirection.outbound,
                onTripSelected: (t) => setState(() => selected = t),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 08:00
      await tester.tap(find.text('08:00'));
      await tester.pumpAndSettle();
      expect(selected?.tripId, 'trip-0800');
      expect(find.text('Selected'), findsOneWidget);

      // Tap 09:00
      await tester.tap(find.text('09:00'));
      await tester.pumpAndSettle();
      expect(selected?.tripId, 'trip-0900');
      // Only ONE item displays Selected
      expect(find.text('Selected'), findsOneWidget);
    });

    // 3. existing booked trip is removed
    test('3. existing booked trip is removed from available options', () async {
      final repo = _FakeBookingRepository();
      repo.trips = [sampleTrip1, sampleTrip2];
      repo.passengerBookings = [
        PassengerBooking(
          bookingId: 'b-1',
          tripId: 'trip-0800',
          direction: BookingDirection.outbound,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'بوابة توشكى',
          destinationNameEn: 'Toshka Gate',
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          departureAt: DateTime.now().add(const Duration(hours: 1)),
          seatNumber: '5',
          farePoints: 25.0,
          status: 'confirmed',
          qrToken: 'TOKEN1',
          bookedAt: DateTime.now(),
        ),
      ];

      final cubit = BookingCubit(
        getRouteStopsUseCase: GetRouteStopsUseCase(repo),
        getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
        getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
        createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
        releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
        confirmBookingUseCase: ConfirmBookingUseCase(repo),
        getPassengerBookingsUseCase: GetPassengerBookingsUseCase(repo),
      );

      await cubit.initBooking();

      expect(cubit.state.availableTrips.length, 1);
      expect(cubit.state.availableTrips.first.tripId, 'trip-0900');
      expect(cubit.state.availableTrips.any((t) => t.tripId == 'trip-0800'), isFalse);
    });

    // 4. cancelled booking does not incorrectly block if canonical business rule allows rebooking
    test('4. cancelled booking does not block rebooking the same trip', () async {
      final repo = _FakeBookingRepository();
      repo.trips = [sampleTrip1, sampleTrip2];
      repo.passengerBookings = [
        PassengerBooking(
          bookingId: 'b-cancelled',
          tripId: 'trip-0800',
          direction: BookingDirection.outbound,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'بوابة توشكى',
          destinationNameEn: 'Toshka Gate',
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          departureAt: DateTime.now().add(const Duration(hours: 1)),
          seatNumber: '5',
          farePoints: 25.0,
          status: 'cancelled',
          qrToken: 'TOKEN_CAN',
          bookedAt: DateTime.now(),
        ),
      ];

      final cubit = BookingCubit(
        getRouteStopsUseCase: GetRouteStopsUseCase(repo),
        getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
        getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
        createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
        releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
        confirmBookingUseCase: ConfirmBookingUseCase(repo),
        getPassengerBookingsUseCase: GetPassengerBookingsUseCase(repo),
      );

      await cubit.initBooking();

      expect(cubit.state.availableTrips.length, 2);
      expect(cubit.state.availableTrips.any((t) => t.tripId == 'trip-0800'), isTrue);
    });

    // 5. outbound and return filtering are independent
    test('5. outbound and return filtering are independent', () async {
      final repo = _FakeBookingRepository();
      repo.trips = [sampleTripReturn];
      // User booked outbound 08:00
      repo.passengerBookings = [
        PassengerBooking(
          bookingId: 'b-out',
          tripId: 'trip-0800',
          direction: BookingDirection.outbound,
          originNameAr: 'كوبرى عزت',
          originNameEn: 'Ezzat Bridge',
          destinationNameAr: 'بوابة توشكى',
          destinationNameEn: 'Toshka Gate',
          serviceDate: DateTime.now(),
          departureTime: '08:00',
          departureAt: DateTime.now().add(const Duration(hours: 1)),
          seatNumber: '5',
          farePoints: 25.0,
          status: 'confirmed',
          qrToken: 'TOKEN_OUT',
          bookedAt: DateTime.now(),
        ),
      ];

      final cubit = BookingCubit(
        getRouteStopsUseCase: GetRouteStopsUseCase(repo),
        getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
        getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
        createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
        releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
        confirmBookingUseCase: ConfirmBookingUseCase(repo),
        getPassengerBookingsUseCase: GetPassengerBookingsUseCase(repo),
      );

      await cubit.initBooking(initialDirection: BookingDirection.returnTrip);

      // Return trip 14:00 is NOT blocked by outbound booking
      expect(cubit.state.availableTrips.length, 1);
      expect(cubit.state.availableTrips.first.tripId, 'trip-1400');
    });

    // 6. specific-trip flow displays selected time correctly
    testWidgets('6. specific-trip flow displays locked selected time correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DepartureTimeSelector(
            trips: [sampleTrip1],
            selectedTrip: sampleTrip1,
            direction: BookingDirection.outbound,
            isTripLocked: true,
            onTripSelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Selected Trip'), findsOneWidget);
    });

    // 7. no available trips shows proper empty state
    testWidgets('7. no available trips shows proper empty state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DepartureTimeSelector(
            trips: const [],
            selectedTrip: null,
            direction: BookingDirection.outbound,
            onTripSelected: (_) {},
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('انتهت رحلات اليوم'), findsOneWidget);
      expect(find.text('تابع التطبيق غداً لمواعيد الرحلات الجديدة.'), findsOneWidget);
    });
  });

  group('SEAT MAP & AVATARS TESTS', () {
    // 8. bus entrance starts below final position and completes
    testWidgets('8. bus entrance starts below final position and completes', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BusSeatMapWidget(
            seats: [sampleSeatAvailable],
            selectedSeat: null,
            onSeatTap: (_) {},
          ),
        ),
      );

      // Inspect initial slide position before animation completes
      final slideFinder = find.descendant(
        of: find.byType(BusSeatMapWidget),
        matching: find.byType(SlideTransition),
      );
      expect(slideFinder, findsOneWidget);

      final SlideTransition initialSlide = tester.widget(slideFinder);
      expect(initialSlide.position.value.dy, greaterThan(0.0));

      // Advance clock to completion
      await tester.pumpAndSettle();

      final SlideTransition completedSlide = tester.widget(slideFinder);
      expect(completedSlide.position.value, Offset.zero);
    });

    // 9. animation does not replay on seat selection/state rebuild
    testWidgets('9. animation does not replay on seat selection/rebuild', (tester) async {
      TripSeat? selected;
      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return BusSeatMapWidget(
                seats: [sampleSeatAvailable],
                selectedSeat: selected,
                onSeatTap: (s) => setState(() => selected = s),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at zero
      final slideFinder = find.descendant(
        of: find.byType(BusSeatMapWidget),
        matching: find.byType(SlideTransition),
      );
      SlideTransition slide = tester.widget(slideFinder);
      expect(slide.position.value, Offset.zero);

      // Tap seat to select
      await tester.tap(find.byType(BusSeatVisual).first);
      await tester.pump(const Duration(milliseconds: 50));

      // Must remain at Offset.zero without dropping to 0.75
      slide = tester.widget(slideFinder);
      expect(slide.position.value, Offset.zero);
    });

    // 10. animation can replay on actual re-entry into seat-map step
    testWidgets('10. animation can replay on re-entry (fresh widget mount)', (tester) async {
      bool inSeatMap = true;
      late StateSetter triggerSetState;

      await tester.pumpWidget(
        buildTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              triggerSetState = setState;
              if (inSeatMap) {
                return BusSeatMapWidget(
                  seats: [sampleSeatAvailable],
                  selectedSeat: null,
                  onSeatTap: (_) {},
                );
              }
              return const Text('Review Step');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch away to Review step
      triggerSetState(() => inSeatMap = false);
      await tester.pumpAndSettle();
      expect(find.text('Review Step'), findsOneWidget);

      // Return back to Seat Map
      triggerSetState(() => inSeatMap = true);
      await tester.pump(); // frame 1 of re-entry

      final SlideTransition reenteredSlide = tester.widget(
        find.descendant(of: find.byType(BusSeatMapWidget), matching: find.byType(SlideTransition)),
      );
      expect(reenteredSlide.position.value.dy, greaterThan(0.0));

      await tester.pumpAndSettle();
      final SlideTransition finishedSlide = tester.widget(
        find.descendant(of: find.byType(BusSeatMapWidget), matching: find.byType(SlideTransition)),
      );
      expect(finishedSlide.position.value, Offset.zero);
    });

    // 11. reduced motion shows final bus immediately
    testWidgets('11. reduced motion shows final bus position immediately', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BusSeatMapWidget(
            seats: [sampleSeatAvailable],
            selectedSeat: null,
            onSeatTap: (_) {},
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump(); // frame 1

      final SlideTransition slide = tester.widget(
        find.descendant(of: find.byType(BusSeatMapWidget), matching: find.byType(SlideTransition)),
      );
      expect(slide.position.value, Offset.zero);
    });

    // 12. initially booked male seat shows avatar without selecting any seat
    testWidgets('12. initially booked male seat shows avatar on first frame', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BusSeatVisual(
            label: '2',
            state: SeatVisualState.bookedMale,
            width: 40,
            height: 50,
          ),
        ),
      );
      await tester.pump(); // First frame

      // CustomPaint is immediately rendered with avatarOpacity = 1.0 (no need to wait for seat tap)
      expect(find.byType(BusSeatVisual), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(BusSeatVisual), matching: find.byType(CustomPaint)),
      );
      final dynamic painter = customPaint.painter;
      expect(painter.avatarOpacity, equals(1.0));
      expect(painter.state, equals(SeatVisualState.bookedMale));
    });

    // 13. initially booked female seat shows avatar without selecting any seat
    testWidgets('13. initially booked female seat shows avatar on first frame', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BusSeatVisual(
            label: '3',
            state: SeatVisualState.bookedFemale,
            width: 40,
            height: 50,
          ),
        ),
      );
      await tester.pump(); // First frame

      expect(find.byType(BusSeatVisual), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(BusSeatVisual), matching: find.byType(CustomPaint)),
      );
      final dynamic painter = customPaint.painter;
      expect(painter.avatarOpacity, equals(1.0));
      expect(painter.state, equals(SeatVisualState.bookedFemale));
    });

    // 14. held seat icon appears immediately
    testWidgets('14. held seat icon appears immediately on first frame', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const BusSeatVisual(
            label: '4',
            state: SeatVisualState.held,
            width: 40,
            height: 50,
          ),
        ),
      );
      await tester.pump(); // First frame

      expect(find.byType(BusSeatVisual), findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(BusSeatVisual), matching: find.byType(CustomPaint)),
      );
      final dynamic painter = customPaint.painter;
      expect(painter.avatarOpacity, equals(1.0));
      expect(painter.state, equals(SeatVisualState.held));
    });

    // 15. successful seat hold uses bottom inline banner, not center dialog
    testWidgets('15. successful seat hold uses bottom banner, not center dialog', (tester) async {
      final repo = _FakeBookingRepository();
      repo.trips = [sampleTrip1];
      repo.seats = [sampleSeatAvailable];
      repo.hold = BookingHold(
        holdId: 'hold-1',
        tripId: 'trip-0800',
        seatId: 'seat-1',
        seatNumber: '1',
        farePoints: 25.0,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        serverTime: DateTime.now(),
      );

      final cubit = BookingCubit(
        getRouteStopsUseCase: GetRouteStopsUseCase(repo),
        getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
        getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
        createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
        releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
        confirmBookingUseCase: ConfirmBookingUseCase(repo),
        getPassengerBookingsUseCase: GetPassengerBookingsUseCase(repo),
      );

      await cubit.initBooking();
      cubit.selectTrip(sampleTrip1);
      await cubit.selectSeatAndHold(sampleSeatAvailable);

      expect(cubit.state.activeHold, isNotNull);
      expect(cubit.state.selectedSeat?.seatNumber, '1');
      expect(cubit.state.holdSecondsRemaining, greaterThan(0));

      await cubit.close();
    });

    // 16. changing seat updates banner/hold without timer stacking
    testWidgets('16. changing seat updates banner/hold cleanly without timer stacking', (tester) async {
      final repo = _FakeBookingRepository();
      repo.trips = [sampleTrip1];
      repo.seats = [sampleSeatAvailable, sampleSeatHeld];
      repo.hold = BookingHold(
        holdId: 'hold-1',
        tripId: 'trip-0800',
        seatId: 'seat-1',
        seatNumber: '1',
        farePoints: 25.0,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        serverTime: DateTime.now(),
      );

      final cubit = BookingCubit(
        getRouteStopsUseCase: GetRouteStopsUseCase(repo),
        getAvailableTripsUseCase: GetAvailableTripsUseCase(repo),
        getTripSeatMapUseCase: GetTripSeatMapUseCase(repo),
        createBookingHoldUseCase: CreateBookingHoldUseCase(repo),
        releaseBookingHoldUseCase: ReleaseBookingHoldUseCase(repo),
        confirmBookingUseCase: ConfirmBookingUseCase(repo),
        getPassengerBookingsUseCase: GetPassengerBookingsUseCase(repo),
      );

      await cubit.initBooking();
      cubit.selectTrip(sampleTrip1);
      await cubit.selectSeatAndHold(sampleSeatAvailable);

      expect(cubit.state.selectedSeat?.seatNumber, '1');

      // Select seat 2
      final seat2 = const TripSeat(
        seatId: 'seat-2',
        seatNumber: '2',
        rowIndex: 0,
        columnIndex: 1,
        seatType: 'standard',
        status: SeatAvailabilityStatus.available,
        isMine: false,
      );

      repo.hold = BookingHold(
        holdId: 'hold-2',
        tripId: 'trip-0800',
        seatId: 'seat-2',
        seatNumber: '2',
        farePoints: 25.0,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        serverTime: DateTime.now(),
      );

      await cubit.selectSeatAndHold(seat2);

      expect(cubit.state.selectedSeat?.seatNumber, '2');
      expect(cubit.state.activeHold?.holdId, 'hold-2');

      await cubit.close();
    });
  });
}
