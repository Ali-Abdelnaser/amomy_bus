import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/direction_selector.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/bus_seat_map_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_review_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';

void main() {
  Widget buildTestableWidget(Widget child, {Locale locale = const Locale('en')}) {
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
    originNameAr: 'محطة أكتوبر',
    originNameEn: 'October Station',
    destinationNameAr: 'محطة التجمع',
    destinationNameEn: 'Tagamoa Station',
    departureTime: '08:00',
    departureAt: DateTime(2026, 9, 15, 8, 0),
    farePoints: 50.0,
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
    originNameAr: 'محطة أكتوبر',
    originNameEn: 'October Station',
    destinationNameAr: 'محطة التجمع',
    destinationNameEn: 'Tagamoa Station',
    serviceDate: DateTime(2026, 9, 15),
    departureTime: '08:00',
    departureAt: DateTime(2026, 9, 15, 8, 0),
    seatNumber: '1A',
    farePoints: 50.0,
    status: 'confirmed',
    qrToken: 'AMY_TOKEN_123456789',
    bookedAt: DateTime(2026, 9, 11, 12, 0),
  );

  group('DirectionSelector Widget', () {
    testWidgets('renders Outbound and Return options in English', (tester) async {
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

  group('BusSeatMapWidget', () {
    testWidgets('renders driver indicator, seat items and legend', (tester) async {
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
      await tester.pumpAndSettle();

      expect(find.text('Front / Driver'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Selected'), findsOneWidget);
      expect(find.text('Held'), findsOneWidget);
      expect(find.text('Booked'), findsOneWidget);

      expect(find.text('1A'), findsOneWidget);
      expect(find.text('1B'), findsOneWidget);
      expect(find.text('2A'), findsOneWidget);

      await tester.tap(find.text('1A'));
      expect(tappedSeat?.seatNumber, '1A');
    });
  });

  group('AppQrTicketWidget', () {
    testWidgets('renders deterministic QR matrix and custom paint', (tester) async {
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
    testWidgets('displays trip direction, seat, fare and available points', (tester) async {
      bool confirmed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          BookingReviewCard(
            trip: sampleTrip,
            seat: sampleSeats.first,
            userAvailablePoints: 200.0,
            onConfirm: () => confirmed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1A'), findsOneWidget);
      expect(find.text('50 Points'), findsOneWidget);
      expect(find.text('200 Points'), findsOneWidget);

      await tester.tap(find.text('Confirm Booking'));
      expect(confirmed, isTrue);
    });
  });

  group('BookingSuccessView', () {
    testWidgets('renders confirmation pass and QR code', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(
            booking: sampleBooking,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('View My Trips'), findsOneWidget);
      expect(find.byType(AppQrTicketWidget), findsOneWidget);
    });
  });
}
