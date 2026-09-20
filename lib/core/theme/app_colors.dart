import 'package:flutter/material.dart';

/// Centralized color palette for Amomy Bus.
///
/// Brand identity: WHITE + BLUE
/// Official Primary Brand Blue: #01589F
abstract final class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF01589F);
  static const Color primaryDark = Color(0xFF01467F);
  static const Color primaryDarker = Color(0xFF00355F);
  static const Color deepNavy = Color(0xFF00355F);
  static const Color primaryLight = Color(0xFFE7F2FA);

  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF6F9FC);

  // Accent Color
  static const Color accentYellow = Color(0xFFFFC928);

  // Text Colors
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // UI Colors
  static const Color border = Color(0xFFE4E7EC);
  static const Color borderSubtle = Color(0xFFF2F4F7);
  static const Color disabled = Color(0xFFB8C1CC);
  static const Color disabledBackground = Color(0xFFF2F4F7);

  // Semantic Status Colors
  static const Color success = Color(0xFF12B76A);
  static const Color successLight = Color(0xFFECFDF3);
  static const Color warning = Color(0xFFF79009);
  static const Color warningLight = Color(0xFFFEF0C7);
  static const Color error = Color(0xFFD92D20);
  static const Color errorLight = Color(0xFFFEE4E2);
  static const Color info = Color(0xFF01589F);
  static const Color infoLight = Color(0xFFE7F2FA);

  // Future Seat Status Colors
  static const Color seatAvailable = Color(0xFF01589F); // Blue
  static const Color seatPending = Color(0xFFF79009); // Orange
  static const Color seatConfirmed = Color(0xFF12B76A); // Green
  static const Color seatDisabled = Color(0xFFB8C1CC); // Disabled Gray

  // Transparent / Shimmer Colors
  static const Color shimmerBase = Color(0xFFE4E7EC);
  static const Color shimmerHighlight = Color(0xFFF6F9FC);
  static const Color overlayScrim = Color(0x66101828);
}
