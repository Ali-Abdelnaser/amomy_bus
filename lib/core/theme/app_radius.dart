import 'package:flutter/material.dart';

/// Centralized radius tokens (8, 12, 16, 20, 24, circular).
abstract final class AppRadius {
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double circular = 999.0;

  // Semantic aliases
  static const double sm = r8;
  static const double md = r12;
  static const double lg = r16;
  static const double xl = r20;
  static const double xxl = r24;

  // BorderRadius presets
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(r8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(r12));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(r16));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(r20));
  static const BorderRadius radiusXxl = BorderRadius.all(Radius.circular(r24));
  static const BorderRadius radiusCircular = BorderRadius.all(Radius.circular(circular));

  // Component radius aliases
  static const BorderRadius button = radiusMd;
  static const BorderRadius card = radiusMd;
  static const BorderRadius input = radiusMd;

  // Top rounded corners (e.g. bottom sheets, modals)
  static const BorderRadius topMd = BorderRadius.vertical(top: Radius.circular(r12));
  static const BorderRadius topLg = BorderRadius.vertical(top: Radius.circular(r16));
  static const BorderRadius topXl = BorderRadius.vertical(top: Radius.circular(r20));
  static const BorderRadius topXxl = BorderRadius.vertical(top: Radius.circular(r24));
}
