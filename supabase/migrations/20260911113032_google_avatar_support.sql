-- ==============================================================================
-- Migration: 20260911143000_google_avatar_support.sql
-- Description: Update handle_new_user() trigger function to fall back to Google's
--              'picture' metadata field for avatar_url when 'avatar_url' is not set.
-- Security: Preserves SECURITY DEFINER, search_path=public, and REVOKE on EXECUTE.
-- Financial: Zero modification to wallet creation or balances.
-- Roles: Retains strict assignment of default passenger role only.
-- Audit: Preserves USER_REGISTERED audit log entry.
-- ==============================================================================

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
  v_avatar_url text;
BEGIN
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

  -- Support standard Supabase avatar_url and Google OAuth picture
  v_avatar_url := COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture'
  );

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
    v_avatar_url,
    true
  ) ON CONFLICT (id) DO UPDATE SET
    avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url);

  -- 2. Create Initial Wallet (Untouched financial logic)
  INSERT INTO public.wallets (
    user_id,
    cached_available_balance,
    cached_held_balance
  ) VALUES (
    NEW.id,
    0,
    0
  ) ON CONFLICT (user_id) DO NOTHING;

  -- 3. Assign Default Passenger Role (Zero trust of metadata for roles)
  INSERT INTO public.user_roles (
    user_id,
    role
  ) VALUES (
    NEW.id,
    'passenger'
  ) ON CONFLICT (user_id, role) DO NOTHING;

  -- 4. Registration Audit Log Entry
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

-- Re-enforce security restriction on handle_new_user
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM public, anon, authenticated;
