# Product

<!-- impeccable:product-schema 1 -->

## Platform

Cross-platform Flutter (Android & iOS)

## Users

Primary users are Egyptian daily commuters, university students, and workers seeking dependable, dignified, and comfortable scheduled bus transportation on the Mit Ghamr / Mit Fadala – Mansoura corridor. They need predictable departure schedules, guaranteed seat reservations, cashless payment, live vehicle tracking, and rapid QR boarding without boarding chaos or cash hassles.

## Product Purpose

AMOMY elevates mass transit in Egypt into a smart, predictable, and stress-free passenger service. It empowers commuters to reserve guaranteed seats on scheduled daily departures, track their bus in real time on Google Maps with authoritative road geometry, and pay smoothly using a points-based wallet system, replacing uncertainty and crowding with structured reliability.

## Positioning

Unlike uncoordinated public transport or ride-hailing cars with surging prices, AMOMY offers premium, scheduled, reserved-seat bus commuting with live hardware GPS tracking and an integrated points economy (Cash Points and Subscription Points).

## Operating Context

- **Environment**: 34 designated passenger stops along the Mit Ghamr / Mit Fadala to Mansoura transit corridor.
- **Service Windows & Schedule**:
  - Outbound Trips: 08:00, 09:00, 10:00, 11:00
  - Return Trips: 13:00, 14:00, 15:00, 16:00
  - Live Tracking Active Windows: 08:00–12:00 and 13:00–17:00 (outside these hours, the tracking service displays OFFLINE / Service Resumes).
- **Visual & Cultural Context**: Full bilingual Arabic (RTL primary) and English (LTR secondary) support. High contrast, readable typography, and thumb-friendly controls tailored for outdoor mobile use under bright sunlight.
- **Physical Touchpoints**: Boarding validation via digital QR code scanner or NFC/smart cards, physical 28-seat bus cabin numbering, and local transit landmarks.

## Capabilities and Business Invariants

- **Mobile Architecture**: Cross-platform Flutter (Android & iOS) with Clean Architecture (Domain, Data, Presentation), BLoC state management, and GoRouter shell navigation.
- **Authentication**: Email/Password with 6-digit verification code and native Google Sign-In with automated backend user provisioning via Supabase.
- **Economy Model**: Strict points-based ledger ("رصيد النقاط" / "Points Balance") with Cash Points (non-expiring, minimum 200 PTS top-up) and Subscription Points (monthly expiring). 1 Point = 1 EGP for top-up accounting. No raw cash/money labels in passenger UI.
- **Profile Gate**: Full profile completion (Full Name, Phone, Gender, Date of Birth) is strictly enforced prior to seat hold and booking.
- **Booking Rules**:
  - Regular booking is **today-only** (based on Africa/Cairo timezone).
  - Physical bus capacity is **28 seats** (1 front single + 12 left + 10 right + 5 rear bench).
  - Dynamic stop pricing based on boarding stop only:
    - Stops 1–5: 30 Points
    - Stops 6–17: 25 Points
    - Stops 18–34: 20 Points
  - Duplicate-trip booking protection prevents booking multiple seats on the same trip by the same passenger.
  - Cancellations and seat swaps permitted up to **30 minutes prior to trip departure**; cancellations issue an exact batch refund to the passenger's points wallet.
- **Live Bus Tracking**:
  - Telemetry source is **physical ETrack hardware IoT trackers** only (scope: Amomy 1 and Amomy 2 only).
  - Passenger and staff phones are **never** used as GPS tracking sources.
  - Rendered on **Google Maps Platform** with stored road-following Google Routes geometry.
  - Real-time stop semantics: Last Stop (yellow, actual arrival timestamp formatted as "Arrived at <time>" / "وصل الساعة <time>"), Next Stop (blue with ETA), Future Stops (white), and older passed stops (muted).
- **Navigation Shell**: 4 persistent tabs — Home (الرئيسية), My Trips (رحلاتي), Wallet (المحفظة), and Profile (حسابي).

## Brand Commitments

- **Primary Color**: AMOMY Brand Blue `#01589F`.
- **Accent Color**: Egyptian Warm Gold / Accent Yellow `#FFC928`.
- **Background & Surfaces**: Crisp white `#FFFFFF` dominant surfaces, soft blue/gray container accents `#F7FAFD` / `#EBF3FA`, and neutral borders `#E2E8F0`.
- **Voice & Tone**: Respectful, modern, friendly, clear, and reassuring Egyptian Arabic tone paired with crisp English.
- **Visual Personality**: Modern consumer transport app — clean, fast, and accessible; strictly avoiding admin dashboard aesthetics.

## Product Principles

1. **Clarity Over Clutter**: Passenger information (routes, departure times, seats, points) must be instantly readable at a glance on mobile screens.
2. **Predictable & Dependable**: Never mislead the commuter. Real-time statuses, seat reservations, and points balances are ground truth.
3. **Frictionless Commuting**: Booking, wallet recharges, and QR boarding passes must require minimum taps and function reliably under variable cellular networks.
4. **Cultural & Platform Fluency**: Deep native feel on both Android and iOS with first-class Arabic RTL typography and layout mirroring.

## Accessibility & Inclusion

- Adherence to WCAG 2.2 AA standards for minimum 4.5:1 text contrast on primary blue and neutral surfaces.
- Minimum 44x44pt interactive touch targets throughout all mobile flows.
- Respect for device safe areas, gesture bars, and dynamic OS text scaling.

---
**Last Updated**: 2026-09-14

