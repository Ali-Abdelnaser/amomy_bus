# 06 — Seven-Day Delivery Roadmap

```
Day 1: Foundation ──► Day 2: Auth & Wallet ──► Day 3: Trips & Holds ──► Day 4: Passenger Booking
                                                                                  │
Day 7: Admin & Release ◄── Day 6: GPS & Push ◄── Day 5: Staff App ◄───────────────┘
```

---

### DAY 1 — Flutter & Architectural Foundation (Current Phase)
- [x] Project initialization & platform configuration (Android & iOS).
- [x] Clean Architecture + Feature-First structure.
- [x] Core dependencies (BLoC, GetIt, Injectable, GoRouter, Dio, Skeletonizer).
- [x] Localization setup (Arabic RTL & English LTR with ARB files).
- [x] Centralized design system (AppColors, AppSpacing, AppRadius, AppTheme).
- [x] Dependency injection wiring via `build_runner`.
- [x] GoRouter setup with splash route and auth guard hooks.
- [ ] Supabase project initialization & initial database schema migrations (next sub-phase).

---

### DAY 2 — Authentication, Roles & Points Wallet
- Supabase Auth integration (Phone/Email login, OTP verification).
- User profile entity, data source, and repository.
- Role management (`PASSENGER`, `STAFF`, `ADMIN`, `SUPER_ADMIN`).
- Points Wallet feature:
  - Cash vs. Subscription points balance display.
  - Double-entry point ledger implementation.
  - Manual top-up request submission (image upload for Vodafone/Orange Cash receipts).
- Super Admin financial permissions & approval workflow.

---

### DAY 3 — Trips, Seats & Atomic Holds
- Trip templates and daily trip instance generation.
- Seat map data models & layouts.
- **Atomic 5-minute seat locking** via PostgreSQL stored procedures.
- Point reservation / hold system.
- Supabase Realtime subscriptions for live seat availability updates.
- Automatic hold expiration background job / trigger.

---

### DAY 4 — Passenger Booking Experience & 2D Seat Layout
- Polished 2D top-view bus interactive layout (custom renderer).
- Visual seat status indicators (Available, Pending, Confirmed with gender avatar, Boarded).
- Trip selection flow (Going & Return schedules).
- Checkout & point deduction confirmation.
- "My Trips" history and upcoming booking details.
- Cryptographically signed booking QR code pass generator.

---

### DAY 5 — Staff Application Foundation
- Separate Flutter project setup for Android operations staff.
- Operational dashboard & active bus trip selection.
- Realtime passenger manifest list.
- Hardware QR code scanner integration.
- Physical NFC card touch reading (random token resolution).
- Manual attendance confirmation workflow.
- Offline-resilient queue for boarding confirmations.

---

### DAY 6 — GPS Tracking & Push Notifications
- External GPS hardware provider API abstraction layer.
- Fallback mock telemetry service for staging/testing.
- Passenger live bus tracking map with restricted tracking window.
- Route stations & waypoint visualization.
- Firebase Cloud Messaging (FCM) integration:
  - Seat hold expiration reminders.
  - Top-up approval/rejection alerts.
  - Departure proximity notifications.

---

### DAY 7 — Admin Dashboard, Security & Release Readiness
- In-app Super Admin & Admin management dashboard:
  - Review and approve/reject recharge receipts with high-res viewer.
  - Manual point adjustment ledger entries.
  - User and trip management.
  - Immutable audit log browser and reports.
- Comprehensive end-to-end integration testing.
- Field readiness verification on real physical buses.
- Android APK/Bundle and iOS archive release builds.
