import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_animation_durations.dart';

/// Centralized GoRouter CustomTransitionPage builders for natural iOS and Android transitions.
abstract final class AppPageTransitions {
  /// Standard platform-adaptive page transition
  static CustomTransitionPage<T> standardPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: AppAnimationDurations.normal,
      reverseTransitionDuration: AppAnimationDurations.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppAnimationDurations.decelerate,
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// Fade page transition (ideal for splash -> auth / bottom nav tab switches)
  static CustomTransitionPage<T> fadePage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: AppAnimationDurations.normal,
      reverseTransitionDuration: AppAnimationDurations.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppAnimationDurations.decelerate,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide-up modal page transition (ideal for checkout, filter sheets, confirmation dialogs)
  static CustomTransitionPage<T> modalPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: child,
      transitionDuration: AppAnimationDurations.medium,
      reverseTransitionDuration: AppAnimationDurations.fast,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: AppAnimationDurations.decelerate,
            ),
          ),
          child: child,
        );
      },
    );
  }
}
