---
name: AMOMY Bus Design System
description: Modern, clean, and accessible transport experience for Egyptian bus commuters
colors:
  primary: "#01589F"
  primary-dark: "#01467F"
  primary-light: "#E7F2FA"
  accent: "#FFC928"
  neutral-bg: "#FFFFFF"
  surface: "#FFFFFF"
  surface-soft: "#F6F9FC"
  text-primary: "#101828"
  text-secondary: "#667085"
  text-tertiary: "#98A2B3"
  border: "#E4E7EC"
  border-subtle: "#F2F4F7"
  success: "#12B76A"
  warning: "#F79009"
  error: "#D92D20"
typography:
  display:
    fontFamily: "System"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.25
  headline:
    fontFamily: "System"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.3
  title:
    fontFamily: "System"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.4
  body:
    fontFamily: "System"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "System"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.4
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  circular: "999px"
spacing:
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "20px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.neutral-bg}"
    rounded: "{rounded.md}"
    height: "48px"
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
---

# Design System: AMOMY Bus

## Overview

**Creative North Star: "The Dependable Commute"**

AMOMY Bus is an everyday consumer transit experience tailored for Egyptian commuters. The visual tone is clear, light, dependable, and dignified. It replaces the anxiety of uncoordinated mass transport with calm, orderly visual hierarchy and confident branding.

The interface is distinctly mobile-first and transport-oriented, designed for rapid single-handed scanning while walking or standing at busy transit stops. It strictly rejects the heavy data density, gray utility styling, and cluttered metric grids of enterprise admin dashboards.

**Key Characteristics:**
- **White Dominant Canvas:** Crisp white backgrounds (`#FFFFFF`) establish breathing room and outdoor readability under bright Egyptian sunlight.
- **Authoritative Transit Blue:** Egyptian Nile navy `#01589F` anchors core branding, primary calls-to-action, and navigational indicators.
- **Purposeful Gold Accent:** Warm gold `#FFC928` is reserved for subscription points and special status moments, never for full-bleed decoration.
- **Bilingual Symmetry:** Identical visual weight and comfort across Arabic (RTL) and English (LTR).

## Colors

The color palette combines high-contrast functional neutrals with an authoritative transport blue and warm gold accents.

### Primary
- **AMOMY Blue** (`#01589F`): Primary buttons, brand headers, active bottom navigation tabs, and primary action affordances.
- **Deep Navy** (`#01467F`): Hover, active tap states, and high-emphasis icons.
- **Soft Tint Blue** (`#E7F2FA`): Light tinted background for badges, active navigation pills, and secondary containers.

### Secondary
- **Warm Gold** (`#FFC928`): Secondary accent representing subscription balances and premium tier status.

### Neutral
- **Pure Canvas** (`#FFFFFF`): Main screen background and elevated card surfaces.
- **Surface Soft** (`#F6F9FC`): Light contrast fills for secondary cards and empty states.
- **Text Primary** (`#101828`): High-contrast ink for headlines, card titles, and primary numbers.
- **Text Secondary** (`#667085`): Subtitles, helper text, and secondary labels.
- **Text Tertiary** (`#98A2B3`): Inactive placeholders and captions.
- **Border Neutral** (`#E4E7EC`): Subtle structural dividers and outline card perimeters.

### Named Rules
**The Rarity of Blue Rule.** White space dominates 80%+ of any screen. AMOMY Blue `#01589F` is focused deliberately on primary actions and state markers so the eye immediately knows where to tap.

## Typography

Typography adapts to the native platform font family while honoring Egyptian Arabic typography rhythm and English legibility.

### Hierarchy
- **Display** (Bold 700, 28–32px, height 1.25): High-impact points numbers and onboarding headlines.
- **Headline** (Bold/SemiBold 600–700, 18–24px, height 1.35): Screen titles and primary CTA headers.
- **Title** (SemiBold 600, 14–16px, height 1.4): Card section headers and list items.
- **Body** (Regular 400, 14–16px, height 1.5): Descriptive explanations, form inputs, and dialogues.
- **Label** (Medium/SemiBold 500–600, 11–12px, height 1.3): Badge tags, tab bar titles, and helper indicators.

### Named Rules
**The Dual-Language Rhythm Rule.** Arabic text naturally occupies slightly more vertical clearance than English; line heights must stay between 1.3 and 1.5 with zero vertical clipping.

## Layout

- **Viewport Spacing:** Screen horizontal margins stay locked at 16–20dp on mobile screens.
- **Component Rhythm:** 12–16dp gap between major section groups; 8dp between nested elements.
- **Touch Targets:** Minimum 44x44pt interactive targets for all mobile controls and icon buttons.
- **Safe Area Insets:** Strict observance of top status bars, display cutouts, and bottom iOS Home indicator gesture zones.

## Elevation & Depth

AMOMY employs a crisp, flat-by-default architectural aesthetic with subtle tonal layering rather than heavy, muddy drop shadows.

- **Resting Surfaces:** Elevated cards use a crisp white fill (`#FFFFFF`) with a 1px subtle neutral border (`#E4E7EC`) and an ambient, low-opacity shadow (`0 1px 2px rgba(16, 24, 40, 0.06)`).
- **Secondary Containers:** Fills use `#F6F9FC` to establish depth without needing shadow offsets.

## Shapes

- **Corner Radius:**
  - Standard cards and buttons: 12–16px radius (`AppRadius.r12`, `AppRadius.r16`).
  - Action pills and status badges: Full circular pill radius (`AppRadius.circular`).
  - Bottom sheets and modals: 20–24px rounded top corners (`AppRadius.topXl`).

## Components

### Primary Booking CTA Card
- **Background:** High-contrast AMOMY Blue `#01589F`.
- **Text:** White text with subtle gold or white action button.
- **Hierarchy:** Positioned prominently on Passenger Home as the primary action.

### Points Summary Card
- **Background:** Clean surface `#FFFFFF` with `#E4E7EC` border.
- **Labels:** Labeled "Points Balance" ("رصيد النقاط") with numeric point count and dual breakdown (Cash Points vs Subscription Points). No raw currency symbols.

### Bottom Navigation Bar
- **Style:** Clean white bar with top subtle border `#E4E7EC`.
- **Destinations:** Home, My Trips, Wallet, Profile.
- **Active State:** Tinted blue icon and bold label; inactive state text secondary `#667085`.

### Live Google Map System (Silver / Monochrome Palette)
- **Base Map Style**: Google Maps Platform Silver JSON styling (`#EBEBEB` land, `#C5CAD1` water, `#D6D6D6` roads) to create a clean, non-distracting background for route overlays.
- **Route Polyline Progression**:
  - Unreached / Upcoming road path: Official AMOMY Brand Blue `#01589F` (width: 5.5px, rounded cap).
  - Traveled / Behind the bus: Soft muted slate `#94A3B8` (width: 4.5px, opacity: 0.6).
- **Bus Marker**:
  - Footprint: Circular upright 36x36 logical px (no SVG vehicle distortion, stays north-up).
  - Normal/Live state: Solid AMOMY Blue `#01589F` with white border & centered white bus glyph.
  - Reconnecting/Stale state: Amber outer ring `#F59E0B`.
- **Stop Pins (Teardrop Geometry)**:
  - Last Arrived Stop: Warm Accent Yellow `#FFC928` with white border.
  - Immediate Next Stop: AMOMY Brand Blue `#01589F` with white inner dot.
  - Future Stops: Clean White `#FFFFFF` with slate border `#94A3B8` and dark core dot.
  - Older Passed Stops: Muted gray `#CBD5E1`.
  - Selected Stop: Elevated 32x40px pin with primary fill.

### 28-Seat Physical Bus Cabin Visualization
- **Layout**: 1 front standalone seat + 12 left seats (6 rows × 2) + 10 right seats (5 rows × 2) + 5 rear connected bench seats.
- **Seat States**:
  - Available: Light container `#E7F2FA` with `#01589F` border.
  - Selected (by user): High-contrast AMOMY Blue `#01589F` with white checkmark.
  - Held (by user): Active timer with countdown indicator.
  - Booked Male: Gender avatar (Male) with subtle neutral background.
  - Booked Female: Gender avatar (Female) with subtle neutral background.
  - Unavailable: Soft disabled gray `#E4E7EC`.

## Do's and Don'ts

### Do:
- **Do** keep "Book Your Ride" / "احجز رحلتك" the single most prominent action on the Home screen.
- **Do** use Skeletonizer for loading states instead of full-screen blocking spinners.
- **Do** keep points balances labeled as Points ("نقطة"), never as cash currency.
- **Do** format arrival copy as "Arrived at <time>" / "وصل الساعة <time>", avoiding raw backend terms like "Actual Arrival".
- **Do** respect device gesture bars and system navigation on both iOS and Android.

### Don't:
- **Don't** make the consumer app feel like an enterprise admin dashboard with heavy tabular grids.
- **Don't** add random gradients, heavy glassmorphism, or noisy decorative animations.
- **Don't** show user UUIDs, active roles, or debug information on production screens.
- **Don't** place destructive Sign Out controls on the Home screen; keep them inside Profile.

---
**Last Updated**: 2026-09-14
