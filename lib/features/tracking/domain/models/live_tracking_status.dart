enum LiveTrackingStatus {
  /// Bus is actively transmitting fresh telemetry within scheduled service window.
  online,

  /// Between scheduled service runs (e.g. 08:00 run completed, waiting/repositioning for 09:00).
  betweenRuns,

  /// In service window, but latest GPS update exceeds stale threshold (60-120s) or reconnecting.
  stale,

  /// Outside operating hours (08:00-12:00, 13:00-17:00 Cairo time).
  offline,

  /// Safe authorized preview outside operating hours for visual route verification.
  qaPreview,
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
enum ApproachStatus {
  approaching,
  atStop,
  departed,
}
