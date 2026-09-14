-- =============================================================================
-- AMOMY BUS - FIX CONFIRM_BOOKING & CREATE_BOOKING_HOLD AFTER REGRESSION
-- Migration: 20260912230000_fix_confirm_booking_after_duplicate_guard_regression.sql
--
-- Context:
-- Migration 20260912220000_prevent_duplicate_trip_booking.sql added the
-- ALREADY_BOOKED_TRIP guard and uq_passenger_active_trip_booking index, but
-- copied a legacy draft of confirm_booking and create_booking_hold that wrote
-- invalid statuses:
--   1. confirm_booking attempted: seat_holds.status = 'fulfilled' and
--      point_holds.status = 'fulfilled'
--      (PostgrestException 22P02, violates seat_hold_status enum and point_holds check)
--   2. create_booking_hold attempted: seat_holds.status = 'cancelled' and
--      point_holds.status = 'cancelled', and omitted wallet held balance refund
--
-- This migration safely combines:
--   (A) Correct canonical enum/status contract from 20260912210000:
--       - seat_holds.status = 'converted'
--       - point_holds.status = 'consumed'
--       - seat_holds.status = 'released' (when releasing previous hold)
--       - point_holds.status = 'released'
--       - restores wallet balances on release
--       - authoritative bookings & point_transactions schema
--       - complete PassengerBooking response fields
--   (B) ALREADY_BOOKED_TRIP protection from 20260912220000:
--       - duplicate check in confirm_booking
--       - duplicate check in create_booking_hold
-- =============================================================================

-- 1. FIX confirm_booking
CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private', 'extensions'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_hold RECORD;
  v_point_hold RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_wallet RECORD;
  v_booking_id uuid;
  v_qr_token text;
  v_alloc RECORD;
  v_fare_points numeric;
  v_new_wallet_held numeric;
  v_pref_orig_stop_id uuid;
  v_pref_dest_stop_id uuid;
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

  IF v_hold.status = 'expired' OR v_hold.expires_at <= now() THEN
    UPDATE public.seat_holds SET status = 'expired' WHERE id = p_hold_id;
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

  -- 4b. DUPLICATE TRIP GUARD (Prevent duplicate non-cancelled booking on same trip)
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = v_hold.trip_id
      AND user_id = v_user_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'ALREADY_BOOKED_TRIP';
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

  -- Deduct from point_batches and log into point_transactions
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

  -- 8. Mark holds as CONVERTED / CONSUMED (Strictly respecting seat_hold_status enum)
  UPDATE public.seat_holds
  SET status = 'converted',
      booking_id = v_booking_id,
      released_at = now()
  WHERE id = p_hold_id;

  UPDATE public.point_holds
  SET status = 'consumed',
      consumed_at = now()
  WHERE id = v_point_hold.id;

  -- 9. Update wallet: Decrement cached_held_balance
  v_new_wallet_held := GREATEST(0, v_wallet.cached_held_balance - v_fare_points);
  UPDATE public.wallets
  SET cached_held_balance = v_new_wallet_held,
      updated_at = now()
  WHERE id = v_wallet.id;

  -- 10. Auto-upsert preferred journey
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
    'seat_number', v_seat.seat_number,
    'fare_points', v_fare_points,
    'qr_token', v_qr_token,
    'direction', (SELECT direction FROM public.routes WHERE id = v_trip.route_id),
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
$function$;

-- 2. FIX create_booking_hold (Restore 'released' enum + wallet held balance refund + preserve ALREADY_BOOKED_TRIP)
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL::uuid,
  p_destination_route_stop_id uuid DEFAULT NULL::uuid
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
  -- 1. Authentication check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Profile completion check
  SELECT full_name, email, phone, gender, date_of_birth INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  IF NOT FOUND OR
     v_profile.phone IS NULL OR trim(v_profile.phone) = '' OR
     v_profile.gender IS NULL OR v_profile.gender NOT IN ('male', 'female') OR
     v_profile.date_of_birth IS NULL THEN
    RAISE EXCEPTION 'PROFILE_INCOMPLETE';
  END IF;

  -- 3. Trip check
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  -- 4. TODAY-ONLY BOOKING ENFORCEMENT (evaluated against effective calendar date)
  IF v_trip.service_date != v_cairo_today THEN
    RAISE EXCEPTION 'TODAY_ONLY_BOOKING';
  END IF;

  IF v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  IF v_trip.departure_at <= v_now OR v_trip.booking_close_at <= v_now THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  -- 4b. DUPLICATE TRIP BOOKING GUARD
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND user_id = v_user_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'ALREADY_BOOKED_TRIP';
  END IF;

  -- 5. Route Stop & Dynamic Fare Resolution (Boarding Stop determines price)
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
    -- Default/fallback trip fare
    v_effective_fare := v_trip.fare_points;
    SELECT rs.fare_zone_id INTO v_fare_zone_id
    FROM public.route_stops rs
    WHERE rs.route_id = v_trip.route_id AND rs.is_active = true
    ORDER BY rs.stop_order ASC
    LIMIT 1;
  END IF;

  -- 5b. Destination Route Stop Validation
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

  -- 6. Seat validity check
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = p_seat_id
    AND bus_id = v_trip.bus_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_INVALID';
  END IF;

  -- Check confirmed booking conflict
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status = 'confirmed'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- Expire stale holds on this seat
  UPDATE public.seat_holds
  SET status = 'expired'
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at <= now();

  -- Check active hold on this seat
  IF EXISTS (
    SELECT 1 FROM public.seat_holds
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status = 'active'
      AND expires_at > now()
      AND user_id != v_user_id
  ) THEN
    RAISE EXCEPTION 'SEAT_HELD_BY_ANOTHER_USER';
  END IF;

  -- 7. Lock wallet first so balance adjustments are strictly serialized
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

  -- Release any previous active holds by THIS user for this trip using valid 'released' enum
  -- and refund their held points back to available before checking balance for new hold
  FOR v_existing_hold IN
    SELECT sh.id, sh.point_hold_id, ph.amount as held_amount
    FROM public.seat_holds sh
    LEFT JOIN public.point_holds ph ON ph.id = sh.point_hold_id
    WHERE sh.trip_id = p_trip_id
      AND sh.user_id = v_user_id
      AND sh.status = 'active'
  LOOP
    UPDATE public.seat_holds SET status = 'released', released_at = now() WHERE id = v_existing_hold.id;
    IF v_existing_hold.point_hold_id IS NOT NULL THEN
      UPDATE public.point_holds SET status = 'released', released_at = now() WHERE id = v_existing_hold.point_hold_id;
      DELETE FROM public.point_hold_allocations WHERE hold_id = v_existing_hold.point_hold_id;
      IF v_existing_hold.held_amount IS NOT NULL AND v_existing_hold.held_amount > 0 THEN
        UPDATE public.wallets
        SET cached_available_balance = cached_available_balance + v_existing_hold.held_amount,
            cached_held_balance = GREATEST(0, cached_held_balance - v_existing_hold.held_amount),
            updated_at = now()
        WHERE id = v_wallet.id;
      END IF;
    END IF;
  END LOOP;

  -- Reload wallet after release refund
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF v_wallet.cached_available_balance < v_effective_fare THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- Seat hold duration: 5 real minutes from now
  v_hold_expires_at := now() + interval '5 minutes';

  -- 8. Create seat hold record with dynamic fare snapshot and destination
  INSERT INTO public.seat_holds (
    trip_id,
    seat_id,
    user_id,
    route_stop_id,
    destination_route_stop_id,
    fare_zone_id,
    fare_points_snapshot,
    expires_at,
    status
  ) VALUES (
    p_trip_id,
    p_seat_id,
    v_user_id,
    p_route_stop_id,
    p_destination_route_stop_id,
    v_fare_zone_id,
    v_effective_fare,
    v_hold_expires_at,
    'active'
  ) RETURNING id INTO v_seat_hold_id;

  -- 9. Create point hold record using authoritative point_holds schema
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
    now()
  ) RETURNING id INTO v_point_hold_id;

  -- Link point hold to seat hold
  UPDATE public.seat_holds
  SET point_hold_id = v_point_hold_id
  WHERE id = v_seat_hold_id;

  -- 10. FIFO Batch allocation: Subscription points first, then cash points
  v_remaining_needed := v_effective_fare;

  FOR v_batch IN
    SELECT id, remaining_amount
    FROM public.point_batches
    WHERE user_id = v_user_id
      AND source_type = 'subscription'
      AND remaining_amount > 0
      AND (expires_at IS NULL OR expires_at > now())
    ORDER BY expires_at ASC NULLS LAST, created_at ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_remaining_needed <= 0;

    v_take := LEAST(v_batch.remaining_amount, v_remaining_needed);
    IF v_take > 0 THEN
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
    END IF;
  END LOOP;

  IF v_remaining_needed > 0 THEN
    FOR v_batch IN
      SELECT id, remaining_amount
      FROM public.point_batches
      WHERE user_id = v_user_id
        AND source_type = 'cash'
        AND remaining_amount > 0
      ORDER BY created_at ASC
      FOR UPDATE
    LOOP
      EXIT WHEN v_remaining_needed <= 0;

      v_take := LEAST(v_batch.remaining_amount, v_remaining_needed);
      IF v_take > 0 THEN
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
      END IF;
    END LOOP;
  END IF;

  IF v_remaining_needed > 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- 11. Move balances in wallet: available decremented, held incremented
  UPDATE public.wallets
  SET cached_available_balance = cached_available_balance - v_effective_fare,
      cached_held_balance = cached_held_balance + v_effective_fare,
      updated_at = now()
  WHERE id = v_wallet.id;

  RETURN jsonb_build_object(
    'success', true,
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_effective_fare,
    'expires_at', v_hold_expires_at,
    'server_time', now(),
    'route_stop_id', p_route_stop_id,
    'destination_route_stop_id', p_destination_route_stop_id,
    'stop_name', v_stop_name,
    'destination_stop_name', v_dest_stop_name,
    'locality', v_stop_locality,
    'fare_zone_id', v_fare_zone_id
  );
END;
$function$;

-- 3. Overload create_booking_hold with 3 arguments
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
BEGIN
  RETURN public.create_booking_hold(p_trip_id, p_seat_id, p_route_stop_id, NULL);
END;
$function$;

-- 4. Permissions
REVOKE EXECUTE ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) TO authenticated;
