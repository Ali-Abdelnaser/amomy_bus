import 'package:flutter/material.dart';

import 'app_animations.dart';

/// Centralized duration constants for animation timing and curves.
abstract final class AppAnimationDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = AppAnimations.routeTransitionDuration;
  static const Duration medium = AppAnimations.screenEntryDuration;
  static const Duration slow = Duration(milliseconds: 500);

  // Standard Curves
  static const Curve standard = Curves.easeInOutCubicEmphasized;
  static const Curve decelerate = AppAnimations.routeCurve;
  static const Curve bounce = Curves.elasticOut;
}
