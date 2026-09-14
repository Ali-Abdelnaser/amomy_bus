# 07 — Backend Architecture & Integration Plan

## 1. Supabase Backend Infrastructure

```
                               ┌─────────────────────────────┐
                               │     Supabase PostgreSQL     │
                               │  - Schema Migrations        │
                               │  - Row-Level Security (RLS) │
                               │  - Atomic Stored Procedures │
                               └──────────────┬──────────────┘
                                              │
                 ┌────────────────────────────┼────────────────────────────┐
                 ▼                            ▼                            ▼
      ┌──────────────────────┐   ┌──────────────────────┐   ┌──────────────────────┐
      │    Supabase Auth     │   │   Supabase Storage   │   │  Supabase Realtime   │
      │ - Trigger on signup  │   │ - payment-proofs     │   │ - Live seat holds    │
      │ - Automated profile  │   │   (Private, 10MB)    │   │ - Ledger balances    │
      │ - Default passenger  │   │ - Path ownership     │   │ - Live GPS telemetry │
      └──────────────────────┘   └──────────────────────┘   └──────────────────────┘
```

---

## 2. Implemented Stored Procedures & Atomic RPCs

### 2.1. `create_topup_request`
- **Purpose**: Securely creates a cash point recharge request for external payments (e.g., Vodafone Cash, Orange Cash). Direct client table `INSERT` is strictly revoked.
- **Security**: `SECURITY DEFINER`, accessible only to authenticated users. Always uses `auth.uid()`, ignoring any spoofed client user IDs.
- **Parameters**:
  - `p_requested_amount numeric` (> 0)
  - `p_payment_method text`
  - `p_payment_reference text` (optional, protected by partial unique index against duplicates)
  - `p_screenshot_path text` (optional, validated to start with `{auth.uid()}/`)
- **Side Effects**: Creates `topup_requests` in `pending` state and records `TOPUP_REQUEST_CREATED` in `audit_logs`.

### 2.2. `attach_topup_payment_proof`
- **Purpose**: Attaches proof screenshot to a pending request with strict path verification.
- **Security**: `SECURITY DEFINER`, accessible only to authenticated request owner.
- **Parameters**:
  - `p_request_id uuid`
  - `p_screenshot_path text`
- **Enforcement**: Validates path starts strictly with `{auth.uid()}/{p_request_id}/` before attaching to prevent path spoofing or cross-tenant attachment.

### 2.3. `approve_topup_request`
- **Purpose**: Super Admin approval of a cash recharge request.
- **Security**: `SECURITY DEFINER`, restricted strictly to `super_admin` role via `app_private.is_super_admin()`.
- **Parameters**:
  - `p_request_id uuid`
- **Transactional Steps (All in ONE Atomic Transaction)**:
  1. Row-lock on `topup_requests` (`FOR UPDATE`). Verifies `status = 'pending'`.
  2. Row-lock on target user's `wallets` (`FOR UPDATE`).
  3. Inserts a non-expiring Cash Point batch into `point_batches` (`expires_at = NULL`).
  4. Inserts a `credit` transaction into the immutable `point_transactions` ledger.
  5. Updates `wallets.cached_available_balance = cached_available_balance + requested_amount`.
  6. Updates `topup_requests` to `status = 'approved'`, `reviewed_by = auth.uid()`, `reviewed_at = now()`.
  7. Inserts `TOPUP_APPROVED` entry into `audit_logs`.

### 2.4. `reject_topup_request`
- **Purpose**: Super Admin rejection of a cash recharge request with explicit reason.
- **Security**: `SECURITY DEFINER`, restricted strictly to `super_admin` role via `app_private.is_super_admin()`.
- **Parameters**:
  - `p_request_id uuid`
  - `p_reason text`
- **Side Effects**: Updates request status to `rejected`, records reviewer and reason, and appends `TOPUP_REJECTED` in `audit_logs`.

### 2.5. `admin_add_cash_points`
- **Purpose**: Super Admin manual grant of cash points (corrections, VIP credits, compensation).
- **Security**: `SECURITY DEFINER`, restricted strictly to `super_admin` role via `app_private.is_super_admin()`.
- **Parameters**:
  - `p_target_user_id uuid`
  - `p_amount numeric` (> 0)
  - `p_reason text`
- **Transactional Steps**:
  1. Row-lock on target user's `wallets`.
  2. Creates a non-expiring Cash batch (`source_type = 'cash'`, `source_reference_type = 'manual_adjustment'`) in `point_batches`.
  3. Records `manual_adjustment` ledger entry in `point_transactions`.
  4. Updates `wallets.cached_available_balance`.
  5. Appends `MANUAL_POINTS_GRANTED` in `audit_logs`.

### 2.6. `assign_user_role` & `remove_user_role`
- **Purpose**: Fully audited role lifecycle management.
- **Security**: `SECURITY DEFINER`, restricted to `super_admin`.
- **Guarantees**: Self-lockout prevention (super admin cannot remove their own super_admin role), transactional execution, and full before/after audit trail in `audit_logs`.

### 2.7. `create_user_subscription`
- **Purpose**: Activates a monthly subscription for a user.
- **Security**: `SECURITY DEFINER`, restricted to `admin` and `super_admin` via `app_private.is_admin()`.
- **Parameters**:
  - `p_target_user_id uuid`
  - `p_plan_id uuid`
- **Transactional Steps**:
  1. Validates `subscription_plans` is active and retrieves points and duration directly from database.
  2. Row-lock on target user's `wallets`.
  3. Inserts an expiring Subscription Point batch into `point_batches` (`expires_at = now() + duration_days`).
  4. Creates `subscriptions` record in `active` state linked to the batch.
  5. Inserts `credit` transaction into `point_transactions`.
  6. Updates `wallets.cached_available_balance`.
  7. Appends `SUBSCRIPTION_CREATED` in `audit_logs`.

### 2.9. `create_booking_hold`
- **Purpose**: Creates an atomic 5-minute hold on a physical 28-seat slot, resolves the dynamic fare based on boarding stop (30, 25, or 20 PTS), freezes `fare_points_snapshot`, and reserves wallet points via `point_holds` and `point_hold_allocations`.
- **Security**: `SECURITY DEFINER`, authenticated users only.
- **Enforcements**: Today-only booking guard, duplicate-trip booking prevention, full profile completeness check, row-level locks on seat and wallet (`FOR UPDATE`).

### 2.10. `confirm_booking`
- **Purpose**: Permanently debits the held points based on frozen snapshot, converts `seat_holds` to `consumed`, and creates a `bookings` record with a cryptographically secure QR token.

### 2.11. `cancel_passenger_booking`
- **Purpose**: Cancels a confirmed booking up to 30 minutes before departure and atomically refunds points to the exact originating `point_batches` recorded in `point_transactions`.

### 2.12. `change_booking_seat`
- **Purpose**: Swaps seat assignment on the same bus up to 30 minutes before departure with atomic conflict validation.

### 2.13. `get_available_trips` & `get_today_available_trips`
- **Purpose**: Retrieves active today trips with dynamic stop fare, real available seat counts, and duplicate-trip filtering.

### 2.14. `get_route_stops`
- **Purpose**: Returns the 34 ordered route stops with localized names and linked fare zones.

### 2.15. `compute_bus_progression` & `record_stop_arrival_event`
- **Purpose**: Server-side calculation of monotonic bus progress along route stops and recording actual stop arrival events in `trip_stop_events`.

---

## 3. Implemented Supabase Edge Functions

### 3.1. `etrack-sync` (Hardware IoT GPS Telemetry)
- **Schedule / Trigger**: Automated periodic invocation.
- **Scope**: Amomy 1 and Amomy 2 only.
- **Security**: Authenticates with ETrack portal via secure credentials vault RPC (`get_etrack_credentials`).
- **Functionality**:
  1. Fetches real hardware GPS telemetry (latitude, longitude, speed, heading, battery, ignition, hardware timestamp).
  2. Validates coordinates and timestamps.
  3. Authoritatively upserts into `bus_live_locations` with `source = 'etrack'`.
  4. Triggers `compute_bus_progression` and logs breadcrumbs into `bus_location_history`.
  5. Records execution health in `sync_health_logs`.

### 3.2. `google-route-generator` (Google Routes Road Geometry)
- **Purpose**: Calls Google Routes API (`directions/v2:computeRoutes`) using ordered `route_anchor_points` to generate official road-following high-precision polylines.
- **Functionality**:
  1. Computes road distances and durations.
  2. Decodes polyline coordinates.
  3. Validates proximity of all 34 passenger landmark stops.
  4. Stores versioned, active polyline in `route_geometries`.

---

## 4. Storage Architecture: `payment-proofs`
- **Bucket Visibility**: **Private (`public = false`)**.
- **Max File Size**: **10 MB** (10,485,760 bytes).
- **MIME Types**: `image/jpeg`, `image/png`, `image/webp`, `image/heic`.
- **Path Pattern**: `{user_id}/{topup_request_id}/{filename}`.
- **Access Policies**:
  - `INSERT`: Allowed only if user is authenticated and path root matches `auth.uid()`.
  - `SELECT`: Allowed if path root matches `auth.uid()` OR user has `super_admin` role.

---
**Last Updated**: 2026-09-14

