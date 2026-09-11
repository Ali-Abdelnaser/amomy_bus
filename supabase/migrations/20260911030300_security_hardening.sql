-- Migration: 20260911030300_security_hardening.sql
-- Description: Apply search_path fix to handle_updated_at and revoke execute permissions
--              from anon and public for SECURITY DEFINER functions.

-- 1. Fix search_path on handle_updated_at
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Revoke execute on trigger functions from all external clients
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.handle_updated_at() FROM public, anon, authenticated;

-- 3. Revoke execute from anon on all business RPCs (only authenticated or service_role)
REVOKE EXECUTE ON FUNCTION public.create_topup_request(numeric, text, text, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.create_topup_request(numeric, text, text, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.approve_topup_request(uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.approve_topup_request(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.reject_topup_request(uuid, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.reject_topup_request(uuid, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.admin_add_cash_points(uuid, numeric, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.admin_add_cash_points(uuid, numeric, text) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.create_user_subscription(uuid, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.create_user_subscription(uuid, uuid) TO authenticated;

-- 4. Expiration job (only callable by background service / cron / postgres)
REVOKE EXECUTE ON FUNCTION public.expire_point_batches() FROM anon, public;
GRANT EXECUTE ON FUNCTION public.expire_point_batches() TO service_role, postgres;
