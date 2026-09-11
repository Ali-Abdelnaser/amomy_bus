import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_animation_durations.dart';

/// Centralized animation extensions and presets using flutter_animate.
///
/// Designed to be subtle, professional, and accessible.
extension AppAnimationExtensions on Widget {
  /// Subtle fade-in animation
  Widget animateFadeIn({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
  }) {
    return animate(delay: delay).fadeIn(
      duration: duration,
      curve: AppAnimationDurations.decelerate,
    );
  }

  /// Subtle slide-up + fade-in animation
  Widget animateSlideUp({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginY = 0.15,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppAnimationDurations.decelerate)
        .slideY(
          begin: beginY,
          end: 0,
          duration: duration,
          curve: AppAnimationDurations.decelerate,
        );
  }

  /// Subtle slide-down animation
  Widget animateSlideDown({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginY = -0.15,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppAnimationDurations.decelerate)
        .slideY(
          begin: beginY,
          end: 0,
          duration: duration,
          curve: AppAnimationDurations.decelerate,
        );
  }

  /// Horizontal slide from right (e.g. for step navigation or card entrance)
  Widget animateSlideFromRight({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginX = 0.2,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: AppAnimationDurations.decelerate)
        .slideX(
          begin: beginX,
          end: 0,
          duration: duration,
          curve: AppAnimationDurations.decelerate,
        );
  }

  /// Scale-in animation with slight spring
  Widget animateScaleIn({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginScale = 0.85,
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration)
        .scale(
          begin: Offset(beginScale, beginScale),
          end: const Offset(1, 1),
          duration: duration,
          curve: AppAnimationDurations.decelerate,
        );
  }

  /// Staggered list item entrance animation
  Widget animateListItem(int index) {
    return animate(delay: Duration(milliseconds: 30 * index))
        .fadeIn(duration: AppAnimationDurations.normal)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: AppAnimationDurations.normal,
          curve: AppAnimationDurations.decelerate,
        );
  }

  // Shorthand aliases matching AMOMY design system specifications
  Widget appFadeIn({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
  }) =>
      animateFadeIn(duration: duration, delay: delay);

  Widget appSlideUp({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginY = 0.15,
  }) =>
      animateSlideUp(duration: duration, delay: delay, beginY: beginY);

  Widget appSlideDown({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginY = -0.15,
  }) =>
      animateSlideDown(duration: duration, delay: delay, beginY: beginY);

  Widget appSlideFromRight({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginX = 0.2,
  }) =>
      animateSlideFromRight(duration: duration, delay: delay, beginX: beginX);

  Widget appScaleIn({
    Duration duration = AppAnimationDurations.normal,
    Duration delay = Duration.zero,
    double beginScale = 0.85,
  }) =>
      animateScaleIn(duration: duration, delay: delay, beginScale: beginScale);

  Widget appListItemEntrance(int index) => animateListItem(index);
}
