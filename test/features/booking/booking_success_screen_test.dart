import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/booking_success_view.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestableWidget(
    Widget child, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
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
          size: size,
          padding: const EdgeInsets.only(bottom: 24),
        ),
        child: Scaffold(body: child),
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

  group('BookingSuccessView digital boarding pass', () {
    testWidgets('shows compact confirmation state', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed'), findsOneWidget);
      expect(
        find.text('Your seat has been successfully reserved.'),
        findsOneWidget,
      );
      expect(find.text('AMOMY DIGITAL DISPENSER'), findsNothing);
    });

    testWidgets('renders trip summary card with route and booking details', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outbound Trip'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('Ezzat Bridge'), findsOneWidget);
      expect(find.text('Mit Fadala'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Toshka Gate'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('12 Sep'), findsOneWidget);
      expect(find.text('Seat'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Fare'), findsOneWidget);
      expect(find.text('30 Points'), findsOneWidget);
    });

    testWidgets('does not expose internal bus identity', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bus 1'), findsNothing);
      expect(find.text('Bus'), findsNothing);
      expect(find.textContaining('Plate'), findsNothing);
      expect(find.textContaining('Driver'), findsNothing);
      expect(find.textContaining('Device'), findsNothing);
    });

    testWidgets('renders compact QR boarding card with real token', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scan to board'), findsOneWidget);
      expect(find.text('Seat 7'), findsOneWidget);
      expect(
        find.text('Use your NFC card or this QR code when boarding.'),
        findsOneWidget,
      );

      final qrFinder = find.byType(AppQrTicketWidget);
      expect(qrFinder, findsOneWidget);
      final qrWidget = tester.widget<AppQrTicketWidget>(qrFinder);
      expect(qrWidget.data, 'AMY_TOKEN_SECURE_777');
      expect(qrWidget.size, lessThanOrEqualTo(172));
    });

    testWidgets('preserves legacy seat labels without changing booking data', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleLegacyBooking)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Return Trip'), findsOneWidget);
      expect(find.text('16:00'), findsOneWidget);
      expect(find.text('1A'), findsOneWidget);
      expect(find.text('Seat 1A'), findsOneWidget);
      expect(find.text('25 Points'), findsOneWidget);
    });

    testWidgets('keeps actions visible and scroll-safe on small phones', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          size: const Size(320, 568),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View My Trips'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('renders RTL Arabic version correctly', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تم تأكيد الحجز'), findsOneWidget);
      expect(find.text('تم حجز مقعدك بنجاح.'), findsOneWidget);
      expect(find.text('رحلة الذهاب'), findsOneWidget);
      expect(find.text('امسح للصعود'), findsOneWidget);
      expect(find.text('مقعد 7'), findsOneWidget);
      expect(find.text('عرض رحلاتي'), findsOneWidget);
      expect(find.text('العودة للرئيسية'), findsOneWidget);
      expect(find.text('حافلة 1'), findsNothing);
    });
  });
}
