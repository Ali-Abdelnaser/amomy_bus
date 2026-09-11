/// Centralized duration tokens for consistent micro-interactions and transitions.
abstract final class AppDurations {
  /// Instant micro-feedback (button tap, toggle, icon state change)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard element transition (card hover, expand/collapse, tab change)
  static const Duration normal = Duration(milliseconds: 250);

  /// Modal, bottom sheet, or complex entrance animation
  static const Duration slow = Duration(milliseconds: 350);

  /// Splash / screen transition duration
  static const Duration screenTransition = Duration(milliseconds: 400);

  /// Splash sequence duration (~2 seconds)
  static const Duration splashSequence = Duration(milliseconds: 2000);

  /// Toast / SnackBar display duration
  static const Duration snackBarDisplay = Duration(seconds: 4);

  /// Seat hold countdown default tick
  static const Duration timerTick = Duration(seconds: 1);
}
