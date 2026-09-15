-- ============================================================================
-- AMOMY DATABASE MIGRATION: 20260915010000_fix_confirm_booking_route_columns.sql
-- Fix: Remove invalid r.name_ar and r.name_en references in confirm_booking
-- ============================================================================

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

  -- 2. Fetch trip and route info using authoritative routes columns
  SELECT t.*,
         (r.origin_name_ar || ' - ' || r.destination_name_ar) AS route_name_ar,
         (COALESCE(NULLIF(r.origin_name_en, ''), r.origin_name_ar) || ' - ' || COALESCE(NULLIF(r.destination_name_en, ''), r.destination_name_ar)) AS route_name_en
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
