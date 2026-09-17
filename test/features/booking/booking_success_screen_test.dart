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
          disableAnimations: true,
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
    departureAt: DateTime(2026, 9, 12, 8),
    seatNumber: '7',
    farePoints: 30,
    status: 'confirmed',
    qrToken: 'AMY_TOKEN_SECURE_777',
    bookedAt: DateTime(2026, 9, 12),
  );

  group('BookingSuccessView compact ticket', () {
    testWidgets('uses the supplied SVG ticket with a confirmed header', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pump();

      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(
        find.text('Your trip seat is successfully reserved.'),
        findsOneWidget,
      );
      
    });

    testWidgets('shows only QR, time, seat, and fees in the ticket', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(BookingSuccessView(booking: sampleBooking)),
      );
      await tester.pump();

      final qrWidget = tester.widget<AppQrTicketWidget>(
        find.byType(AppQrTicketWidget),
      );
      expect(qrWidget.data, 'AMY_TOKEN_SECURE_777');
      expect(qrWidget.size, greaterThanOrEqualTo(200));
      expect(find.text('TIME'), findsOneWidget);
      expect(find.text('8:00 AM'), findsOneWidget);
      expect(find.text('SEAT'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('FEES'), findsOneWidget);
      expect(find.text('30 Points'), findsOneWidget);
      expect(find.textContaining('Ezzat Bridge'), findsNothing);
      expect(find.textContaining('Toshka Gate'), findsNothing);
      expect(find.textContaining('NFC'), findsNothing);
    });

    testWidgets('has exactly My Trips and Go to Home actions on small phones', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          size: const Size(320, 568),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('My Trips'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
      expect(find.textContaining('Live Map'), findsNothing);
    });

    testWidgets('keeps the SVG direction and localizes Arabic text', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          BookingSuccessView(booking: sampleBooking),
          locale: const Locale('ar'),
        ),
      );
      await tester.pump();

      expect(find.text('تم تأكيد الحجز بنجاح!'), findsOneWidget);
      expect(find.text('الوقت'), findsOneWidget);
      expect(find.text('المقعد'), findsOneWidget);
      expect(find.text('التكلفة'), findsOneWidget);
      expect(find.text('8:00 ص'), findsOneWidget);
      expect(find.text('رحلاتي'), findsOneWidget);
      expect(find.text('العودة للرئيسية'), findsOneWidget);
    });
  });
}
