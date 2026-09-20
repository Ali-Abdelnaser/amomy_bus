import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_locale_controller.dart';
import 'app_colors.dart';

/// Centralized platform-safe typography styles for Amomy Bus.
///
/// Strictly applies:
/// - Arabic: Tajawal (GoogleFonts.tajawal) with native weights (200, 300, 400, 500, 700, 800, 900)
/// - English: Open Sans (GoogleFonts.openSans) with native weights (300, 400, 500, 600, 700, 800)
///
/// Handles weight mapping (e.g. w600 -> w700 for Tajawal since Tajawal has no w600),
/// ensuring all bold/regular/medium weights render clearly and dynamically.
abstract final class AppTextStyles {
  // --- Raw Static Constants (Platform/Material specifications) ---

  // Display Styles
  static const TextStyle rawDisplayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawDisplayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // Headline Styles
  static const TextStyle rawHeadlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawHeadlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawHeadlineSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Title Styles
  static const TextStyle rawTitleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawTitleMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawTitleSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Body Styles
  static const TextStyle rawBodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawBodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawBodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // Label & Button Styles
  static const TextStyle rawLabelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle rawLabelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle rawLabelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // Legacy / Convenience Aliases
  static const TextStyle rawButtonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const TextStyle rawButtonMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static const TextStyle rawCaption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // --- Dynamic Locale-Bound Font Getters ---

  static TextStyle get displayLarge => localized(rawDisplayLarge);
  static TextStyle get displayMedium => localized(rawDisplayMedium);
  static TextStyle get headlineLarge => localized(rawHeadlineLarge);
  static TextStyle get headlineMedium => localized(rawHeadlineMedium);
  static TextStyle get headlineSmall => localized(rawHeadlineSmall);
  static TextStyle get titleLarge => localized(rawTitleLarge);
  static TextStyle get titleMedium => localized(rawTitleMedium);
  static TextStyle get titleSmall => localized(rawTitleSmall);
  static TextStyle get bodyLarge => localized(rawBodyLarge);
  static TextStyle get bodyMedium => localized(rawBodyMedium);
  static TextStyle get bodySmall => localized(rawBodySmall);
  static TextStyle get labelLarge => localized(rawLabelLarge);
  static TextStyle get labelMedium => localized(rawLabelMedium);
  static TextStyle get labelSmall => localized(rawLabelSmall);
  static TextStyle get buttonLarge => localized(rawButtonLarge);
  static TextStyle get buttonMedium => localized(rawButtonMedium);
  static TextStyle get caption => localized(rawCaption);

  /// Converts any [TextStyle] into a fully bound, locale-aware GoogleFonts style (Tajawal for Arabic, Open Sans for English).
  ///
  /// Automatically resolves font weights so that [FontWeight.bold], [FontWeight.w700],
  /// [FontWeight.w800], [FontWeight.w900], [FontWeight.w500], [FontWeight.normal]
  /// and [FontWeight.w400] load their respective font files without fallback locks.
  static TextStyle localized(TextStyle style, {Locale? locale}) {
    final isAr =
        (locale ?? AppLocaleController.instance.locale).languageCode == 'ar';

    // Tajawal on Google Fonts supports 200, 300, 400, 500, 700, 800, 900.
    // Map w600 to w700 for Tajawal so bold/semibold text renders sharply.
    FontWeight? targetWeight = style.fontWeight;
    if (isAr && (targetWeight == FontWeight.w600)) {
      targetWeight = FontWeight.w700;
    }

    final cleanStyle = targetWeight != null && targetWeight != style.fontWeight
        ? style.copyWith(fontWeight: targetWeight)
        : style;

    return isAr
        ? GoogleFonts.tajawal(textStyle: cleanStyle)
        : GoogleFonts.openSans(textStyle: cleanStyle);
  }

  /// Explicit Tajawal (Arabic) style generator with font weight resolution.
  static TextStyle tajawal(TextStyle style) {
    FontWeight? targetWeight = style.fontWeight;
    if (targetWeight == FontWeight.w600) {
      targetWeight = FontWeight.w700;
    }
    final cleanStyle = targetWeight != null && targetWeight != style.fontWeight
        ? style.copyWith(fontWeight: targetWeight)
        : style;
    return GoogleFonts.tajawal(textStyle: cleanStyle);
  }

  /// Explicit Open Sans (English) style generator with font weight resolution.
  static TextStyle openSans(TextStyle style) {
    return GoogleFonts.openSans(textStyle: style);
  }

  // --- Static Helper Methods ---

  /// Applies Bold (w700) with proper font file binding.
  static TextStyle bold(TextStyle style, {Locale? locale}) =>
      localized(style.copyWith(fontWeight: FontWeight.bold), locale: locale);

  /// Applies SemiBold (w700 for Arabic Tajawal, w600 for English Open Sans).
  static TextStyle semiBold(TextStyle style, {Locale? locale}) =>
      localized(style.copyWith(fontWeight: FontWeight.w600), locale: locale);

  /// Applies Medium (w500).
  static TextStyle medium(TextStyle style, {Locale? locale}) =>
      localized(style.copyWith(fontWeight: FontWeight.w500), locale: locale);

  /// Applies Regular (w400).
  static TextStyle regular(TextStyle style, {Locale? locale}) =>
      localized(style.copyWith(fontWeight: FontWeight.w400), locale: locale);

  /// Applies custom [FontWeight] with proper font file binding.
  static TextStyle withWeight(
    TextStyle style,
    FontWeight weight, {
    Locale? locale,
  }) => localized(style.copyWith(fontWeight: weight), locale: locale);

  /// Modifies color while preserving font family & weight bindings.
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  /// Modifies size while preserving font family & weight bindings.
  static TextStyle withSize(TextStyle style, double size) =>
      style.copyWith(fontSize: size);
}

/// Extension on [TextStyle] for fluent, weight-safe font mutations.
extension AppTextStyleExtension on TextStyle {
  /// Re-applies the active font family (Tajawal / Open Sans) with a new [FontWeight].
  TextStyle withWeight(FontWeight weight, {Locale? locale}) =>
      AppTextStyles.withWeight(this, weight, locale: locale);

  /// Returns this style in Bold (w700).
  TextStyle bold({Locale? locale}) => AppTextStyles.bold(this, locale: locale);

  /// Returns this style in SemiBold (w700 for Arabic Tajawal, w600 for English Open Sans).
  TextStyle semiBold({Locale? locale}) =>
      AppTextStyles.semiBold(this, locale: locale);

  /// Returns this style in Medium (w500).
  TextStyle medium({Locale? locale}) =>
      AppTextStyles.medium(this, locale: locale);

  /// Returns this style in Regular (w400).
  TextStyle regular({Locale? locale}) =>
      AppTextStyles.regular(this, locale: locale);

  /// Returns this style in ExtraBold (w800).
  TextStyle extraBold({Locale? locale}) =>
      AppTextStyles.withWeight(this, FontWeight.w800, locale: locale);

  /// Returns this style in Black (w900).
  TextStyle black({Locale? locale}) =>
      AppTextStyles.withWeight(this, FontWeight.w900, locale: locale);

  /// Modifies color while preserving font binding.
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Modifies size while preserving font binding.
  TextStyle withSize(double size) => copyWith(fontSize: size);

  /// Modifies line height while preserving font binding.
  TextStyle withHeight(double height) => copyWith(height: height);

  /// Re-binds this style to the active locale font family.
  TextStyle get localized => AppTextStyles.localized(this);
}
