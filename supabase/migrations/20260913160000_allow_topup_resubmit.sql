-- Migration: 20260913160000_allow_topup_resubmit.sql
-- Description: Allow resubmitting rejected top-up payment proof without modifying frozen financial fields.

-- 1. Add resubmission_count to topup_requests if not exists
ALTER TABLE public.topup_requests 
ADD COLUMN IF NOT EXISTS resubmission_count integer DEFAULT 0 NOT NULL;

-- 2. Update submit_topup_payment_proof to accept rejected status and reset review state
CREATE OR REPLACE FUNCTION public.submit_topup_payment_proof(
  p_request_id uuid,
  p_sender_phone text,
  p_transfer_reference text,
  p_transferred_at timestamptz,
  p_screenshot_path text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid;
  v_topup RECORD;
  v_norm_phone text;
  v_norm_ref text;
  v_expected_prefix text;
  v_is_resubmit boolean := false;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 1. Lock request row FOR UPDATE
  SELECT * INTO v_topup
  FROM public.topup_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TOPUP_NOT_FOUND';
  END IF;

  IF v_topup.user_id != v_user_id THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  -- Allow awaiting_payment, pending, or rejected requests to submit/resubmit proof
  IF v_topup.status NOT IN ('awaiting_payment', 'pending', 'rejected') THEN
    RAISE EXCEPTION 'INVALID_STATUS_%', v_topup.status;
  END IF;

  IF v_topup.status = 'rejected' THEN
    v_is_resubmit := true;
  END IF;

  -- 2. Validate sender phone (11 digits Egyptian format e.g. 01XXXXXXXXX)
  IF p_sender_phone IS NULL OR length(trim(p_sender_phone)) = 0 THEN
    RAISE EXCEPTION 'SENDER_PHONE_REQUIRED';
  END IF;

  v_norm_phone := regexp_replace(trim(p_sender_phone), '[^0-9]', '', 'g');
  IF length(v_norm_phone) = 12 AND v_norm_phone LIKE '201%' THEN
    v_norm_phone := '01' || substr(v_norm_phone, 4);
  END IF;

  IF length(v_norm_phone) != 11 OR NOT (v_norm_phone ~ '^01[0125][0-9]{8}$') THEN
    RAISE EXCEPTION 'INVALID_EGYPTIAN_PHONE_NUMBER';
  END IF;

  -- 3. Validate screenshot path & existence in storage
  IF p_screenshot_path IS NULL OR length(trim(p_screenshot_path)) = 0 THEN
    RAISE EXCEPTION 'SCREENSHOT_PATH_REQUIRED';
  END IF;

  v_expected_prefix := v_user_id::text || '/';
  IF NOT (p_screenshot_path LIKE (v_expected_prefix || '%')) THEN
    RAISE EXCEPTION 'INVALID_SCREENSHOT_PATH';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM storage.objects
    WHERE bucket_id = 'payment-proofs'
      AND name = p_screenshot_path
  ) THEN
    RAISE EXCEPTION 'PAYMENT_PROOF_NOT_IN_STORAGE';
  END IF;

  -- 4. Normalize reference (if present)
  IF p_transfer_reference IS NOT NULL AND length(trim(p_transfer_reference)) > 0 THEN
    v_norm_ref := trim(p_transfer_reference);
    IF EXISTS (
      SELECT 1 FROM public.topup_requests
      WHERE id != p_request_id
        AND lower(trim(payment_reference)) = lower(v_norm_ref)
        AND status IN ('pending', 'pending_review', 'approved')
    ) THEN
      RAISE EXCEPTION 'DUPLICATE_PAYMENT_REFERENCE';
    END IF;
  ELSE
    v_norm_ref := NULL;
  END IF;

  -- 5. Update request to pending_review and clear rejection state
  -- NOTE: requested_amount, expected_amount_egp, conversion_rate, receiving_phone are frozen!
  UPDATE public.topup_requests
  SET sender_phone = v_norm_phone,
      payment_reference = v_norm_ref,
      transferred_at = COALESCE(p_transferred_at, now()),
      screenshot_path = p_screenshot_path,
      submitted_at = now(),
      status = 'pending_review',
      rejection_reason = NULL,
      reviewed_by = NULL,
      reviewed_at = NULL,
      resubmission_count = COALESCE(resubmission_count, 0) + (CASE WHEN v_is_resubmit THEN 1 ELSE 0 END),
      updated_at = now()
  WHERE id = p_request_id;

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
    CASE WHEN v_is_resubmit THEN 'TOPUP_PROOF_RESUBMITTED' ELSE 'TOPUP_PROOF_SUBMITTED' END,
    'topup_requests',
    p_request_id,
    jsonb_build_object(
      'sender_phone', v_norm_phone,
      'payment_reference', v_norm_ref,
      'screenshot_path', p_screenshot_path,
      'public_id', v_topup.public_id,
      'resubmitted', v_is_resubmit
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'public_id', v_topup.public_id,
    'status', 'pending_review',
    'resubmitted', v_is_resubmit
  );
END;
$$;
REVOKE ALL ON FUNCTION public.submit_topup_payment_proof(uuid, text, text, timestamptz, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_topup_payment_proof(uuid, text, text, timestamptz, text) TO authenticated;

-- 3. Update get_my_topup_requests to include resubmission_count
CREATE OR REPLACE FUNCTION public.get_my_topup_requests()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid;
  v_result jsonb;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  SELECT coalesce(jsonb_agg(r), '[]'::jsonb) INTO v_result
  FROM (
    SELECT 
      t.id,
      t.public_id,
      t.user_id,
      t.requested_amount,
      t.expected_amount_egp,
      t.conversion_rate,
      t.receiving_phone,
      t.payment_method,
      t.payment_reference,
      t.sender_phone,
      t.transferred_at,
      t.submitted_at,
      t.screenshot_path,
      t.status,
      t.rejection_reason,
      t.resubmission_count,
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
$$;
REVOKE ALL ON FUNCTION public.get_my_topup_requests() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_topup_requests() TO authenticated;
