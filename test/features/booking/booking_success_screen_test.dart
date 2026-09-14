import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:amomy_bus/core/assets/app_assets.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_qr_ticket_card.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/trips/presentation/widgets/trip_ticket_svg_background.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
    bool disableAnimations = false,
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
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  final sampleBooking = PassengerBooking(
    bookingId: 'book-123',
    tripId: 'trip-456',
    direction: BookingDirection.outbound,
    originNameAr: 'كوبرى عزت',
    originNameEn: 'Ezzat Bridge',
    destinationNameAr: 'بوابة توشكى',
    destinationNameEn: 'Toshka Gate',
    serviceDate: DateTime(2026, 9, 12),
    departureTime: '08:00',
    departureAt: DateTime(2026, 9, 12, 8, 0),
    seatNumber: '7',
    farePoints: 30.0,
    status: 'confirmed',
    qrToken: 'AMY_TOKEN_SECURE_777',
    bookedAt: DateTime(2026, 9, 12),
    stopName: 'Ezzat Bridge',
    locality: 'Mit Fadala',
  );

  final sampleLegacyBooking = PassengerBooking(
    bookingId: 'book-legacy',
    tripId: 'trip-legacy',
    direction: BookingDirection.returnTrip,
    originNameAr: 'بوابة توشكى',
    originNameEn: 'Toshka Gate',
    destinationNameAr: 'كوبرى عزت',
    destinationNameEn: 'Ezzat Bridge',
    serviceDate: DateTime(2026, 9, 12),
    departureTime: '16:00',
    departureAt: DateTime(2026, 9, 12, 16, 0),
    seatNumber: '1A',
    farePoints: 25.0,
    status: 'confirmed',
    qrToken: 'AMY_TOKEN_LEGACY_1A',
    bookedAt: DateTime(2026, 9, 12),
  );

  group('BookingSuccessView Printing Ticket Tests', () {
    testWidgets('1 & 2: uses qr_scaneer.svg and does NOT use trip_ticket.svg', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // Verify qr_scaneer.svg is authoritative
      expect(find.byKey(const ValueKey(AppAssets.qrScannerTicket)), findsOneWidget);
      expect(find.byType(BookingQrTicketCard), findsOneWidget);
      expect(find.byType(BookingQrTicketSvgBackground), findsOneWidget);
      expect(BookingQrTicketCard.assetPath, 'assets/qr_scaneer.svg');
      expect(BookingQrTicketSvgBackground.assetPath, 'assets/qr_scaneer.svg');

      // Verify TripTicketSvgBackground is NOT used in BookingSuccessView
      expect(find.byType(TripTicketSvgBackground), findsNothing);
    });

    testWidgets('3: preserves portrait aspect ratio ~0.474', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      final ticketCard = tester.widget<BookingQrTicketCard>(find.byType(BookingQrTicketCard));
      final ratio = ticketCard.ticketWidth / ticketCard.ticketHeight;
      final expectedRatio = 445.0 / 939.0; // ≈ 0.4739

      expect((ratio - expectedRatio).abs() < 0.001, isTrue);
      expect(BookingQrTicketSvgBackground.aspectRatio, closeTo(0.4739, 0.001));
    });

    testWidgets('4: renders booking data (stops, localities, date, fare) without removed header rows', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // Stop names & locality
      expect(find.text('Ezzat Bridge'), findsOneWidget);
      expect(find.text('Mit Fadala'), findsOneWidget);
      expect(find.text('Toshka Gate'), findsOneWidget);

      // Verified: Top direction/time rows are removed to prioritize vertical space & route
      expect(find.text('Outbound'), findsNothing);

      // Date & Fare
      expect(find.text('12 Sep'), findsOneWidget);
      expect(find.text('30 Points'), findsOneWidget);
    });

    testWidgets('5: renders real QR token widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      final qrFinder = find.byType(AppQrTicketWidget);
      expect(qrFinder, findsOneWidget);

      final qrWidget = tester.widget<AppQrTicketWidget>(qrFinder);
      expect(qrWidget.data, 'AMY_TOKEN_SECURE_777');
    });

    testWidgets('6: renders seat snapshot directly (including legacy 1A)', (tester) async {
      // Modern numeric seat
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Seat 7'), findsOneWidget);

      // Legacy seat (e.g. 1A)
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleLegacyBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('Seat 1A'), findsOneWidget);
    });

    testWidgets('7, 8 & 9: animation timing - hidden during feed, revealed after 3100ms', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: false,
        ),
      );

      // Initial frame (wake-up phase: 0.00-0.08)
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('AMOMY DIGITAL DISPENSER'), findsOneWidget);

      // During feed phase (e.g., at 1500ms, progress ≈ 0.48):
      // Ticket is emerging, actions are hidden (opacity = 0)
      await tester.pump(const Duration(milliseconds: 1400));
      final opacityFinder = find.byType(Opacity).last;
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.0);

      // Advance through remaining feed (up to 2500ms)
      await tester.pump(const Duration(milliseconds: 1000));

      // Advance through settle and actions reveal (to 3100ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Actions are now fully revealed
      final finalOpacity = tester.widget<Opacity>(opacityFinder);
      expect(finalOpacity.opacity, closeTo(1.0, 0.001));
      // View Ticket removed, View My Trips + Back to Home present side-by-side
      expect(find.text('View Ticket'), findsNothing);
      expect(find.text('View My Trips'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('10: reduced motion renders immediately without animation delay', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      // Actions and ticket are immediately visible
      final opacityFinder = find.byType(Opacity).last;
      final opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, closeTo(1.0, 0.001));
      expect(find.text('View Ticket'), findsNothing);
      expect(find.text('View My Trips'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('renders RTL Arabic version correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          locale: const Locale('ar'),
          disableAnimations: true,
        ),
      );
      await tester.pump();

      expect(find.text('تم تأكيد الحجز بنجاح!'), findsOneWidget);
      expect(find.text('مؤكد'), findsNothing); // Removed from ticket header
      expect(find.text('ذهاب'), findsNothing); // Removed from ticket header
      expect(find.text('امسح للصعود'), findsOneWidget);
      expect(find.text('مقعد 7'), findsOneWidget);
      expect(find.text('عرض التذكرة'), findsNothing); // Removed View Ticket button
      expect(find.text('عرض رحلاتي'), findsOneWidget);
      expect(find.text('العودة للرئيسية'), findsOneWidget);
    });
  });
}
