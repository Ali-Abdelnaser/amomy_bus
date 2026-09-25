import 'package:equatable/equatable.dart';
import 'bus_stop_model.dart';
import 'route_geometry.dart';

class FleetRoute extends Equatable {
  final String routeId;
  final String direction;
  final String originNameAr;
  final String originNameEn;
  final String destinationNameAr;
  final String destinationNameEn;
  final List<BusStopModel> stops;
  final RouteGeometry? geometry;

  const FleetRoute({
    required this.routeId,
    required this.direction,
    required this.originNameAr,
    required this.originNameEn,
    required this.destinationNameAr,
    required this.destinationNameEn,
    this.stops = const [],
    this.geometry,
  });

  String localizedName(String locale) {
    if (locale.startsWith('ar')) {
      return '$originNameAr - $destinationNameAr';
    }
    return '$originNameEn - $destinationNameEn';
  }

  factory FleetRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List? ?? const [];
    final geomRaw = json['geometry'];
    return FleetRoute(
      routeId: json['route_id']?.toString() ?? '',
      direction: json['direction']?.toString() ?? 'outbound',
      originNameAr: json['origin_name_ar']?.toString() ?? '',
      originNameEn: json['origin_name_en']?.toString() ?? '',
      destinationNameAr: json['destination_name_ar']?.toString() ?? '',
      destinationNameEn: json['destination_name_en']?.toString() ?? '',
      stops: rawStops
          .whereType<Map>()
          .map((s) => BusStopModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      geometry: geomRaw != null && geomRaw is Map<String, dynamic>
          ? RouteGeometry.fromJson(geomRaw)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    routeId,
    direction,
    originNameAr,
    originNameEn,
    destinationNameAr,
    destinationNameEn,
    stops,
    geometry,
  ];
}
