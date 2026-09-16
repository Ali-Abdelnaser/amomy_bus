import 'package:equatable/equatable.dart';

/// Clean model representing an authoritative physical route stop from backend.
class BusStopModel extends Equatable {
  final String id;
  final String routeStopId;
  final int stopOrder;
  final String nameAr;
  final String nameEn;
  final String localityAr;
  final String localityEn;
  final double? latitude;
  final double? longitude;
  final bool isBoarding;
  final bool isDropoff;
  final bool isTemporaryQa;
  final String? coordinateSource;
  final int farePoints;
  final DateTime? actualArrivalTime;
  final DateTime? estimatedArrivalTime;

  const BusStopModel({
    required this.id,
    required this.routeStopId,
    required this.stopOrder,
    required this.nameAr,
    required this.nameEn,
    required this.localityAr,
    required this.localityEn,
    this.latitude,
    this.longitude,
    this.isBoarding = true,
    this.isDropoff = true,
    this.isTemporaryQa = false,
    this.coordinateSource,
    this.farePoints = 20,
    this.actualArrivalTime,
    this.estimatedArrivalTime,
  });

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      !latitude!.isNaN &&
      !longitude!.isNaN &&
      !latitude!.isInfinite &&
      !longitude!.isInfinite &&
      latitude! >= -90.0 &&
      latitude! <= 90.0 &&
      longitude! >= -180.0 &&
      longitude! <= 180.0;

  BusStopModel copyWith({
    String? id,
    String? routeStopId,
    int? stopOrder,
    String? nameAr,
    String? nameEn,
    String? localityAr,
    String? localityEn,
    double? latitude,
    double? longitude,
    bool? isBoarding,
    bool? isDropoff,
    bool? isTemporaryQa,
    String? coordinateSource,
    int? farePoints,
    DateTime? actualArrivalTime,
    DateTime? estimatedArrivalTime,
  }) {
    return BusStopModel(
      id: id ?? this.id,
      routeStopId: routeStopId ?? this.routeStopId,
      stopOrder: stopOrder ?? this.stopOrder,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      localityAr: localityAr ?? this.localityAr,
      localityEn: localityEn ?? this.localityEn,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isBoarding: isBoarding ?? this.isBoarding,
      isDropoff: isDropoff ?? this.isDropoff,
      isTemporaryQa: isTemporaryQa ?? this.isTemporaryQa,
      coordinateSource: coordinateSource ?? this.coordinateSource,
      farePoints: farePoints ?? this.farePoints,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      estimatedArrivalTime: estimatedArrivalTime ?? this.estimatedArrivalTime,
    );
  }

  String localizedName(String locale) {
    if (locale.startsWith('ar')) {
      return nameAr.isNotEmpty ? nameAr : nameEn;
    }
    return nameEn.isNotEmpty ? nameEn : nameAr;
  }

  String localizedLocality(String locale) {
    if (locale.startsWith('ar')) {
      return localityAr.isNotEmpty ? localityAr : localityEn;
    }
    return localityEn.isNotEmpty ? localityEn : localityAr;
  }

  factory BusStopModel.fromJson(Map<String, dynamic> json) {
    final isQa =
        (json['is_qa_coord'] as bool?) ??
        (json['source'] == 'temporary_qa' ||
            json['coordinate_source'] == 'temporary_qa');

    final actualRaw = json['actual_arrival_time'] ?? json['arrived_at'];
    final estRaw = json['estimated_arrival_time'] ?? json['eta'];

    return BusStopModel(
      id: (json['stop_id'] ?? json['id'] ?? '') as String,
      routeStopId: (json['route_stop_id'] ?? '') as String,
      stopOrder: (json['stop_order'] as num?)?.toInt() ?? 0,
      nameAr: (json['name_ar'] ?? '') as String,
      nameEn: (json['name_en'] ?? '') as String,
      localityAr: (json['locality_ar'] ?? '') as String,
      localityEn: (json['locality_en'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isBoarding: (json['is_boarding'] as bool?) ?? true,
      isDropoff: (json['is_dropoff'] as bool?) ?? true,
      isTemporaryQa: isQa,
      coordinateSource:
          json['coordinate_source'] as String? ??
          (isQa
              ? 'temporary_qa'
              : (json['latitude'] != null ? 'verified' : null)),
      farePoints: (json['fare_points'] as num?)?.toInt() ?? 20,
      actualArrivalTime: actualRaw != null
          ? DateTime.tryParse(actualRaw.toString())
          : null,
      estimatedArrivalTime: estRaw != null
          ? DateTime.tryParse(estRaw.toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'route_stop_id': routeStopId,
    'stop_order': stopOrder,
    'name_ar': nameAr,
    'name_en': nameEn,
    'locality_ar': localityAr,
    'locality_en': localityEn,
    'latitude': latitude,
    'longitude': longitude,
    'is_boarding': isBoarding,
    'is_dropoff': isDropoff,
    'is_qa_coord': isTemporaryQa,
    'coordinate_source': coordinateSource,
    'fare_points': farePoints,
    'actual_arrival_time': actualArrivalTime?.toIso8601String(),
    'estimated_arrival_time': estimatedArrivalTime?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    routeStopId,
    stopOrder,
    nameAr,
    nameEn,
    localityAr,
    localityEn,
    latitude,
    longitude,
    isBoarding,
    isDropoff,
    isTemporaryQa,
    coordinateSource,
    farePoints,
    actualArrivalTime,
    estimatedArrivalTime,
  ];
}
