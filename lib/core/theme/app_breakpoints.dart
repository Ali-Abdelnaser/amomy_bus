import 'package:flutter/material.dart';

/// Lightweight responsive breakpoints for mobile phone layouts.
abstract final class AppBreakpoints {
  /// Small compact phones (e.g. iPhone SE, compact Android)
  static const double compactMax = 360.0;

  /// Standard modern smartphone width
  static const double phoneMax = 600.0;

  /// Tablet breakpoint (reserved for future adaptive layouts)
  static const double tabletMax = 900.0;

  /// Returns true if the screen width is small/compact (<= 360px)
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= compactMax;

  /// Returns true if device is standard mobile phone (<= 600px)
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= phoneMax;

  /// Returns true if device width exceeds standard phone
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width > phoneMax;
}

/// Adaptive layout builder helper for responsive screens without overengineering.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.compact,
    this.tablet,
  });

  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? compact;
  final Widget Function(BuildContext context)? tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (compact != null && width <= AppBreakpoints.compactMax) {
      return compact!(context);
    }
    if (tablet != null && width > AppBreakpoints.phoneMax) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
