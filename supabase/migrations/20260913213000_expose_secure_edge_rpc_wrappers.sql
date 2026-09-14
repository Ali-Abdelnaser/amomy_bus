-- Migration: 20260913213000_expose_secure_edge_rpc_wrappers.sql
-- Exposes secure RPC endpoints in public schema for Supabase Edge Functions with strict service_role gating.

-- 1. Secure Vault Credentials Reader for Edge Function
CREATE OR REPLACE FUNCTION public.get_etrack_credentials()
RETURNS TABLE (
  account text,
  password text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private, vault
AS $$
BEGIN
  -- Strict guard: service_role or postgres superuser only
  IF auth.role() <> 'service_role' AND current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Access denied: service_role required';
  END IF;

  RETURN QUERY SELECT * FROM app_private.get_etrack_credentials();
END;
$$;

REVOKE ALL ON FUNCTION public.get_etrack_credentials() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_etrack_credentials() TO service_role;

-- 2. Sync Health Recorder for Edge Function
CREATE OR REPLACE FUNCTION public.record_sync_health(
  p_success boolean,
  p_devices integer,
  p_error_code text,
  p_error_message text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
BEGIN
  -- Strict guard: service_role or postgres superuser only
  IF auth.role() <> 'service_role' AND current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Access denied: service_role required';
  END IF;

  PERFORM app_private.record_sync_health(p_success, p_devices, p_error_code, p_error_message);
END;
$$;

REVOKE ALL ON FUNCTION public.record_sync_health(boolean, integer, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.record_sync_health(boolean, integer, text, text) TO service_role;

-- 3. Authoritative Progression Evaluator wrapper
CREATE OR REPLACE FUNCTION public.compute_bus_progression(p_bus_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
BEGIN
  RETURN app_private.compute_bus_progression(p_bus_id);
END;
$$;

REVOKE ALL ON FUNCTION public.compute_bus_progression(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.compute_bus_progression(uuid) TO authenticated, service_role;
