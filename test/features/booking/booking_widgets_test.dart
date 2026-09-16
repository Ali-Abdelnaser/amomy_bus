import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/direction_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/departure_time_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_map_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';

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
    farePoints: 25.0,
    availableSeatsCount: 10,
    status: 'scheduled',
  );

  final sampleSeats = [
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
      seatNumber: '1B',
      rowIndex: 0,
      columnIndex: 1,
      seatType: 'standard',
      status: SeatAvailabilityStatus.held,
      isMine: false,
    ),
    const TripSeat(
      seatId: 's3',
      seatNumber: '2A',
      rowIndex: 1,
      columnIndex: 0,
      seatType: 'standard',
      status: SeatAvailabilityStatus.booked,
      isMine: false,
    ),
  ];

  final sampleBooking = PassengerBooking(
    bookingId: 'b1',
    tripId: 'trip-1',
    direction: BookingDirection.outbound,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    serviceDate: DateTime.now(),
    departureTime: '08:00',
    departureAt: DateTime.now().add(const Duration(hours: 2)),
    seatNumber: '1A',
    farePoints: 25.0,
    status: 'confirmed',
    qrToken: 'AMY_TOKEN_123456789',
    bookedAt: DateTime.now(),
  );

  group('DirectionSelector Widget', () {
    testWidgets('renders Outbound and Return options in English', (
      tester,
    ) async {
      BookingDirection? selectedDirection;
      await tester.pumpWidget(
        buildTestableWidget(
          DirectionSelector(
            selectedDirection: BookingDirection.outbound,
            onDirectionChanged: (dir) => selectedDirection = dir,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outbound'), findsOneWidget);
      expect(find.text('Return'), findsOneWidget);

      await tester.tap(find.text('Return'));
      expect(selectedDirection, BookingDirection.returnTrip);
    });

    testWidgets('renders Outbound and Return in Arabic RTL', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          DirectionSelector(
            selectedDirection: BookingDirection.outbound,
            onDirectionChanged: (_) {},
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ذهاب'), findsOneWidget);
      expect(find.text('عودة'), findsOneWidget);
    });
  });

  group('DepartureTimeSelector Widget', () {
    testWidgets('renders vertical radio rows for trips and selects on tap', (
      tester,
    ) async {
      TripOption? selected;
      await tester.pumpWidget(
        buildTestableWidget(
          DepartureTimeSelector(
            trips: [sampleTrip],
            selectedTrip: null,
            direction: BookingDirection.outbound,
            onTripSelected: (t) => selected = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('Bus at Mit Fadala'), findsOneWidget);
      expect(find.text('First stop · Available'), findsOneWidget);

      await tester.tap(find.text('8:00 AM'));
      expect(selected, sampleTrip);
    });

    testWidgets('renders end-of-day empty state when trips are finished', (
      tester,
    ) async {
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

      expect(find.text('لا توجد رحلات متاحة اليوم'), findsOneWidget);
      expect(
        find.text('تابع التطبيق غداً لمواعيد الرحلات الجديدة.'),
        findsOneWidget,
      );
    });
  });

  group('BusSeatMapWidget', () {
    testWidgets('renders seat items and responds to taps', (tester) async {
      TripSeat? tappedSeat;
      await tester.pumpWidget(
        buildTestableWidget(
          BusSeatMapWidget(
            seats: sampleSeats,
            selectedSeat: sampleSeats.first,
            onSeatTap: (seat) => tappedSeat = seat,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel('Seat 1A'), findsOneWidget);
      expect(find.bySemanticsLabel('Seat 1B'), findsOneWidget);
      expect(find.bySemanticsLabel('Seat 2A'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Seat 1A'));
      expect(tappedSeat?.seatNumber, '1A');
    });
  });

  group('AppQrTicketWidget', () {
    testWidgets('renders deterministic QR matrix and custom paint', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppQrTicketWidget(
            data: 'AMY_TOKEN_SECURE_987654321',
            size: 200,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('BookingReviewCard', () {
    testWidgets(
      'displays boarding stop, seat, dynamic fare and available points',
      (tester) async {
        bool confirmed = false;
        const sampleStop = RouteStop(
          routeStopId: 'rs-6',
          stopId: 'stop-6',
          stopOrder: 6,
          stopNameAr: 'القنطرة البيضة',
          stopNameEn: 'El Qantara El Baida',
          localityAr: 'ميت العامل',
          localityEn: 'Meet El Amel',
          fareZoneId: 'zone-25',
          farePoints: 25.0,
        );

        await tester.pumpWidget(
          buildTestableWidget(
            BookingReviewCard(
              trip: sampleTrip,
              seat: sampleSeats.first,
              routeStop: sampleStop,
              userAvailablePoints: 200.0,
              onConfirm: () => confirmed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1A'), findsOneWidget);
        expect(find.text('25 Points'), findsNWidgets(2)); // Trip fare and Total
        expect(find.text('200 Points'), findsOneWidget);
        expect(
          find.text('175 Points'),
          findsOneWidget,
        ); // Balance after booking
        expect(find.text('El Qantara El Baida'), findsOneWidget);

        await tester.tap(find.text('Confirm Booking'));
        expect(confirmed, isTrue);
      },
    );
  });

  group('BookingSuccessView', () {
    testWidgets('renders confirmation pass and QR code', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('View My Trips'), findsOneWidget);
      expect(find.byType(AppQrTicketWidget), findsOneWidget);
    });
  });
}
