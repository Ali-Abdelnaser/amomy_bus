-- Migration: 20260911030400_revoke_anon_helpers.sql
-- Description: Revoke anon execution from role helpers and restrict expire_point_batches to service_role/postgres.

REVOKE EXECUTE ON FUNCTION public.has_role(uuid, role_type) FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
REVOKE EXECUTE ON FUNCTION public.is_super_admin() FROM anon;

REVOKE EXECUTE ON FUNCTION public.expire_point_batches() FROM authenticated;
