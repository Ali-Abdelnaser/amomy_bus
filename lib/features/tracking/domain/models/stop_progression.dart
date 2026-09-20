import 'package:equatable/equatable.dart';
import 'bus_stop_model.dart';
import 'live_tracking_status.dart';

/// Progress state along the active physical route sequence.
class StopProgression extends Equatable {
  final BusStopModel currentStop;
  final BusStopModel nextStop;
  final ApproachStatus status;
  final double? distanceToCurrentMeters;
  final double? distanceToNextMeters;
  final bool isCoordinatesPending;

  const StopProgression({
    required this.currentStop,
    required this.nextStop,
    required this.status,
    this.distanceToCurrentMeters,
    this.distanceToNextMeters,
    this.isCoordinatesPending = false,
  });

  /// Check if the bus is approaching or at the given target stop ID.
  bool isApproachingStop(String targetStopId) {
    if (nextStop.id == targetStopId && status == ApproachStatus.approaching) {
      return true;
    }
    return false;
  }

  bool isAtTargetStop(String targetStopId) {
    return currentStop.id == targetStopId && status == ApproachStatus.atStop;
  }

  @override
  List<Object?> get props => [
    currentStop,
    nextStop,
    status,
    distanceToCurrentMeters,
    distanceToNextMeters,
    isCoordinatesPending,
  ];
}
