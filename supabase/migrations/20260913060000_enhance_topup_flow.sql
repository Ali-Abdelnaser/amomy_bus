-- Migration: 20260913060000_enhance_topup_flow.sql
-- Full Add Points flow enhancement:
-- 1. app_config table and payment_config entry (rate, receiver number, min points = 200)
-- 2. public_id, sender_phone, transferred_at, submitted_at, expected_amount_egp, receiving_phone on topup_requests
-- 3. Minimum 200 points hard constraint in database and RPC
-- 4. Server-authoritative create_topup_request freezing expected amount and receiving number
-- 5. submit_topup_payment_proof validating Egyptian mobile sender phone, storage proof, and idempotent status
-- 6. Exactly-once approve_topup_request inserting point_batches and point_transactions credit ('topup')
-- 7. get_my_topup_requests exposing public reference and transfer details

-- 1. Create app_config table if not exists
CREATE TABLE IF NOT EXISTS public.app_config (
  key text PRIMARY KEY,
  value jsonb NOT NULL,
  description text,
  updated_at timestamptz DEFAULT now()
);

INSERT INTO public.app_config (key, value, description)
VALUES (
  'payment_config',
  jsonb_build_object(
    'mobile_cash_enabled', true,
    'mobile_cash_receiver_number', '01000000000',
    'egp_per_point', 1.0,
    'minimum_topup_points', 200
  ),
  'Authoritative payment configuration for top-up flow'
)
ON CONFLICT (key) DO NOTHING;

-- 2. Add public_id generator
CREATE OR REPLACE FUNCTION app_private.generate_topup_public_id()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_id text;
  v_exists boolean;
BEGIN
  LOOP
    v_id := 'AMY-' || upper(substr(encode(extensions.gen_random_bytes(4), 'hex'), 1, 6));
    SELECT EXISTS (SELECT 1 FROM public.topup_requests WHERE public_id = v_id) INTO v_exists;
    EXIT WHEN NOT v_exists;
  END LOOP;
  RETURN v_id;
END;
$$;

-- 3. Add columns to topup_requests
ALTER TABLE public.topup_requests
ADD COLUMN IF NOT EXISTS public_id text UNIQUE DEFAULT app_private.generate_topup_public_id(),
ADD COLUMN IF NOT EXISTS sender_phone text,
ADD COLUMN IF NOT EXISTS transferred_at timestamptz,
ADD COLUMN IF NOT EXISTS submitted_at timestamptz,
ADD COLUMN IF NOT EXISTS expected_amount_egp numeric NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS conversion_rate numeric NOT NULL DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS receiving_phone text;

-- Backfill public_id if any existing rows lack it
UPDATE public.topup_requests
SET public_id = app_private.generate_topup_public_id()
WHERE public_id IS NULL;

-- Backfill expected_amount_egp if 0
UPDATE public.topup_requests
SET expected_amount_egp = requested_amount
WHERE expected_amount_egp = 0 AND requested_amount > 0;

-- Ensure min amount constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_topup_min_amount'
  ) THEN
    ALTER TABLE public.topup_requests
    ADD CONSTRAINT chk_topup_min_amount CHECK (requested_amount >= 200);
  END IF;
END $$;

-- 4. get_payment_config
CREATE OR REPLACE FUNCTION public.get_payment_config()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_val jsonb;
BEGIN
  SELECT value INTO v_val
  FROM public.app_config
  WHERE key = 'payment_config';

  IF v_val IS NULL THEN
    RETURN jsonb_build_object(
      'mobile_cash_enabled', true,
      'mobile_cash_receiver_number', '01000000000',
      'egp_per_point', 1.0,
      'minimum_topup_points', 200
    );
  END IF;

  RETURN v_val;
END;
$$;
REVOKE ALL ON FUNCTION public.get_payment_config() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_payment_config() TO authenticated, anon;

-- 5. create_topup_request
CREATE OR REPLACE FUNCTION public.create_topup_request(
  p_requested_amount numeric,
  p_payment_method text,
  p_payment_reference text DEFAULT NULL,
  p_screenshot_path text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid;
  v_request_id uuid;
  v_public_id text;
  v_config jsonb;
  v_min_points numeric;
  v_rate numeric;
  v_expected_egp numeric;
  v_receiver text;
  v_norm_ref text;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- Load payment configuration
  SELECT public.get_payment_config() INTO v_config;
  v_min_points := COALESCE((v_config->>'minimum_topup_points')::numeric, 200);
  v_rate := COALESCE((v_config->>'egp_per_point')::numeric, 1.0);
  v_receiver := COALESCE(v_config->>'mobile_cash_receiver_number', '01000000000');

  -- Enforce minimum points (hard rule >= 200)
  IF p_requested_amount < v_min_points THEN
    RAISE EXCEPTION 'MINIMUM_TOPUP_POINTS_%', v_min_points;
  END IF;

  IF p_payment_method IS NULL OR length(trim(p_payment_method)) = 0 THEN
    RAISE EXCEPTION 'PAYMENT_METHOD_REQUIRED';
  END IF;

  -- Fetch specific account identifier from payment_methods if matching
  SELECT account_identifier INTO v_receiver
  FROM public.payment_methods
  WHERE code = p_payment_method AND is_active = true;
  IF v_receiver IS NULL THEN
    v_receiver := COALESCE(v_config->>'mobile_cash_receiver_number', '01000000000');
  END IF;

  v_expected_egp := round(p_requested_amount * v_rate, 2);
  v_public_id := app_private.generate_topup_public_id();

  -- Normalize payment reference if given early
  IF p_payment_reference IS NOT NULL AND length(trim(p_payment_reference)) > 0 THEN
    v_norm_ref := trim(p_payment_reference);
    IF EXISTS (
      SELECT 1 FROM public.topup_requests
      WHERE lower(trim(payment_reference)) = lower(v_norm_ref)
        AND status IN ('pending', 'pending_review', 'approved')
    ) THEN
      RAISE EXCEPTION 'DUPLICATE_PAYMENT_REFERENCE';
    END IF;
  ELSE
    v_norm_ref := NULL;
  END IF;

  INSERT INTO public.topup_requests (
    user_id,
    requested_amount,
    payment_method,
    payment_reference,
    screenshot_path,
    status,
    public_id,
    expected_amount_egp,
    conversion_rate,
    receiving_phone,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    p_requested_amount,
    trim(p_payment_method),
    v_norm_ref,
    p_screenshot_path,
    'awaiting_payment',
    v_public_id,
    v_expected_egp,
    v_rate,
    v_receiver,
    now(),
    now()
  ) RETURNING id INTO v_request_id;

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
      'expected_amount_egp', v_expected_egp,
      'public_id', v_public_id,
      'payment_method', p_payment_method
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id,
    'public_id', v_public_id,
    'requested_points', p_requested_amount,
    'expected_amount_egp', v_expected_egp,
    'receiving_phone', v_receiver,
    'conversion_rate', v_rate,
    'status', 'awaiting_payment'
  );
END;
$$;
REVOKE ALL ON FUNCTION public.create_topup_request(numeric, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_topup_request(numeric, text, text, text) TO authenticated;

-- 6. submit_topup_payment_proof
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

  IF v_topup.status NOT IN ('awaiting_payment', 'pending') THEN
    RAISE EXCEPTION 'INVALID_STATUS_%', v_topup.status;
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

  -- 5. Update request to pending_review
  UPDATE public.topup_requests
  SET sender_phone = v_norm_phone,
      payment_reference = v_norm_ref,
      transferred_at = COALESCE(p_transferred_at, now()),
      screenshot_path = p_screenshot_path,
      submitted_at = now(),
      status = 'pending_review',
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
    'TOPUP_PROOF_SUBMITTED',
    'topup_requests',
    p_request_id,
    jsonb_build_object(
      'sender_phone', v_norm_phone,
      'payment_reference', v_norm_ref,
      'screenshot_path', p_screenshot_path,
      'public_id', v_topup.public_id
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'public_id', v_topup.public_id,
    'status', 'pending_review'
  );
END;
$$;
REVOKE ALL ON FUNCTION public.submit_topup_payment_proof(uuid, text, text, timestamptz, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_topup_payment_proof(uuid, text, text, timestamptz, text) TO authenticated;

-- 7. attach_topup_payment_proof backward compatible wrapper
CREATE OR REPLACE FUNCTION public.attach_topup_payment_proof(
  p_request_id uuid,
  p_screenshot_path text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
BEGIN
  RETURN public.submit_topup_payment_proof(
    p_request_id,
    '01000000000',
    NULL,
    now(),
    p_screenshot_path
  );
END;
$$;
REVOKE ALL ON FUNCTION public.attach_topup_payment_proof(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.attach_topup_payment_proof(uuid, text) TO authenticated;

-- 8. approve_topup_request (strict server-authoritative approval)
CREATE OR REPLACE FUNCTION public.approve_topup_request(
  p_request_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
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
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Super Admin access required';
  END IF;

  SELECT * INTO v_topup
  FROM public.topup_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topup request not found';
  END IF;

  IF v_topup.status = 'approved' THEN
    RAISE EXCEPTION 'Topup request is already approved';
  END IF;

  IF v_topup.status NOT IN ('pending', 'pending_review') THEN
    RAISE EXCEPTION 'Topup request status % cannot be approved', v_topup.status;
  END IF;

  SELECT id, cached_available_balance INTO v_wallet_id, v_balance_before
  FROM public.wallets
  WHERE user_id = v_topup.user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Wallet not found for user %', v_topup.user_id;
  END IF;

  v_balance_after := v_balance_before + v_topup.requested_amount;

  -- Create unified regular point batch (cash/non-expiring)
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
    NULL,
    'topup',
    p_request_id,
    'Points Top-up via ' || v_topup.payment_method,
    v_actor_id
  ) RETURNING id INTO v_batch_id;

  -- Real point transaction credit
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
    'topup',
    p_request_id,
    'Points Top-up',
    v_actor_id,
    jsonb_build_object(
      'payment_method', v_topup.payment_method,
      'public_id', v_topup.public_id,
      'sender_phone', v_topup.sender_phone,
      'payment_reference', v_topup.payment_reference
    )
  );

  -- Update wallet cached_available_balance
  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  -- Mark top-up approved
  UPDATE public.topup_requests
  SET status = 'approved',
      reviewed_by = v_actor_id,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_request_id;

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
    jsonb_build_object('status', v_topup.status),
    jsonb_build_object('status', 'approved', 'amount', v_topup.requested_amount),
    jsonb_build_object('user_id', v_topup.user_id, 'batch_id', v_batch_id, 'public_id', v_topup.public_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'public_id', v_topup.public_id,
    'credited_amount', v_topup.requested_amount,
    'new_balance', v_balance_after
  );
END;
$$;
REVOKE ALL ON FUNCTION public.approve_topup_request(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.approve_topup_request(uuid) TO authenticated;

-- 9. reject_topup_request
CREATE OR REPLACE FUNCTION public.reject_topup_request(
  p_request_id uuid,
  p_reason text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_actor_id uuid;
  v_topup RECORD;
BEGIN
  v_actor_id := auth.uid();
  IF v_actor_id IS NULL OR NOT app_private.is_super_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Super Admin access required';
  END IF;

  SELECT * INTO v_topup
  FROM public.topup_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topup request not found';
  END IF;

  IF v_topup.status = 'rejected' THEN
    RAISE EXCEPTION 'Topup request is already rejected';
  END IF;

  IF v_topup.status = 'approved' THEN
    RAISE EXCEPTION 'Approved topup request cannot be rejected';
  END IF;

  UPDATE public.topup_requests
  SET status = 'rejected',
      reviewed_by = v_actor_id,
      reviewed_at = now(),
      rejection_reason = p_reason,
      updated_at = now()
  WHERE id = p_request_id;

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
    jsonb_build_object('status', v_topup.status),
    jsonb_build_object('status', 'rejected', 'reason', p_reason),
    jsonb_build_object('user_id', v_topup.user_id, 'public_id', v_topup.public_id)
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', p_request_id,
    'public_id', v_topup.public_id,
    'status', 'rejected'
  );
END;
$$;
REVOKE ALL ON FUNCTION public.reject_topup_request(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_topup_request(uuid, text) TO authenticated;

-- 10. get_my_topup_requests
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

-- 11. create_booking_hold (Support permanent non-expiring cash point batches and cached_available_balance)
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL,
  p_destination_route_stop_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_profile RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_wallet RECORD;
  v_stop_fare numeric;
  v_stop_name text;
  v_stop_locality text;
  v_dest_stop_name text;
  v_fare_zone_id uuid;
  v_effective_fare numeric;
  v_hold_expires_at timestamptz;
  v_seat_hold_id uuid;
  v_point_hold_id uuid;
  v_batch RECORD;
  v_remaining_needed numeric;
  v_take numeric;
  v_existing_hold RECORD;
  v_orig_order integer;
  v_dest_order integer;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  SELECT full_name, email, phone, gender, date_of_birth INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  IF NOT FOUND OR
     v_profile.phone IS NULL OR trim(v_profile.phone) = '' OR
     v_profile.gender IS NULL OR v_profile.gender NOT IN ('male', 'female') OR
     v_profile.date_of_birth IS NULL THEN
    RAISE EXCEPTION 'PROFILE_INCOMPLETE';
  END IF;

  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.service_date != v_cairo_today THEN
    RAISE EXCEPTION 'TODAY_ONLY_BOOKING';
  END IF;

  IF v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  IF v_trip.departure_at <= v_now OR v_trip.booking_close_at <= v_now THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  IF p_route_stop_id IS NOT NULL THEN
    SELECT
      fz.fare_points,
      fz.id,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar),
      s.locality_ar,
      rs.stop_order
    INTO
      v_stop_fare,
      v_fare_zone_id,
      v_stop_name,
      v_stop_locality,
      v_orig_order
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.id = p_route_stop_id
      AND rs.route_id = v_trip.route_id
      AND rs.is_active = true
      AND fz.is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ROUTE_STOP_INVALID';
    END IF;

    v_effective_fare := v_stop_fare;
  ELSE
    SELECT
      fz.fare_points,
      fz.id,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar),
      s.locality_ar,
      rs.stop_order
    INTO
      v_stop_fare,
      v_fare_zone_id,
      v_stop_name,
      v_stop_locality,
      v_orig_order
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.route_id = v_trip.route_id
      AND rs.is_active = true
      AND fz.is_active = true
    ORDER BY rs.stop_order ASC
    LIMIT 1;

    v_effective_fare := COALESCE(v_stop_fare, v_trip.fare_points, 30);
  END IF;

  IF p_destination_route_stop_id IS NOT NULL THEN
    SELECT
      COALESCE(NULLIF(s.name_en, ''), s.name_ar),
      rs.stop_order
    INTO
      v_dest_stop_name,
      v_dest_order
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.id = p_destination_route_stop_id
      AND rs.route_id = v_trip.route_id
      AND rs.is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'DESTINATION_STOP_INVALID';
    END IF;

    IF v_orig_order IS NOT NULL AND v_dest_order <= v_orig_order THEN
      RAISE EXCEPTION 'DESTINATION_MUST_BE_AFTER_ORIGIN';
    END IF;
  END IF;

  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = p_seat_id
    AND bus_id = v_trip.bus_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_INVALID';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  SELECT * INTO v_existing_hold
  FROM public.seat_holds
  WHERE user_id = v_user_id
    AND trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at > v_now;

  IF FOUND THEN
    RETURN jsonb_build_object(
      'hold_id', v_existing_hold.id,
      'trip_id', v_existing_hold.trip_id,
      'seat_id', v_existing_hold.seat_id,
      'seat_number', v_seat.seat_number,
      'fare_points', v_existing_hold.fare_points_snapshot,
      'expires_at', v_existing_hold.expires_at,
      'server_time', v_now,
      'route_stop_id', v_existing_hold.route_stop_id,
      'destination_route_stop_id', v_existing_hold.destination_route_stop_id,
      'stop_name', v_stop_name,
      'destination_stop_name', v_dest_stop_name,
      'locality', v_stop_locality,
      'fare_zone_id', v_fare_zone_id
    );
  END IF;

  PERFORM app_private._release_booking_hold_internal(sh.id, 'expired')
  FROM public.seat_holds sh
  WHERE (sh.seat_id = p_seat_id OR sh.user_id = v_user_id)
    AND sh.status = 'active'
    AND sh.expires_at <= v_now;

  IF EXISTS (
    SELECT 1 FROM public.seat_holds
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status = 'active'
      AND expires_at > v_now
      AND user_id != v_user_id
  ) THEN
    RAISE EXCEPTION 'SEAT_HELD';
  END IF;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_wallet.cached_available_balance < v_effective_fare THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;

  v_hold_expires_at := v_now + interval '5 minutes';
  v_seat_hold_id := gen_random_uuid();

  INSERT INTO public.point_holds (
    user_id,
    amount,
    reference_type,
    reference_id,
    status,
    expires_at,
    created_at
  ) VALUES (
    v_user_id,
    v_effective_fare,
    'trip_booking',
    v_seat_hold_id,
    'active',
    v_hold_expires_at,
    v_now
  ) RETURNING id INTO v_point_hold_id;

  v_remaining_needed := v_effective_fare;
  FOR v_batch IN
    SELECT id, remaining_amount
    FROM public.point_batches
    WHERE user_id = v_user_id
      AND remaining_amount > 0
      AND (expires_at IS NULL OR expires_at > v_now)
    ORDER BY (expires_at IS NULL) ASC, expires_at ASC, created_at ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_remaining_needed <= 0;
    v_take := LEAST(v_batch.remaining_amount, v_remaining_needed);

    INSERT INTO public.point_hold_allocations (
      hold_id,
      batch_id,
      amount
    ) VALUES (
      v_point_hold_id,
      v_batch.id,
      v_take
    );

    v_remaining_needed := v_remaining_needed - v_take;
  END LOOP;

  IF v_remaining_needed > 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_USABLE_BATCH_BALANCE';
  END IF;

  UPDATE public.wallets
  SET cached_available_balance = cached_available_balance - v_effective_fare,
      cached_held_balance = cached_held_balance + v_effective_fare,
      updated_at = v_now
  WHERE user_id = v_user_id;

  INSERT INTO public.seat_holds (
    id,
    trip_id,
    seat_id,
    user_id,
    point_hold_id,
    route_stop_id,
    destination_route_stop_id,
    fare_zone_id,
    fare_points_snapshot,
    status,
    expires_at,
    created_at
  ) VALUES (
    v_seat_hold_id,
    p_trip_id,
    p_seat_id,
    v_user_id,
    v_point_hold_id,
    p_route_stop_id,
    p_destination_route_stop_id,
    v_fare_zone_id,
    v_effective_fare,
    'active',
    v_hold_expires_at,
    v_now
  );

  RETURN jsonb_build_object(
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_effective_fare,
    'expires_at', v_hold_expires_at,
    'server_time', v_now,
    'route_stop_id', p_route_stop_id,
    'destination_route_stop_id', p_destination_route_stop_id,
    'stop_name', v_stop_name,
    'destination_stop_name', v_dest_stop_name,
    'locality', v_stop_locality,
    'fare_zone_id', v_fare_zone_id
  );
END;
$function$;

-- 12. confirm_booking
CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_hold RECORD;
  v_point_hold RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_wallet RECORD;
  v_booking_id uuid;
  v_qr_token text;
  v_fare_points numeric;
  v_alloc RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  SELECT * INTO v_hold
  FROM public.seat_holds
  WHERE id = p_hold_id
    AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'HOLD_NOT_FOUND';
  END IF;

  IF v_hold.status = 'expired' OR v_hold.expires_at <= v_now THEN
    PERFORM app_private._release_booking_hold_internal(p_hold_id, 'expired');
    RAISE EXCEPTION 'HOLD_EXPIRED';
  END IF;

  IF v_hold.status != 'active' THEN
    RAISE EXCEPTION 'HOLD_INVALID';
  END IF;

  SELECT * INTO v_point_hold
  FROM public.point_holds
  WHERE id = v_hold.point_hold_id
  FOR UPDATE;

  IF NOT FOUND OR v_point_hold.status != 'active' THEN
    RAISE EXCEPTION 'POINT_HOLD_INVALID';
  END IF;

  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = v_hold.trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.status = 'cancelled' THEN
    RAISE EXCEPTION 'TRIP_CANCELLED';
  END IF;

  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = v_hold.seat_id
    AND bus_id = v_trip.bus_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_NOT_FOUND';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = v_hold.trip_id
      AND seat_id = v_hold.seat_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

  v_fare_points := COALESCE(v_hold.fare_points_snapshot, v_point_hold.amount, v_trip.fare_points);
  v_qr_token := 'AMY-' || upper(substr(encode(extensions.gen_random_bytes(16), 'hex'), 1, 16));

  INSERT INTO public.bookings (
    user_id,
    trip_id,
    seat_id,
    route_stop_id,
    destination_route_stop_id,
    fare_zone_id,
    fare_points,
    seat_number_snapshot,
    status,
    qr_token,
    booked_at,
    created_at
  ) VALUES (
    v_user_id,
    v_hold.trip_id,
    v_hold.seat_id,
    v_hold.route_stop_id,
    v_hold.destination_route_stop_id,
    v_hold.fare_zone_id,
    v_fare_points,
    v_seat.seat_number,
    'confirmed',
    v_qr_token,
    v_now,
    v_now
  ) RETURNING id INTO v_booking_id;

  FOR v_alloc IN
    SELECT pha.batch_id, pha.amount, pb.source_type
    FROM public.point_hold_allocations pha
    JOIN public.point_batches pb ON pb.id = pha.batch_id
    WHERE pha.hold_id = v_point_hold.id
  LOOP
    UPDATE public.point_batches
    SET remaining_amount = GREATEST(0, remaining_amount - v_alloc.amount)
    WHERE id = v_alloc.batch_id;

    INSERT INTO public.point_transactions (
      wallet_id,
      user_id,
      batch_id,
      transaction_type,
      amount,
      balance_before,
      balance_after,
      reference_type,
      reference_id,
      description,
      actor_user_id,
      metadata,
      created_at
    ) VALUES (
      v_wallet.id,
      v_user_id,
      v_alloc.batch_id,
      'debit',
      v_alloc.amount,
      v_wallet.cached_available_balance + v_fare_points,
      v_wallet.cached_available_balance,
      'booking',
      v_booking_id,
      'Deduction for seat ' || v_seat.seat_number,
      v_user_id,
      jsonb_build_object(
        'trip_id', v_hold.trip_id,
        'seat_id', v_hold.seat_id,
        'seat_number', v_seat.seat_number,
        'source_type', v_alloc.source_type
      ),
      v_now
    );
  END LOOP;

  UPDATE public.wallets
  SET cached_held_balance = GREATEST(0, cached_held_balance - v_fare_points),
      updated_at = v_now
  WHERE user_id = v_user_id;

  UPDATE public.point_holds
  SET status = 'consumed',
      consumed_at = v_now
  WHERE id = v_point_hold.id;

  UPDATE public.seat_holds
  SET status = 'converted'
  WHERE id = v_hold.id;

  RETURN jsonb_build_object(
    'booking_id', v_booking_id,
    'trip_id', v_hold.trip_id,
    'seat_id', v_hold.seat_id,
    'seat_number', v_seat.seat_number,
    'qr_token', v_qr_token,
    'fare_points', v_fare_points,
    'status', 'confirmed'
  );
END;
$function$;

