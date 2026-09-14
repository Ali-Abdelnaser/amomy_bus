-- Migration: 20260914200000_notification_preferences.sql
-- Description: Creates notification_preferences table for per-passenger category push settings.

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  all_enabled boolean NOT NULL DEFAULT true,
  service_updates boolean NOT NULL DEFAULT true,
  booking_updates boolean NOT NULL DEFAULT true,
  wallet_updates boolean NOT NULL DEFAULT true,
  trip_updates boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON public.notification_preferences(user_id);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_read_own_notification_preferences ON public.notification_preferences;
CREATE POLICY user_read_own_notification_preferences ON public.notification_preferences
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_insert_own_notification_preferences ON public.notification_preferences;
CREATE POLICY user_insert_own_notification_preferences ON public.notification_preferences
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_update_own_notification_preferences ON public.notification_preferences;
CREATE POLICY user_update_own_notification_preferences ON public.notification_preferences
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Helper RPC: get or lazily create preferences for authenticated passenger
CREATE OR REPLACE FUNCTION public.get_or_create_notification_preferences()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_prefs record;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_prefs FROM public.notification_preferences WHERE user_id = v_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.notification_preferences (
      user_id,
      all_enabled,
      service_updates,
      booking_updates,
      wallet_updates,
      trip_updates
    )
    VALUES (
      v_user_id,
      true,
      true,
      true,
      true,
      true
    )
    RETURNING * INTO v_prefs;
  END IF;

  RETURN to_jsonb(v_prefs);
END;
$$;

-- Helper RPC: update preferences for authenticated passenger
CREATE OR REPLACE FUNCTION public.update_notification_preferences(
  p_all_enabled boolean,
  p_service_updates boolean,
  p_booking_updates boolean,
  p_wallet_updates boolean,
  p_trip_updates boolean
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid;
  v_prefs record;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.notification_preferences (
    user_id,
    all_enabled,
    service_updates,
    booking_updates,
    wallet_updates,
    trip_updates,
    updated_at
  )
  VALUES (
    v_user_id,
    COALESCE(p_all_enabled, true),
    COALESCE(p_service_updates, true),
    COALESCE(p_booking_updates, true),
    COALESCE(p_wallet_updates, true),
    COALESCE(p_trip_updates, true),
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    all_enabled = COALESCE(EXCLUDED.all_enabled, public.notification_preferences.all_enabled),
    service_updates = COALESCE(EXCLUDED.service_updates, public.notification_preferences.service_updates),
    booking_updates = COALESCE(EXCLUDED.booking_updates, public.notification_preferences.booking_updates),
    wallet_updates = COALESCE(EXCLUDED.wallet_updates, public.notification_preferences.wallet_updates),
    trip_updates = COALESCE(EXCLUDED.trip_updates, public.notification_preferences.trip_updates),
    updated_at = now()
  RETURNING * INTO v_prefs;

  RETURN to_jsonb(v_prefs);
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_notification_preferences() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_notification_preferences(boolean, boolean, boolean, boolean, boolean) TO authenticated;
