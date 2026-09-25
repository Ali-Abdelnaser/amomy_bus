import 'package:equatable/equatable.dart';
import 'bus_stop_model.dart';
import 'fleet_bus.dart';
import 'fleet_route.dart';
import 'live_tracking_status.dart';
import 'route_geometry.dart';
import 'tracking_summary.dart';

class FleetTrackingSummary extends Equatable {
  final bool mapEnabled;
  final List<FleetBus> buses;
  final List<FleetRoute> routes;
  final DateTime? serverTime;

  const FleetTrackingSummary({
    required this.mapEnabled,
    this.buses = const [],
    this.routes = const [],
    this.serverTime,
  });

  bool get hasBuses => buses.isNotEmpty;
  List<FleetBus> get busesWithValidLocation =>
      buses.where((b) => b.hasValidCoordinates).toList();
  bool get hasBusesWithLocation => busesWithValidLocation.isNotEmpty;

  FleetRoute? get primaryRoute => routes.isNotEmpty ? routes.first : null;
  List<BusStopModel> get primaryStops => primaryRoute?.stops ?? const [];
  RouteGeometry? get primaryGeometry => primaryRoute?.geometry;

  factory FleetTrackingSummary.fromJson(Map<String, dynamic> json) {
    final rawBuses = json['buses'] as List? ?? const [];
    final rawRoutes = json['routes'] as List? ?? const [];
    final serverTimeRaw = json['server_time'];

    return FleetTrackingSummary(
      mapEnabled: (json['map_enabled'] as bool?) ?? false,
      buses: rawBuses
          .whereType<Map>()
          .map((b) => FleetBus.fromJson(Map<String, dynamic>.from(b)))
          .toList(),
      routes: rawRoutes
          .whereType<Map>()
          .map((r) => FleetRoute.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      serverTime: serverTimeRaw != null
          ? DateTime.tryParse(serverTimeRaw.toString())?.toUtc()
          : null,
    );
  }

  /// Synthesizes a compatible [TrackingSummary] so existing UI widgets and getters
  /// seamlessly render the fleet route, stops, direction, and online status without breaking.
  TrackingSummary toTrackingSummary() {
    final now = DateTime.now();
    final firstBusWithLoc =
        busesWithValidLocation.isNotEmpty ? busesWithValidLocation.first : null;

    final status = !mapEnabled
        ? LiveTrackingStatus.offline
        : (hasBusesWithLocation
            ? (firstBusWithLoc?.isStale == true
                ? LiveTrackingStatus.stale
                : LiveTrackingStatus.live)
            : LiveTrackingStatus.offline);

    final phase = !mapEnabled
        ? TrackingPhase.mapDisabled
        : (hasBusesWithLocation
            ? (firstBusWithLoc?.isStale == true
                ? TrackingPhase.gpsStale
                : TrackingPhase.live)
            : (hasBuses ? TrackingPhase.gpsOffline : TrackingPhase.unknown));

    return TrackingSummary(
      status: status,
      trackingPhase: phase,
      trackingEnabled: mapEnabled && hasBusesWithLocation,
      isInServiceWindow: true,
      serviceWindow: 'fleet_service',
      cairoTime:
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      cairoDate:
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      activeDirection: primaryRoute?.direction.toLowerCase() == 'return'
          ? TrackingDirection.returnDirection
          : TrackingDirection.outbound,
      activeRouteId: primaryRoute?.routeId,
      activeRouteNameAr: primaryRoute?.originNameAr != null
          ? '${primaryRoute!.originNameAr} - ${primaryRoute!.destinationNameAr}'
          : null,
      activeRouteNameEn: primaryRoute?.originNameEn != null
          ? '${primaryRoute!.originNameEn} - ${primaryRoute!.destinationNameEn}'
          : null,
      busLocation: firstBusWithLoc?.toBusTelemetry(),
      fleetBuses: buses,
      routeStops: primaryStops,
      passengerMapEnabled: mapEnabled,
      busVisibleOnPassengerMap: hasBuses,
      mapVisibilityState: mapEnabled ? 'visible' : 'global_disabled',
      hasStopCoordinates: primaryStops.any((s) => s.hasCanonicalCoordinates),
    );
  }

  @override
  List<Object?> get props => [mapEnabled, buses, routes, serverTime];
}
