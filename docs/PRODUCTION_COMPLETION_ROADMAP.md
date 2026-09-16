# AMOMY Bus — Master Production Completion Roadmap

This document is the single authoritative roadmap capturing all remaining production completion work for the **AMOMY Bus** transportation platform across Passenger Apps (Android & iOS), Driver/Staff App (Android), Administrative Backoffice, and the shared Supabase backend.

---

## 1. System Overview & Core Tenets

AMOMY Bus is an automated, scheduled intercity bus transportation service operating between **Mit Fadala** and the **University District** (Al-Mansoura).

### Components
1. **Passenger App**: Flutter (iOS & Android) — scheduled trip discovery, seat selection, digital boarding passes (QR/NFC), wallet/points management, and authoritative live tracking.
2. **Driver / Staff App**: Flutter (Android) — atomic trip claiming, passenger manifests, boarding check-in scanning, and route/stop status updates.
3. **Admin / Fleet Backoffice**: Supabase Dashboards & administrative workflows — scheduling, vehicle inventory, manual credit/debit overrides, driver reassignments, and financial reconciliation.
4. **Physical GPS Hardware**: Dual Teltonika/ETrack cellular IoT units hard-wired into physical buses (`Bus 1` and `Bus 2`) transmitting telemetry to Supabase.

### 🛡️ The Passenger Privacy Mandate
Under no circumstances may the passenger client expose, render, or leak internal fleet identities. Passengers **MUST NEVER SEE**:
- Internal bus IDs (UUIDs or integer keys)
- Physical bus names (`Bus 1`, `Bus 2`, etc.)
- Physical license plate numbers
- Driver personal identities / phone numbers
- Internal GPS device IMEI / telemetry hardware IDs

All passenger-facing experiences are strictly **TRIP-BOUND**, not bus-bound.

---

## 2. Master Phase Status & Dependency Table

| Phase | Title | Status | Depends On | Primary Platform |
|---|---|:---:|---|---|
| **Phase 1** | Passenger UI Polish & Design Consistency | `COMPLETE` | — | Passenger App |
| **Phase 2** | Passenger Realtime Architecture & Seat Invalidation | `COMPLETE` | — | Flutter + Supabase |
| **Phase 3** | Notifications Client Architecture & Deduplication | `COMPLETE*` | — | Flutter App (*Local/Client) |
| **Phase 4** | Extra Seat Fare Snapshotting | `COMPLETE` | — | Supabase Backend |
| **Phase 5** | Wallet & Recent Transactions Human Semantics | `PENDING` | Phase 2 | Flutter + Supabase RPC |
| **Phase 6** | Production Booking Availability, Stop Cutoffs & Time Rules | `PENDING` | Phase 4 | Supabase RPC + Flutter |
| **Phase 7** | Driver Trip Claim, Atomic Assignment & Roster | `PENDING` | Phase 6 | Driver App + Supabase |
| **Phase 8** | Trip-Bound GPS, Route Direction & Live Tracking UX | `PENDING` | Phase 7 | Flutter + Telemetry Engine |
| **Phase 9** | Home Page Logic & State-Aware Upcoming Trip Redesign | `PENDING` | Phase 6, 7, 8 | Passenger App |
| **Phase 10** | Digital Boarding Pass Redesign (Anti-Paper Pattern) | `PENDING` | Phase 6 | Passenger App |
| **Phase 11** | iOS Cold-Start Splash Frame Seamless Transition | `PENDING` | Phase 1 | iOS Runner / Flutter |
| **Phase 12** | Complete Bilingual Localization & 12-Hour Time Format Pass | `PENDING` | Phase 5, 8, 9, 10 | Flutter (AR/EN) |
| **Phase 13** | Restrained Micro-Interactions, Motions & Polish | `PENDING` | Phase 9, 10, 11 | Flutter UI |
| **Phase 14** | Diagnostic Stripping, Logging Hardening & Final E2E Regression | `PENDING` | All Phases | Entire Platform |
| **GATE** | Physical iPhone Remote APNs/FCM Verification | `PENDING` | Phase 3, 14 | Apple APNs + TestFlight |

---

## 3. Completed Phases (Reference & Baseline)

### [x] Phase 1 — Passenger UI Polish
- **Status**: `COMPLETE`
- **Accomplished**:
  - Standardized all modal surfaces to unified AMOMY bottom sheets.
  - Configured `useSafeArea: false` on bottom sheets with edge-to-edge styling.
  - Redesigned Booking departure time card.
  - Clarified Mit Fadala first-stop location semantics.
  - Eliminated seat selection bus grid clipping issues.
  - Engineered reusable AMOMY dialog system featuring dimmed and Gaussian-blurred backdrops.
  - Redesigned Trip Cancellation confirmation dialog with clear consequence warnings.

### [x] Phase 2 — Passenger Realtime Architecture
- **Status**: `COMPLETE`
- **Accomplished**:
  - Implemented real-time synchronization for My Trips, Wallet Balance, Recent Transactions, and Notification Inbox.
  - Home unread badge counter wired to real-time notification stream.
  - Implemented privacy-safe `trip_seat_state` invalidation architecture:
    ```
    bookings / seat_holds change
               ↓
        backend trigger
               ↓
    trip_seat_state.revision++
               ↓
     Flutter realtime signal
               ↓
    get_trip_seat_map(trip_id)
               ↓
    Safe seat snapshot delivered to client
    ```
  - Direct passenger reads on raw `seat_holds` or other users' booking records are strictly prohibited; seat map data is aggregated server-side.

### [x] Phase 3 — Notifications Client UX & Deduplication
- **Status**: `COMPLETE` *(Local & Client Logic)*
- **Accomplished**:
  - Foreground local notifications presentation pipeline.
  - Booking confirmed, departure reminder, and cancellation/refund notification handlers.
  - In-memory bounded FIFO deduplication cache (`_processedMessageKeys`) preventing duplicate UI banners between realtime DB events and FCM payloads.
  - Deep-link tap router directing booking notifications to `/trips` rather than invalid standalone paths.
  - *Note*: Physical iPhone remote FCM/APNs verification is tracked as the final quality gate before release.

### [x] Phase 4 — Extra Seat Fare Snapshotting
- **Status**: `COMPLETE`
- **Accomplished**:
  - Server-authoritative booking RPCs updated to store and preserve the original confirmed booking fare snapshot.
  - Extra seat purchases strictly reuse the primary booking's price per seat (20 pts, 25 pts, or 30 pts) rather than querying floating tariff tables.
  - Financial records remain immutable and deterministic.

---

## 4. Remaining Implementation Phases

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           REMAINING ROADMAP                             │
├───────────────┬─────────────────────────────────────────────────────────┤
│ Phase 5       │ Wallet & Recent Transactions Human Semantics            │
│ Phase 6       │ Production Booking Availability, Stop Cutoffs & Times   │
│ Phase 7       │ Driver Trip Claim, Atomic Bus Assignment & Roster       │
│ Phase 8       │ Trip-Bound GPS, Route Reversal & Stop Tracking UX       │
│ Phase 9       │ Home Page Hierarchy & State-Aware Upcoming Trip         │
│ Phase 10      │ Digital Boarding Pass Redesign (Anti-Paper Pattern)     │
│ Phase 11      │ iOS Cold-Start Splash Frame Seamless Transition         │
│ Phase 12      │ Complete Bilingual Localization & 12-Hour Time Pass     │
│ Phase 13      │ Restrained Micro-Interactions & Performance Polish      │
│ Phase 14      │ Production Diagnostics Removal & Final Regression Gate  │
└───────────────┴─────────────────────────────────────────────────────────┘
```

---

### Phase 5 — Wallet & Recent Transactions Human Semantics

#### Goal
Transform the Wallet and Recent Transactions screen from raw database logs into clear, passenger-friendly financial receipts with descriptive metadata, while keeping the existing Supabase Realtime subscription infrastructure.

#### Current Problem
Transaction labels are generic or ambiguous (e.g., displaying `Trip` without direction, departure time, or seat count). Passengers cannot tell which specific trip was deducted, whether an entry represents an extra seat, or if a refund was credited.

#### Product Rules
- **Normal Booking Debit**: Must display Trip Direction, Service Date, Departure Time (12-hour format), and points deducted.
  - *Example*: `Outbound • 16 Sep • 8:00 AM (-25 pts)`
- **Extra Seat Debit**: Must explicitly display `Extra Seat` label with Direction, Date, Departure Time, and points deducted.
  - *Example*: `Extra Seat • Outbound • 16 Sep • 8:00 AM (-25 pts)`
- **Cancellation Refund**: Must explicitly display `Refund` with original trip reference, date/time, and positive point credit.
  - *Example*: `Refund • 16 Sep • 8:00 AM (+25 pts)`
- **Points Top-up**: Must display `Points Top-up` with payment channel if applicable.
  - *Example*: `Points Top-up • Vodafone Cash (+300 pts)`
- **Admin / Manual Credit**: Must display `Extra Points` or `Promotional Credit` (never internal terms like `manual_adjustment_rpc` or `ledger_override`).
- **Visual Styling**:
  - Credits (+Points): Emerald green bold text with positive prefix (`+25 pts`).
  - Debits (-Points): Slate/Charcoal standard text with negative prefix (`-25 pts`).
  - Order: Strictly newest-first (`created_at DESC`).
  - Realtime: Automatically appends new transactions via existing `WalletCubit` streams without pull-to-refresh.

#### Backend Work
- Audit `get_wallet_transactions` RPC to ensure `metadata` or `description` payload returns:
  `trip_direction`, `service_date`, `departure_time`, `is_extra_seat`, `refund_reason`, and `source_type`.
- Ensure raw internal DB column names are translated or encapsulated into structured JSON.

#### Flutter / Client Work
- Update `PointTransactionModel` and domain entity to parse the enriched metadata.
- Redesign `TransactionListItem` widget to render multi-part metadata pills.
- Add Arabic/English localized strings for transaction labels.

#### Acceptance Criteria
- [ ] Every trip debit shows direction, date, and departure time.
- [ ] Extra seats are clearly tagged as `Extra Seat`.
- [ ] Refunds display `+` points in green with trip context.
- [ ] No raw accounting jargon is exposed to the passenger.
- [ ] Real-time updates reflect instantaneously when balance changes.

---

### Phase 6 — Production Booking Availability, Stop Cutoffs & Time Rules

#### Goal
Enforce realistic operating schedule availability, morning-visible return trips, per-trip progressive cutoffs based on bus movement, and automated daily booking window rollover.

#### Current Problem
Trips may cut off abruptly at the service start time, return trips may not be accessible in the morning, and the "Book a Ride" button does not dynamically disable when daily operating slots have expired.

#### Product Rules
1. **Daily Operating Schedule**:
   - **Outbound Trips** (Mit Fadala → University): `8:00 AM`, `9:00 AM`, `10:00 AM`, `11:00 AM`
   - **Return Trips** (University → Mit Fadala): `1:00 PM`, `2:00 PM`, `3:00 PM`, `4:00 PM`
   - **Display Format**: Strictly 12-hour format with localized AM/PM (`8:00 AM`, `1:00 PM` / `٨:٠٠ ص`, `١:٠٠ م`). Never display 24-hour times (`13:00`, `14:00`) to passengers.
2. **Booking Window Availability**:
   - Booking opens daily at **12:00 AM (00:00 Africa/Cairo time)** for the current day.
   - **ALL Return Trips** (`1:00 PM` – `4:00 PM`) **MUST BE VISIBLE AND BOOKABLE** starting from 12:00 AM. A passenger booking an 8:00 AM morning trip must be able to book their 2:00 PM return trip in the same session.
3. **Per-Stop Dynamic Cutoff**:
   - Trips do NOT simply vanish at their departure time.
   - Booking closes for a specific passenger when the bus has **passed that passenger's selected boarding stop**.
   - *Example*: Passenger boards at Stop 4. The bus left Stop 1 at 8:00 AM, but has not reached Stop 4. The passenger can still book until the bus departs Stop 4.
   - Requires authoritative server progression logic.
4. **Home "Book a Ride" Button**:
   - Enabled as long as **at least one** upcoming trip for today remains bookable for at least one stop.
   - Disabled when all trips for today have departed their final boarding stops.
   - Automatically re-enables at **12:00 AM** next day for the new day's schedule.
5. **Testing Account Exception (Passenger One)**:
   - The verified test account (`Passenger One`) must bypass daily time windows and progressive cutoffs to allow full E2E testing at any hour.
   - **SECURITY RULE**: Bypass check MUST NOT evaluate display name (`user_metadata -> name == 'Passenger One'`). It must be governed by an authoritative database flag (e.g., `profiles.is_test_account = true` or user UUID whitelist).

#### Backend Work
- Update trip availability RPCs (`get_available_trips_for_date`) to evaluate stop progression state against current Egypt time.
- Implement server-side check for `is_test_account` bypass.

#### Flutter / Client Work
- Update `BookingCubit` and Home screen button state evaluation to respect remaining bookable trips.
- Format all booking UI timestamps using `DateFormat.jm()` with active locale.

#### Acceptance Criteria
- [ ] Return trips are 100% visible and bookable at 8:00 AM.
- [ ] No 24-hour military times (`13:00`, `14:00`) appear in passenger UI.
- [ ] Booking remains open for downstream stops until the bus clears them.
- [ ] "Book a Ride" CTA disables cleanly when all daily trips conclude.
- [ ] Test account bypass functions reliably without hardcoded string matching.

---

### Phase 7 — Driver Trip Claim, Atomic Bus Assignment & Roster

#### Goal
Allow drivers to claim scheduled trips on demand before departure, atomically binding the physical bus to that trip instance and provisioning operational passenger manifests.

#### Current Problem
AMOMY owns two physical buses (`Bus 1` and `Bus 2`). Currently, the system lacks an atomic claim mechanism, meaning physical vehicles cannot be deterministically mapped to scheduled runs, leading to GPS collision and uncoordinated driver operations.

#### Product Rules
1. **Fleet Agnostic Booking**:
   - Passenger bookings belong to the **TRIP SCHEDULE** (e.g., `16 Sep • 8:00 AM Outbound`), NEVER to `Bus 1` or `Bus 2`.
   - Passengers book seats on an abstract trip template that has identical layout across both vehicles.
2. **Driver Claim Workflow**:
   - Before departure (e.g., 20 minutes prior), an authenticated driver selects the scheduled trip in the Driver App and taps **Start / Claim Trip**.
   - The driver selects their current physical vehicle (`Bus 1` or `Bus 2`).
   - The backend atomically creates an active assignment binding `(trip_instance_id, driver_id, bus_id)`.
3. **Atomic Mutual Exclusion & Race Prevention**:
   - Only ONE driver and ONE bus may be assigned to a specific trip instance.
   - If Driver A claims the 8:00 AM trip, Driver B attempting to claim the same trip must receive an immediate rejection (`Trip already claimed`).
   - A physical bus cannot be assigned to two overlapping active trips.
4. **Driver Manifest & Check-In**:
   - Upon successful claim, the Driver App receives the passenger manifest:
     - Total passenger count per stop.
     - Ordered list of passengers, seat numbers, phone numbers (staff use only), and check-in status (`pending`, `boarded`, `no-show`).
   - QR scanner in Driver App validates and checks in boarding passengers for that trip only.
5. **Administrative Override**:
   - Admin/Super Admin dashboard retains the authority to reassign, release, or swap drivers/buses without invalidating passenger reservations.
6. **Passenger Privacy**:
   - Passenger apps NEVER display driver name or physical bus number.

#### Backend Work
- Create table `trip_assignments` with unique constraints on `(trip_id, service_date)` and `(bus_id, is_active)`.
- Write atomic Postgres function `claim_trip_assignment(p_trip_id, p_bus_id, p_driver_id)`.
- Implement `get_driver_manifest(p_assignment_id)` returning boarding details.

#### Flutter / Client Work
- Build Driver App Trip Selection and Vehicle Binding Screen.
- Build Driver App Live Manifest and Boarding Verification UI.

#### Acceptance Criteria
- [ ] Concurrent claim attempts result in exactly one winner; the second receives an error dialog.
- [ ] Bus 1 cannot be bound to two concurrent active trips.
- [ ] Passenger bookings stay intact regardless of which bus/driver operates the trip.
- [ ] Passenger UI reveals zero internal driver or bus information.

---

### Phase 8 — Trip-Bound GPS, Route Direction & Live Tracking UX

#### Goal
Eliminate GPS jumping between buses, reverse route geometry for return trips, and provide an accurate, direction-aware live tracking experience with stop progression colors and arrival ETAs.

#### Current Problem
Both physical buses stream GPS coordinates simultaneously. Without trip-to-bus binding, tracking can pick up telemetry from the wrong bus or alternate between buses, causing the bus icon to jump erratically across the map. Return trips also display outbound stop orders.

#### Product Rules
1. **Trip-Bound Telemetry Ingestion**:
   - Both physical buses continue streaming GPS data to `bus_live_locations`.
   - When a passenger tracks a trip, the app queries the active `trip_assignment` for that trip:
     $$\text{Trip} \longrightarrow \text{Assigned Bus ID} \longrightarrow \text{Live Telemetry for that Bus ID only}$$
   - The client tracks ONLY the assigned bus. If no bus is assigned, display:
     `Bus assignment pending — Tracking will activate before departure.`
2. **Direction-Aware Stop Progression**:
   - **Outbound Trips**: Mit Fadala $\longrightarrow$ University District. Stops are ordered 1 to 34.
   - **Return Trips**: University District $\longrightarrow$ Mit Fadala. Stops MUST BE REVERSED (34 to 1). Progression engine must follow return geometry.
3. **Stop Visual States on Passenger Live Map**:
   - **Passed Stops**: **Yellow** (`#F1C40F` / AMOMY Yellow). Once passed, a stop NEVER reverts to future.
   - **Current / Next Active Stop**: **Blue** (`#2E86DE` / AMOMY Primary Blue).
   - **Future Upcoming Stops**: **White / Slate** (`#FFFFFF` with subtle stroke).
4. **Authoritative Last / Next Stop Cards**:
   - **Last Stop Card**: Shows stop name and **actual passed time** recorded by the backend.
     - *Example*: `Last Stop: Mit El-Amel • Passed 8:24 AM`
   - **Next Stop Card**: Shows stop name and **predicted arrival time (ETA)**.
     - *Example*: `Next Stop: Sangid • Expected 8:31 AM`
5. **Authoritative ETA Computation**:
   - ETAs must NOT be calculated as naive client-side Euclidean distance divided by instant speed.
   - ETAs must use the existing server-authoritative progression engine (`StopEtaEngine`), combining route polyline distance, scheduled window, and rolling speed averages.
6. **Live Tracking Operating Windows (Africa/Cairo Time)**:
   - **Window 1**: `8:00 AM – 12:00 PM`
   - **Window 2**: `1:00 PM – 5:00 PM`
   - Outside these windows, the map card transitions to an offline placeholder:
     - `12:00 PM – 1:00 PM`: Displays `Tracking resumes at 1:00 PM`
     - `After 5:00 PM`: Displays `Tracking resumes tomorrow at 8:00 AM`
     - "View Live Map" button is disabled outside service windows.

#### Backend Work
- Update `get_live_bus_tracking_summary` RPC to accept `p_trip_id` and resolve telemetry strictly from the bound bus.
- Support return route geometry retrieval from `route_geometries`.

#### Flutter / Client Work
- Update `LiveBusMapWidget` marker and polyline rendering to apply Yellow/Blue/White stop color rules.
- Update `HomeLiveTrackingCard` to display Last Stop and Next Stop ETA cards.
- Wire operating window timer to transition between active map and offline banner.

#### Acceptance Criteria
- [ ] No GPS jumping occurs when both buses are simultaneously driving.
- [ ] Return trips strictly start from University and end at Mit Fadala in reverse order.
- [ ] Passed stops turn yellow and remain yellow.
- [ ] Next stop is blue; future stops are white.
- [ ] Last Stop card displays actual recorded time, not ETA.
- [ ] Outside 8–12 and 1–5 Cairo time, tracking displays clean offline status.

---

### Phase 9 — Home Page Hierarchy & State-Aware Upcoming Trip Redesign

#### Goal
Reorganize the passenger home screen around a smart, state-aware "Upcoming Trip" card that accurately reflects the passenger's nearest active reservation and adapts its actions throughout the trip lifecycle.

#### Current Problem
The existing Upcoming Trip card is static, does not prioritize the nearest confirmed reservation, and shows fixed action buttons that do not adapt to pre-trip, boarding, or in-transit states.

#### Product Rules
1. **Nearest Active Booking Resolution**:
   - If a passenger has multiple bookings (e.g., today at 10:00 AM and 2:00 PM), the card MUST display the **earliest upcoming confirmed booking** that has not reached `completed` or `cancelled` status.
   - When the 10:00 AM trip completes, the card automatically transitions to the 2:00 PM trip.
2. **State-Adaptive Presentation**:
   - **Scheduled (Pre-service)**:
     - Shows departure time, boarding stop, seat number, and status badge `Confirmed`.
     - Actions: `View Details`, `Change Seat`, `Cancel Trip`.
   - **Approaching (15 mins before or bus within 2 stops)**:
     - Status badge turns Amber `Bus Approaching`.
     - Prominent CTA: `Boarding Pass (QR)`.
   - **In Transit (Live Trip)**:
     - Status badge turns Blue `On Board / Live`.
     - Displays live next stop and ETA.
     - Actions: `View Live Map`, `Show Boarding QR`.
   - **Completed**:
     - Status badge updates to `Arrived`, card rolls over to subsequent booking or empty state.
3. **Home Quick Summary Strip**:
   - Below the Upcoming Trip card, render clear, actionable metric cards:
     - **Wallet Balance**: Points count with one-tap `Add Points`.
     - **Today's Trips**: Total confirmed seats for today.
     - **Notifications**: Unread notification pill.
   - Quick action shortcuts: `Book a Ride`, `My Trips`, `Wallet`.

#### Flutter / Client Work
- Refactor `PassengerHomePage` and `UpcomingTripCard` widget tree.
- Implement selector logic in `BookingCubit` / `TripsCubit` to resolve the immediate active booking.
- Ensure smooth animated cross-fade when active booking status transitions.

#### Acceptance Criteria
- [ ] Passenger with multiple bookings always sees the soonest trip.
- [ ] Cancel/Change Seat buttons vanish once the trip enters transit.
- [ ] QR code access is elevated when the bus approaches.
- [ ] Card seamlessly rolls over to next booking upon trip completion.

---

### Phase 10 — Digital Boarding Pass Redesign (Anti-Paper Pattern)

#### Goal
Eliminate outdated paper-ticket metaphors (e.g., ripped edges, perforation marks, "dispenser" graphics) and replace them with a sleek, modern digital boarding pass.

#### Current Problem
The booking confirmed and ticket detail screens use an artificial paper-ticket aesthetic with oversized QR codes and empty space, and have occasionally displayed internal vehicle labels like `Bus 1`.

#### Product Rules
1. **Visual Language**:
   - Modern, high-contrast digital card surface with soft AMOMY gradient accents.
   - Absolutely NO fake perforated paper edges, barcode lines, or "digital dispenser" branding.
2. **Card Hierarchy**:
   - **Header**: AMOMY Bus Logo + Status Badge (`Confirmed & Active`).
   - **Trip Route Banner**: Origin Stop $\longrightarrow$ Destination Stop with Direction Tag.
   - **Key Metadata Grid**:
     - Date (Localized)
     - Departure Time (12-hour format)
     - Seat Number (Prominent Pill)
     - Fare Paid (`25 Points`)
   - **Digital Verification Module**:
     - Clean, scannable QR Code centered with high contrast.
     - Subtitle: `Scan QR code or tap NFC card at bus entrance`.
     - Security watermark: Pulsing subtle timestamp or animated micro-badge to deter static screenshot sharing.
3. **Zero Fleet Leaks**:
   - Under no circumstances will the boarding pass render physical bus numbers or driver details.

#### Flutter / Client Work
- Redesign `BookingConfirmedPage` and `TicketDetailPage`.
- Remove legacy dispenser custom painters / clipped path assets.
- Integrate animated boarding pass header and localized Arabic/English typography.

#### Acceptance Criteria
- [ ] All fake paper ticket visuals, perforations, and dispenser text are completely removed.
- [ ] QR code renders with crisp margins and reliable scanner readability.
- [ ] Seat number, time, and route are visible at a glance.
- [ ] Zero internal bus names or identifiers appear anywhere on the pass.

---

### Phase 11 — iOS Cold-Start Splash Frame Seamless Transition

#### Goal
Eliminate visual glitches during iOS cold launch, ensuring a seamless visual transition from native launch screen to Flutter rendering.

#### Current Problem
On physical iOS devices and simulator, cold booting produces a fragmented visual jump:
$$\text{Black Window} \longrightarrow \text{Dark/Gray Native Splash} \longrightarrow \text{White Flutter Splash} \longrightarrow \text{Home UI}$$
This looks unpolished and harms perceived performance.

#### Technical Audit & Fix Areas
1. **`LaunchScreen.storyboard`**:
   - Verify view controller background color matches the primary AMOMY branded background (`#FFFFFF` in light mode or unified navy in dark mode).
   - Ensure AMOMY logo asset uses identical aspect ratio and sizing constraints as the Flutter splash widget.
2. **`Assets.xcassets / LaunchImage`**:
   - Ensure native launch image catalog contains crisp vector/PDF or 1x/2x/3x PNG assets with universal sizing.
3. **Flutter First Frame Coordination**:
   - Ensure `WidgetsBinding.instance.deferFirstFrame()` and `allowFirstFrame()` are invoked precisely when the root widget tree has initialized its core theme.
   - Avoid intermediate blank/black Scaffold builds before DI containers resolve.

#### Acceptance Criteria
- [ ] Zero black frames occur during iOS cold launch.
- [ ] Native splash logo perfectly aligns with Flutter entry screen without resizing jumps.
- [ ] Seamless transition directly from launch screen to Auth or Home.

---

### Phase 12 — Complete Bilingual Localization & 12-Hour Time Pass

#### Goal
Audit and standardize 100% of user-facing copy across Arabic (RTL) and English (LTR), eliminating hardcoded strings, broken text alignment, and 24-hour military timestamps.

#### Audit Areas
1. **Time Formatting**:
   - Every single displayed time must strictly use 12-hour format with localized AM/PM designations:
     - English: `8:00 AM`, `1:00 PM`
     - Arabic: `٨:٠٠ ص`, `١:٠٠ م`
   - Never show `13:00`, `14:00`, `15:00`, etc.
2. **ARB Files (`app_en.arb` & `app_ar.arb`)**:
   - Audit all keys across booking, tracking, wallet, notifications, profile, and dialogs.
   - Ensure proper Arabic grammatical plurals for points (`نقطة`, `نقاط`).
   - Standardize transaction labels and tracking statuses (`Approaching` / `يقترب الآن`, `At Stop` / `في المحطة`).
3. **Layout & RTL Safety**:
   - Verify start/end directional padding (avoid hardcoded `left`/`right`).
   - Check icon mirroring (arrows, chevrons must flip in RTL; bus icons must face travel direction).

#### Acceptance Criteria
- [ ] Zero untranslated or missing ARB strings in `flutter gen-l10n`.
- [ ] No hardcoded English or Arabic strings in Dart presentation widgets.
- [ ] All timestamps display exclusively in 12-hour format with localized markers.
- [ ] RTL layouts render symmetrically without text clipping.

---

### Phase 13 — Restrained Micro-Interactions, Motions & Polish

#### Goal
Elevate the application's perceived quality through purposeful, restrained micro-interactions and smooth state transitions while maintaining strict 60/120 FPS performance.

#### Polish Candidates
1. **Seat Selection**: Gentle haptic tap + subtle bounce scale when toggling seats.
2. **Live Map Tracking**: Smooth camera panning and animated marker interpolation between GPS updates (no teleporting).
3. **Bottom Sheets**: Fluid spring animation when opening and dragging to dismiss.
4. **Notification Badge**: Subtle pulse/pop animation when a new notification arrives.
5. **Loading Skeletons**: Unified shimmer effects on trip cards and wallet transactions during initial load.

#### Guidelines
- Never add motion for the sake of motion; keep durations under 250ms.
- Respect `MediaQuery.disableAnimationsOf(context)` for accessibility.

#### Acceptance Criteria
- [ ] Interactions feel tactile, fluid, and premium.
- [ ] Frame rate remains rock-solid on budget Android and older iOS hardware.

---

### Phase 14 — Diagnostic Stripping, Logging Hardening & Final Regression

#### Goal
Purge all temporary diagnostic logs, ensure zero sensitive data leakage in production builds, and run an exhaustive automated and manual regression suite.

#### Tasks
1. **Diagnostic Cleanup**:
   - Audit and remove or gate behind `kDebugMode`:
     - `[IOS_PUSH_DIAG]`
     - `[REALTIME_DIAG]`
     - `[NOTIF_PRESENT_DIAG]`
     - `[IOS_LOCAL_NOTIF_DIAG]`
     - `[FULL_MAP_DIAG]`
2. **Zero Log Leakage Audit**:
   - Guarantee that no production log statement ever prints:
     - User UUIDs
     - Phone numbers
     - Auth tokens / JWTs
     - Push notification tokens (APNs / FCM)
     - Raw transaction financial payloads
3. **Developer Controls Removal**:
   - Remove or secure all QA simulation shortcuts, debug floating action buttons, and mock notification triggers before creating App Store / Play Store release binaries.
4. **Master Regression Sweep**:
   - Execute full test passes across Auth, Profile, Booking, Seat Hold, Extra Seats, Cancellation, Wallet, Realtime, Tracking, Push Notifications, and Localization on physical devices.

#### Acceptance Criteria
- [ ] Production console logs emit zero diagnostic noise or PII.
- [ ] All automated tests pass cleanly with zero warnings or errors.
- [ ] Master regression checklist signed off.

---

## 5. Final External Test Gate — Physical iPhone FCM/APNs Verification

```
[ PENDING PHYSICAL TEST GATE ]
Must be verified on a real iPhone running a signed TestFlight Release build.
```

While local foreground notifications and simulator behavior are fully verified, the real remote push notification pipeline requires validation against physical hardware and Apple APNs production gateways.

### Required Physical Test Cases
1. **Cold Start & Permission Request**:
   - Install fresh TestFlight build on physical iPhone.
   - Verify AMOMY pre-permission bottom sheet displays.
   - Accept permission $\longrightarrow$ verify iOS system prompt displays $\longrightarrow$ tap Allow.
2. **APNs & FCM Registration**:
   - Verify `getAPNSToken()` resolves a valid 32-byte production APNs token.
   - Verify `getToken()` receives a valid FCM registration token.
   - Verify token is synced to Supabase `user_device_tokens` with `platform: 'ios'`.
3. **Remote Push in Foreground**:
   - Send test push from Supabase/FCM.
   - Verify local banner displays without duplicate audio/visual alerts.
4. **Remote Push in Background**:
   - Put app in background.
   - Send push $\longrightarrow$ verify native iOS lock screen / Notification Center banner appears with AMOMY branding and sound.
5. **Remote Push in Terminated State**:
   - Force quit AMOMY app.
   - Send push $\longrightarrow$ verify native banner appears on device.
6. **Tap Routing & Cold Launch from Push**:
   - Tap remote push notification from locked/terminated screen.
   - App must boot directly to the target destination (e.g., `/trips` or `/notifications`) without routing crashes or Page Not Found errors.
7. **APNs Credential Verification**:
   - Confirm that the previous `Invalid APNs credential` error from Firebase is permanently resolved with the production `.p8` key and signed production entitlement.

---

## 6. DO NOT FORGET: Critical Architecture Invariants

> [!CAUTION]
> The following rules represent the highest-risk operational boundaries in the AMOMY codebase. Any change violating these principles will break production security or cause fleet failures.

1. **Passenger Never Sees Internal Bus Identity**:
   Passengers book trips, not buses. Never expose `Bus 1`, `Bus 2`, plate numbers, internal UUIDs, or driver identities in any passenger UI, ticket, receipt, or notification.
2. **Trip Assignment Governs GPS Source**:
   Never allow the passenger client to choose between physical buses. The active `trip_assignment` maps the trip to a physical bus ID; the client tracks **only** that assigned bus.
3. **Return Tracking Reverses Route Direction**:
   Return trips run from University District to Mit Fadala. The progression engine and UI stop list must reverse stop order ($34 \longrightarrow 1$) and follow return polyline geometry.
4. **Stop Progression Color Palette**:
   - **Passed Stop**: **Yellow** (`#F1C40F`) — once passed, never reverts.
   - **Active / Next Stop**: **Blue** (`#2E86DE`).
   - **Future Stop**: **White** (`#FFFFFF`).
5. **Last Stop vs. Next Stop Semantics**:
   - Last Stop card shows **actual recorded arrival time**.
   - Next Stop card shows **predicted ETA**.
6. **Dynamic Boarding Stop Cutoff**:
   Booking closes for a passenger when the bus has passed their selected boarding stop, not simply when the trip start time strikes.
7. **Return Trips Visible from Morning**:
   All daily return trips (1 PM, 2 PM, 3 PM, 4 PM) must be visible and bookable at 12:00 AM midnight. Never hide return trips until the afternoon.
8. **Controlled Testing Bypass**:
   The `Passenger One` test account bypass for booking time restrictions must be authorized strictly via server-side database attributes, never by matching client display names.
9. **Extra Seat Fare Snapshotting**:
   Extra seats must always inherit the parent booking's confirmed fare snapshot ($20, $25, or $30 pts). Never recalculate extra seat fares against live tariff schedules.
10. **Server-Authoritative Financial State**:
    All wallet balances, point debits, credits, and refunds must be calculated and verified via atomic Postgres transactions. Client code never computes or updates balances directly.
11. **Pending Physical iPhone Test Gate**:
    Do not declare the notification system fully production-ready until physical iPhone TestFlight verification passes all 7 remote push test cases.

