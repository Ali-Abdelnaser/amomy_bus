# 04 — Core Business Rules

## 1. Internal Points Economy
Amomy Bus operates strictly on an internal **Points Economy**. There are **no direct cash or credit card payments per trip**.

### 1.1. Point Types
1. **Subscription Points**:
   - Granted via monthly subscriptions (e.g., 1000 EGP = 1000 Subscription Points).
   - Valid for **one month** from purchase. Unused subscription points expire at the end of the subscription period.
2. **Cash Points**:
   - Acquired via manual top-up (Vodafone Cash, Orange Cash, Bank Transfer).
   - Passenger uploads payment proof screenshot.
   - Requires Super Admin verification and approval before points are credited.
   - Cash points **do not expire**.

### 1.2. Spending Priority Order
When a passenger books a seat:
1. **Subscription Points are consumed first.**
2. **Cash Points are consumed only when subscription points are exhausted or expired.**
3. Points are held in an atomic hold state when a seat is selected, and permanently deducted upon booking confirmation.

### 1.3. Double-Entry Ledger Requirement
- Point balances are never mutated directly by updating a single numeric field.
- Every credit, debit, hold, release, or expiration must be recorded as an immutable row in the `point_transactions` ledger with a reference to the related booking, hold, or top-up request.

---

## 2. Trips, Schedules & Seat Hold Lifecycle

### 2.1. Initial Daily Schedules (Backend-Configurable)
- **Going Routes**: 08:00, 09:00, 10:00, 11:00
- **Return Routes**: 13:00, 14:00, 15:00, 16:00

### 2.2. Seat States & Visual UI Tokens
| Seat State | Visual Token | Description |
| :--- | :--- | :--- |
| **AVAILABLE** | Blue (`#2563EB`) | Available for selection |
| **PENDING** | Orange (`#F97316`)| Temporarily held by a passenger during checkout |
| **CONFIRMED** | Green (`#16A34A`) | Booked and paid with points; shows Male/Female avatar only |
| **BOARDED** | Slate Gray (`#64748B`)| Passenger attendance confirmed by staff on the bus |

### 2.3. Atomic Seat Hold Mechanics
- **Hold Duration**: Exactly **5 minutes**.
- When a passenger selects an available seat, the backend atomically creates a `seat_holds` record and places a corresponding `point_holds` lock.
- If booking is confirmed within 5 minutes:
  - Seat transitions to **CONFIRMED**.
  - Points are permanently deducted from the wallet.
- If the hold timer expires:
  - Seat automatically reverts to **AVAILABLE**.
  - Point hold is unlocked and released back to passenger's available balance.
- **Seat locking must be atomic at the database level (PostgreSQL function with `FOR UPDATE`). Client-side checks alone are forbidden.**

### 2.4. Passenger Privacy Protection
- Passengers see only occupied seat gender avatars (Male/Female).
- **Never expose passenger names, phone numbers, or identities to other passengers on the seat map.**

---

## 3. Bus & Vehicle Abstraction
- Passengers **never choose a specific bus** and cannot see:
  - Internal Bus ID
  - Internal bus name or code
  - License plate number
  - Driver personal details
- Passengers choose only: **Route, Time Slot, and Seat Position**.
- The fleet management backend assigns physical buses and drivers dynamically based on route capacity.

---

## 4. Boarding: NFC & QR Verification

### 4.1. Identification Media
- **Standard Passenger**: Receives a cryptographically signed QR code per confirmed booking.
- **Monthly Subscriber**: Receives a physical NFC card included with the initial subscription. Other passengers may purchase an NFC card separately.

### 4.2. NFC Card Security
- The physical NFC card stores **only a secure, cryptographically random card token**.
- **No personal information or sequential database user IDs are written to the card.**

### 4.3. Staff Attendance Confirmation Flow
```
Passenger Taps NFC / Presents QR
               │
               ▼
Staff App scans token & fetches active booking from backend
               │
               ▼
Backend validates Staff session & displays Passenger manifest details
               │
               ▼
Staff manually reviews & presses [Confirm Attendance]
               │
               ▼
Booking state transitions to BOARDED & Audit log recorded
```
- **Rule**: Scanning an NFC card or QR code must **never** automatically mark attendance without explicit manual staff confirmation.

---

## 5. User Roles & Permissions

1. **PASSENGER**:
   - Browse trips, view schedules, hold/book seats, view points, request top-ups, access booking QR, view live tracking during active booking window.
2. **STAFF**:
   - Scan boarding passes (QR/NFC), view passenger manifest for assigned bus, confirm attendance.
3. **ADMIN**:
   - Manage routes, trip templates, daily schedules, bus assignments, view operations reports.
4. **SUPER_ADMIN**:
   - All Admin privileges PLUS:
   - Review and approve/reject cash top-up screenshots.
   - Perform manual point ledger adjustments.
   - Inspect full financial audit logs and security records.

---

## 6. GPS Telemetry & Tracking Restrictions
- GPS location is ingested directly from hardware IoT GPS trackers installed on physical buses, **not from staff phones**.
- **Privacy & Security Window**: Passengers can only view live bus tracking for their specific booked trip, and only during an active travel window (e.g., 30 minutes before departure until arrival).

---

## 7. Audit Logging Rules
All sensitive business and financial operations must be logged to `audit_logs`:
- Point top-up requests, approvals, and rejections
- Manual balance corrections
- Booking reservations, cancellations, and status changes
- Boarding attendance confirmations
- NFC card bindings and reassignments
- Admin role changes and route alterations
- Mandatory metadata: `actor_id`, `role`, `target_id`, `action`, `timestamp`, `ip_address`, `before_state`, `after_state`.
