-- Migration: 20260915030000_fix_profiles_rls_recursion.sql
-- Description: Fix infinite recursion in public.profiles UPDATE RLS policy.
-- Previous policy queried public.profiles inside the WITH CHECK clause to enforce column immutability.
-- Replaced with non-recursive RLS policy using authoritative app_private.is_admin() and auth.uid(),
-- and enforces immutable column protection (id, email, created_at, is_active) via a BEFORE UPDATE trigger.

-- 1. Drop existing recursive update policy
DROP POLICY IF EXISTS "profiles_update_unified" ON public.profiles;

-- 2. Create non-recursive unified update policy for profiles
-- Passengers can only update their own row; admins can update any row
CREATE POLICY "profiles_update_unified" ON public.profiles
  FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id OR app_private.is_admin())
  WITH CHECK ((select auth.uid()) = id OR app_private.is_admin());

-- 3. Trigger to enforce immutability of protected columns without RLS recursion
CREATE OR REPLACE FUNCTION public.protect_profiles_immutable_columns()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- If executed by admin or super_admin, allow updates
  IF NOT app_private.is_admin() THEN
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'Cannot modify immutable column: id'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.email IS DISTINCT FROM OLD.email THEN
      RAISE EXCEPTION 'Cannot modify immutable column: email'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
      RAISE EXCEPTION 'Cannot modify immutable column: created_at'
        USING ERRCODE = '42501';
    END IF;
    IF NEW.is_active IS DISTINCT FROM OLD.is_active THEN
      RAISE EXCEPTION 'Cannot modify immutable column: is_active'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_profiles_protect_immutable ON public.profiles;
CREATE TRIGGER tr_profiles_protect_immutable
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profiles_immutable_columns();

-- Ensure permissions remain intact
GRANT SELECT, UPDATE ON public.profiles TO authenticated;
