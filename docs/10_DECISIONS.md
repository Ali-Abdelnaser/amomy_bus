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
- **Consequences**: Native user experience without webview redirects, bulletproof identity linking without manual merging, zero client secrets committed, and robust session persistence.


