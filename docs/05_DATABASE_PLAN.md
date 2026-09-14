# 05 — Database Entity & Schema Plan

## 1. Overview
The database layer is hosted on **Supabase PostgreSQL** and managed exclusively via immutable, version-controlled migrations.

- **Current Status**: **Phase 1 Schema Implemented & Applied** (Migration `20260911030140_backend_phase1_core.sql`).
- **Database Posture**: Row-Level Security (RLS) is strictly enabled on 100% of public tables. Direct write mutations from clients to wallets, batches, ledger transactions, and audit logs are completely prohibited.

---

## 2. Custom Enumerated Types (`public.*`)

| Enum Type | Allowed Values | Purpose |
| :--- | :--- | :--- |
| `role_type` | `'passenger'`, `'staff'`, `'admin'`, `'super_admin'` | System authorization roles |
| `point_source_type` | `'cash'`, `'subscription'`, `'promo'`, `'refund'`, `'manual_adjustment'` | Origin of point batches |
| `recharge_status` | `'pending'`, `'approved'`, `'rejected'` | Cash top-up approval status |
| `point_transaction_type`| `'credit'`, `'debit'`, `'hold'`, `'release'`, `'expire'`, `'refund'`, `'manual_adjustment'` | Financial ledger actions |
| `subscription_status` | `'active'`, `'expired'`, `'cancelled'` | Passenger subscription state |

---

## 3. Implemented Database Tables (Phase 1)

### 3.1. `public.profiles`
Primary user profile table, created automatically via `handle_new_user()` trigger when a user registers through Supabase Auth (`auth.users`).

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY`, `REFERENCES auth.users(id) ON DELETE CASCADE` | Matches auth user ID |
| `full_name` | `text` | `NOT NULL` | Passenger full name |
| `email` | `text` | `NOT NULL` | Contact email (synced from auth) |
| `phone` | `text` | `NULLABLE` | Contact phone number |
| `gender` | `text` | `CHECK (gender IN ('male', 'female'))` | Required for gender-based seat avatars |
| `date_of_birth`| `date` | `NULLABLE` | Date of birth |
| `avatar_url` | `text` | `NULLABLE` | Profile picture URL |
| `is_active` | `boolean` | `NOT NULL DEFAULT true` | Account active toggle |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Registration timestamp |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Automated via `handle_updated_at` trigger |

### 3.2. `public.user_roles`
Normalized role mappings supporting role-based access control.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Role record identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE` | Assigned user |
| `role` | `role_type` | `NOT NULL` | System role |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Role grant timestamp |
| `created_by` | `uuid` | `NULLABLE REFERENCES public.profiles(id)` | Admin actor who granted role |
| *Constraint* | Unique | `UNIQUE (user_id, role)` | Prevents duplicate role assignment |

### 3.3. `public.wallets`
Fast read-optimized balance cache. **Not the financial source of truth**.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Wallet identifier |
| `user_id` | `uuid` | `UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE` | Owner |
| `cached_available_balance`| `numeric` | `NOT NULL DEFAULT 0 CHECK (>= 0)` | Available points for booking |
| `cached_held_balance` | `numeric` | `NOT NULL DEFAULT 0 CHECK (>= 0)` | Points locked in active seat holds |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Creation timestamp |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Updated via trigger |

### 3.4. `public.point_batches`
The financial source of truth for point holdings, source attribution, and expiration.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Batch identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE` | Recipient |
| `source_type` | `point_source_type` | `NOT NULL` | Origin (`cash`, `subscription`, etc.) |
| `original_amount`| `numeric` | `NOT NULL CHECK (original_amount > 0)` | Initial granted points |
| `remaining_amount`| `numeric` | `NOT NULL CHECK (remaining_amount >= 0)`| Unspent points remaining in batch |
| `expires_at` | `timestamptz` | `NULLABLE` | Expiry (`NULL` for Cash Points) |
| `source_reference_type`| `text`| `NULLABLE` | Table name of source (`topup_requests`) |
| `source_reference_id` | `uuid`| `NULLABLE` | Source record ID |
| `description`| `text` | `NULLABLE` | Human-readable description |
| `created_by` | `uuid` | `NULLABLE REFERENCES public.profiles(id)` | Grantor or reviewer |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Grant timestamp |

### 3.5. `public.point_transactions`
Append-only immutable double-entry ledger of all point movements.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Transaction identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id)` | Passenger account |
| `wallet_id` | `uuid` | `NOT NULL REFERENCES public.wallets(id)` | Affected wallet |
| `batch_id` | `uuid` | `NULLABLE REFERENCES public.point_batches(id)` | Associated point batch |
| `transaction_type`| `point_transaction_type`| `NOT NULL` | Movement action code |
| `amount` | `numeric` | `NOT NULL CHECK (amount > 0)` | Point magnitude |
| `balance_before`| `numeric` | `NULLABLE` | Pre-transaction balance snapshot |
| `balance_after` | `numeric` | `NULLABLE` | Post-transaction balance snapshot |
| `reference_type`| `text` | `NULLABLE` | Originating domain entity |
| `reference_id` | `uuid` | `NULLABLE` | Originating record UUID |
| `description` | `text` | `NULLABLE` | Explanation |
| `actor_user_id`| `uuid` | `NULLABLE REFERENCES public.profiles(id)` | System or admin actor |
| `metadata` | `jsonb` | `NOT NULL DEFAULT '{}'::jsonb` | Structured contextual metadata |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Immutable audit timestamp |

### 3.6. `public.point_holds`
Temporary point holds associated with 5-minute seat reservations.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Hold identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id)` | Passenger holding points |
| `amount` | `numeric` | `NOT NULL CHECK (amount > 0)` | Reserved points |
| `reference_type`| `text` | `NOT NULL` | Reference (`trip_seat_hold`) |
| `reference_id` | `uuid` | `NULLABLE` | Target seat hold UUID |
| `status` | `text` | `NOT NULL DEFAULT 'active' CHECK IN ('active', 'released', 'consumed')` | Hold lifecycle state |
| `expires_at` | `timestamptz` | `NOT NULL` | Expiration (strictly 5 minutes) |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Reservation timestamp |
| `released_at`| `timestamptz` | `NULLABLE` | Timestamp when hold reverted |
| `consumed_at`| `timestamptz` | `NULLABLE` | Timestamp when hold completed into booking |

### 3.7. `public.point_hold_allocations`
Exact batch-level reservations per hold (e.g., 30 Subscription Points + 10 Cash Points).

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Allocation record identifier |
| `hold_id` | `uuid` | `NOT NULL REFERENCES public.point_holds(id) ON DELETE CASCADE` | Associated hold |
| `batch_id` | `uuid` | `NOT NULL REFERENCES public.point_batches(id)` | Reserved point batch |
| `amount` | `numeric` | `NOT NULL CHECK (amount > 0)` | Points reserved from this batch |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Allocation creation timestamp |

### 3.7. `public.topup_requests`
Cash point manual top-up requests (Vodafone Cash, Orange Cash, Bank Transfers).

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Request identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id)` | Requesting passenger |
| `requested_amount`| `numeric`| `NOT NULL CHECK (requested_amount > 0)` | Points requested (= EGP paid) |
| `payment_method` | `text` | `NOT NULL` | e.g. `vodafone_cash`, `orange_cash` |
| `payment_reference`| `text` | `NULLABLE` | Wallet transaction number / reference |
| `screenshot_path` | `text` | `NULLABLE` | Path in private `payment-proofs` bucket |
| `status` | `recharge_status` | `NOT NULL DEFAULT 'pending'` | `pending`, `approved`, `rejected` |
| `reviewed_by` | `uuid` | `NULLABLE REFERENCES public.profiles(id)` | Super Admin reviewer |
| `reviewed_at` | `timestamptz` | `NULLABLE` | Review timestamp |
| `rejection_reason`| `text` | `NULLABLE` | Reason if rejected |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Creation timestamp |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Last update timestamp |

### 3.8. `public.subscription_plans`
Available monthly recurring subscription plans.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Plan identifier |
| `name` | `text` | `NOT NULL` | Display title (e.g. "Monthly Commuter 1000") |
| `price_egp` | `numeric` | `NOT NULL CHECK (price_egp >= 0)` | Monetary cost in EGP |
| `points_amount` | `numeric` | `NOT NULL CHECK (points_amount > 0)` | Points credited per cycle |
| `duration_days` | `integer` | `NOT NULL CHECK (duration_days > 0)` | Validity period (e.g. 30 days) |
| `is_active` | `boolean` | `NOT NULL DEFAULT true` | Active enrollment toggle |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Creation timestamp |
| `updated_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Last update timestamp |

### 3.9. `public.subscriptions`
Concrete passenger subscription instances.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Subscription identifier |
| `user_id` | `uuid` | `NOT NULL REFERENCES public.profiles(id)` | Subscriber |
| `plan_id` | `uuid` | `NOT NULL REFERENCES public.subscription_plans(id)`| Selected tier |
| `status` | `subscription_status` | `NOT NULL` | `active`, `expired`, `cancelled` |
| `starts_at` | `timestamptz` | `NOT NULL` | Activation start |
| `expires_at` | `timestamptz` | `NOT NULL` | Expiration (end of term) |
| `point_batch_id`| `uuid` | `NULLABLE REFERENCES public.point_batches(id)` | Linked subscription point batch |
| `created_by` | `uuid` | `NULLABLE REFERENCES public.profiles(id)` | Admin actor who activated subscription |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Creation timestamp |

### 3.10. `public.audit_logs`
System-wide append-only audit trail.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `uuid` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Log identifier |
| `actor_user_id`| `uuid` | `NULLABLE REFERENCES public.profiles(id)` | Operating user |
| `actor_role` | `text` | `NULLABLE` | Role of actor at operation time |
| `action` | `text` | `NOT NULL` | Action code (`TOPUP_APPROVED`, etc.) |
| `target_type` | `text` | `NULLABLE` | Entity type affected (`wallets`, `topup_requests`) |
| `target_id` | `uuid` | `NULLABLE` | Entity primary key |
| `before_data` | `jsonb` | `NULLABLE` | Pre-change JSON snapshot |
| `after_data` | `jsonb` | `NULLABLE` | Post-change JSON snapshot |
| `metadata` | `jsonb` | `NOT NULL DEFAULT '{}'::jsonb` | Context (IP, browser, remarks) |
| `created_at` | `timestamptz` | `NOT NULL DEFAULT now()` | Exact timestamp of event |

---

## 4. Implemented Fleet, Route & Booking Entities

### 4.1. `public.buses` & `public.bus_seats`
- `buses`: Stores physical buses (`id`, `name`, `plate_number`, `capacity` = 28, `is_active`).
- `bus_seats`: Authoritative 28 seat slots per bus (`id`, `bus_id`, `seat_number` '1'..'28', `is_active`).

### 4.2. `public.routes`, `public.stops`, `public.fare_zones` & `public.route_stops`
- `routes`: Transit corridors (`id`, `name_ar`, `name_en`, `direction` `'outbound'|'return'`).
- `stops`: 34 landmark stops (`id`, `name_ar`, `name_en`, `locality_ar`, `locality_en`, `latitude`, `longitude`).
- `fare_zones`: Dynamic pricing zones (`id`, `code` `ZONE_30|ZONE_25|ZONE_20`, `fare_points` 30, 25, 20).
- `route_stops`: Stop order along route with linked fare zone (`id`, `route_id`, `stop_id`, `fare_zone_id`, `stop_order`).

### 4.3. `public.route_geometries` & `public.route_anchor_points`
- `route_geometries`: Stored road polyline geometry generated via Google Routes API (`id`, `route_id`, `direction`, `version`, `polyline_encoded`, `polyline_points`, `distance_meters`, `duration_seconds`).
- `route_anchor_points`: Strategic shaping waypoints defining road trajectories.

### 4.4. `public.trips`, `public.seat_holds` & `public.bookings`
- `trips`: Daily scheduled departures (`id`, `route_id`, `bus_id`, `service_date`, `departure_at`, `status`, `fare_points`).
- `seat_holds`: 5-minute atomic reservations (`id`, `trip_id`, `seat_id`, `user_id`, `route_stop_id`, `fare_zone_id`, `fare_points_snapshot`, `status`, `expires_at`).
- `bookings`: Confirmed reservations (`id`, `trip_id`, `seat_id`, `user_id`, `route_stop_id`, `destination_route_stop_id`, `seat_number_snapshot`, `fare_points`, `qr_token`, `status` `'confirmed'|'cancelled'|'boarded'`).

### 4.5. `public.bus_tracking_devices`, `public.bus_live_locations`, `public.bus_location_history` & `public.trip_stop_events`
- `bus_tracking_devices`: Hardware IoT trackers mapped to buses (`bus_id`, `provider` `'etrack'`, `provider_device_id`, `provider_device_name` `'Amomy1'|'Amomy2'`).
- `bus_live_locations`: Authoritative realtime vehicle position (`bus_id`, `latitude`, `longitude`, `speed_kmh`, `heading`, `gps_recorded_at`, `current_stop_id`, `next_stop_id`, `source` `'etrack'`, `is_valid`).
- `bus_location_history`: Historical breadcrumb logs.
- `trip_stop_events`: Recorded actual stop arrival events (`trip_id`, `stop_id`, `stop_order`, `arrived_at`, `recorded_at`).

---
**Last Updated**: 2026-09-14

