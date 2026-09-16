import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'animated_screen_entry.dart';
import 'app_animations.dart';

/// Centralized GoRouter page builders for app-level motion.
abstract final class AppPageTransitions {
  static Widget _entryChild(Widget child, {bool screenEntry = true}) {
    return screenEntry ? AnimatedScreenEntry(child: child) : child;
  }

  /// Normal pushed page transition: subtle fade plus content entrance.
  static CustomTransitionPage<T> standardPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    bool screenEntry = true,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: _entryChild(child, screenEntry: screenEntry),
      transitionDuration: AppAnimations.routeTransitionDuration,
      reverseTransitionDuration: AppAnimations.routeReverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = AppAnimations.reduceMotion(context);
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: reduceMotion ? Curves.linear : AppAnimations.routeCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Fade page transition without screen-entry by default.
  static CustomTransitionPage<T> fadePage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
    bool screenEntry = false,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      name: name,
      child: _entryChild(child, screenEntry: screenEntry),
      transitionDuration: AppAnimations.routeTransitionDuration,
      reverseTransitionDuration: AppAnimations.routeReverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AppAnimations.reduceMotion(context)
                ? Curves.linear
                : AppAnimations.routeCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Shell tab roots keep branch switching immediate while entering once.
  static Page<T> shellPage<T>({
    required Widget child,
    required LocalKey key,
    String? name,
  }) {
    return NoTransitionPage<T>(
      key: key,
      name: name,
      child: AnimatedScreenEntry(child: child),
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
      transitionDuration: AppAnimations.screenEntryDuration,
      reverseTransitionDuration: AppAnimations.routeReverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: AppAnimations.routeCurve,
                ),
              ),
          child: child,
        );
      },
    );
  }
}
