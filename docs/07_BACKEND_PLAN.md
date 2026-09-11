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

### 2.8. `expire_point_batches`
- **Purpose**: Background scheduled job to expire points past their expiration date.
- **Security**: `SECURITY DEFINER`, restricted to `service_role` and `postgres` (run by `pg_cron` hourly).
- **Hold-Safe Idempotency**: Inspects `point_hold_allocations` joined to active `point_holds`; only expires `GREATEST(0, remaining_amount - held_amount)` to protect points reserved for active bookings.
- **Steps**:
  1. Selects batches past `expires_at` with `remaining_amount > 0` (`FOR UPDATE SKIP LOCKED`).
  2. Calculates active held points from `point_hold_allocations`.
  3. Locks corresponding user wallet.
  4. Creates `expire` transaction in `point_transactions` for expirable amount.
  5. Deducts expirable amount from `wallets.cached_available_balance`.
  6. Sets `point_batches.remaining_amount = remaining_amount - expirable_amount`.
  7. If batch balance reaches zero, marks related `subscriptions.status = 'expired'`.
  8. Appends summary `POINTS_EXPIRED_BATCH_JOB` in `audit_logs`.

---

## 3. Storage Architecture: `payment-proofs`
- **Bucket Visibility**: **Private (`public = false`)**.
- **Max File Size**: **10 MB** (10,485,760 bytes).
- **MIME Types**: `image/jpeg`, `image/png`, `image/webp`, `image/heic`.
- **Path Pattern**: `{user_id}/{topup_request_id}/{filename}`.
- **Access Policies**:
  - `INSERT`: Allowed only if user is authenticated and path root matches `auth.uid()`.
  - `SELECT`: Allowed if path root matches `auth.uid()` OR user has `super_admin` role.
  - `UPDATE` / `DELETE`: Disallowed from client.

---

## 4. Background Expiration Strategy (`pg_cron`)
For automated background execution on Supabase:
```sql
-- Recommended pg_cron schedule (e.g. every hour)
SELECT cron.schedule(
  'expire-subscription-points-hourly',
  '0 * * * *',
  'SELECT public.expire_point_batches();'
);
```
No mobile client is ever required to be open for expiration to occur.
