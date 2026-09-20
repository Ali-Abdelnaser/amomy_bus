import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization/app_locale_controller.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Centralized Material 3 Theme definition for Amomy Bus.
///
/// Strictly applies:
/// - Arabic: Tajawal (GoogleFonts.tajawal)
/// - English: Open Sans (GoogleFonts.openSans)
///
/// Preserves official primary brand color #01589F and handles full bi-directional typography.
abstract final class AppTheme {
  /// Builds locale-aware ThemeData with Tajawal for Arabic and Open Sans for English.
  static ThemeData getTheme([Locale? locale]) {
    final effectiveLocale = locale ?? AppLocaleController.instance.locale;
    final isArabic = effectiveLocale.languageCode == 'ar';

    final primaryFont = isArabic
        ? GoogleFonts.tajawal().fontFamily
        : GoogleFonts.openSans().fontFamily;

    final fallbackFont = isArabic
        ? GoogleFonts.openSans().fontFamily!
        : GoogleFonts.tajawal().fontFamily!;

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.primaryDarker,
      secondary: AppColors.accentYellow,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: Color(0xFFFFF3D6),
      onSecondaryContainer: Color(0xFF6B4F00),
      tertiary: AppColors.primaryDark,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
      shadow: Color(0x14101828),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryLight,
    );

    final baseTextTheme = TextTheme(
      displayLarge: AppTextStyles.rawDisplayLarge,
      displayMedium: AppTextStyles.rawDisplayMedium,
      headlineLarge: AppTextStyles.rawHeadlineLarge,
      headlineMedium: AppTextStyles.rawHeadlineMedium,
      headlineSmall: AppTextStyles.rawHeadlineSmall,
      titleLarge: AppTextStyles.rawTitleLarge,
      titleMedium: AppTextStyles.rawTitleMedium,
      titleSmall: isArabic
          ? AppTextStyles.rawTitleSmall.copyWith(fontWeight: FontWeight.w700)
          : AppTextStyles.rawTitleSmall,
      bodyLarge: AppTextStyles.rawBodyLarge,
      bodyMedium: AppTextStyles.rawBodyMedium,
      bodySmall: AppTextStyles.rawBodySmall,
      labelLarge: AppTextStyles.rawLabelLarge,
      labelMedium: isArabic
          ? AppTextStyles.rawLabelMedium.copyWith(fontWeight: FontWeight.w700)
          : AppTextStyles.rawLabelMedium,
      labelSmall: AppTextStyles.rawLabelSmall,
    );

    final localizedTextTheme = isArabic
        ? GoogleFonts.tajawalTextTheme(baseTextTheme)
        : GoogleFonts.openSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: primaryFont,
      fontFamilyFallback: [primaryFont!, fallbackFont],

      // Typography
      textTheme: localizedTextTheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: AppTextStyles.localized(
          AppTextStyles.rawHeadlineSmall,
          locale: effectiveLocale,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Elevated Button Theme (Primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.disabledBackground,
          disabledForegroundColor: AppColors.disabled,
          textStyle: AppTextStyles.localized(
            AppTextStyles.rawLabelLarge,
            locale: effectiveLocale,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          minimumSize: const Size(0, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
          elevation: 0,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabled,
          textStyle: AppTextStyles.localized(
            AppTextStyles.rawLabelLarge,
            locale: effectiveLocale,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s20,
            vertical: AppSpacing.s12,
          ),
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.disabled,
          textStyle: AppTextStyles.localized(
            AppTextStyles.rawLabelLarge,
            locale: effectiveLocale,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        hintStyle: AppTextStyles.localized(
          AppTextStyles.rawBodyMedium.copyWith(color: const Color(0xFF94A3B8)),
          locale: effectiveLocale,
        ),
        labelStyle: AppTextStyles.localized(
          AppTextStyles.rawLabelMedium.copyWith(color: AppColors.textSecondary),
          locale: effectiveLocale,
        ),
        errorStyle: AppTextStyles.localized(
          AppTextStyles.rawBodySmall.copyWith(
            color: AppColors.error,
            fontSize: 12,
          ),
          locale: effectiveLocale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topXxl),
        showDragHandle: false,
        dragHandleColor: AppColors.disabled,
        dragHandleSize: Size(36, 4),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXxl),
        titleTextStyle: AppTextStyles.localized(
          AppTextStyles.rawHeadlineSmall,
          locale: effectiveLocale,
        ),
        contentTextStyle: AppTextStyles.localized(
          AppTextStyles.rawBodyMedium,
          locale: effectiveLocale,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceSoft,
        disabledColor: AppColors.disabledBackground,
        selectedColor: AppColors.primaryLight,
        secondarySelectedColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        labelStyle: AppTextStyles.localized(
          AppTextStyles.rawLabelMedium,
          locale: effectiveLocale,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.radiusSm,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.localized(
          AppTextStyles.rawBodyMedium.copyWith(color: Colors.white),
          locale: effectiveLocale,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusMd),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.primaryLight,
        circularTrackColor: AppColors.primaryLight,
      ),
    );
  }

  /// Default light theme using current active locale
  static ThemeData get lightTheme => getTheme();

  /// Scaffold placeholder for future Dark Theme expansion
  static ThemeData get darkTheme => lightTheme;
}
