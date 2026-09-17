import 'package:flutter/material.dart';

/// Centralized spacing tokens (4, 8, 12, 16, 20, 24, 32, 40, 48).
abstract final class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // Aliases
  static const double xxs = s4;
  static const double xs = s8;
  static const double sm = s12;
  static const double md = s16;
  static const double lg = s20;
  static const double xl = s24;
  static const double xxl = s32;
  static const double xxxl = s40;
  static const double huge = s48;

  // EdgeInsets presets
  static const EdgeInsets zero = EdgeInsets.zero;
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  static const EdgeInsets paddingXs = p8;
  static const EdgeInsets paddingSm = p12;
  static const EdgeInsets paddingMd = p16;
  static const EdgeInsets paddingLg = p20;
  static const EdgeInsets paddingXl = p24;

  // Semantic naming aliases
  static const EdgeInsets edgeInsetsA8 = p8;
  static const EdgeInsets edgeInsetsA12 = p12;
  static const EdgeInsets edgeInsetsA16 = p16;
  static const EdgeInsets edgeInsetsA20 = p20;
  static const EdgeInsets edgeInsetsA24 = p24;
  static const EdgeInsets edgeInsetsA32 = p32;

  // Horizontal presets
  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets h12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets h20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: s24);

  static const EdgeInsets edgeInsetsH8 = h8;
  static const EdgeInsets edgeInsetsH12 = h12;
  static const EdgeInsets edgeInsetsH16 = h16;
  static const EdgeInsets edgeInsetsH20 = h20;
  static const EdgeInsets edgeInsetsH24 = h24;

  // Vertical presets
  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets v20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: s24);

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(s16);
  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(horizontal: s16);

  // Width Gaps
  static const SizedBox gapW4 = SizedBox(width: s4);
  static const SizedBox gapW6 = SizedBox(width: 6.0);
  static const SizedBox gapW8 = SizedBox(width: s8);
  static const SizedBox gapW10 = SizedBox(width: 10.0);
  static const SizedBox gapW12 = SizedBox(width: s12);
  static const SizedBox gapW14 = SizedBox(width: 14.0);
  static const SizedBox gapW16 = SizedBox(width: s16);
  static const SizedBox gapW18 = SizedBox(width: 18.0);
  static const SizedBox gapW20 = SizedBox(width: s20);
  static const SizedBox gapW24 = SizedBox(width: s24);
  static const SizedBox gapW32 = SizedBox(width: s32);
  static const SizedBox gapW40 = SizedBox(width: s40);
  static const SizedBox gapW48 = SizedBox(width: s48);

  // Height Gaps
  static const SizedBox gapH2 = SizedBox(height: 2.0);
  static const SizedBox gapH4 = SizedBox(height: s4);
  static const SizedBox gapH6 = SizedBox(height: 6.0);
  static const SizedBox gapH8 = SizedBox(height: s8);
  static const SizedBox gapH10 = SizedBox(height: 10.0);
  static const SizedBox gapH12 = SizedBox(height: s12);
  static const SizedBox gapH14 = SizedBox(height: 14.0);
  static const SizedBox gapH16 = SizedBox(height: s16);
  static const SizedBox gapH18 = SizedBox(height: 18.0);
  static const SizedBox gapH20 = SizedBox(height: s20);
  static const SizedBox gapH24 = SizedBox(height: s24);
  static const SizedBox gapH32 = SizedBox(height: s32);
  static const SizedBox gapH40 = SizedBox(height: s40);
  static const SizedBox gapH48 = SizedBox(height: s48);

  /// Centralized bottom clearance for scroll views above the floating navigation bar.
  static const double bottomNavClearance = 96.0;
  static const SizedBox gapBottomNav = SizedBox(height: bottomNavClearance);
}
