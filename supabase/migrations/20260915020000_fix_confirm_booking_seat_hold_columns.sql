-- ============================================================================
-- AMOMY DATABASE MIGRATION: 20260915020000_fix_confirm_booking_seat_hold_columns.sql
-- Fix: Remove invalid seat_holds.updated_at reference (code 42703) and align
-- confirm_booking with authoritative live schema for seat_holds, point_holds,
-- bookings, point_batches, point_transactions, and wallets.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_hold RECORD;
  v_point_hold RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_wallet RECORD;
  v_booking_id uuid;
  v_qr_token text;
  v_fare_points numeric;
  v_alloc RECORD;
  v_pref_orig_stop_id uuid;
  v_pref_dest_stop_id uuid;
  v_dep_time text;
  v_dedupe_key text;
BEGIN
  -- 1. Authentication check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Lock & validate active seat hold
  SELECT * INTO v_hold
  FROM public.seat_holds
  WHERE id = p_hold_id
    AND user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'HOLD_NOT_FOUND';
  END IF;

  -- 2b. If expired, canonically release hold and point hold
  IF v_hold.status = 'expired' OR v_hold.expires_at <= now() THEN
    PERFORM app_private._release_booking_hold_internal(p_hold_id, 'expired');
    RAISE EXCEPTION 'HOLD_EXPIRED';
  END IF;

  IF v_hold.status != 'active' THEN
    RAISE EXCEPTION 'HOLD_INVALID';
  END IF;

  -- 3. Lock & validate point hold
  SELECT * INTO v_point_hold
  FROM public.point_holds
  WHERE id = v_hold.point_hold_id
  FOR UPDATE;

  IF NOT FOUND OR v_point_hold.status != 'active' THEN
    RAISE EXCEPTION 'POINT_HOLD_INVALID';
  END IF;

  -- 4. Lock & validate trip
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

  -- 5. Lock & validate seat
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = v_hold.seat_id
    AND bus_id = v_trip.bus_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_NOT_FOUND';
  END IF;

  -- Ensure seat is not already booked by another active booking
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = v_hold.trip_id
      AND seat_id = v_hold.seat_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- 6. Lock wallet
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

  v_fare_points := COALESCE(v_hold.fare_points_snapshot, v_point_hold.amount, v_trip.fare_points);

  -- 7. Insert booking into public.bookings using authoritative schema
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
    now(),
    now()
  ) RETURNING id INTO v_booking_id;

  -- 8. Deduct from point_batches and log into point_transactions
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
      v_wallet.cached_available_balance,
      v_wallet.cached_available_balance,
      'booking',
      v_booking_id,
      'Trip Seat Booking ' || v_seat.seat_number,
      v_user_id,
      jsonb_build_object(
        'booking_id', v_booking_id,
        'trip_id', v_trip.id,
        'seat_id', v_seat.id,
        'seat_number', v_seat.seat_number,
        'batch_source_type', v_alloc.source_type
      ),
      now()
    );
  END LOOP;

  -- 9. Mark holds as CONVERTED / CONSUMED using authoritative schema and timestamps
  UPDATE public.seat_holds
  SET status = 'converted',
      booking_id = v_booking_id,
      released_at = now()
  WHERE id = p_hold_id;

  UPDATE public.point_holds
  SET status = 'consumed',
      consumed_at = now()
  WHERE id = v_point_hold.id;

  -- 10. Update wallet: Decrement cached_held_balance
  UPDATE public.wallets
  SET cached_held_balance = GREATEST(0, cached_held_balance - v_fare_points),
      updated_at = now()
  WHERE id = v_wallet.id;

  -- 11. Record in-app notification
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

  -- 12. Auto-upsert preferred journey
  IF v_hold.route_stop_id IS NOT NULL THEN
    BEGIN
      SELECT stop_id INTO v_pref_orig_stop_id FROM public.route_stops WHERE id = v_hold.route_stop_id;

      IF v_hold.destination_route_stop_id IS NOT NULL THEN
        SELECT stop_id INTO v_pref_dest_stop_id FROM public.route_stops WHERE id = v_hold.destination_route_stop_id;
      ELSE
        SELECT stop_id INTO v_pref_dest_stop_id
        FROM public.route_stops
        WHERE route_id = v_trip.route_id AND is_active = true
        ORDER BY stop_order DESC LIMIT 1;
      END IF;

      IF v_pref_orig_stop_id IS NOT NULL AND v_pref_dest_stop_id IS NOT NULL AND v_pref_orig_stop_id != v_pref_dest_stop_id THEN
        INSERT INTO public.passenger_trip_preferences (
          user_id, origin_stop_id, destination_stop_id, origin_route_stop_id, destination_route_stop_id, updated_at
        ) VALUES (
          v_user_id, v_pref_orig_stop_id, v_pref_dest_stop_id, v_hold.route_stop_id, v_hold.destination_route_stop_id, now()
        )
        ON CONFLICT (user_id) DO UPDATE SET
          origin_stop_id = EXCLUDED.origin_stop_id,
          destination_stop_id = EXCLUDED.destination_stop_id,
          origin_route_stop_id = EXCLUDED.origin_route_stop_id,
          destination_route_stop_id = EXCLUDED.destination_route_stop_id,
          updated_at = now();
      END IF;
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'trip_id', v_hold.trip_id,
    'seat_id', v_hold.seat_id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_fare_points,
    'qr_token', v_qr_token,
    'direction', (SELECT direction::text FROM public.routes WHERE id = v_trip.route_id),
    'departure_at', v_trip.departure_at,
    'departure_time', to_char(v_trip.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI'),
    'origin_name_ar', (SELECT origin_name_ar FROM public.routes WHERE id = v_trip.route_id),
    'origin_name_en', (SELECT origin_name_en FROM public.routes WHERE id = v_trip.route_id),
    'destination_name_ar', (SELECT destination_name_ar FROM public.routes WHERE id = v_trip.route_id),
    'destination_name_en', (SELECT destination_name_en FROM public.routes WHERE id = v_trip.route_id),
    'status', 'confirmed',
    'booked_at', now()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;
