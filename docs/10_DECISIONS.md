# 10 — Architecture Decision Records (ADR)

## ADR 001: Clean Architecture & Feature-First Organization
- **Status**: Accepted
- **Context**: The app will grow to support complex booking, wallet, admin, and live tracking workflows. A monolithic or layer-first structure degrades maintainability over time.
- **Decision**: Adopt Clean Architecture combined with a feature-first folder hierarchy (`features/<feature_name>/{data, domain, presentation}`).
- **Consequences**: Strict decoupling of business logic from UI frameworks; straightforward unit testing and feature ownership.

---

## ADR 002: BLoC / Cubit for State Management
- **Status**: Accepted
- **Context**: State across seat holds, countdown timers, wallets, and realtime subscriptions requires predictable, testable, event-driven state streams.
- **Decision**: Standardize on `flutter_bloc` and `bloc` with `Equatable`.
- **Consequences**: Explicit state transitions, elimination of business logic inside Flutter widgets, simple debugging with global `BlocObserver`.

---

## ADR 003: GetIt + Injectable for Dependency Injection
- **Status**: Accepted
- **Context**: Manual service locator registration creates boilerplate and runtime type lookup risks.
- **Decision**: Use `injectable` code generation with `get_it`.
- **Consequences**: Compile-time safe dependency graph, clear lifecycle scopes (`@lazySingleton`, `@injectable`, `@preResolve`).

---

## ADR 004: Declarative Routing with GoRouter
- **Status**: Accepted
- **Context**: Deep linking, path parameter extraction (`/trips/:tripId`), and role-based redirects are essential for passenger and admin portals.
- **Decision**: Standardize on `go_router`.
- **Consequences**: Clean URL scheme, centralized route guards for passenger vs. admin authentication.

---

## ADR 005: Internal Points Economy & Immutable Ledger
- **Status**: Accepted
- **Context**: Direct payment per trip introduces payment gateway friction and complex reconciliation.
- **Decision**: Bookings are funded exclusively through Cash Points and Subscription Points. All point movements are stored in an append-only double-entry ledger (`point_transactions`).
- **Consequences**: Strict audit compliance, robust financial reconciliation, and zero risk of balance drift.

---

## ADR 006: Database-Enforced Atomic 5-Minute Seat Holds
- **Status**: Accepted
- **Context**: Multiple passengers may attempt to claim the same seat concurrently. Client-side locks are susceptible to race conditions.
- **Decision**: Seat locking is executed via a PostgreSQL stored procedure (`hold_seat_atomic`) utilizing row-level locks (`FOR UPDATE`).
- **Consequences**: Complete elimination of double-booking races across concurrent passenger sessions.

---

## ADR 007: 2D Vector Seat Map with Pluggable 3D Interface
- **Status**: Accepted
- **Context**: Passenger seat selection requires an intuitive top-view representation without heavy initial 3D rendering overhead.
- **Decision**: Implement a custom 2D top-view bus renderer for Phase 1 while keeping the domain interface decoupled so a 3D interactive bus view can replace it later without touching booking logic.
- **Consequences**: Lightweight initial bundle, rapid rendering on low-end devices, future-proof graphics upgrade path.

---

## ADR 008: Secure NFC Token Storage (Zero PII on Card)
- **Status**: Accepted
- **Context**: Physical NFC cards can be lost or stolen.
- **Decision**: Store only a random high-entropy token on physical NFC cards. No names, phone numbers, or balances are written to the card.
- **Consequences**: Zero PII risk if a card is lost; instant blocking/re-issuance from Super Admin portal.

---

## ADR 009: Skeletonizer for Standardized Loading UX
- **Status**: Accepted
- **Context**: Inconsistent circular progress indicators throughout the app create jarring layout shifts.
- **Decision**: Standardize on `Skeletonizer` for content shimmer loading.
- **Consequences**: Premium visual polish, predictable layout geometry, and reusable loading abstractions.

---

## ADR 010: Cached Wallet Balance vs. Point Batches Source of Truth
- **Status**: Accepted
- **Context**: Calculating a user's point balance dynamically from all historical transactions or active batches on every screen load degrades database query performance. Conversely, relying only on a mutable balance field makes it impossible to expire subscription points correctly.
- **Decision**: Maintain `point_batches` as the financial source of truth for unspent points, coupled with an immutable `point_transactions` ledger. Use `wallets.cached_available_balance` strictly as a read-optimized cache maintained atomically by database functions.
- **Consequences**: Sub-millisecond balance reads for mobile clients, zero discrepancy risk, and clean support for batch-level expiration.

---

## ADR 011: Server-Authoritative Financial RPCs with Pessimistic Row Locking
- **Status**: Accepted
- **Context**: Client applications cannot be trusted to perform financial state transitions (recharge approval, point debiting, holds). Concurrent requests can result in double-spending or duplicate approvals.
- **Decision**: All financial state transitions must execute within PostgreSQL functions using `SELECT ... FOR UPDATE` row locks. Clients are denied direct write permissions to all financial tables.
- **Consequences**: Complete protection against race conditions and client manipulation.

---

## ADR 012: Private Storage with First-Segment Path Ownership
- **Status**: Accepted
- **Context**: Payment proof screenshots (Vodafone/Orange Cash transfers) contain sensitive banking information and must not be publicly viewable or readable by other passengers.
- **Decision**: Use a private bucket (`payment-proofs`) with an RLS policy enforcing path ownership where `(storage.foldername(name))[1] = auth.uid()::text`. Only the uploader and Super Admins have read access via signed URLs.
- **Consequences**: Strong privacy compliance, defense against unauthorized browsing, and prevention of fraudulent screenshot reuse.

---

## ADR 013: Role Helper Isolation in `app_private` Schema
- **Status**: Accepted
- **Context**: Public `SECURITY DEFINER` role check functions (`has_role`, `is_admin`, `is_super_admin`) exposed via PostgREST allow arbitrary users to probe privileges or trigger unnecessary database overhead over the public REST API.
- **Decision**: Relocate role helper functions into a private `app_private` schema (`app_private.has_role`, etc.) with `USAGE` granted to `authenticated` for RLS policy evaluation, while completely excluding `app_private` from PostgREST `api.schemas`.
- **Consequences**: Zero public RPC surface for internal authorization checks, complete protection against anonymous role reconnaissance, and resolution of database security linter warnings.

---

## ADR 014: Granular Point Hold Allocations (`point_hold_allocations`)
- **Status**: Accepted
- **Context**: When a passenger reserves a seat for 5 minutes, their wallet points may span multiple point batches (e.g. 30 Subscription Points expiring in 3 days + 10 non-expiring Cash Points). A single aggregate hold field cannot accurately track which batches are locked or prevent expiring points from being prematurely cancelled while on hold.
- **Decision**: Introduce `point_hold_allocations` to track exact `(hold_id, batch_id, amount)` tuples. The hourly `expire_point_batches()` cron job protects actively held points (`expirable = GREATEST(0, remaining_amount - held_amount)`).
- **Consequences**: Deterministic multi-source consumption during checkout, full protection of active booking sessions during background expiration runs, and strict financial auditability.

---

## ADR 015: Centralized Design System, Duotone Icon Abstraction, and Two-Tier Splash
- **Status**: Accepted
- **Context**: Visual inconsistency, hardcoded magic numbers, and raw third-party icon/asset references create maintenance bottlenecks and break accessibility across English and Arabic layouts. Furthermore, native app startup requires instant display without flashing a blank canvas.
- **Decision**: 
  1. Enforce strict White + Blue `#01589F` brand identity with centralized design tokens under `lib/core/theme/`.
  2. Abstract all iconography behind `AppIcons` utilizing Phosphor Duotone icons (`package:phosphor_icons: ^3.0.1`), preventing direct third-party couplings in feature widgets.
  3. Implement a two-tier splash architecture: static native splash via `flutter_native_splash` to eliminate OS launch delay, followed by an animated Flutter `SplashPage` (2-second sequence) synchronized with app initialization.
  4. Standardize all dialogs, bottom sheets, snackbars, and form inputs as reusable core widgets with built-in validation and RTL adaptability.
- **Consequences**: High visual consistency, seamless theme and icon maintainability, and fluid user onboarding.

---

## ADR 016: Dual-Platform Supabase PKCE Auth, Native Google Sign-In & OTP Code UX
- **Status**: Accepted
- **Context**: Mobile authentication across Android and iOS requires secure token exchange, reliable session persistence, defense against account collision, and streamlined verification without forcing mobile users to open external web browser tabs for email confirmation links.
- **Decision**:
  1. **PKCE Auth Flow**: Enforce Proof Key for Code Exchange (`AuthFlowType.pkce`) in `Supabase.initialize` for mobile security.
  2. **Native Google Sign-In**: Use native Google Sign-In (`package:google_sign_in: ^7.2.0`) on Android and iOS to retrieve Google ID tokens and authenticate directly via `supabase.auth.signInWithIdToken()`.
  3. **Profile Completeness Guard**: If an OAuth user signs up without mandatory transport metadata (phone, gender, date of birth), route them immediately to `CompleteProfilePage` before allowing access to the main app.
  4. **Email OTP Code UX**: Utilize Supabase 6-digit email OTP codes (`type: signup`) via `AppOtpField` rather than link-only verification, complete with a 60-second resend throttling timer.
  5. **Cross-Platform Deep Linking**: Standardize deep-link scheme `com.aliabdelnaser.amomy://login-callback` for password recovery across Android Intent Filters and iOS URL Types.
## ADR 017: Authoritative 28-Seat Physical Bus Layout
- **Status**: Accepted
- **Context**: The physical bus fleet operates on a 28-seat configuration (1 front single + 12 left + 10 right + 5 rear bench). The legacy 14-seat layout was insufficient for production capacity.
- **Decision**: Standardize `buses.capacity = 28`, seed `bus_seats` numbers '1' through '28', and implement custom 2D cabin rendering with exact physical slot coordinates and touch boundaries.
- **Consequences**: Accurate physical bus parity, robust seat number mapping, and high-precision visual selection.

---

## ADR 018: Dynamic 3-Zone Stop Pricing & Frozen Fare Snapshots
- **Status**: Accepted
- **Context**: Uniform fixed pricing per trip fails to accommodate short-distance vs. long-distance passengers across the 34-stop corridor.
- **Decision**: Implement a 3-tier fare model determined strictly by the boarding stop:
  - Zone 30 (Stops 1–5): 30 Points
  - Zone 25 (Stops 6–17): 25 Points
  - Zone 20 (Stops 18–34): 20 Points
  Freeze `fare_points_snapshot` at the moment of seat hold creation in `seat_holds` and carry it into `bookings.fare_points` to protect confirmed bookings against future fare modifications.
- **Consequences**: Fair, zone-based pricing and guaranteed financial immutability for passenger bookings.

---

## ADR 019: Google Maps Platform & Road-Following Google Routes Geometry
- **Status**: Accepted
- **Context**: Generic OSM/raster map tiles and straight-line waypoint connections exhibited visual stutter, white flashes, and unrealistic bus paths across water and fields.
- **Decision**: Migrate entirely to official Google Maps Platform (`google_maps_flutter`), generate road-following high-precision polylines via Google Routes API Edge Function, and apply custom Silver monochrome map styling with upright circular bus markers and teardrop stop pins.
- **Consequences**: Fluid 60fps vector map rendering, exact road alignment, zero tile pop-in, and premium brand aesthetics.

---

## ADR 020: Hardware-Only ETrack GPS Telemetry & Tracking Windows
- **Status**: Accepted
- **Context**: Mobile client GPS relies on driver/staff phones which are prone to battery drain, app backgrounding, and location spoofing.
- **Decision**: Ingest vehicle telemetry exclusively from dedicated physical ETrack hardware IoT trackers installed on Amomy 1 and Amomy 2 via an automated Edge Function (`etrack-sync`). Limit passenger live tracking visibility to active operational windows (08:00–12:00 and 13:00–17:00).
- **Consequences**: 100% backend-authoritative vehicle telemetry, zero battery drain on passenger/staff devices, and clear offline states outside service runs.

---

## ADR 021: Today-Only Booking & 30-Minute Cancellation Cutoff with Exact Batch Refund
- **Status**: Accepted
- **Context**: Multi-day pre-booking introduces complex scheduling volatility, while late cancellations create empty seats that cannot be resold.
- **Decision**: Enforce today-only booking (Africa/Cairo timezone) across daily scheduled departures. Allow cancellations and seat swaps up to 30 minutes before departure. Upon cancellation, restore points to the exact originating point batches (`point_batches.remaining_amount`) using `point_transactions` audit records.
- **Consequences**: Predictable daily seat utilization, passenger flexibility, and zero financial leakage.

---

## ADR 022: Elimination of Legacy 50-Point Fallbacks
- **Status**: Accepted
- **Context**: Early prototyping contained a hardcoded 50-point fallback in trip tables and booking procedures.
- **Decision**: Eliminate all 50-point fallbacks in active migrations and RPCs (`get_available_trips`, `get_today_available_trips`, `create_booking_hold`), ensuring dynamic stop 1 zone fare (30 pts outbound / 20 pts return) serves as the canonical baseline.
- **Consequences**: 100% price consistency between schedule discovery, seat selection, and wallet debiting.

---
**Last Updated**: 2026-09-14



