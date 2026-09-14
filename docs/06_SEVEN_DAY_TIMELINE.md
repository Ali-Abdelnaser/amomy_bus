# 06 — Seven-Day Delivery Roadmap

```
Day 1: Foundation (COMPLETE) ──► Day 2: Auth & Wallet (COMPLETE) ──► Day 3: Trips & Holds (COMPLETE) ──► Day 4: Passenger Booking (COMPLETE)
                                                                                                                   │
Day 7: Release Readiness ◄────── Day 6: Notifications (NEXT) ◄── Day 5: GPS & Maps (COMPLETE) ◄───────────────────┘
```

---

### DAY 1 — Flutter & Architectural Foundation
- [x] Project initialization & platform configuration (Android & iOS).
- [x] Clean Architecture + Feature-First structure.
- [x] Core dependencies (BLoC, GetIt, Injectable, GoRouter, Dio, Skeletonizer).
- [x] Localization setup (Arabic RTL & English LTR with ARB files).
- [x] Centralized design system (AppColors, AppSpacing, AppRadius, AppTheme).
- [x] Dependency injection wiring via `build_runner`.
- [x] GoRouter setup with splash route and auth guard hooks.
- [x] Supabase project initialization & initial database schema migrations.

---

### DAY 2 — Authentication, Roles & Points Wallet
- [x] Supabase Auth integration (Email/Password login, 6-digit OTP verification).
- [x] Native Google Sign-In with Complete Profile Guard.
- [x] User profile entity, data source, and repository.
- [x] Points Wallet feature:
  - [x] Cash vs. Subscription points balance display.
  - [x] Double-entry point ledger implementation (`point_transactions`).
  - [x] Manual top-up request submission (Vodafone Cash, InstaPay receipts) & resubmission support.
  - [x] Minimum top-up threshold (200 PTS).

---

### DAY 3 — Trips, Seats & Atomic Holds
- [x] Daily scheduled trips (4 Outbound, 4 Return runs).
- [x] Today-only booking enforcement (`TODAY_ONLY_BOOKING`).
- [x] Authoritative 28-seat bus layout and number mapping.
- [x] **Atomic 5-minute seat locking** (`create_booking_hold` via PostgreSQL `FOR UPDATE`).
- [x] Dynamic 3-Zone Stop Fare Engine (Stops 1–5: 30 pts, Stops 6–17: 25 pts, Stops 18–34: 20 pts).
- [x] Fare points snapshotting in seat holds.
- [x] Duplicate-trip booking protection guard.

---

### DAY 4 — Passenger Booking Experience & My Trips Hub
- [x] Interactive 28-seat physical cabin map with real-time slot state rendering.
- [x] Gender avatars for booked seats (Male / Female) with zero passenger PII exposed.
- [x] Direction selector, stop selector, and time slot selector.
- [x] Booking review card with fare breakdown and balance validation.
- [x] Cryptographically signed booking QR code pass generator (`BookingQrTicketCard`).
- [x] "My Trips" hub:
  - [x] 30-minute departure cutoff for cancellations.
  - [x] Atomic batch-level points refund on cancellation (`cancel_passenger_booking`).
  - [x] Atomic seat swap on same bus (`change_booking_seat`).

---

### DAY 5 — Live GPS Tracking & Google Maps Architecture
- [x] Migration to official Google Maps Platform (`google_maps_flutter`).
- [x] Road-following polyline generation via Google Routes API Edge Function.
- [x] ETrack VIP IoT hardware telemetry ingestion Edge Function (`etrack-sync`).
- [x] Fleet scope restricted to Amomy 1 & Amomy 2 only.
- [x] 08:00–12:00 & 13:00–17:00 operational tracking windows with clean offline states.
- [x] Realtime stop arrival events and ETA calculation engine (`StopEtaEngine`).
- [x] UI Stop pin semantics (Yellow Last Stop with "Arrived at <time>", Blue Next Stop, White Future, Muted Older).
- [x] Edge-to-edge Live Map with Follow Bus camera tracking.

---

### DAY 6 — Push Notifications (NEXT DEVELOPMENT PHASE)
- [ ] Firebase Cloud Messaging (FCM) integration on Android & iOS.
- [ ] Notification token registration and storage (`user_device_tokens`).
- [ ] Transactional push triggers (booking confirmed, cancelled, seat changed, topup approved/rejected).
- [ ] Bus approach notifications when bus reaches upstream stops.
- [ ] In-app notification inbox & unread counter.

---

### DAY 7 — Release Readiness & App Store Preparation
- [x] Static code analysis (`flutter analyze`: 0 errors).
- [x] Unit, widget & regression test suites.
- [ ] Android release signing & Play Console setup.
- [ ] iOS APNs certificates, provisioning & TestFlight packaging.

---
**Last Updated**: 2026-09-14

