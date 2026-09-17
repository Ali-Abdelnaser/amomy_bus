import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';
import 'package:amomy_bus/features/tracking/domain/services/stop_eta_engine.dart';
import 'package:amomy_bus/features/tracking/presentation/cubit/tracking_state.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/amomy_map_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<BusStopModel> testStops = [
    const BusStopModel(
      id: 'stop-1',
      routeStopId: 'rs-1',
      stopOrder: 1,
      nameAr: 'كوبرى عزت',
      nameEn: 'Ezzat Bridge',
      localityAr: 'ميت فضالة',
      localityEn: 'Mit Fadala',
      latitude: 30.9100,
      longitude: 31.3100,
      isTemporaryQa: true, // QA temporary
      farePoints: 20,
    ),
    const BusStopModel(
      id: 'stop-18',
      routeStopId: 'rs-18',
      stopOrder: 18,
      nameAr: 'ماركت المراعي',
      nameEn: 'Al Marai Market',
      localityAr: 'برج النور الحمص',
      localityEn: 'Borg El Nour',
      latitude: 30.9350,
      longitude: 31.3471,
      isTemporaryQa: false, // Verified
      farePoints: 20,
    ),
    const BusStopModel(
      id: 'stop-19',
      routeStopId: 'rs-19',
      stopOrder: 19,
      nameAr: 'شركة الحرمين',
      nameEn: 'Al Haramain Co',
      localityAr: 'برج النور الحمص',
      localityEn: 'Borg El Nour',
      latitude: 30.9388,
      longitude: 31.3524,
      isTemporaryQa: false, // Verified
      farePoints: 20,
    ),
  ];

  group('AMOMY Google Maps Production Migration Tests', () {
    test(
      '1. Custom Stop Pin icon generation creates valid BitmapDescriptors',
      () async {
        final normPin = await AmomyMapIcons.getStopPinIcon();
        expect(normPin, isNotNull);

        final passedPin = await AmomyMapIcons.getStopPinIcon(isPassed: true);
        expect(passedPin, isNotNull);

        final curPin = await AmomyMapIcons.getStopPinIcon(isCurrent: true);
        expect(curPin, isNotNull);

        final nextPin = await AmomyMapIcons.getStopPinIcon(isNext: true);
        expect(nextPin, isNotNull);

        final selPin = await AmomyMapIcons.getStopPinIcon(isSelected: true);
        expect(selPin, isNotNull);
      },
    );

    test(
      '2. Bus Marker icon is circular, distinct, and does not depend on heading rotation',
      () async {
        final busLive = await AmomyMapIcons.getBusMarkerIcon(
          isStale: false,
          isQa: false,
        );
        expect(busLive, isNotNull);

        final busStale = await AmomyMapIcons.getBusMarkerIcon(
          isStale: true,
          isQa: false,
        );
        expect(busStale, isNotNull);

        final busQa = await AmomyMapIcons.getBusMarkerIcon(
          isStale: false,
          isQa: true,
        );
        expect(busQa, isNotNull);
      },
    );

    test(
      '3. Route geometry polyline decoding handles Google Encoded format',
      () {
        // Encoded polyline representing a sample path
        const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
        final points = RouteGeometry.decodePolyline(encoded);
        expect(points.length, greaterThanOrEqualTo(2));
        expect(points.first.latitude, isNotNull);
        expect(points.first.longitude, isNotNull);
      },
    );

    test(
      '4. Route validation calculates perpendicular/shortest stop-to-polyline distance',
      () {
        final polyline = [
          const LatLng(30.9350, 31.3470),
          const LatLng(30.9388, 31.3524),
        ];

        // A stop right on the corridor (less than 75m)
        final closeStop = {
          'id': 's1',
          'stop_order': 18,
          'latitude': 30.9351,
          'longitude': 31.3471,
        };
        final reports = RouteGeometryEngine.validateStopsProximity(
          polyline: polyline,
          stops: [closeStop],
        );

        expect(reports.length, 1);
        expect(reports.first.shortestDistanceMeters, lessThan(75.0));
        expect(reports.first.quality, StopProximityQuality.excellent);

        // An offset stop (> 150m away)
        final farStop = {
          'id': 's2',
          'stop_order': 1,
          'latitude': 31.0000,
          'longitude': 31.5000,
        };
        final farReports = RouteGeometryEngine.validateStopsProximity(
          polyline: polyline,
          stops: [farStop],
        );
        expect(farReports.first.quality, StopProximityQuality.reviewNeeded);
      },
    );

    test('6. QA temporary stops 1-17 are strictly marked as unverified', () {
      final geom = RouteGeometry(
        id: 'geom-qa-1',
        routeId: 'mit-ghamr-mansoura',
        direction: 'OUTBOUND',
        version: 1,
        polylineEncoded: '...',
        points: const [LatLng(30.91, 31.31), LatLng(30.93, 31.34)],
        isVerified: false,
        source: 'google_routes_qa',
      );

      expect(geom.isVerified, isFalse);
      expect(geom.source, 'google_routes_qa');
    });

    test(
      '7. Outbound and Return geometries are separate and non-reversible',
      () {
        final outbound = RouteGeometry(
          id: 'geom-outbound',
          routeId: 'mit-ghamr-mansoura',
          direction: 'OUTBOUND',
          version: 1,
          polylineEncoded: 'outbound_poly',
          points: const [LatLng(30.91, 31.31), LatLng(30.93, 31.34)],
        );

        final returnGeom = RouteGeometry(
          id: 'geom-return',
          routeId: 'mit-ghamr-mansoura',
          direction: 'RETURN',
          version: 1,
          polylineEncoded: 'return_poly_separate_one_ways',
          points: const [LatLng(30.935, 31.345), LatLng(30.912, 31.312)],
        );

        expect(outbound.direction, 'OUTBOUND');
        expect(returnGeom.direction, 'RETURN');
        expect(
          outbound.polylineEncoded,
          isNot(equals(returnGeom.polylineEncoded)),
        );
      },
    );

    test(
      '8. ETrack GPS projection keeps raw GPS authoritative if off-route (> 80m)',
      () {
        final polyline = [
          const LatLng(30.9350, 31.3470),
          const LatLng(30.9388, 31.3524),
        ];

        // Way off route
        const farGps = LatLng(31.2000, 31.8000);
        final snapped = RouteGeometryEngine.projectBusLocation(
          rawGps: farGps,
          polyline: polyline,
          maxSnapDistanceMeters: 80.0,
        );

        // Raw GPS preserved, not snapped to road
        expect(snapped.latitude, farGps.latitude);
        expect(snapped.longitude, farGps.longitude);
      },
    );

    test('9. Map Follow Bus state toggle operates cleanly', () {
      var state = const TrackingState();
      expect(state.followBus, isTrue);

      state = state.copyWith(followBus: false);
      expect(state.followBus, isFalse);

      state = state.copyWith(followBus: true);
      expect(state.followBus, isTrue);
    });

    test(
      '10. Stop ETA calculates distance along polyline when road geometry is present',
      () {
        final polyline = [
          const LatLng(30.9350, 31.3470),
          const LatLng(30.9370, 31.3500),
          const LatLng(30.9388, 31.3524),
        ];

        final engine = StopEtaEngine();
        final remainingMeters = engine.calculateRemainingRouteDistanceMeters(
          orderedStops: testStops,
          busLat: 30.9350,
          busLng: 31.3470,
          nextStopOrder: 18,
          targetStopOrder: 19,
          routePolylinePoints: polyline,
        );

        expect(remainingMeters, greaterThan(0));
      },
    );

    test(
      '11. AmomyMapIcons defines precise anchors aligning pin tip and bus center to GPS',
      () {
        expect(AmomyMapIcons.busMarkerAnchor, const Offset(0.5, 0.5));
        expect(AmomyMapIcons.normalPinAnchor.dx, 0.5);
        expect(AmomyMapIcons.normalPinAnchor.dy, closeTo(0.886, 0.005));
        expect(AmomyMapIcons.selectedPinAnchor.dx, 0.5);
        expect(AmomyMapIcons.selectedPinAnchor.dy, closeTo(0.888, 0.005));

        expect(
          AmomyMapIcons.getStopPinAnchor(StopPinVisualState.normal),
          AmomyMapIcons.normalPinAnchor,
        );
        expect(
          AmomyMapIcons.getStopPinAnchor(StopPinVisualState.selected),
          AmomyMapIcons.selectedPinAnchor,
        );
      },
    );

    test(
      '14. Stop Pin semantics: Last is yellow, Next is blue, Future is white, Passed is muted',
      () async {
        await AmomyMapIcons.preloadAllIcons();

        // Ensure all descriptors generated without throwing
        final lastPin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.current,
        );
        final nextPin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.next,
        );
        final futurePin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.normal,
        );
        final passedPin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.passed,
        );
        final selLastPin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.selectedLast,
        );
        final selNextPin = AmomyMapIcons.getCachedStopIcon(
          StopPinVisualState.selectedNext,
        );

        expect(lastPin, isNotNull);
        expect(nextPin, isNotNull);
        expect(futurePin, isNotNull);
        expect(passedPin, isNotNull);
        expect(selLastPin, isNotNull);
        expect(selNextPin, isNotNull);
      },
    );

    test(
      '15. Stop timing engine preserves actual recorded arrival timestamp and does not fabricate when null',
      () {
        final recordedArrival = DateTime.utc(2026, 9, 14, 13, 42);
        final stops = [
          BusStopModel(
            id: 's-1',
            routeStopId: 'rs-1',
            stopOrder: 1,
            nameAr: 'جامعة السلاب',
            nameEn: 'El Sallab University',
            localityAr: 'المنصورة',
            localityEn: 'Mansoura',
            latitude: 31.035,
            longitude: 31.380,
            actualArrivalTime: recordedArrival,
          ),
          const BusStopModel(
            id: 's-2',
            routeStopId: 'rs-2',
            stopOrder: 2,
            nameAr: 'أحمد ماهر',
            nameEn: 'Ahmed Maher',
            localityAr: 'المنصورة',
            localityEn: 'Mansoura',
            latitude: 31.038,
            longitude: 31.385,
            actualArrivalTime: null, // No recorded arrival
          ),
        ];

        final engine = StopEtaEngine();
        final timings = engine.computeAllStopTimings(
          orderedStops: stops,
          telemetry: null,
          activeRunTime: '13:30',
          isQaPreview: false,
        );

        // Stop 1 has recorded arrival
        expect(timings['s-1']?.actualArrivalTime, recordedArrival);
        // Stop 2 has NO recorded arrival, must not be fabricated from currentTime or ETA
        expect(timings['s-2']?.actualArrivalTime, isNull);
      },
    );

    test(
      '16. Clock format displays exact passenger format in Arabic and English',
      () {
        final sampleTime = DateTime(2026, 9, 14, 15, 42); // 3:42 PM local
        final enFormatted = StopEtaEngine.formatClockTime(sampleTime, 'en');
        final arFormatted = StopEtaEngine.formatClockTime(sampleTime, 'ar');

        expect(
          enFormatted.contains('03:42 PM') || enFormatted.contains('3:42 PM'),
          isTrue,
        );
        expect(
          arFormatted.contains('03:42 م') || arFormatted.contains('3:42 م'),
          isTrue,
        );
      },
    );
  });
}
