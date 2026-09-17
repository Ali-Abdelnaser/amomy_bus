import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/features/tracking/domain/models/bus_stop_model.dart';
import 'package:amomy_bus/features/tracking/domain/models/live_tracking_status.dart';
import 'package:amomy_bus/features/tracking/domain/models/tracking_summary.dart';
import 'package:amomy_bus/features/tracking/presentation/widgets/live_bus_map_widget.dart';

BusStopModel _stop({
  required int order,
  double? latitude,
  double? longitude,
  bool isTemporaryQa = false,
  String? coordinateSource,
  TrackingStopSemanticState state = TrackingStopSemanticState.future,
}) {
  return BusStopModel(
    id: 'stop-$order',
    routeStopId: 'route-stop-$order',
    stopOrder: order,
    nameAr: 'محطة $order',
    nameEn: 'Stop $order',
    localityAr: 'المنصورة',
    localityEn: 'Mansoura',
    latitude: latitude,
    longitude: longitude,
    isTemporaryQa: isTemporaryQa,
    coordinateSource: coordinateSource,
    semanticState: state,
  );
}

void main() {
  test('null coordinate stop does not create passenger map marker', () {
    final nullLatitude = _stop(order: 1, latitude: null, longitude: 31.30);
    final nullLongitude = _stop(order: 2, latitude: 31.10, longitude: null);

    expect(LiveBusMapWidget.shouldRenderStopMarker(nullLatitude), isFalse);
    expect(LiveBusMapWidget.shouldRenderStopMarker(nullLongitude), isFalse);
    expect(
      LiveBusMapWidget.markerEligibleStops([
        nullLatitude,
        nullLongitude,
      ], isCompactPreview: false),
      isEmpty,
    );
  });

  test('null coordinate stop remains in ordered tracking list', () {
    final summary = TrackingSummary.fromJson({
      'tracking_status': 'progression_unavailable',
      'trip_id': 'trip-1',
      'direction': 'outbound',
      'ordered_stops': [
        _stop(order: 1, latitude: 31.01, longitude: 31.31).toJson(),
        _stop(order: 2, latitude: null, longitude: null).toJson(),
        _stop(order: 3, latitude: 31.03, longitude: 31.33).toJson(),
      ],
    });

    expect(summary.status, LiveTrackingStatus.progressionUnavailable);
    expect(summary.routeStops.map((s) => s.stopOrder), [1, 2, 3]);
    expect(summary.routeStops[1].hasCoordinates, isFalse);
    expect(summary.routeStops[1].hasCanonicalCoordinates, isFalse);
  });

  test('missing coordinates do not fall back to 0,0', () {
    final missing = BusStopModel.fromJson({
      'stop_id': 'stop-missing',
      'route_stop_id': 'route-stop-missing',
      'stop_order': 7,
      'name_ar': 'محطة بدون إحداثيات',
      'name_en': 'Missing Coordinate Stop',
      'locality_ar': 'المنصورة',
      'locality_en': 'Mansoura',
      'latitude': null,
      'longitude': null,
    });

    expect(missing.latitude, isNull);
    expect(missing.longitude, isNull);
    expect(missing.hasCanonicalCoordinates, isFalse);

    final source = File(
      'lib/features/tracking/presentation/widgets/live_bus_map_widget.dart',
    ).readAsStringSync();
    expect(source.contains('LatLng(0'), isFalse);
    expect(source.contains('latitude ?? 0'), isFalse);
    expect(source.contains('longitude ?? 0'), isFalse);
  });

  test('QA or temporary coordinates do not become passenger markers', () {
    final temporaryQa = _stop(
      order: 4,
      latitude: 31.04,
      longitude: 31.34,
      isTemporaryQa: true,
      coordinateSource: 'temporary_qa',
    );
    final qaTableSource = _stop(
      order: 5,
      latitude: 31.05,
      longitude: 31.35,
      coordinateSource: 'qa_stop_coordinates',
    );

    expect(temporaryQa.hasCoordinates, isTrue);
    expect(temporaryQa.hasCanonicalCoordinates, isFalse);
    expect(qaTableSource.hasCoordinates, isTrue);
    expect(qaTableSource.hasCanonicalCoordinates, isFalse);
    expect(LiveBusMapWidget.shouldRenderStopMarker(temporaryQa), isFalse);
    expect(LiveBusMapWidget.shouldRenderStopMarker(qaTableSource), isFalse);
  });

  test('verified coordinate stop still renders normally', () {
    final verified = _stop(
      order: 18,
      latitude: 31.18,
      longitude: 31.48,
      coordinateSource: 'verified',
    );

    expect(verified.hasCanonicalCoordinates, isTrue);
    expect(LiveBusMapWidget.shouldRenderStopMarker(verified), isTrue);
    expect(
      LiveBusMapWidget.markerEligibleStops([verified], isCompactPreview: false),
      [verified],
    );
  });

  test(
    'route order remains unchanged while marker eligibility is coordinate-based',
    () {
      final stops = [
        _stop(order: 1, latitude: 31.01, longitude: 31.31),
        _stop(order: 2),
        _stop(order: 3, latitude: 31.03, longitude: 31.33),
        _stop(
          order: 4,
          latitude: 31.04,
          longitude: 31.34,
          coordinateSource: 'qa_stop_coordinates',
        ),
      ];

      expect(stops.map((s) => s.stopOrder), [1, 2, 3, 4]);
      expect(
        LiveBusMapWidget.markerEligibleStops(
          stops,
          isCompactPreview: false,
        ).map((s) => s.stopOrder),
        [1, 3],
      );
    },
  );
}
