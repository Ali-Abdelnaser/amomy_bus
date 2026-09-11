-- Migration: 20260911040000_backend_phase1_final_hardening.sql
-- Description: Backend Phase 1 Final Hardening: Private role helpers in app_private schema,
--              point_hold_allocations table, RPC-only topups, screenshot path validation,
--              role & plan audit triggers, duplicate payment reference index,
--              covering indexes for unindexed foreign keys, auth RLS initplan optimization,
--              and hold-safe subscription expiration cron.

-- =============================================================================
-- 1. INTERNAL SCHEMA & ROLE HELPERS HARDENING
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA app_private FROM public, anon;
GRANT USAGE ON SCHEMA app_private TO authenticated, service_role, postgres;

-- 1.1 Private Role Verification Helpers (NOT exposed via PostgREST)
CREATE OR REPLACE FUNCTION app_private.has_role(p_user_id uuid, p_role role_type)
RETURNS boolean
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = p_user_id
      AND role = p_role
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION app_private.is_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
  RETURN (
    app_private.has_role((select auth.uid()), 'admin') OR
    app_private.has_role((select auth.uid()), 'super_admin')
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION app_private.is_super_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
  RETURN app_private.has_role((select auth.uid()), 'super_admin');
END;
$$ LANGUAGE plpgsql;

REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app_private FROM public, anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_private TO authenticated, service_role, postgres;

-- =============================================================================
-- 2. POINT HOLD ALLOCATIONS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.point_hold_allocations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  hold_id uuid NOT NULL REFERENCES public.point_holds(id) ON DELETE CASCADE,
  batch_id uuid NOT NULL REFERENCES public.point_batches(id),
  amount numeric NOT NULL CHECK (amount > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.point_hold_allocations ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_point_hold_allocations_hold_id ON public.point_hold_allocations(hold_id);
CREATE INDEX IF NOT EXISTS idx_point_hold_allocations_batch_id ON public.point_hold_allocations(batch_id);

CREATE POLICY "point_hold_allocations_select" ON public.point_hold_allocations
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.point_holds ph
      WHERE ph.id = hold_id
        AND ph.user_id = (select auth.uid())
    ) OR app_private.is_admin()
  );

-- =============================================================================
-- 3. DUPLICATE PAYMENT REFERENCE PROTECTION & INDEXES
-- =============================================================================

CREATE UNIQUE INDEX IF NOT EXISTS uq_active_topup_payment_ref
  ON public.topup_requests (payment_method, lower(trim(payment_reference)))
  WHERE payment_reference IS NOT NULL AND status IN ('pending', 'approved');

-- Covering indexes for unindexed foreign keys identified by Supabase Advisor
CREATE INDEX IF NOT EXISTS idx_point_batches_created_by ON public.point_batches (created_by);
CREATE INDEX IF NOT EXISTS idx_point_transactions_actor ON public.point_transactions (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_point_transactions_batch_id ON public.point_transactions (batch_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_created_by ON public.subscriptions (created_by);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_id ON public.subscriptions (plan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_point_batch_id ON public.subscriptions (point_batch_id);
CREATE INDEX IF NOT EXISTS idx_topup_requests_reviewed_by ON public.topup_requests (reviewed_by);
CREATE INDEX IF NOT EXISTS idx_user_roles_created_by ON public.user_roles (created_by);

-- =============================================================================
-- 4. RLS POLICIES CLEANUP & OPTIMIZATION (Fixing InitPlan & Multiple Policies)
-- =============================================================================

-- 4.1 Profiles Policies
DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_admin_update" ON public.profiles;

CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = id OR app_private.is_admin());

CREATE POLICY "profiles_update_unified" ON public.profiles
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id OR app_private.is_admin())
  WITH CHECK (
    app_private.is_admin()
    OR (
      (select auth.uid()) = id AND
      id = (select auth.uid()) AND
      email = (SELECT p.email FROM public.profiles p WHERE p.id = (select auth.uid())) AND
      is_active = (SELECT p.is_active FROM public.profiles p WHERE p.id = (select auth.uid())) AND
      created_at = (SELECT p.created_at FROM public.profiles p WHERE p.id = (select auth.uid()))
    )
  );

-- 4.2 User Roles Policies
DROP POLICY IF EXISTS "user_roles_select_own_or_admin" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles_super_admin_manage" ON public.user_roles;

CREATE POLICY "user_roles_select_unified" ON public.user_roles
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.3 Wallets Policies
DROP POLICY IF EXISTS "wallets_select_own_or_admin" ON public.wallets;

CREATE POLICY "wallets_select_unified" ON public.wallets
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.4 Point Batches Policies
DROP POLICY IF EXISTS "point_batches_select_own_or_admin" ON public.point_batches;

CREATE POLICY "point_batches_select_unified" ON public.point_batches
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.5 Point Transactions Policies
DROP POLICY IF EXISTS "point_transactions_select_own_or_admin" ON public.point_transactions;

CREATE POLICY "point_transactions_select_unified" ON public.point_transactions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.6 Point Holds Policies
DROP POLICY IF EXISTS "point_holds_select_own_or_admin" ON public.point_holds;

CREATE POLICY "point_holds_select_unified" ON public.point_holds
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.7 Topup Requests Policies (Direct INSERT removed; RPC only)
DROP POLICY IF EXISTS "topup_requests_select_own_or_super_admin" ON public.topup_requests;
DROP POLICY IF EXISTS "topup_requests_insert_own" ON public.topup_requests;

CREATE POLICY "topup_requests_select_unified" ON public.topup_requests
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_super_admin());

-- 4.8 Subscription Plans Policies
DROP POLICY IF EXISTS "subscription_plans_read_active" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_super_admin_all" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_select_unified" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_dml_super_admin" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_insert_super_admin" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_update_super_admin" ON public.subscription_plans;
DROP POLICY IF EXISTS "subscription_plans_delete_super_admin" ON public.subscription_plans;

CREATE POLICY "subscription_plans_select_unified" ON public.subscription_plans
  FOR SELECT
  USING (is_active = true OR app_private.is_super_admin());

CREATE POLICY "subscription_plans_insert_super_admin" ON public.subscription_plans
  FOR INSERT TO authenticated
  WITH CHECK (app_private.is_super_admin());

CREATE POLICY "subscription_plans_update_super_admin" ON public.subscription_plans
  FOR UPDATE TO authenticated
  USING (app_private.is_super_admin())
  WITH CHECK (app_private.is_super_admin());

CREATE POLICY "subscription_plans_delete_super_admin" ON public.subscription_plans
  FOR DELETE TO authenticated
  USING (app_private.is_super_admin());

-- 4.9 Subscriptions Policies
DROP POLICY IF EXISTS "subscriptions_select_own_or_admin" ON public.subscriptions;

CREATE POLICY "subscriptions_select_unified" ON public.subscriptions
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.10 Audit Logs Policies
DROP POLICY IF EXISTS "audit_logs_select_super_admin" ON public.audit_logs;

CREATE POLICY "audit_logs_select_unified" ON public.audit_logs
  FOR SELECT TO authenticated
  USING (app_private.is_super_admin());

-- 4.11 Storage Objects Policies
DROP POLICY IF EXISTS "payment_proofs_super_admin_view_all" ON storage.objects;
CREATE POLICY "payment_proofs_super_admin_view_all" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'payment-proofs' AND
    app_private.is_super_admin()
  );

-- Drop old public helper functions from schema
DROP FUNCTION IF EXISTS public.has_role(uuid, role_type);
DROP FUNCTION IF EXISTS public.is_admin();
DROP FUNCTION IF EXISTS public.is_super_admin();

-- =============================================================================
-- 5. TABLE PRIVILEGE HARDENING (LEAST PRIVILEGE)
-- =============================================================================

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.wallets FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.point_batches FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.point_transactions FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.point_holds FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.point_hold_allocations FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, SELECT ON public.topup_requests FROM anon, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.topup_requests FROM authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.audit_logs FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.user_roles FROM anon, authenticated, public;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.subscriptions FROM anon, authenticated, public;

GRANT SELECT ON public.wallets TO authenticated;
GRANT SELECT ON public.point_batches TO authenticated;
GRANT SELECT ON public.point_transactions TO authenticated;
GRANT SELECT ON public.point_holds TO authenticated;
GRANT SELECT ON public.point_hold_allocations TO authenticated;
GRANT SELECT ON public.topup_requests TO authenticated;
GRANT SELECT ON public.audit_logs TO authenticated;
GRANT SELECT ON public.user_roles TO authenticated;
GRANT SELECT ON public.subscriptions TO authenticated;
GRANT SELECT ON public.subscription_plans TO authenticated, anon;
GRANT SELECT, UPDATE ON public.profiles TO authenticated;

-- =============================================================================
-- 6. AUDIT TRIGGER FOR SUBSCRIPTION PLANS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_subscription_plan_audit()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public, app_private
AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    INSERT INTO public.audit_logs (
      actor_user_id,
      actor_role,
      action,
      target_type,
      target_id,
      after_data
    ) VALUES (
      auth.uid(),
      'super_admin',
      'SUBSCRIPTION_PLAN_CREATED',
      'subscription_plans',
      NEW.id,
      to_jsonb(NEW)
    );
    RETURN NEW;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO public.audit_logs (
      actor_user_id,
      actor_role,
      action,
      target_type,
      target_id,
      before_data,
      after_data
    ) VALUES (
      auth.uid(),
      'super_admin',
      'SUBSCRIPTION_PLAN_UPDATED',
      'subscription_plans',
      NEW.id,
      to_jsonb(OLD),
      to_jsonb(NEW)
    );
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO public.audit_logs (
      actor_user_id,
      actor_role,
      action,
      target_type,
      target_id,
      before_data
    ) VALUES (
      auth.uid(),
      'super_admin',
      'SUBSCRIPTION_PLAN_DELETED',
      'subscription_plans',
      OLD.id,
      to_jsonb(OLD)
    );
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_subscription_plans_audit ON public.subscription_plans;
CREATE TRIGGER tr_subscription_plans_audit
  AFTER INSERT OR UPDATE OR DELETE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.handle_subscription_plan_audit();

REVOKE EXECUTE ON FUNCTION public.handle_subscription_plan_audit() FROM anon, authenticated, public;

-- =============================================================================
-- 7. REVISED & NEW STORED PROCEDURES (RPCS)
-- =============================================================================

-- 7.1 RPC: create_topup_request (With duplicate ref check & path ownership check)
CREATE OR REPLACE FUNCTION public.create_topup_request(
  p_requested_amount numeric,
  p_payment_method text,
  p_payment_reference text DEFAULT NULL,
  p_screenshot_path text DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid;
  v_request_id uuid;
  v_norm_ref text;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_requested_amount <= 0 THEN
    RAISE EXCEPTION 'Requested amount must be greater than zero';
  END IF;

  IF p_payment_method IS NULL OR length(trim(p_payment_method)) = 0 THEN
    RAISE EXCEPTION 'Payment method is required';
  END IF;

  -- Normalize payment reference
  IF p_payment_reference IS NOT NULL AND length(trim(p_payment_reference)) > 0 THEN
    v_norm_ref := lower(trim(p_payment_reference));
    
    -- Check for duplicate active or approved requests
    IF EXISTS (
      SELECT 1
      FROM public.topup_requests
      WHERE payment_method = p_payment_method
        AND lower(trim(payment_reference)) = v_norm_ref
        AND status IN ('pending', 'approved')
    ) THEN
      RAISE EXCEPTION 'A top-up request with this payment reference is already active or approved.';
    END IF;
  ELSE
    v_norm_ref := NULL;
  END IF;

  -- Validate screenshot path ownership if provided
  IF p_screenshot_path IS NOT NULL AND length(trim(p_screenshot_path)) > 0 THEN
    IF NOT (p_screenshot_path LIKE (v_user_id::text || '/%')) THEN
      RAISE EXCEPTION 'Invalid screenshot path: must belong to the authenticated user';
    END IF;
  END IF;

  INSERT INTO public.topup_requests (
    user_id,
    requested_amount,
    payment_method,
    payment_reference,
    screenshot_path,
    status
  ) VALUES (
    v_user_id,
    p_requested_amount,
    trim(p_payment_method),
    v_norm_ref,
    p_screenshot_path,
    'pending'
  ) RETURNING id INTO v_request_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    metadata
  ) VALUES (
    v_user_id,
    'passenger',
    'TOPUP_REQUEST_CREATED',
    'topup_requests',
    v_request_id,
    jsonb_build_object(
      'amount', p_requested_amount,
      'payment_method', p_payment_method,
      'payment_reference', v_norm_ref
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id
  );
END;
$$ LANGUAGE plpgsql;

-- 7.2 RPC: attach_topup_payment_proof (Validates exact path {user_id}/{request_id}/...)
CREATE OR REPLACE FUNCTION public.attach_topup_payment_proof(
  p_request_id uuid,
  p_screenshot_path text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid;
  v_expected_prefix text;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  v_expected_prefix := v_user_id::text || '/' || p_request_id::text || '/';

  IF NOT (p_screenshot_path LIKE (v_expected_prefix || '%')) THEN
    RAISE EXCEPTION 'Invalid screenshot path. Expected format: %<filename>', v_expected_prefix;
  END IF;

  UPDATE public.topup_requests
  SET screenshot_path = p_screenshot_path,
      updated_at = now()
  WHERE id = p_request_id
    AND user_id = v_user_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Top-up request not found or not in pending status';
  END IF;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    metadata
  ) VALUES (
    v_user_id,
    'passenger',
    'TOPUP_PROOF_ATTACHED',
    'topup_requests',
    p_request_id,
    jsonb_build_object('screenshot_path', p_screenshot_path)
  );

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

-- 7.3 RPC: admin_add_cash_points (Fix source_type to 'cash')
CREATE OR REPLACE FUNCTION public.admin_add_cash_points(
  p_target_user_id uuid,
  p_amount numeric,
  p_reason text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_wallet_id uuid;
  v_balance_before numeric;
  v_balance_after numeric;
  v_batch_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be greater than zero';
  END IF;

  SELECT id, cached_available_balance INTO v_wallet_id, v_balance_before
  FROM public.wallets
  WHERE user_id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target user wallet not found';
  END IF;

  v_balance_after := v_balance_before + p_amount;

  -- Create non-expiring cash point batch with source_type = 'cash' for spending compatibility
  INSERT INTO public.point_batches (
    user_id,
    source_type,
    original_amount,
    remaining_amount,
    expires_at,
    source_reference_type,
    description,
    created_by
  ) VALUES (
    p_target_user_id,
    'cash',
    p_amount,
    p_amount,
    NULL,
    'manual_adjustment',
    'Manual Cash Grant: ' || p_reason,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  INSERT INTO public.point_transactions (
    user_id,
    wallet_id,
    batch_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    reference_type,
    reference_id,
    description,
    actor_user_id,
    metadata
  ) VALUES (
    p_target_user_id,
    v_wallet_id,
    v_batch_id,
    'manual_adjustment',
    p_amount,
    v_balance_before,
    v_balance_after,
    'manual_grant',
    v_batch_id,
    p_reason,
    v_actor_id,
    jsonb_build_object('reason', p_reason, 'granted_by', v_actor_id)
  );

  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    after_data,
    metadata
  ) VALUES (
    v_actor_id,
    'super_admin',
    'MANUAL_POINTS_GRANTED',
    'wallets',
    v_wallet_id,
    jsonb_build_object('amount', p_amount, 'new_balance', v_balance_after),
    jsonb_build_object('target_user_id', p_target_user_id, 'reason', p_reason)
  );

  RETURN jsonb_build_object(
    'success', true,
    'target_user_id', p_target_user_id,
    'granted_amount', p_amount,
    'new_balance', v_balance_after
  );
END;
$$ LANGUAGE plpgsql;

-- 7.4 RPCs: assign_user_role & remove_user_role (Audited Super Admin management)
CREATE OR REPLACE FUNCTION public.assign_user_role(
  p_target_user_id uuid,
  p_role role_type
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_role_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  INSERT INTO public.user_roles (
    user_id,
    role,
    created_by
  ) VALUES (
    p_target_user_id,
    p_role,
    v_actor_id
  )
  ON CONFLICT (user_id, role) DO NOTHING
  RETURNING id INTO v_role_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    metadata
  ) VALUES (
    v_actor_id,
    'super_admin',
    'USER_ROLE_ASSIGNED',
    'user_roles',
    v_role_id,
    jsonb_build_object('target_user_id', p_target_user_id, 'role', p_role)
  );

  RETURN jsonb_build_object('success', true, 'assigned', v_role_id IS NOT NULL);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.remove_user_role(
  p_target_user_id uuid,
  p_role role_type
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  -- Prevent self-lockout from super_admin role
  IF p_target_user_id = v_actor_id AND p_role = 'super_admin' THEN
    RAISE EXCEPTION 'Action aborted: You cannot remove your own super_admin role';
  END IF;

  DELETE FROM public.user_roles
  WHERE user_id = p_target_user_id
    AND role = p_role;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    metadata
  ) VALUES (
    v_actor_id,
    'super_admin',
    'USER_ROLE_REMOVED',
    'user_roles',
    jsonb_build_object('target_user_id', p_target_user_id, 'role', p_role)
  );

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

-- 7.5 RPC: expire_point_batches (Hold-aware, idempotent expiration)
CREATE OR REPLACE FUNCTION public.expire_point_batches()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_batch RECORD;
  v_wallet RECORD;
  v_expired_count int := 0;
  v_total_points_expired numeric := 0;
  v_held_amount numeric := 0;
  v_expirable_amount numeric := 0;
  v_new_balance numeric;
BEGIN
  FOR v_batch IN
    SELECT pb.*
    FROM public.point_batches pb
    WHERE pb.expires_at IS NOT NULL
      AND pb.expires_at <= now()
      AND pb.remaining_amount > 0
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Calculate points in this batch currently reserved by active unexpired holds
    SELECT COALESCE(SUM(pha.amount), 0) INTO v_held_amount
    FROM public.point_hold_allocations pha
    JOIN public.point_holds ph ON ph.id = pha.hold_id
    WHERE pha.batch_id = v_batch.id
      AND ph.status = 'active'
      AND ph.expires_at > now();

    v_expirable_amount := GREATEST(0, v_batch.remaining_amount - v_held_amount);

    IF v_expirable_amount > 0 THEN
      SELECT * INTO v_wallet
      FROM public.wallets
      WHERE user_id = v_batch.user_id
      FOR UPDATE;

      IF FOUND THEN
        v_new_balance := GREATEST(0, v_wallet.cached_available_balance - v_expirable_amount);

        INSERT INTO public.point_transactions (
          user_id,
          wallet_id,
          batch_id,
          transaction_type,
          amount,
          balance_before,
          balance_after,
          reference_type,
          reference_id,
          description,
          metadata
        ) VALUES (
          v_batch.user_id,
          v_wallet.id,
          v_batch.id,
          'expire',
          v_expirable_amount,
          v_wallet.cached_available_balance,
          v_new_balance,
          'point_batches',
          v_batch.id,
          'Subscription Points expired',
          jsonb_build_object('expired_at', now(), 'held_amount_protected', v_held_amount)
        );

        UPDATE public.wallets
        SET cached_available_balance = v_new_balance,
            updated_at = now()
        WHERE id = v_wallet.id;

        UPDATE public.point_batches
        SET remaining_amount = remaining_amount - v_expirable_amount
        WHERE id = v_batch.id;

        -- If remaining is now 0, mark related subscription expired
        IF (v_batch.remaining_amount - v_expirable_amount) <= 0 THEN
          UPDATE public.subscriptions
          SET status = 'expired'
          WHERE point_batch_id = v_batch.id
            AND status = 'active';
        END IF;

        v_expired_count := v_expired_count + 1;
        v_total_points_expired := v_total_points_expired + v_expirable_amount;
      END IF;
    END IF;
  END LOOP;

  IF v_expired_count > 0 THEN
    INSERT INTO public.audit_logs (
      action,
      target_type,
      metadata
    ) VALUES (
      'POINTS_EXPIRED_BATCH_JOB',
      'point_batches',
      jsonb_build_object(
        'batches_expired', v_expired_count,
        'total_points', v_total_points_expired
      )
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'expired_batches_count', v_expired_count,
    'total_points_expired', v_total_points_expired
  );
END;
$$ LANGUAGE plpgsql;

-- 7.6 RPC: approve_topup_request (Updated to use app_private.is_super_admin)
CREATE OR REPLACE FUNCTION public.approve_topup_request(p_request_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_topup RECORD;
  v_wallet_id uuid;
  v_balance_before numeric;
  v_balance_after numeric;
  v_batch_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  SELECT * INTO v_topup
  FROM public.topup_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topup request not found';
  END IF;

  IF v_topup.status != 'pending' THEN
    RAISE EXCEPTION 'Topup request is already %', v_topup.status;
  END IF;

  SELECT id, cached_available_balance INTO v_wallet_id, v_balance_before
  FROM public.wallets
  WHERE user_id = v_topup.user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user %', v_topup.user_id;
  END IF;

  v_balance_after := v_balance_before + v_topup.requested_amount;

  INSERT INTO public.point_batches (
    user_id,
    source_type,
    original_amount,
    remaining_amount,
    expires_at,
    source_reference_type,
    source_reference_id,
    description,
    created_by
  ) VALUES (
    v_topup.user_id,
    'cash',
    v_topup.requested_amount,
    v_topup.requested_amount,
    NULL,
    'topup_requests',
    p_request_id,
    'Cash Point Top-up via ' || v_topup.payment_method,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  INSERT INTO public.point_transactions (
    user_id,
    wallet_id,
    batch_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    reference_type,
    reference_id,
    description,
    actor_user_id,
    metadata
  ) VALUES (
    v_topup.user_id,
    v_wallet_id,
    v_batch_id,
    'credit',
    v_topup.requested_amount,
    v_balance_before,
    v_balance_after,
    'topup_requests',
    p_request_id,
    'Approved top-up credit',
    v_actor_id,
    jsonb_build_object('payment_method', v_topup.payment_method)
  );

  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  UPDATE public.topup_requests
  SET status = 'approved',
      reviewed_by = v_actor_id,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_request_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    before_data,
    after_data,
    metadata
  ) VALUES (
    v_actor_id,
    'super_admin',
    'TOPUP_APPROVED',
    'topup_requests',
    p_request_id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'approved', 'amount', v_topup.requested_amount),
    jsonb_build_object('user_id', v_topup.user_id, 'batch_id', v_batch_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'credited_amount', v_topup.requested_amount,
    'new_balance', v_balance_after
  );
END;
$$ LANGUAGE plpgsql;

-- 7.7 RPC: reject_topup_request (Updated to use app_private.is_super_admin)
CREATE OR REPLACE FUNCTION public.reject_topup_request(
  p_request_id uuid,
  p_reason text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_topup RECORD;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  SELECT * INTO v_topup
  FROM public.topup_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topup request not found';
  END IF;

  IF v_topup.status != 'pending' THEN
    RAISE EXCEPTION 'Topup request is already %', v_topup.status;
  END IF;

  UPDATE public.topup_requests
  SET status = 'rejected',
      reviewed_by = v_actor_id,
      reviewed_at = now(),
      rejection_reason = p_reason,
      updated_at = now()
  WHERE id = p_request_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    before_data,
    after_data,
    metadata
  ) VALUES (
    v_actor_id,
    'super_admin',
    'TOPUP_REJECTED',
    'topup_requests',
    p_request_id,
    jsonb_build_object('status', 'pending'),
    jsonb_build_object('status', 'rejected', 'reason', p_reason),
    jsonb_build_object('user_id', v_topup.user_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'status', 'rejected'
  );
END;
$$ LANGUAGE plpgsql;

-- 7.8 RPC: create_user_subscription (Updated to use app_private.is_admin)
CREATE OR REPLACE FUNCTION public.create_user_subscription(
  p_target_user_id uuid,
  p_plan_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_plan RECORD;
  v_wallet_id uuid;
  v_balance_before numeric;
  v_balance_after numeric;
  v_starts_at timestamptz;
  v_expires_at timestamptz;
  v_batch_id uuid;
  v_sub_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = p_plan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription plan not found';
  END IF;

  IF NOT v_plan.is_active THEN
    RAISE EXCEPTION 'Subscription plan is currently inactive';
  END IF;

  SELECT id, cached_available_balance INTO v_wallet_id, v_balance_before
  FROM public.wallets
  WHERE user_id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Target user wallet not found';
  END IF;

  v_starts_at := now();
  v_expires_at := v_starts_at + (v_plan.duration_days || ' days')::interval;
  v_balance_after := v_balance_before + v_plan.points_amount;

  INSERT INTO public.point_batches (
    user_id,
    source_type,
    original_amount,
    remaining_amount,
    expires_at,
    source_reference_type,
    source_reference_id,
    description,
    created_by
  ) VALUES (
    p_target_user_id,
    'subscription',
    v_plan.points_amount,
    v_plan.points_amount,
    v_expires_at,
    'subscription_plans',
    p_plan_id,
    'Subscription Points for ' || v_plan.name,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  INSERT INTO public.subscriptions (
    user_id,
    plan_id,
    status,
    starts_at,
    expires_at,
    point_batch_id,
    created_by
  ) VALUES (
    p_target_user_id,
    p_plan_id,
    'active',
    v_starts_at,
    v_expires_at,
    v_batch_id,
    v_actor_id
  ) RETURNING id INTO v_sub_id;

  INSERT INTO public.point_transactions (
    user_id,
    wallet_id,
    batch_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    reference_type,
    reference_id,
    description,
    actor_user_id,
    metadata
  ) VALUES (
    p_target_user_id,
    v_wallet_id,
    v_batch_id,
    'credit',
    v_plan.points_amount,
    v_balance_before,
    v_balance_after,
    'subscriptions',
    v_sub_id,
    'Subscription activation credit',
    v_actor_id,
    jsonb_build_object('plan_name', v_plan.name, 'duration_days', v_plan.duration_days)
  );

  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    after_data,
    metadata
  ) VALUES (
    v_actor_id,
    'admin',
    'SUBSCRIPTION_CREATED',
    'subscriptions',
    v_sub_id,
    jsonb_build_object(
      'plan_id', p_plan_id,
      'points', v_plan.points_amount,
      'expires_at', v_expires_at
    ),
    jsonb_build_object('target_user_id', p_target_user_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'subscription_id', v_sub_id,
    'credited_points', v_plan.points_amount,
    'expires_at', v_expires_at
  );
END;
$$ LANGUAGE plpgsql;

-- 7.9 Permissions for all newly updated/created RPCs
REVOKE EXECUTE ON FUNCTION public.create_topup_request(numeric, text, text, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.create_topup_request(numeric, text, text, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.attach_topup_payment_proof(uuid, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.attach_topup_payment_proof(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.admin_add_cash_points(uuid, numeric, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.admin_add_cash_points(uuid, numeric, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.assign_user_role(uuid, role_type) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.assign_user_role(uuid, role_type) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.remove_user_role(uuid, role_type) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.remove_user_role(uuid, role_type) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.approve_topup_request(uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.approve_topup_request(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.reject_topup_request(uuid, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.reject_topup_request(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.create_user_subscription(uuid, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.create_user_subscription(uuid, uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.expire_point_batches() FROM anon, public, authenticated;
GRANT EXECUTE ON FUNCTION public.expire_point_batches() TO service_role, postgres;

-- =============================================================================
-- 8. PG_CRON SCHEDULE FOR EXPIRE_POINT_BATCHES
-- =============================================================================

DO $$ BEGIN
  -- Unschedule previous job if registered
  PERFORM cron.unschedule('expire-subscription-points-hourly');
EXCEPTION WHEN others THEN null;
END $$;

DO $$ BEGIN
  PERFORM cron.schedule(
    'expire-subscription-points-hourly',
    '0 * * * *',
    'SELECT public.expire_point_batches();'
  );
EXCEPTION WHEN others THEN null;
END $$;
