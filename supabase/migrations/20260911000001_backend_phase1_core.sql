-- Migration: 20260911000001_backend_phase1_core.sql
-- Description: Backend Phase 1: Core User/Roles Schema, Points Wallet Architecture,
--              Recharge Requests, Subscriptions, RLS, Audit Logging, and Stored Procedures.

-- =============================================================================
-- 1. ENUMS & EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$ BEGIN
  CREATE TYPE role_type AS ENUM ('passenger', 'staff', 'admin', 'super_admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE point_source_type AS ENUM ('cash', 'subscription', 'promo', 'refund', 'manual_adjustment');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE recharge_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE point_transaction_type AS ENUM ('credit', 'debit', 'hold', 'release', 'expire', 'refund', 'manual_adjustment');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE subscription_status AS ENUM ('active', 'expired', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- =============================================================================
-- 2. CORE TABLES
-- =============================================================================

-- 2.1 Profiles Table (Linked to auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  email text NOT NULL,
  phone text,
  gender text CHECK (gender IS NULL OR gender IN ('male', 'female')),
  date_of_birth date,
  avatar_url text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.2 User Roles Table
CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role role_type NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES public.profiles(id),
  CONSTRAINT uq_user_role UNIQUE (user_id, role)
);

-- 2.3 Wallets Table (Cached summary, NOT financial ground truth)
CREATE TABLE IF NOT EXISTS public.wallets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cached_available_balance numeric NOT NULL DEFAULT 0 CHECK (cached_available_balance >= 0),
  cached_held_balance numeric NOT NULL DEFAULT 0 CHECK (cached_held_balance >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.4 Point Batches Table (Source of truth for points & expiration)
CREATE TABLE IF NOT EXISTS public.point_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  source_type point_source_type NOT NULL,
  original_amount numeric NOT NULL CHECK (original_amount > 0),
  remaining_amount numeric NOT NULL CHECK (remaining_amount >= 0),
  expires_at timestamptz,
  source_reference_type text,
  source_reference_id uuid,
  description text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2.5 Point Transactions Table (Append-only immutable financial ledger)
CREATE TABLE IF NOT EXISTS public.point_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  wallet_id uuid NOT NULL REFERENCES public.wallets(id),
  batch_id uuid REFERENCES public.point_batches(id),
  transaction_type point_transaction_type NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0),
  balance_before numeric,
  balance_after numeric,
  reference_type text,
  reference_id uuid,
  description text,
  actor_user_id uuid REFERENCES public.profiles(id),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2.6 Point Holds Table (Pre-allocation during 5-minute seat reservation)
CREATE TABLE IF NOT EXISTS public.point_holds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  amount numeric NOT NULL CHECK (amount > 0),
  reference_type text NOT NULL,
  reference_id uuid,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released', 'consumed')),
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  released_at timestamptz,
  consumed_at timestamptz
);

-- 2.7 Top-up Requests Table (Cash points manual recharge)
CREATE TABLE IF NOT EXISTS public.topup_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  requested_amount numeric NOT NULL CHECK (requested_amount > 0),
  payment_method text NOT NULL,
  payment_reference text,
  screenshot_path text,
  status recharge_status NOT NULL DEFAULT 'pending',
  reviewed_by uuid REFERENCES public.profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.8 Subscription Plans Table
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  price_egp numeric NOT NULL CHECK (price_egp >= 0),
  points_amount numeric NOT NULL CHECK (points_amount > 0),
  duration_days integer NOT NULL CHECK (duration_days > 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.9 Subscriptions Table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  plan_id uuid NOT NULL REFERENCES public.subscription_plans(id),
  status subscription_status NOT NULL,
  starts_at timestamptz NOT NULL,
  expires_at timestamptz NOT NULL,
  point_batch_id uuid REFERENCES public.point_batches(id),
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2.10 Audit Logs Table (Immutable audit trail)
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id uuid REFERENCES public.profiles(id),
  actor_role text,
  action text NOT NULL,
  target_type text,
  target_id uuid,
  before_data jsonb,
  after_data jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- 3. TRIGGERS & AUTOMATION
-- =============================================================================

-- 3.1 Updated_at Helper Trigger Function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_profiles_updated_at ON public.profiles;
CREATE TRIGGER tr_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_wallets_updated_at ON public.wallets;
CREATE TRIGGER tr_wallets_updated_at
  BEFORE UPDATE ON public.wallets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_topup_requests_updated_at ON public.topup_requests;
CREATE TRIGGER tr_topup_requests_updated_at
  BEFORE UPDATE ON public.topup_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER tr_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 3.2 New Auth User Creation Trigger Function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_full_name text;
  v_phone text;
  v_gender text;
  v_dob_str text;
  v_dob date;
BEGIN
  -- Safe extraction of optional metadata
  v_full_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );
  
  v_phone := COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone');
  
  v_gender := NEW.raw_user_meta_data->>'gender';
  IF v_gender NOT IN ('male', 'female') THEN
    v_gender := NULL;
  END IF;

  v_dob_str := NEW.raw_user_meta_data->>'date_of_birth';
  IF v_dob_str IS NOT NULL THEN
    BEGIN
      v_dob := v_dob_str::date;
    EXCEPTION WHEN others THEN
      v_dob := NULL;
    END;
  END IF;

  -- 1. Create Profile
  INSERT INTO public.profiles (
    id,
    full_name,
    email,
    phone,
    gender,
    date_of_birth,
    avatar_url,
    is_active
  ) VALUES (
    NEW.id,
    v_full_name,
    COALESCE(NEW.email, ''),
    v_phone,
    v_gender,
    v_dob,
    NEW.raw_user_meta_data->>'avatar_url',
    true
  ) ON CONFLICT (id) DO NOTHING;

  -- 2. Create Initial Wallet
  INSERT INTO public.wallets (
    user_id,
    cached_available_balance,
    cached_held_balance
  ) VALUES (
    NEW.id,
    0,
    0
  ) ON CONFLICT (user_id) DO NOTHING;

  -- 3. Assign Default Passenger Role
  INSERT INTO public.user_roles (
    user_id,
    role
  ) VALUES (
    NEW.id,
    'passenger'
  ) ON CONFLICT (user_id, role) DO NOTHING;

  -- 4. Record Audit Log Entry
  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    metadata
  ) VALUES (
    NEW.id,
    'passenger',
    'USER_REGISTERED',
    'profiles',
    NEW.id,
    jsonb_build_object('email', NEW.email)
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 4. SECURITY & ROLE HELPER FUNCTIONS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.has_role(p_user_id uuid, p_role role_type)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = p_user_id
      AND role = p_role
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN (
    public.has_role(auth.uid(), 'admin') OR
    public.has_role(auth.uid(), 'super_admin')
  );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
BEGIN
  RETURN public.has_role(auth.uid(), 'super_admin');
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.point_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.topup_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- 5.1 Profiles Policies
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    -- Prevent passenger from modifying sensitive operational fields
    is_active = (SELECT p.is_active FROM public.profiles p WHERE p.id = auth.uid())
  );

CREATE POLICY "profiles_admin_update" ON public.profiles
  FOR UPDATE USING (public.is_admin());

-- 5.2 User Roles Policies
CREATE POLICY "user_roles_select_own_or_admin" ON public.user_roles
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "user_roles_super_admin_manage" ON public.user_roles
  FOR ALL USING (public.is_super_admin());

-- 5.3 Wallets Policies (Read only for users; updates strictly via backend RPCs)
CREATE POLICY "wallets_select_own_or_admin" ON public.wallets
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- 5.4 Point Batches Policies
CREATE POLICY "point_batches_select_own_or_admin" ON public.point_batches
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- 5.5 Point Transactions Policies
CREATE POLICY "point_transactions_select_own_or_admin" ON public.point_transactions
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- 5.6 Point Holds Policies
CREATE POLICY "point_holds_select_own_or_admin" ON public.point_holds
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- 5.7 Topup Requests Policies
CREATE POLICY "topup_requests_select_own_or_super_admin" ON public.topup_requests
  FOR SELECT USING (auth.uid() = user_id OR public.is_super_admin());

CREATE POLICY "topup_requests_insert_own" ON public.topup_requests
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    status = 'pending'
  );

-- 5.8 Subscription Plans Policies
CREATE POLICY "subscription_plans_read_active" ON public.subscription_plans
  FOR SELECT USING (is_active = true OR public.is_admin());

CREATE POLICY "subscription_plans_super_admin_all" ON public.subscription_plans
  FOR ALL USING (public.is_super_admin());

-- 5.9 Subscriptions Policies
CREATE POLICY "subscriptions_select_own_or_admin" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id OR public.is_admin());

-- 5.10 Audit Logs Policies (Super Admin read only; append via internal functions)
CREATE POLICY "audit_logs_select_super_admin" ON public.audit_logs
  FOR SELECT USING (public.is_super_admin());

-- =============================================================================
-- 6. INDEXES
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles (email);
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON public.profiles (phone);

CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON public.user_roles (user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles (role);

CREATE INDEX IF NOT EXISTS idx_point_batches_user_id ON public.point_batches (user_id);
CREATE INDEX IF NOT EXISTS idx_point_batches_user_expires ON public.point_batches (user_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_point_batches_source_type ON public.point_batches (user_id, source_type);

CREATE INDEX IF NOT EXISTS idx_point_transactions_user_created ON public.point_transactions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_point_transactions_wallet ON public.point_transactions (wallet_id);

CREATE INDEX IF NOT EXISTS idx_point_holds_user_status ON public.point_holds (user_id, status);
CREATE INDEX IF NOT EXISTS idx_point_holds_expires_at ON public.point_holds (expires_at) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_topup_requests_user_status ON public.topup_requests (user_id, status);
CREATE INDEX IF NOT EXISTS idx_topup_requests_status_created ON public.topup_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON public.subscriptions (user_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires_at ON public.subscriptions (expires_at) WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_created ON public.audit_logs (actor_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target ON public.audit_logs (target_type, target_id);

-- =============================================================================
-- 7. STORED PROCEDURES & ATOMIC BUSINESS RPCS
-- =============================================================================

-- 7.1 RPC: Create Topup Request (Ensures client uses auth.uid())
CREATE OR REPLACE FUNCTION public.create_topup_request(
  p_requested_amount numeric,
  p_payment_method text,
  p_payment_reference text DEFAULT NULL,
  p_screenshot_path text DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid;
  v_request_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_requested_amount <= 0 THEN
    RAISE EXCEPTION 'Requested amount must be greater than zero';
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
    p_payment_method,
    p_payment_reference,
    p_screenshot_path,
    'pending'
  ) RETURNING id INTO v_request_id;

  -- Record in audit log
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
      'payment_method', p_payment_method
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id
  );
END;
$$ LANGUAGE plpgsql;

-- 7.2 RPC: Approve Topup Request (Super Admin Only, Atomic)
CREATE OR REPLACE FUNCTION public.approve_topup_request(p_request_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
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
  IF v_actor_id IS NULL OR NOT public.is_super_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Super Admin access required';
  END IF;

  -- 1. Lock and validate topup request
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

  -- 2. Lock user wallet
  SELECT id, cached_available_balance INTO v_wallet_id, v_balance_before
  FROM public.wallets
  WHERE user_id = v_topup.user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user %', v_topup.user_id;
  END IF;

  v_balance_after := v_balance_before + v_topup.requested_amount;

  -- 3. Create non-expiring Cash Point Batch
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
    NULL, -- Cash points do not expire
    'topup_requests',
    p_request_id,
    'Cash Point Top-up via ' || v_topup.payment_method,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  -- 4. Create immutable Ledger Transaction
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

  -- 5. Update cached wallet balance
  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- 6. Mark topup request as approved
  UPDATE public.topup_requests
  SET status = 'approved',
      reviewed_by = v_actor_id,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_request_id;

  -- 7. Audit log entry
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

-- 7.3 RPC: Reject Topup Request (Super Admin Only)
CREATE OR REPLACE FUNCTION public.reject_topup_request(
  p_request_id uuid,
  p_reason text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid;
  v_topup RECORD;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT public.is_super_admin() THEN
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

  -- Audit log
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

-- 7.4 RPC: Admin Add Cash Points (Super Admin Only, Manual adjustment)
CREATE OR REPLACE FUNCTION public.admin_add_cash_points(
  p_target_user_id uuid,
  p_amount numeric,
  p_reason text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor_id uuid;
  v_wallet_id uuid;
  v_balance_before numeric;
  v_balance_after numeric;
  v_batch_id uuid;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT public.is_super_admin() THEN
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

  -- Create non-expiring cash point batch
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
    'manual_adjustment',
    p_amount,
    p_amount,
    NULL,
    'admin_manual_grant',
    p_reason,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  -- Create ledger transaction
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
    jsonb_build_object('reason', p_reason)
  );

  -- Update wallet cache
  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- Audit log
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

-- 7.5 RPC: Create User Subscription (Admin/Super Admin Only, Atomic)
CREATE OR REPLACE FUNCTION public.create_user_subscription(
  p_target_user_id uuid,
  p_plan_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
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
  IF v_actor_id IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  -- 1. Validate plan
  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = p_plan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription plan not found';
  END IF;

  IF NOT v_plan.is_active THEN
    RAISE EXCEPTION 'Subscription plan is currently inactive';
  END IF;

  -- 2. Lock target user wallet
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

  -- 3. Create Subscription Points Batch (with mandatory expiry)
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

  -- 4. Create Subscription Record
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

  -- 5. Create Ledger Transaction
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

  -- 6. Update cached wallet balance
  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- 7. Audit log entry
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

-- 7.6 Server-side Batch Expiration Function (Idempotent, safe for pg_cron)
CREATE OR REPLACE FUNCTION public.expire_point_batches()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_batch RECORD;
  v_wallet RECORD;
  v_expired_count int := 0;
  v_total_points_expired numeric := 0;
  v_new_balance numeric;
BEGIN
  -- Iterate through active point batches past their expiration date with remaining points
  FOR v_batch IN
    SELECT pb.*
    FROM public.point_batches pb
    WHERE pb.expires_at IS NOT NULL
      AND pb.expires_at <= now()
      AND pb.remaining_amount > 0
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Lock wallet of user
    SELECT * INTO v_wallet
    FROM public.wallets
    WHERE user_id = v_batch.user_id
    FOR UPDATE;

    IF FOUND THEN
      v_new_balance := GREATEST(0, v_wallet.cached_available_balance - v_batch.remaining_amount);

      -- 1. Create expire ledger transaction
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
        v_batch.remaining_amount,
        v_wallet.cached_available_balance,
        v_new_balance,
        'point_batches',
        v_batch.id,
        'Subscription Points expired',
        jsonb_build_object('expired_at', now(), 'batch_type', v_batch.source_type)
      );

      -- 2. Update wallet cached balance
      UPDATE public.wallets
      SET cached_available_balance = v_new_balance,
          updated_at = now()
      WHERE id = v_wallet.id;

      -- 3. Mark batch remaining as 0
      UPDATE public.point_batches
      SET remaining_amount = 0
      WHERE id = v_batch.id;

      -- 4. Expire related subscription if tied
      UPDATE public.subscriptions
      SET status = 'expired'
      WHERE point_batch_id = v_batch.id
        AND status = 'active';

      v_expired_count := v_expired_count + 1;
      v_total_points_expired := v_total_points_expired + v_batch.remaining_amount;
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

-- =============================================================================
-- 8. STORAGE BUCKET: payment-proofs
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'payment-proofs',
  'payment-proofs',
  false,
  10485760, -- 10 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic'];

-- Storage RLS: Users upload only to their own folder: {user_id}/{topup_request_id}/{filename}
DO $$ BEGIN
  CREATE POLICY "payment_proofs_user_upload" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'payment-proofs' AND
      auth.uid() IS NOT NULL AND
      (storage.foldername(name))[1] = (auth.uid())::text
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "payment_proofs_user_view_own" ON storage.objects
    FOR SELECT USING (
      bucket_id = 'payment-proofs' AND
      auth.uid() IS NOT NULL AND
      (storage.foldername(name))[1] = (auth.uid())::text
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE POLICY "payment_proofs_super_admin_view_all" ON storage.objects
    FOR SELECT USING (
      bucket_id = 'payment-proofs' AND
      public.is_super_admin()
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;
