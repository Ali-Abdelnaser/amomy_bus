-- =============================================================================
-- Migration: 20260911180000_topup_payment_methods_hardening.sql
-- Description: Add payment_methods table, harden attach_topup_payment_proof with
--              storage verification, and provide passenger top-up helper RPCs.
-- =============================================================================

-- 1. Create payment_methods configuration table
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  name_ar text NOT NULL,
  name_en text NOT NULL,
  account_identifier text NOT NULL,
  instructions_ar text NOT NULL,
  instructions_en text NOT NULL,
  icon_key text NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Trigger to update updated_at on payment_methods
CREATE OR REPLACE FUNCTION public.set_payment_methods_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_payment_methods_updated_at ON public.payment_methods;
CREATE TRIGGER tr_payment_methods_updated_at
  BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW
  EXECUTE FUNCTION public.set_payment_methods_updated_at();

-- 2. Seed initial payment methods (safe placeholders for identifiers)
INSERT INTO public.payment_methods (code, name_ar, name_en, account_identifier, instructions_ar, instructions_en, icon_key, is_active, sort_order)
VALUES
  (
    'VODAFONE_CASH',
    'فودافون كاش',
    'Vodafone Cash',
    '01014045363',
    'قم بتحويل المبلغ المطلوب إلى رقم فودافون كاش أعلاه. بعد إتمام التحويل، احتفظ برقم العملية والتقط صورة لإيصال التحويل لإرفاقها.',
    'Transfer the required amount to the Vodafone Cash number above. After completing the transfer, keep the reference number and take a screenshot of the receipt to attach.',
    'vodafone_cash',
    true,
    1
  ),
  (
    'ORANGE_CASH',
    'أورنج كاش',
    'Orange Cash',
    '01200000000',
    'قم بتحويل المبلغ المطلوب إلى رقم أورنج كاش أعلاه. بعد إتمام التحويل، احتفظ برقم العملية والتقط صورة لإيصال التحويل لإرفاقها.',
    'Transfer the required amount to the Orange Cash number above. After completing the transfer, keep the reference number and take a screenshot of the receipt to attach.',
    'orange_cash',
    true,
    2
  )
ON CONFLICT (code) DO UPDATE SET
  name_ar = EXCLUDED.name_ar,
  name_en = EXCLUDED.name_en,
  instructions_ar = EXCLUDED.instructions_ar,
  instructions_en = EXCLUDED.instructions_en,
  icon_key = EXCLUDED.icon_key,
  is_active = EXCLUDED.is_active,
  sort_order = EXCLUDED.sort_order;

-- 3. RLS on payment_methods
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payment_methods_select_active" ON public.payment_methods;
CREATE POLICY "payment_methods_select_active" ON public.payment_methods
  FOR SELECT TO authenticated, anon
  USING (
    is_active = true OR
    app_private.is_super_admin()
  );

DROP POLICY IF EXISTS "payment_methods_admin_manage" ON public.payment_methods;
CREATE POLICY "payment_methods_admin_manage" ON public.payment_methods
  FOR ALL TO authenticated
  USING (app_private.is_super_admin())
  WITH CHECK (app_private.is_super_admin());

-- Least privilege table grants on payment_methods
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.payment_methods FROM anon, authenticated, public;
GRANT SELECT ON public.payment_methods TO authenticated, anon;

-- 4. RPC: get_active_payment_methods
CREATE OR REPLACE FUNCTION public.get_active_payment_methods()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_result jsonb;
BEGIN
  SELECT coalesce(jsonb_agg(m ORDER BY m.sort_order ASC, m.created_at ASC), '[]'::jsonb) INTO v_result
  FROM (
    SELECT 
      id,
      code,
      name_ar,
      name_en,
      account_identifier,
      instructions_ar,
      instructions_en,
      icon_key,
      is_active,
      sort_order,
      created_at,
      updated_at
    FROM public.payment_methods
    WHERE is_active = true
  ) m;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 5. Harden attach_topup_payment_proof with actual object existence in storage.objects
CREATE OR REPLACE FUNCTION public.attach_topup_payment_proof(
  p_request_id uuid,
  p_screenshot_path text
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private, storage
AS $$
DECLARE
  v_user_id uuid;
  v_expected_prefix text;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_screenshot_path IS NULL OR length(trim(p_screenshot_path)) = 0 THEN
    RAISE EXCEPTION 'Screenshot path is required';
  END IF;

  v_expected_prefix := v_user_id::text || '/' || p_request_id::text || '/';

  IF NOT (p_screenshot_path LIKE (v_expected_prefix || '%')) THEN
    RAISE EXCEPTION 'Invalid screenshot path. Expected format: %<filename>', v_expected_prefix;
  END IF;

  -- Verify that the object ACTUALLY EXISTS in storage.objects within the payment-proofs bucket
  IF NOT EXISTS (
    SELECT 1 FROM storage.objects
    WHERE bucket_id = 'payment-proofs'
      AND name = p_screenshot_path
  ) THEN
    RAISE EXCEPTION 'Payment proof file does not exist in storage: %', p_screenshot_path;
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

-- 6. RPC: get_my_topup_requests
CREATE OR REPLACE FUNCTION public.get_my_topup_requests()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid;
  v_result jsonb;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT coalesce(jsonb_agg(r), '[]'::jsonb) INTO v_result
  FROM (
    SELECT 
      t.id,
      t.user_id,
      t.requested_amount,
      t.payment_method,
      t.payment_reference,
      t.screenshot_path,
      t.status,
      t.rejection_reason,
      t.created_at,
      t.updated_at,
      pm.name_ar AS payment_method_name_ar,
      pm.name_en AS payment_method_name_en,
      pm.icon_key AS payment_method_icon_key
    FROM public.topup_requests t
    LEFT JOIN public.payment_methods pm ON t.payment_method = pm.code
    WHERE t.user_id = v_user_id
    ORDER BY t.created_at DESC
  ) r;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 7. Grant permissions
REVOKE EXECUTE ON FUNCTION public.get_active_payment_methods() FROM anon, public;
GRANT EXECUTE ON FUNCTION public.get_active_payment_methods() TO authenticated, anon;

REVOKE EXECUTE ON FUNCTION public.get_my_topup_requests() FROM anon, public;
GRANT EXECUTE ON FUNCTION public.get_my_topup_requests() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.attach_topup_payment_proof(uuid, text) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.attach_topup_payment_proof(uuid, text) TO authenticated;
