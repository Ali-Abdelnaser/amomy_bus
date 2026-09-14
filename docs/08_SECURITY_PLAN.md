# 08 — Security & Privacy Architecture

## 1. Zero-Trust Client Model
The application follows a zero-trust model where client Flutter applications are treated as untrusted runtime environments:
- **No Direct Financial Writes**: Direct table `INSERT`, `UPDATE`, `DELETE`, and `TRUNCATE` are revoked on `wallets`, `point_batches`, `point_transactions`, `point_holds`, `point_hold_allocations`, `topup_requests`, `user_roles`, `subscriptions`, and `audit_logs`.
- **Top-up Creation via RPC Only**: `create_topup_request` and `attach_topup_payment_proof` enforce server-side validation, ownership checks, duplicate payment reference prevention, and mandatory audit logging.
- **Server-Authoritative Balances**: Balances and point deductions are computed solely within PostgreSQL functions with pessimistic row locks (`FOR UPDATE`).
- **Private Role Isolation**: Role helpers (`has_role`, `is_admin`, `is_super_admin`) reside in `app_private` schema. PostgREST does NOT expose `app_private`, preventing unauthorized inspection of user roles or direct RPC invocation.

---

## 2. Row Level Security (RLS) Posture
- 100% of public tables have Row-Level Security enabled.
- Default policy posture is **DENY ALL**.
- RLS InitPlan Optimization: Uses `(select auth.uid())` instead of repeated per-row evaluation of `auth.uid()`.
- Single Permissive Policies: Avoids overlapping permissive policies per action/role for peak performance.
- Profiles Update Policy: Passengers can only update non-sensitive columns (`full_name`, `phone`, `gender`, `date_of_birth`, `avatar_url`). System fields (`id`, `email`, `is_active`, `created_at`) are protected by `WITH CHECK` verification against existing profile values.
- Audit logs are accessible exclusively by Super Admins.

---

## 3. Function & RPC Security Hardening
- All stored procedures run with an explicit `SET search_path = public, app_private` to prevent search path injection attacks.
- Internal trigger functions (`handle_new_user`, `handle_updated_at`, `handle_subscription_plan_audit`) have `EXECUTE` privileges revoked from `public`, `anon`, and `authenticated`.
- Background functions (`expire_point_batches`) have `EXECUTE` revoked from external clients and are granted only to `service_role` and `postgres`.
- Privileged RPCs (`approve_topup_request`, `reject_topup_request`, `admin_add_cash_points`, `assign_user_role`, `remove_user_role`) explicitly verify `app_private.is_super_admin()` within the function body and lock target records (`FOR UPDATE`).
- Self-lockout prevention: `remove_user_role` explicitly forbids a super admin from revoking their own super_admin role.

---

## 4. Storage Bucket Security (`payment-proofs`)
- The `payment-proofs` bucket is private (`public = false`). Direct public URLs return HTTP 403.
- Uploads must follow strict ownership pathing: `{user_id}/{topup_request_id}/{filename}` where the first folder segment must match `auth.uid()`.
- `attach_topup_payment_proof` validates that `p_screenshot_path` matches the exact prefix `{auth.uid()}/{p_request_id}/`.
- Only the owning passenger and users with the `super_admin` role can generate signed URLs or read stored receipt objects.

---

## 5. Physical NFC, QR & Booking Security
- NFC cards contain only a cryptographically secure random token (zero PII, zero sequential IDs).
- Boarding QR passes are cryptographically random nonces validated server-side.
- Passenger identity is masked on the seat map (shows only gender icons; passenger names and numbers are strictly redacted).
- Duplicate booking prevention is enforced at the database level (`ALREADY_BOOKED_TRIP`).
- 30-minute cancellation/change-seat cutoff enforced with server-side time checks against `public.get_effective_booking_now()`.
- GPS telemetry ingestion is secured behind edge functions with dedicated service-role execution and vault credentials; direct client writes to telemetry tables are blocked.

---
**Last Updated**: 2026-09-14

