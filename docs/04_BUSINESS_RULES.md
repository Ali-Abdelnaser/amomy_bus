# 04 — Core Business Rules

## 1. Internal Points Economy & Wallet Rules
Amomy Bus operates strictly on an internal **Points Economy**. There are **no cash or credit card payments at the bus door or per trip checkout**.

### 1.1. Point Types & Characteristics
1. **Subscription Points**:
   - Granted via monthly subscriptions.
   - Valid for **one month** from purchase cycle; expired points are purged by background database functions.
   - **Primary Spending Priority**: Subscriptions points are consumed first before cash points.
2. **Cash Points**:
   - Acquired via manual top-up (Vodafone Cash, Orange Cash, InstaPay, Bank Transfer).
   - Minimum top-up amount is **200 Points** (1 Point = 1 EGP for top-up accounting).
   - Passenger uploads payment receipt screenshot.
   - Requires Super Admin verification and approval before points are credited.
   - Rejected top-ups can be corrected and resubmitted by the passenger (`resubmit_topup_request`).
   - Cash points **never expire**.

### 1.2. Double-Entry Ledger Requirement
- Point balances are never mutated directly by raw client updates.
- Every credit, debit, hold, release, expiration, or refund is recorded as an immutable row in the `point_transactions` ledger with source batch tracking.

---

## 2. Trips, Today-Only Booking & 28-Seat Bus Capacity

### 2.1. Daily Scheduled Departures
Regular passenger booking is strictly **today-only** (based on Africa/Cairo timezone):
- **Outbound Departures**: 08:00, 09:00, 10:00, 11:00
- **Return Departures**: 13:00, 14:00, 15:00, 16:00
- Each scheduled departure operates as an independent service run.

### 2.2. Bus Fleet & Physical Capacity
- Current production bus capacity is strictly **28 passenger seats**.
- Physical Cabin Layout:
  - 1 front standalone seat (front-right, before entrance steps)
  - 12 left seats (6 rows × 2 seats)
  - 10 right seats (5 rows × 2 seats)
  - 5 rear connected bench seats
- Total passenger capacity: $1 + 12 + 10 + 5 = 28$ seats.

### 2.3. Dynamic Stop Fare Model (34-Stop Corridor)
Fare is determined strictly by the **boarding physical stop**:
- **Zone 30 (Stops 1–5)**: **30 Points** (e.g., كوبرى عزت, كوبرى الزغبي, البريد, البنزينة, صيدلية حسونة)
- **Zone 25 (Stops 6–17)**: **25 Points** (e.g., القنطرة البيضة, منشار الجوهرى, قاعة اللؤلؤة, الوحدة الصحية, سنجيد)
- **Zone 20 (Stops 18–34)**: **20 Points** (e.g., برج النور, البهو فريك, شبرا البهو, سندوب, جامعة السلاب, بوابات الجامعة)

### 2.4. Atomic Seat Holds & Booking Lifecycle
- **Hold Duration**: Exactly **5 minutes**.
- When a passenger selects a seat, `create_booking_hold` atomically freezes a `fare_points_snapshot` in `seat_holds` and reserves points in `point_holds` using pessimistic row locking (`FOR UPDATE`).
- **Confirmation**: `confirm_booking` permanently debits the frozen snapshot points and generates a cryptographically signed QR boarding ticket.
- **Duplicate-Trip Booking Prevention**: A passenger cannot have more than one active booking per trip run.
- **Cancellations & Seat Changes**:
  - Permitted up to **30 minutes prior to scheduled trip departure**.
  - Cancellation (`cancel_passenger_booking`) atomically refunds points to the exact originating point batches.
  - Seat change (`change_booking_seat`) swaps seat assignment on the same bus within the valid time window.

---

## 3. Live Bus GPS Tracking & Google Maps Architecture

### 3.1. Telemetry Ingestion Source
- Telemetry originates **exclusively from physical ETrack hardware IoT GPS units** installed on buses.
- **Passenger phones are NOT a GPS source.**
- **Staff phones are NOT a GPS source.**
- Production tracking scope is strictly limited to **Amomy 1** and **Amomy 2** (Bus 3 is not tracked).

### 3.2. Tracking Operational Windows
- Active service windows:
  - **Morning Window**: 08:00 – 12:00
  - **Afternoon Window**: 13:00 – 17:00
- Outside these service hours, the map displays **OFFLINE / Service Resumes** even if the physical ETrack device continues transmitting telemetry.

### 3.3. Google Maps Platform & Road Geometry
- Visual palette uses official **Silver monochrome Google Maps style** (`#EBEBEB` base) with AMOMY Blue `#01589F` and Warm Yellow `#FFC928` hierarchy.
- Route paths follow stored road geometry generated via Google Routes API, ensuring bus markers and polylines follow actual roads.
- Stops are passenger landmarks near the road and do not need to sit on the centerline.

### 3.4. Realtime Stop Semantics & Passenger UX
- **Last Stop**: Latest confirmed arrived or passed stop — rendered in **Warm Yellow** (`#FFC928`). Shows actual recorded arrival time:
  - English: `"Arrived at <time>"`
  - Arabic: `"وصل الساعة <time>"`
  - *(Technical wording such as "Actual Arrival" is strictly prohibited in passenger UI)*.
- **Next Stop**: Immediate next authoritative stop — rendered in **AMOMY Blue** (`#01589F`) with calculated ETA.
- **Future Stops**: Unreached downstream stops — rendered in **Clean White** (`#FFFFFF`).
- **Older Passed Stops**: Muted slate gray (`#CBD5E1`).

---

## 4. Passenger Privacy Protection
- Passengers see only occupied seat gender indicators (Male / Female avatar) on the seat map.
- **Passenger names, phone numbers, and profile details are never exposed to other commuters.**
- Boarding QR passes and physical NFC cards contain only secure, cryptographically random tokens with zero PII.

---
**Last Updated**: 2026-09-14

