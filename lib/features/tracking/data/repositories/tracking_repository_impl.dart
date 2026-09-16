import 'dart:async';
import 'package:amomy_bus/features/tracking/domain/models/route_geometry.dart';

import '../../domain/models/tracking_summary.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;

  TrackingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<TrackingSummary> getTripTracking({required String tripId}) {
    return remoteDataSource.getTripTracking(tripId: tripId);
  }

  @override
  Future<RouteGeometry?> getActiveRouteGeometry({
    required String routeId,
    required String direction,
  }) {
    return remoteDataSource.getActiveRouteGeometry(
      routeId: routeId,
      direction: direction,
    );
  }

  @override
  Stream<void> subscribeToTripTrackingState({required String tripId}) {
    return remoteDataSource.subscribeToTripTrackingState(tripId: tripId);
  }

  @override
  Future<bool> recordApproachNotification({
    required String routeId,
    required String targetStopId,
    required String serviceRunTime,
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) {
    return remoteDataSource.recordApproachNotification(
      routeId: routeId,
      targetStopId: targetStopId,
      serviceRunTime: serviceRunTime,
      titleAr: titleAr,
      titleEn: titleEn,
      bodyAr: bodyAr,
      bodyEn: bodyEn,
    );
  }

  @override
  Future<void> updateApproachAlertsPreference(bool enabled) {
    return remoteDataSource.updateApproachAlertsPreference(enabled);
  }

  @override
  Future<void> simulateQaLocation({
    required String busId,
    required double latitude,
    required double longitude,
    int heading = 0,
    double speedKmh = 30,
  }) {
    return remoteDataSource.simulateQaLocation(
      busId: busId,
      latitude: latitude,
      longitude: longitude,
      heading: heading,
      speedKmh: speedKmh,
    );
  }
}
