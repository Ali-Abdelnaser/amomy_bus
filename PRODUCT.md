# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Primary users are Egyptian daily commuters, students, and intercity travelers seeking dependable, dignified, and comfortable scheduled bus transportation. They need predictable departure schedules, guaranteed seat reservations, cashless payment, live vehicle tracking, and rapid QR/card boarding without boarding chaos or cash hassles.

## Product Purpose

AMOMY elevates mass transit in Egypt into a smart, predictable, and stress-free passenger service. It empowers commuters to reserve guaranteed seats ahead of time, track their bus in real time, and pay smoothly using a points-based wallet system, replacing uncertainty and crowding with structured reliability.

## Positioning

Unlike uncoordinated public transport or ride-hailing cars with surging prices, AMOMY offers premium, scheduled, reserved-seat bus commuting with live tracking and an integrated dual-source points economy (Cash Points and Subscription Points).

## Operating Context

- **Environment**: High-density Egyptian urban routes and intercity transit corridors. Commuters frequently interact with the app in transit, on sunny street corners, or walking to stations.
- **Visual & Cultural Context**: Full bilingual Arabic (RTL primary) and English (LTR secondary) support. High contrast, readable typography, and thumb-friendly controls are vital.
- **Physical Touchpoints**: Boarding validation via digital QR code scanner or NFC/smart cards, physical bus seat numbering, and local transit stations.

## Capabilities and Constraints

- **Mobile Architecture**: Cross-platform Flutter (Android & iOS) with Clean Architecture (Domain, Data, Presentation), BLoC state management, and GoRouter shell navigation.
- **Authentication**: Email/Password + OTP and native Google Sign-In with automated backend user provisioning via Supabase.
- **Economy Model**: Strict points-based ledger ("رصيد النقاط" / "Points Balance") with distinct Cash Points and Subscription Points. No raw cash/money labels or exposed ledger batch IDs in passenger UI.
- **Profile Gate**: Passengers can explore the app and manage their wallet with basic credentials, but full profile completion (phone, gender, date of birth) is mandatory prior to trip seat booking.
- **Navigation Shell**: 4 persistent tabs — Home (الرئيسية), My Trips (رحلاتي), Wallet (المحفظة), and Profile (حسابي).

## Brand Commitments

- **Primary Color**: AMOMY Brand Blue `#01589F`.
- **Accent Color**: Egyptian Warm Gold / Accent Yellow `#FFC928`.
- **Background & Surfaces**: Crisp white `#FFFFFF` dominant surfaces, soft blue/gray container accents `#F7FAFD` / `#EBF3FA`, and neutral borders `#E2E8F0`.
- **Voice & Tone**: Respectful, modern, friendly, clear, and reassuring Egyptian Arabic tone paired with crisp English.
- **Visual Personality**: Modern consumer transport app — clean, fast, and accessible; strictly avoiding admin dashboard aesthetics.

## Evidence on Hand

- Onboarding illustrations and brand identity assets located in `assets/images/`.
- Full localization strings in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.
- Production-tested Design System foundation in `lib/core/theme/` and `lib/core/widgets/`.

## Product Principles

1. **Clarity Over Clutter**: Passenger information (routes, departure times, seats, points) must be instantly readable at a glance on mobile screens.
2. **Predictable & Dependable**: Never mislead the commuter. Real-time statuses, seat reservations, and points balances are ground truth.
3. **Frictionless Commuting**: Booking, wallet recharges, and QR boarding passes must require minimum taps and function reliably under variable cellular networks.
4. **Cultural & Platform Fluency**: Deep native feel on both Android and iOS with first-class Arabic RTL typography and layout mirroring.

## Accessibility & Inclusion

- Adherence to WCAG 2.2 AA standards for minimum 4.5:1 text contrast on primary blue and neutral surfaces.
- Minimum 44x44pt interactive touch targets throughout all mobile flows.
- Respect for device safe areas, gesture bars, and dynamic OS text scaling.
