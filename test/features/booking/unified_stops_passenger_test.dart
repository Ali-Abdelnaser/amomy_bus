import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/booking/domain/entities/booking_entities.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/route_stop_selector.dart';
import 'package:amomy_bus/features/home/domain/entities/home_summary.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';

void main() {
  group('Unified Stops — Passenger App Domain & UI Tests', () {
    const canonicalRouteStop = RouteStop(
      routeStopId: 'rs-uuid-101',
      stopId: 'stop-uuid-202',
      stopOrder: 1,
      stopNameAr: 'المدخل الرئيسي - بهو فريك',
      stopNameEn: 'Main Entrance - Baho Fereek',
      localityAr: 'بهو فريك',
      localityEn: 'Baho Fereek',
      fareZoneId: 'fz-uuid-303',
      farePoints: 20.0,
    );

    const destinationRouteStop = RouteStop(
      routeStopId: 'rs-uuid-102',
      stopId: 'stop-uuid-203',
      stopOrder: 2,
      stopNameAr: 'بوابة توشكى - الإسكندرية',
      stopNameEn: 'Toshka Gate - Alexandria',
      localityAr: 'الإسكندرية',
      localityEn: 'Alexandria',
      fareZoneId: 'fz-uuid-304',
      farePoints: 20.0,
    );

    test('1. RouteStop.displayName returns canonical Arabic name directly without duplicate locality suffix', () {
      final nameAr = canonicalRouteStop.displayName('ar');
      expect(nameAr, 'المدخل الرئيسي - بهو فريك');
      expect(nameAr.contains('—'), isFalse);
    });

    test('2. RouteStop.displayName returns canonical English name directly where locale applies', () {
      final nameEn = canonicalRouteStop.displayName('en');
      expect(nameEn, 'Main Entrance - Baho Fereek');
      expect(nameEn.contains('—'), isFalse);
    });

    test('3. PassengerUpcomingTrip.boardingStopDisplayName returns canonical name without locality concatenation', () {
      final upcomingTrip = PassengerUpcomingTrip(
        bookingId: 'b-1',
        tripId: 't-1',
        direction: 'outbound',
        originNameAr: 'ميت غمر',
        originNameEn: 'Mit Ghamr',
        destinationNameAr: 'الإسكندرية',
        destinationNameEn: 'Alexandria',
        serviceDate: DateTime.now(),
        departureAt: DateTime.now().add(const Duration(hours: 2)),
        departureTime: '08:00',
        seatNumber: '4',
        farePoints: 25,
        bookingStatus: 'confirmed',
        qrToken: 'qr-token-123',
        routeStopId: 'rs-uuid-101',
        stopNameAr: 'المدخل الرئيسي - بهو فريك',
        localityAr: 'بهو فريك',
      );

      expect(upcomingTrip.boardingStopDisplayName, 'المدخل الرئيسي - بهو فريك');
      expect(upcomingTrip.boardingStopDisplayName!.contains('—'), isFalse);
    });

    testWidgets('4. RouteStopSelector renders canonical stop names without separate locality subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: RouteStopSelector(
              selectedOrigin: canonicalRouteStop,
              selectedDestination: destinationRouteStop,
              originStops: const [canonicalRouteStop],
              destinationStops: const [destinationRouteStop],
              onOriginSelected: (_) {},
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Canonical names must be displayed
      expect(find.text('Main Entrance - Baho Fereek'), findsOneWidget);
      expect(find.text('Toshka Gate - Alexandria'), findsOneWidget);
      // Locality must NOT be displayed as separate subtitles
      expect(find.text('Baho Fereek'), findsNothing);
      expect(find.text('Alexandria'), findsNothing);
    });

    testWidgets('5. RouteStopSelector modal list renders canonical name only and passes routeStopId on selection', (tester) async {
      RouteStop? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: RouteStopSelector(
              selectedOrigin: null,
              selectedDestination: destinationRouteStop,
              originStops: const [canonicalRouteStop],
              destinationStops: const [destinationRouteStop],
              onOriginSelected: (stop) => selectedResult = stop,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap origin stop to open modal sheet
      await tester.tap(find.text('Select boarding stop'));
      await tester.pumpAndSettle();

      // Search hint reflects stop name only
      expect(find.text('Search stop name...'), findsOneWidget);

      // List item displays canonical stop name
      expect(find.text('Main Entrance - Baho Fereek'), findsOneWidget);
      // Separate locality must NOT appear in the list item
      expect(find.text('Baho Fereek'), findsNothing);

      // Select stop
      await tester.tap(find.text('Main Entrance - Baho Fereek'));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!.routeStopId, 'rs-uuid-101');
      expect(selectedResult!.stopId, 'stop-uuid-202');
      expect(selectedResult!.farePoints, 20.0);
    });

    test('6. BusStopModel retains legacy locality parsing while providing canonical localizedName', () {
      final json = {
        'id': 'stop-uuid-202',
        'route_stop_id': 'rs-uuid-101',
        'stop_order': 1,
        'name_ar': 'المدخل الرئيسي - بهو فريك',
        'name_en': 'Main Entrance - Baho Fereek',
        'locality_ar': 'بهو فريك',
        'locality_en': 'Baho Fereek',
        'latitude': 31.1234,
        'longitude': 31.5678,
      };

      final stopModel = BusStopModel.fromJson(json);
      expect(stopModel.id, 'stop-uuid-202');
      expect(stopModel.routeStopId, 'rs-uuid-101');
      expect(stopModel.latitude, 31.1234);
      expect(stopModel.longitude, 31.5678);
      expect(stopModel.localizedName('ar'), 'المدخل الرئيسي - بهو فريك');
      expect(stopModel.localizedName('en'), 'Main Entrance - Baho Fereek');
      // Legacy fields still accessible if needed
      expect(stopModel.localityAr, 'بهو فريك');
    });
  });
}
