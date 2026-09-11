import 'package:flutter/material.dart';

/// Centralized shadow tokens for elevation and depth.
abstract final class AppShadows {
  /// Subtle shadow for resting cards, input fields, and chips
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0F101828),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  /// Standard shadow for interactive cards, dropdowns, and buttons
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14101828),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x0A101828),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
    ),
  ];

  /// Pronounced shadow for modals, dialogs, and bottom sheets
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A101828),
      offset: Offset(0, 12),
      blurRadius: 16,
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x0F101828),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  /// Floating action bar or elevated bottom navigation shadow
  static const List<BoxShadow> topBar = [
    BoxShadow(
      color: Color(0x0D101828),
      offset: Offset(0, -4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}
