-- Migration: 20260914170000_user_device_tokens_and_notifications.sql
-- Description: Phase 1 notification foundation - user_device_tokens and notifications inbox tables with strict RLS and RPCs.

-- ============================================================================
-- 1. USER DEVICE TOKENS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  installation_id text,
  device_name text,
  app_version text,
  is_active boolean NOT NULL DEFAULT true,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_device_tokens_token UNIQUE (token)
);

CREATE INDEX IF NOT EXISTS idx_user_device_tokens_user_id ON public.user_device_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_active ON public.user_device_tokens(is_active);
CREATE INDEX IF NOT EXISTS idx_user_device_tokens_last_seen ON public.user_device_tokens(last_seen_at);

ALTER TABLE public.user_device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_read_own_device_tokens ON public.user_device_tokens;
CREATE POLICY user_read_own_device_tokens ON public.user_device_tokens
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_insert_own_device_tokens ON public.user_device_tokens;
CREATE POLICY user_insert_own_device_tokens ON public.user_device_tokens
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_update_own_device_tokens ON public.user_device_tokens;
CREATE POLICY user_update_own_device_tokens ON public.user_device_tokens
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_delete_own_device_tokens ON public.user_device_tokens;
CREATE POLICY user_delete_own_device_tokens ON public.user_device_tokens
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Secure RPC to register or reassign a device token on login/token refresh
CREATE OR REPLACE FUNCTION public.register_device_token(
  p_token text,
  p_platform text,
  p_installation_id text DEFAULT NULL,
  p_device_name text DEFAULT NULL,
  p_app_version text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_token_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_platform NOT IN ('android', 'ios') THEN
    RAISE EXCEPTION 'Invalid platform: %', p_platform;
  END IF;

  IF p_token IS NULL OR trim(p_token) = '' THEN
    RAISE EXCEPTION 'Token cannot be empty';
  END IF;

  -- Upsert: if token exists on any user (e.g. phone handed over / relogin),
  -- reassign to current authenticated user and reactivate.
  INSERT INTO public.user_device_tokens (
    user_id,
    token,
    platform,
    installation_id,
    device_name,
    app_version,
    is_active,
    last_seen_at,
    updated_at
  )
  VALUES (
    v_user_id,
    trim(p_token),
    p_platform,
    p_installation_id,
    p_device_name,
    p_app_version,
    true,
    now(),
    now()
  )
  ON CONFLICT (token) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = EXCLUDED.platform,
    installation_id = COALESCE(EXCLUDED.installation_id, user_device_tokens.installation_id),
    device_name = COALESCE(EXCLUDED.device_name, user_device_tokens.device_name),
    app_version = COALESCE(EXCLUDED.app_version, user_device_tokens.app_version),
    is_active = true,
    last_seen_at = now(),
    updated_at = now()
  RETURNING id INTO v_token_id;

  RETURN v_token_id;
END;
$$;

-- Secure RPC to deactivate a device token on logout
CREATE OR REPLACE FUNCTION public.deactivate_device_token(
  p_token text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  UPDATE public.user_device_tokens
  SET is_active = false,
      updated_at = now()
  WHERE token = trim(p_token)
    AND user_id = v_user_id;

  RETURN FOUND;
END;
$$;


-- ============================================================================
-- 2. NOTIFICATIONS INBOX TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL,
  title_ar text NOT NULL,
  body_ar text NOT NULL,
  title_en text NOT NULL,
  body_en text NOT NULL,
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  entity_type text,
  entity_id uuid,
  dedupe_key text,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, read_at);
CREATE UNIQUE INDEX IF NOT EXISTS uq_notifications_user_dedupe ON public.notifications(user_id, dedupe_key) WHERE dedupe_key IS NOT NULL;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Passengers can only SELECT their own notifications
DROP POLICY IF EXISTS user_read_own_notifications ON public.notifications;
CREATE POLICY user_read_own_notifications ON public.notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Passengers can ONLY update the read_at column of their own notifications
DROP POLICY IF EXISTS user_update_own_notifications_read ON public.notifications;
CREATE POLICY user_update_own_notifications_read ON public.notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- NO insert or delete policy for authenticated role: insertions are service_role / backend authoritative only.

-- Secure RPC to mark a notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_as_read(
  p_notification_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.notifications
  SET read_at = COALESCE(read_at, now())
  WHERE id = p_notification_id
    AND user_id = v_user_id;

  RETURN FOUND;
END;
$$;

-- Secure RPC to mark all notifications as read
CREATE OR REPLACE FUNCTION public.mark_all_notifications_as_read()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_count integer;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.notifications
  SET read_at = now()
  WHERE user_id = v_user_id
    AND read_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- Secure RPC to get count of unread notifications
CREATE OR REPLACE FUNCTION public.get_unread_notifications_count()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_count integer;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COUNT(*)::integer INTO v_count
  FROM public.notifications
  WHERE user_id = v_user_id
    AND read_at IS NULL;

  RETURN COALESCE(v_count, 0);
END;
$$;
