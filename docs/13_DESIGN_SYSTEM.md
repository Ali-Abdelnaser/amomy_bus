# Amomy Bus Design System Specification (Day 2A)

## 1. Brand Identity & Color Palette

The Amomy Bus brand is anchored by a crisp, high-contrast **White + Blue** visual identity. Blue communicates safety, reliability, and precision for daily commuters, while white surfaces ensure maximum readability under varying lighting conditions. Yellow is strictly reserved as an intentional accent.

### 1.1 Palette Breakdown
- **Primary Brand Blue**: `#01589F` (Official reference color, preserved across all theme components — never replaced by `ColorScheme.fromSeed` algorithmic substitutions)
- **Primary Dark**: `#01467F` (Used for pressed states and emphasized brand banners)
- **Primary Darker**: `#00355F` (Used for high-contrast headers, deep active badges)
- **Primary Light / Container**: `#E7F2FA` (Used for subtle active pill backgrounds, icon badges, and input fills)
- **Accent Yellow**: `#FFC928` (Secondary highlight only — for status highlights, special offers, and promotional badges. Never used as primary button background)

### 1.2 Neutral & Surface Hierarchy
- **Background**: `#FFFFFF`
- **Surface**: `#FFFFFF`
- **Surface Soft**: `#F6F9FC` (Subtle off-white background for list views and grouped form sections)
- **Border**: `#E4E7EC`
- **Disabled**: `#B8C1CC`
- **Text Primary**: `#101828` (Deep charcoal, WCAG AAA compliant contrast on white)
- **Text Secondary**: `#667085` (Medium gray for captions, subtitles, and placeholder hints)

### 1.3 Semantic Colors
- **Success**: `#12B76A` (Confirmed reservations, successful recharges)
- **Warning**: `#F79009` (Point expiration notices, pending reviews)
- **Error**: `#D92D20` (Booking failures, validation errors, cancellations)

### 1.4 Future Seat Colors (Tokens defined in AppColors)
- **Available Seat**: `#01589F` (Brand Blue)
- **Pending Seat**: `#F79009` (Orange / In checkout hold)
- **Confirmed / Booked Seat**: `#12B76A` (Green / Reserved)

---

## 2. Design Tokens

All design tokens are centralized under `lib/core/theme/`:

| Token Category | File | Values / Conventions |
| :--- | :--- | :--- |
| **Colors** | [app_colors.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_colors.dart) | Hex constants, Material ColorScheme mapping, seat status colors |
| **Spacing** | [app_spacing.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_spacing.dart) | 4, 8, 12, 16, 20, 24, 32, 40, 48 + predefined EdgeInsets & Gap widgets |
| **Radius** | [app_radius.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_radius.dart) | 8 (sm), 12 (md), 16 (lg), 20 (xl), 24 (xxl), circular |
| **Shadows** | [app_shadows.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_shadows.dart) | sm (cards), md (flyouts), lg (modals), topBar (bottom navigation bar shadow) |
| **Durations** | [app_durations.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_durations.dart) | fast (150ms), normal (300ms), slow (500ms), screenTransition (350ms), splash (2000ms) |
| **Breakpoints** | [app_breakpoints.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_breakpoints.dart) | `AppBreakpoints` (mobile: 600, tablet: 900) & `ResponsiveBuilder` |
| **Typography** | [app_text_styles.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_text_styles.dart) | Platform-safe display, headline, title, body, label styles supporting Arabic & English |
| **Theme** | [app_theme.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/theme/app_theme.dart) | Complete Material 3 ThemeData definition |

---

## 3. Typography System

The typography scale provides standard, platform-safe text styles using legible fallback fonts for both Latin and Arabic scripts:

- **Display**: `displayLarge` (32sp / w700), `displayMedium` (28sp / w700)
- **Headline**: `headlineLarge` (24sp / w600), `headlineMedium` (20sp / w600), `headlineSmall` (18sp / w600)
- **Title**: `titleLarge` (16sp / w600), `titleMedium` (14sp / w600), `titleSmall` (12sp / w600)
- **Body**: `bodyLarge` (16sp / w400), `bodyMedium` (14sp / w400), `bodySmall` (12sp / w400)
- **Label**: `labelLarge` (14sp / w500), `labelMedium` (12sp / w500), `labelSmall` (10sp / w500)

---

## 4. Icon System (Phosphor Icons Duotone)

To maintain modern visual polish without third-party coupling:
- Implemented via `package:phosphor_icons` (`^3.0.1`), strictly abstracted in [app_icons.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/icons/app_icons.dart).
- Feature widgets reference `AppIcons.<symbol>` (e.g. `AppIcons.bus`, `AppIcons.wallet`, `AppIcons.location`) rather than third-party classes.
- Ensures future icon family changes require edits to one file only.

---

## 5. Animation System

Centralized under `lib/core/animations/`:
- Uses `flutter_animate` extensions to provide fluent entrance effects (`.appFadeIn()`, `.appSlideUp()`, `.appScaleIn()`).
- Consistent durations from `AppDurations`.
- Centralized GoRouter page transitions via [app_page_transitions.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/animations/app_page_transitions.dart):
  - `standardPage`: Adaptive platform sliding/cupertinopage
  - `fadePage`: Smooth fade-through transition (used for splash to welcome/home)
  - `modalPage`: Slide from bottom for dialogs and sheets

---

## 6. Splash Strategy (Two-Tier Architecture)

1. **Native Launch Screen (`flutter_native_splash`)**:
   - Generates static native splash screens for Android (including Android 12 Splash API) and iOS.
   - White background (`#FFFFFF`) with centered `assets/logo_transperunt.png`.
   - Cannot be animated natively across diverse engine startup speeds.

2. **Custom Animated Flutter Splash (`SplashPage`)**:
   - Executes immediately once the Flutter engine initializes.
   - Smooth 2-second sequence featuring `assets/splash.png` background and `assets/logo_transperunt.png`.
   - Subtle pulse and scale animations with automatic routing handoff once minimum animation completes.

---

## 7. Asset Strategy

- Registered assets in `pubspec.yaml`:
  - `assets/logo_WhiteBg.png`: Used for launcher icon generation and white-card emblems.
  - `assets/logo_transperunt.png`: Used for dark/colored containers, splash page, and adaptive icon foreground.
  - `assets/splash.png`: Full-screen branded graphic asset.
- Abstracted in [app_assets.dart](file:///d:/Flutter_Projects/amomy_bus/lib/core/assets/app_assets.dart) to eliminate raw string literals.

---

## 8. Reusable UI Components

Located under `lib/core/widgets/`:

| Component | Class | Description |
| :--- | :--- | :--- |
| **Buttons** | `AppButton`, `AppIconButton` | Variants: `primary`, `secondary`, `outline`, `text`, `danger`. Supports loading indicator, icons, disabled state, full width. |
| **Inputs** | `AppTextField`, `AppPasswordField`, `AppSearchField`, `AppOtpField` | Form validation, clear button, obscure toggle, Arabic RTL support. |
| **Dropdown** | `AppDropdown<T>` | Generic dropdown with label, hints, custom display mapper, and error handling. |
| **Date Picker** | `AppDatePickerField` | Localized date selector with calendar dialog and formatted display. |
| **Bottom Sheet** | `AppBottomSheet`, `showAppBottomSheet` | Rounded top corners, grabber handle, safe area support. |
| **Dialogs** | `AppDialog`, `AppAlertDialog`, `AppConfirmDialog` | Centralized helpers: `showConfirmDialog`, `showErrorDialog`, `showSuccessDialog`. |
| **SnackBar** | `AppSnackBar` | Floating snackbars with brand styling: `showSuccess`, `showError`, `showWarning`, `showInfo`. |
| **Loading** | `AppLoading`, `AppLoadingOverlay`, `AppSkeleton` | Spinners, full-screen blockers, and Skeletonizer bone placeholders. |
| **Cards & Badges** | `AppCard`, `AppBadge`, `AppChip` | Elevated/outlined containers, pill status tags, filter chips. |
| **Empty & Error** | `AppEmptyView`, `AppErrorView` | Standardized empty and error states with retry actions. |
| **Scaffold & AppBar** | `AppAppBar`, `AppScaffold` | Branded app bar with back navigation and consistent background. |

---

## 9. Design System Preview Page

A developer-only gallery is accessible at the route `/design-system` when in debug mode:
- Showcases brand colors, typography scale, buttons, inputs, dialog triggers, snackbars, cards, badges, chips, skeletons, and icons.
- Excluded from production navigation.
