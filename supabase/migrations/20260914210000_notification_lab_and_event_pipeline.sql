-- =============================================================================
-- Migration: 20260914210000_notification_lab_and_event_pipeline.sql
-- Description:
--   1. Creates public.app_testers table with strict RLS for Notification Test Lab access.
--   2. Provides public.is_notification_tester() RPC.
--   3. Seeds designated QA/admin accounts into app_testers.
--   4. Creates public.record_in_app_notification helper for backend-authoritative events.
--   5. Updates booking, topup, and bus approach event handlers to record in-app notifications.
-- =============================================================================

-- 1. APP TESTERS TABLE
CREATE TABLE IF NOT EXISTS public.app_testers (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_lab_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.app_testers IS
  'Secure server-backed tester allowlist for QA testing and Notification Lab access in production/QA builds.';

ALTER TABLE public.app_testers ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.app_testers FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.app_testers TO authenticated;

DROP POLICY IF EXISTS app_testers_select_own ON public.app_testers;
CREATE POLICY app_testers_select_own
  ON public.app_testers
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 2. IS_NOTIFICATION_TESTER RPC
CREATE OR REPLACE FUNCTION public.is_notification_tester()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_enabled boolean := false;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN false;
  END IF;

  -- 1. Check explicit app_testers table
  SELECT notification_lab_enabled INTO v_enabled
  FROM public.app_testers
  WHERE user_id = v_user_id;

  IF COALESCE(v_enabled, false) THEN
    RETURN true;
  END IF;

  -- 2. Check admin/super_admin role
  IF EXISTS (
    SELECT 1 FROM public.user_roles 
    WHERE user_id = v_user_id AND role IN ('admin', 'super_admin')
  ) THEN
    RETURN true;
  END IF;

  -- 3. Check QA booking override
  IF EXISTS (
    SELECT 1 FROM public.qa_booking_time_overrides 
    WHERE user_id = v_user_id AND enabled = true
  ) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE ALL ON FUNCTION public.is_notification_tester() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_notification_tester() TO authenticated;

-- 3. SEED DESIGNATED QA / ADMIN ACCOUNTS INTO APP_TESTERS
INSERT INTO public.app_testers (user_id, notification_lab_enabled, updated_at)
SELECT user_id, true, now()
FROM public.qa_booking_time_overrides
WHERE enabled = true
ON CONFLICT (user_id) DO UPDATE SET
  notification_lab_enabled = true,
  updated_at = now();

INSERT INTO public.app_testers (user_id, notification_lab_enabled, updated_at)
SELECT user_id, true, now()
FROM public.user_roles
WHERE role IN ('admin', 'super_admin')
ON CONFLICT (user_id) DO UPDATE SET
  notification_lab_enabled = true,
  updated_at = now();

-- 4. IN-APP NOTIFICATION INGESTION HELPER
CREATE OR REPLACE FUNCTION public.record_in_app_notification(
  p_user_id uuid,
  p_type text,
  p_title_ar text,
  p_body_ar text,
  p_title_en text,
  p_body_en text,
  p_data jsonb DEFAULT '{}'::jsonb,
  p_entity_type text DEFAULT NULL,
  p_entity_id uuid DEFAULT NULL,
  p_dedupe_key text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_inserted_id uuid;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  INSERT INTO public.notifications (
    user_id,
    type,
    title_ar,
    body_ar,
    title_en,
    body_en,
    data,
    entity_type,
    entity_id,
    dedupe_key,
    created_at
  ) VALUES (
    p_user_id,
    p_type,
    p_title_ar,
    p_body_ar,
    p_title_en,
    p_body_en,
    p_data,
    p_entity_type,
    p_entity_id,
    p_dedupe_key,
    now()
  )
  ON CONFLICT (user_id, dedupe_key) WHERE dedupe_key IS NOT NULL
  DO NOTHING
  RETURNING id INTO v_inserted_id;

  RETURN v_inserted_id;
END;
$$;

REVOKE ALL ON FUNCTION public.record_in_app_notification(uuid, text, text, text, text, text, jsonb, text, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_in_app_notification(uuid, text, text, text, text, text, jsonb, text, uuid, text) TO authenticated, service_role;

-- 5. WIRE NOTIFICATION DISPATCH TO confirm_booking
CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_hold RECORD;
  v_booking_id uuid;
  v_qr_payload text;
  v_trip RECORD;
  v_route_stop RECORD;
  v_seat RECORD;
  v_dedupe_key text;
  v_dep_time text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Lock and validate hold
  SELECT * INTO v_hold
  FROM public.seat_holds
  WHERE id = p_hold_id AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hold not found or not owned by user';
  END IF;

  IF v_hold.status != 'active' THEN
    RAISE EXCEPTION 'Hold is not active (current status: %)', v_hold.status;
  END IF;

  IF v_hold.expires_at < now() THEN
    UPDATE public.seat_holds SET status = 'expired', updated_at = now() WHERE id = p_hold_id;
    RAISE EXCEPTION 'Hold has expired';
  END IF;

  -- 2. Fetch trip info
  SELECT t.*, r.name_ar as route_name_ar, r.name_en as route_name_en
  INTO v_trip
  FROM public.trips t
  JOIN public.routes r ON r.id = t.route_id
  WHERE t.id = v_hold.trip_id;

  -- 3. Fetch route stop
  SELECT * INTO v_route_stop
  FROM public.route_stops
  WHERE id = v_hold.route_stop_id;

  -- 4. Fetch seat info
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = v_hold.seat_id;

  -- 5. Mark hold converted
  UPDATE public.seat_holds
  SET status = 'converted', updated_at = now()
  WHERE id = p_hold_id;

  -- 6. Insert booking
  v_qr_payload := 'AMOMY:' || encode(gen_random_bytes(16), 'hex');
  INSERT INTO public.bookings (
    user_id,
    trip_id,
    route_stop_id,
    seat_id,
    status,
    qr_payload,
    points_cost,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    v_hold.trip_id,
    v_hold.route_stop_id,
    v_hold.seat_id,
    'confirmed',
    v_qr_payload,
    v_hold.points_held,
    now(),
    now()
  )
  RETURNING id INTO v_booking_id;

  -- 7. Convert point hold to debit transaction
  UPDATE public.point_holds
  SET status = 'converted', updated_at = now()
  WHERE seat_hold_id = p_hold_id;

  -- 8. Record in-app notification
  v_dep_time := to_char((v_trip.departure_at AT TIME ZONE 'Africa/Cairo'), 'HH12:MI AM');
  v_dedupe_key := 'booking_confirmed_' || v_booking_id;

  PERFORM public.record_in_app_notification(
    v_user_id,
    'booking_confirmed',
    'تم تأكيد حجزك',
    'تم تأكيد رحلتك ' || COALESCE(v_dep_time, '') || ' والمقعد رقم ' || COALESCE(v_seat.seat_number::text, '') || '.',
    'Booking confirmed',
    'Your trip at ' || COALESCE(v_dep_time, '') || ' is confirmed. Seat #' || COALESCE(v_seat.seat_number::text, '') || '.',
    jsonb_build_object('screen', 'ticket', 'booking_id', v_booking_id, 'trip_id', v_trip.id),
    'booking',
    v_booking_id,
    v_dedupe_key
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'qr_payload', v_qr_payload,
    'points_spent', v_hold.points_held
  );
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;

-- 6. WIRE NOTIFICATION DISPATCH TO cancel_passenger_booking
CREATE OR REPLACE FUNCTION public.cancel_passenger_booking(
  p_booking_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_booking RECORD;
  v_trip RECORD;
  v_wallet RECORD;
  v_tx RECORD;
  v_total_refund numeric := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF v_booking.user_id != v_user_id AND NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'status', 'cancelled',
      'refund_points', 0,
      'already_cancelled', true
    );
  END IF;

  IF v_booking.status != 'confirmed' THEN
    RAISE EXCEPTION 'BOOKING_NOT_CANCELLABLE';
  END IF;

  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = v_booking.trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.departure_at - interval '30 minutes' < v_now THEN
    RAISE EXCEPTION 'CANCELLATION_WINDOW_CLOSED';
  END IF;

  UPDATE public.bookings
  SET status = 'cancelled',
      cancelled_at = now()
  WHERE id = v_booking.id;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_booking.user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

  -- Refund points back to original batches
  FOR v_tx IN
    SELECT pt.batch_id, pt.amount, pb.source_type
    FROM public.point_transactions pt
    JOIN public.point_batches pb ON pb.id = pt.batch_id
    WHERE pt.reference_type = 'booking'
      AND pt.reference_id = v_booking.id
      AND pt.transaction_type = 'debit'
  LOOP
    UPDATE public.point_batches
    SET remaining_amount = remaining_amount + v_tx.amount
    WHERE id = v_tx.batch_id;

    v_total_refund := v_total_refund + v_tx.amount;
  END LOOP;

  IF v_total_refund > 0 THEN
    UPDATE public.wallets
    SET cached_available_balance = cached_available_balance + v_total_refund,
        updated_at = now()
    WHERE id = v_wallet.id;

    INSERT INTO public.point_transactions (
      user_id,
      wallet_id,
      transaction_type,
      amount,
      balance_before,
      balance_after,
      reference_type,
      reference_id,
      description
    ) VALUES (
      v_booking.user_id,
      v_wallet.id,
      'credit',
      v_total_refund,
      v_wallet.cached_available_balance,
      v_wallet.cached_available_balance + v_total_refund,
      'booking_cancellation_refund',
      v_booking.id,
      'Refund for cancelled booking'
    );
  END IF;

  -- Record in-app notification
  PERFORM public.record_in_app_notification(
    v_booking.user_id,
    'booking_cancelled',
    'تم إلغاء الحجز',
    'تم إلغاء حجز رحلتك بنجاح واسترداد ' || v_total_refund::text || ' نقطة إلى محفظتك.',
    'Booking cancelled',
    'Your trip booking has been cancelled and ' || v_total_refund::text || ' points were refunded to your wallet.',
    jsonb_build_object('screen', 'trips', 'booking_id', v_booking.id),
    'booking',
    v_booking.id,
    'booking_cancelled_' || v_booking.id
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', p_booking_id,
    'status', 'cancelled',
    'refund_points', v_total_refund
  );
END;
$function$;

-- 7. WIRE NOTIFICATION DISPATCH TO approve_topup_request & reject_topup_request
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
    created_by
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
    'Top-up approved: ' || v_topup.requested_amount || ' pts',
    v_actor_id
  );

  UPDATE public.wallets
  SET cached_available_balance = v_balance_after,
      updated_at = now()
  WHERE id = v_wallet_id;

  UPDATE public.topup_requests
  SET status = 'approved',
      processed_at = now(),
      processed_by = v_actor_id,
      updated_at = now()
  WHERE id = p_request_id;

  -- Record in-app notification
  PERFORM public.record_in_app_notification(
    v_topup.user_id,
    'topup_approved',
    'تم قبول طلب الشحن',
    'تم إضافة ' || v_topup.requested_amount::text || ' نقطة إلى محفظتك بنجاح.',
    'Top-up approved',
    v_topup.requested_amount::text || ' points were added to your wallet.',
    jsonb_build_object('screen', 'wallet', 'request_id', p_request_id, 'amount', v_topup.requested_amount),
    'topup_request',
    p_request_id,
    'topup_approved_' || p_request_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'topup_id', p_request_id,
    'new_balance', v_balance_after,
    'points_added', v_topup.requested_amount
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.reject_topup_request(
  p_request_id uuid,
  p_rejection_reason text DEFAULT NULL
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
    RAISE EXCEPTION 'Topup request is already approved and cannot be rejected';
  END IF;

  UPDATE public.topup_requests
  SET status = 'rejected',
      admin_rejection_reason = p_rejection_reason,
      processed_at = now(),
      processed_by = v_actor_id,
      updated_at = now()
  WHERE id = p_request_id;

  -- Record in-app notification
  PERFORM public.record_in_app_notification(
    v_topup.user_id,
    'topup_rejected',
    'لم يتم قبول طلب الشحن',
    COALESCE(p_rejection_reason, 'راجع تفاصيل الطلب أو أعد المحاولة بإرفاق إيصال تحويل صالح.'),
    'Top-up not approved',
    COALESCE(p_rejection_reason, 'Please review your top-up request or submit a valid transfer receipt.'),
    jsonb_build_object('screen', 'wallet', 'request_id', p_request_id),
    'topup_request',
    p_request_id,
    'topup_rejected_' || p_request_id
  );

  RETURN jsonb_build_object(
    'success', true,
    'topup_id', p_request_id,
    'status', 'rejected'
  );
END;
$$;
