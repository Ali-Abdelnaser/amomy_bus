# 12 — Row Level Security (RLS) Permission Matrix

## 1. Security Overview
All public tables in Supabase PostgreSQL have Row-Level Security (`RLS`) enabled. Access is governed by role-evaluation helper functions isolated inside the internal `app_private` schema (inaccessible via PostgREST):
- `app_private.has_role(user_id, role)`
- `app_private.is_admin()` (evaluates to true for `admin` and `super_admin`)
- `app_private.is_super_admin()` (evaluates to true strictly for `super_admin`)

Direct writes (`INSERT`, `UPDATE`, `DELETE`) to financial tables and top-up requests are completely disabled for standard client roles. Financial transitions and top-up submissions must be performed through verified, transactional RPCs.

---

## 2. Table-by-Table Permission Matrix

| Table | Operation | Passenger | Staff | Admin | Super Admin |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`public.profiles`** | `SELECT` | Own profile only (`(select auth.uid()) = id`) | Own profile only | All profiles | All profiles |
| | `INSERT` | System trigger (`handle_new_user`) | System trigger | System trigger | System trigger |
| | `UPDATE` | Own non-sensitive fields | Own non-sensitive fields | All profiles | All profiles |
| | `DELETE` | Denied | Denied | Denied | Allowed |
| **`public.user_roles`** | `SELECT` | Own roles (`(select auth.uid()) = user_id`) | Own roles | All roles | All roles |
| | `INSERT` | **DENIED** (RPC only: `assign_user_role`) | **DENIED** | **DENIED** | **DENIED** (RPC only: `assign_user_role`) |
| | `UPDATE` | **DENIED** | **DENIED** | **DENIED** | **DENIED** |
| | `DELETE` | **DENIED** | **DENIED** | **DENIED** | **DENIED** (RPC only: `remove_user_role`) |
| **`public.wallets`** | `SELECT` | Own wallet (`(select auth.uid()) = user_id`) | Own wallet | All wallets | All wallets |
| | `INSERT` | System trigger only | Denied | Denied | Denied |
| | `UPDATE` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.point_batches`** | `SELECT` | Own batches (`(select auth.uid()) = user_id`) | Own batches | All batches | All batches |
| | `INSERT` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `UPDATE` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.point_transactions`** | `SELECT` | Own ledger (`(select auth.uid()) = user_id`) | Own ledger | All ledger entries | All ledger entries |
| | `INSERT` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `UPDATE` | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) |
| | `DELETE` | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) |
| **`public.point_holds`** | `SELECT` | Own holds (`(select auth.uid()) = user_id`) | Own holds | All holds | All holds |
| | `INSERT` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `UPDATE` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.point_hold_allocations`** | `SELECT` | Own hold allocations | Own hold allocations | All allocations | All allocations |
| | `INSERT` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `UPDATE` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.topup_requests`** | `SELECT` | Own requests (`(select auth.uid()) = user_id`) | Own requests | Own requests | All requests |
| | `INSERT` | **DENIED** (RPC only: `create_topup_request`) | **DENIED** | **DENIED** | **DENIED** |
| | `UPDATE` | **DENIED** (RPC only: `attach_topup_payment_proof`) | **DENIED** | **DENIED** | **DENIED** |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.subscription_plans`** | `SELECT` | All active plans | All active plans | All active plans | All plans (inc. inactive) |
| | `INSERT` | Denied | Denied | Denied | Super Admin (Audited Trigger) |
| | `UPDATE` | Denied | Denied | Denied | Super Admin (Audited Trigger) |
| | `DELETE` | Denied | Denied | Denied | Super Admin (Audited Trigger) |
| **`public.subscriptions`** | `SELECT` | Own subscriptions (`(select auth.uid()) = user_id`) | Own subscriptions | All subscriptions | All subscriptions |
| | `INSERT` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `UPDATE` | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) | **DENIED** (RPC only) |
| | `DELETE` | Denied | Denied | Denied | Denied |
| **`public.routes`** | `SELECT` | Active routes (`is_active = true`) | All routes | All routes | All routes |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.stops`** | `SELECT` | Active stops (`is_active = true`) | All stops | All stops | All stops |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.fare_zones`** | `SELECT` | Active zones (`is_active = true`) | All zones | All zones | All zones |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.route_stops`** | `SELECT` | Active route stops | All route stops | All route stops | All route stops |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.route_geometries`** | `SELECT` | Active verified geoms | All geoms | All geoms | All geoms |
| | `DML` | **DENIED** (Edge function / Admin) | **DENIED** | Admin only | Super Admin |
| **`public.buses`** | `SELECT` | Active fleet (`is_active = true`) | All buses | All buses | All buses |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.bus_seats`** | `SELECT` | Active seats | All seats | All seats | All seats |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.trips`** | `SELECT` | Active scheduled/boarding trips | Assigned trips | All trips | All trips |
| | `DML` | **DENIED** | **DENIED** | Admin only | Super Admin |
| **`public.seat_holds`** | `SELECT` | Own holds (`auth.uid() = user_id`) | All active holds | All holds | All holds |
| | `DML` | **DENIED** (RPC only: `create_booking_hold`) | **DENIED** | **DENIED** | **DENIED** |
| **`public.bookings`** | `SELECT` | Own bookings (`auth.uid() = user_id`) | Manifest for assigned bus | All bookings | All bookings |
| | `DML` | **DENIED** (RPC only: `confirm_booking`, `cancel_passenger_booking`, `change_booking_seat`) | **DENIED** | All bookings | All bookings |
| **`public.bus_live_locations`** | `SELECT` | Public / authenticated read for tracking | Read all | Read all | Read all |
| | `DML` | **DENIED** (Edge function only) | **DENIED** | **DENIED** | Allowed |
| **`public.trip_stop_events`** | `SELECT` | Authenticated read | Read all | Read all | Read all |
| | `DML` | **DENIED** (Server calculation only) | Staff record | Admin | Super Admin |
| **`public.audit_logs`** | `SELECT` | **DENIED** | **DENIED** | **DENIED** | All audit records |
| | `INSERT` | Internal trigger / RPC only | Internal trigger / RPC only | Internal trigger / RPC only | Internal trigger / RPC only |
| | `UPDATE` | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) |
| | `DELETE` | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) | **DENIED** (Immutable) |

---

## 3. Storage Bucket Security (`storage.objects`)

| Bucket | Operation | Passenger | Staff | Admin | Super Admin |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`payment-proofs`** | `INSERT` | Own folder: `{auth.uid()}/*` | Denied | Denied | Denied |
| | `SELECT` | Own folder: `{auth.uid()}/*` | Denied | Denied | All folders & receipts |
| | `UPDATE` | Denied | Denied | Denied | Denied |
| | `DELETE` | Denied | Denied | Denied | Allowed |

---
**Last Updated**: 2026-09-14

