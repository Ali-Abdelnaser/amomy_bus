enum LiveTrackingStatus {
  /// Canonical Phase 8 trip-specific live tracking state.
  live,

  /// Bus is actively transmitting fresh telemetry within scheduled service window.
  online,

  /// Between scheduled service runs (e.g. 08:00 run completed, waiting/repositioning for 09:00).
  betweenRuns,

  /// In service window, but latest GPS update exceeds stale threshold (60-120s) or reconnecting.
  stale,

  /// Outside operating hours or inactive.
  offline,

  /// Driver has not claimed an operational bus for this trip yet.
  assignmentPending,

  /// The booked trip is not active for tracking.
  tripNotActive,

  /// Backend says this trip is outside its tracking window.
  outsideTrackingWindow,

  /// Location may be available, but stop progression cannot be safely computed.
  progressionUnavailable,

  /// Safe authorized preview outside operating hours for visual route verification.
  qaPreview,
}

/// Semantic Phase T2 tracking lifecycle phases driven by Staff Trip lifecycle.
enum TrackingPhase {
  waitingAssignment,
  waitingStart,
  reassignmentPending,
  gpsOffline,
  gpsStale,
  progressionSyncing,
  live,
  completed,
  cancelled,
  serviceDateEnded,
  unknown;

  static TrackingPhase fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'waiting_assignment':
      case 'assignment_pending':
        return TrackingPhase.waitingAssignment;
      case 'waiting_start':
        return TrackingPhase.waitingStart;
      case 'reassignment_pending':
        return TrackingPhase.reassignmentPending;
      case 'gps_offline':
      case 'offline':
        return TrackingPhase.gpsOffline;
      case 'gps_stale':
      case 'stale':
        return TrackingPhase.gpsStale;
      case 'progression_syncing':
      case 'progression_unavailable':
        return TrackingPhase.progressionSyncing;
      case 'live':
      case 'online':
        return TrackingPhase.live;
      case 'completed':
        return TrackingPhase.completed;
      case 'cancelled':
        return TrackingPhase.cancelled;
      case 'service_date_ended':
        return TrackingPhase.serviceDateEnded;
      default:
        return TrackingPhase.unknown;
    }
  }

  bool get isPreTrip =>
      this == TrackingPhase.waitingAssignment ||
      this == TrackingPhase.waitingStart;

  bool get isPostTrip =>
      this == TrackingPhase.completed ||
      this == TrackingPhase.cancelled ||
      this == TrackingPhase.serviceDateEnded;

  bool get isOperational =>
      this == TrackingPhase.live ||
      this == TrackingPhase.gpsStale ||
      this == TrackingPhase.gpsOffline ||
      this == TrackingPhase.progressionSyncing ||
      this == TrackingPhase.reassignmentPending;
}

enum TrackingStopSemanticState {
  passed,
  active,
  next,
  future,
  unknown;

  static TrackingStopSemanticState fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'passed':
        return TrackingStopSemanticState.passed;
      case 'active':
      case 'current':
        return TrackingStopSemanticState.active;
      case 'next':
        return TrackingStopSemanticState.next;
      case 'future':
        return TrackingStopSemanticState.future;
      default:
        return TrackingStopSemanticState.unknown;
    }
  }
}

/// Service direction: Outbound (morning) or Return (afternoon).
enum TrackingDirection {
  outbound,
  returnDirection;

  static TrackingDirection fromString(String? value) {
    if (value == null) return TrackingDirection.outbound;
    final lower = value.toLowerCase();
    if (lower == 'return' || lower == 'inbound') {
      return TrackingDirection.returnDirection;
    }
    return TrackingDirection.outbound;
  }

  String toDbString() {
    switch (this) {
      case TrackingDirection.outbound:
        return 'outbound';
      case TrackingDirection.returnDirection:
        return 'return';
    }
  }
}

/// Dynamic approach status relative to a specific route stop.
enum ApproachStatus { approaching, atStop, departed }
