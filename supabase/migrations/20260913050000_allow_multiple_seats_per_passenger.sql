-- =============================================================================
-- AMOMY BUS - ALLOW MULTIPLE SEAT BOOKINGS PER PASSENGER & MULTI-SEAT TODAY TRIP CARD
-- Migration: 20260913050000_allow_multiple_seats_per_passenger.sql
--
-- 1. Drops uq_passenger_active_trip_booking unique index on (user_id, trip_id).
--    (Unique seat occupancy per trip is already enforced by seat_id constraints).
--
-- 2. Removes ALREADY_BOOKED_TRIP restrictions from:
--    - create_booking_hold
--    - confirm_booking
--    - get_today_available_trips
--    - get_available_trips
--
-- 3. Updates get_passenger_today_trips to aggregate all active seats owned by
--    the passenger on the same trip into comma-separated numbers (e.g. "03، 07"),
--    and sums the fare points for the card.
-- =============================================================================

-- 1. DROP RESTRICTIVE UNIQUE INDEX ON (user_id, trip_id)
DROP INDEX IF EXISTS public.uq_passenger_active_trip_booking;

-- 2. UPDATE create_booking_hold (REMOVE ALREADY_BOOKED_TRIP CHECK)
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL::uuid,
  p_destination_route_stop_id uuid DEFAULT NULL::uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
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

  -- 4. TODAY-ONLY BOOKING ENFORCEMENT
  IF v_trip.service_date != v_cairo_today THEN
    RAISE EXCEPTION 'TODAY_ONLY_BOOKING';
  END IF;

  IF v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  IF v_trip.departure_at <= v_now OR v_trip.booking_close_at <= v_now THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  -- 5. Route Stop & Dynamic Fare Resolution
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

  -- Check confirmed booking conflict for this seat
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status != 'cancelled'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- 7. Idempotency: check existing active hold by this user for the same seat
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

  -- Clean up other holds on this seat or expired holds
  PERFORM app_private._release_booking_hold_internal(sh.id, 'expired')
  FROM public.seat_holds sh
  WHERE (sh.seat_id = p_seat_id OR sh.user_id = v_user_id)
    AND sh.status = 'active'
    AND sh.expires_at <= v_now;

  -- Check if another user holds this seat
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

  -- 8. Wallet balance check
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR (v_wallet.balance - v_wallet.held_balance) < v_effective_fare THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE';
  END IF;

  v_hold_expires_at := v_now + interval '5 minutes';

  -- 9. Insert point_hold
  INSERT INTO public.point_holds (
    user_id,
    amount,
    status,
    expires_at,
    created_at
  ) VALUES (
    v_user_id,
    v_effective_fare,
    'active',
    v_hold_expires_at,
    v_now
  ) RETURNING id INTO v_point_hold_id;

  -- Allocate point batches FIFO
  v_remaining_needed := v_effective_fare;
  FOR v_batch IN
    SELECT id, remaining_amount
    FROM public.point_batches
    WHERE user_id = v_user_id
      AND remaining_amount > 0
      AND expires_at > v_now
    ORDER BY expires_at ASC, created_at ASC
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

  -- Increment held_balance
  UPDATE public.wallets
  SET held_balance = held_balance + v_effective_fare,
      updated_at = v_now
  WHERE user_id = v_user_id;

  -- 10. Insert seat_hold
  INSERT INTO public.seat_holds (
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
  ) RETURNING id INTO v_seat_hold_id;

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

-- 3. UPDATE confirm_booking (REMOVE ALREADY_BOOKED_TRIP CHECK)
CREATE OR REPLACE FUNCTION public.confirm_booking(
  p_hold_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
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
  v_fare_points numeric;
  v_alloc RECORD;
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

  -- 2b. If expired, expire CANONICALLY
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

  -- Ensure seat not already booked by another active booking
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

  -- 7. Insert booking into public.bookings
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
      v_wallet.balance,
      v_wallet.balance - v_alloc.amount,
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
      now()
    );

    v_wallet.balance := v_wallet.balance - v_alloc.amount;
  END LOOP;

  -- Decrement held_balance and balance on wallet
  UPDATE public.wallets
  SET balance = balance - v_fare_points,
      held_balance = GREATEST(0, held_balance - v_fare_points),
      updated_at = now()
  WHERE user_id = v_user_id;

  -- Mark holds confirmed
  UPDATE public.point_holds
  SET status = 'confirmed'
  WHERE id = v_point_hold.id;

  UPDATE public.seat_holds
  SET status = 'confirmed'
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

-- 4. UPDATE get_passenger_today_trips TO AGGREGATE MULTIPLE BOOKED SEATS PER TRIP
CREATE OR REPLACE FUNCTION public.get_passenger_today_trips(
  p_direction text DEFAULT NULL::text,
  p_origin_route_stop_id uuid DEFAULT NULL::uuid
)
RETURNS TABLE (
  trip_id uuid,
  route_id uuid,
  direction text,
  service_date date,
  origin_name_ar text,
  origin_name_en text,
  destination_name_ar text,
  destination_name_en text,
  departure_time text,
  departure_at timestamptz,
  booking_close_at timestamptz,
  fare_points numeric,
  total_seats integer,
  available_seats integer,
  status text,
  already_booked boolean,
  booking_id uuid,
  seat_number text,
  qr_token text,
  availability_status text,
  is_bookable boolean
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_stop_fare numeric;
  v_stop_route_id uuid;
  v_pref_origin_stop_id uuid;
  v_pref_dest_stop_id uuid;
BEGIN
  IF p_direction IS NOT NULL AND p_direction NOT IN ('outbound', 'return') THEN
    RAISE EXCEPTION 'INVALID_DIRECTION';
  END IF;

  IF p_origin_route_stop_id IS NOT NULL THEN
    SELECT fz.fare_points, rs.route_id
    INTO v_stop_fare, v_stop_route_id
    FROM public.route_stops rs
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.id = p_origin_route_stop_id
      AND rs.is_active = true
      AND fz.is_active = true;
  ELSIF v_user_id IS NOT NULL THEN
    SELECT pref.origin_stop_id, pref.destination_stop_id
    INTO v_pref_origin_stop_id, v_pref_dest_stop_id
    FROM public.passenger_trip_preferences pref
    WHERE pref.user_id = v_user_id;
  END IF;

  RETURN QUERY
  WITH raw_user_bookings AS (
    SELECT
      bkg.id AS b_id,
      bkg.trip_id AS b_trip_id,
      COALESCE(bkg.seat_number_snapshot, bs.seat_number) AS seat_num,
      bkg.qr_token AS b_qr_token,
      bkg.fare_points AS b_fare_points,
      s_orig.name_ar AS b_origin_name_ar,
      COALESCE(NULLIF(s_orig.name_en, ''), s_orig.name_ar) AS b_origin_name_en,
      s_dest.name_ar AS b_destination_name_ar,
      COALESCE(NULLIF(s_dest.name_en, ''), s_dest.name_ar) AS b_destination_name_en,
      bkg.created_at
    FROM public.bookings bkg
    JOIN public.bus_seats bs ON bs.id = bkg.seat_id
    LEFT JOIN public.route_stops rs_orig ON rs_orig.id = bkg.route_stop_id
    LEFT JOIN public.stops s_orig ON s_orig.id = rs_orig.stop_id
    LEFT JOIN public.route_stops rs_dest ON rs_dest.id = bkg.destination_route_stop_id
    LEFT JOIN public.stops s_dest ON s_dest.id = rs_dest.stop_id
    WHERE bkg.user_id = v_user_id
      AND bkg.status = 'confirmed'
  ),
  user_bookings AS (
    SELECT
      (ARRAY_AGG(b_id ORDER BY created_at ASC))[1] AS b_id,
      b_trip_id,
      string_agg(seat_num, '، ' ORDER BY seat_num ASC) AS b_seat_number,
      (ARRAY_AGG(b_qr_token ORDER BY created_at ASC))[1] AS b_qr_token,
      SUM(b_fare_points) AS b_fare_points,
      (ARRAY_AGG(b_origin_name_ar ORDER BY created_at ASC))[1] AS b_origin_name_ar,
      (ARRAY_AGG(b_origin_name_en ORDER BY created_at ASC))[1] AS b_origin_name_en,
      (ARRAY_AGG(b_destination_name_ar ORDER BY created_at ASC))[1] AS b_destination_name_ar,
      (ARRAY_AGG(b_destination_name_en ORDER BY created_at ASC))[1] AS b_destination_name_en
    FROM raw_user_bookings
    GROUP BY b_trip_id
  ),
  trip_counts AS (
    SELECT
      t.id AS c_trip_id,
      b.capacity AS c_total_seats,
      b.capacity - (
        SELECT COUNT(*)::integer
        FROM public.bookings bkg
        WHERE bkg.trip_id = t.id AND bkg.status = 'confirmed'
      ) - (
        SELECT COUNT(*)::integer
        FROM public.seat_holds sh
        WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > v_now
      ) AS calc_available
    FROM public.trips t
    JOIN public.buses b ON b.id = t.bus_id
    WHERE t.service_date = v_cairo_today
  ),
  default_fares AS (
    SELECT DISTINCT ON (rs.route_id)
      rs.route_id,
      fz.fare_points AS default_fare
    FROM public.route_stops rs
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.is_active = true AND fz.is_active = true
    ORDER BY rs.route_id, rs.stop_order ASC
  ),
  pref_outbound_stops AS (
    SELECT
      rs.route_id,
      fz.fare_points AS pref_fare,
      s.name_ar AS pref_name_ar,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar) AS pref_name_en
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.stop_id = v_pref_origin_stop_id
      AND rs.is_active = true
      AND fz.is_active = true
  ),
  pref_outbound_dest AS (
    SELECT
      rs.route_id,
      s.name_ar AS dest_name_ar,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar) AS dest_name_en
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.stop_id = v_pref_dest_stop_id
      AND rs.is_active = true
  ),
  pref_return_stops AS (
    SELECT
      rs.route_id,
      fz.fare_points AS pref_fare,
      s.name_ar AS pref_name_ar,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar) AS pref_name_en
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.stop_id = v_pref_dest_stop_id
      AND rs.is_active = true
      AND fz.is_active = true
  ),
  pref_return_dest AS (
    SELECT
      rs.route_id,
      s.name_ar AS dest_name_ar,
      COALESCE(NULLIF(s.name_en, ''), s.name_ar) AS dest_name_en
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.stop_id = v_pref_origin_stop_id
      AND rs.is_active = true
  )
  SELECT
    t.id AS trip_id,
    t.route_id,
    r.direction::text AS direction,
    t.service_date,
    COALESCE(
      NULLIF(ub.b_origin_name_ar, ''),
      CASE WHEN r.direction = 'outbound' THEN po.pref_name_ar ELSE pr.pref_name_ar END,
      r.origin_name_ar
    ) AS origin_name_ar,
    COALESCE(
      NULLIF(ub.b_origin_name_en, ''),
      CASE WHEN r.direction = 'outbound' THEN po.pref_name_en ELSE pr.pref_name_en END,
      NULLIF(r.origin_name_en, ''),
      r.origin_name_ar
    ) AS origin_name_en,
    COALESCE(
      NULLIF(ub.b_destination_name_ar, ''),
      CASE WHEN r.direction = 'outbound' THEN pod.dest_name_ar ELSE prd.dest_name_ar END,
      r.destination_name_ar
    ) AS destination_name_ar,
    COALESCE(
      NULLIF(ub.b_destination_name_en, ''),
      CASE WHEN r.direction = 'outbound' THEN pod.dest_name_en ELSE prd.dest_name_en END,
      NULLIF(r.destination_name_en, ''),
      r.destination_name_ar
    ) AS destination_name_en,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    t.booking_close_at,
    COALESCE(
      ub.b_fare_points,
      v_stop_fare,
      CASE WHEN r.direction = 'outbound' THEN po.pref_fare ELSE pr.pref_fare END,
      df.default_fare,
      30
    ) AS fare_points,
    tc.c_total_seats::integer AS total_seats,
    GREATEST(0, tc.calc_available)::integer AS available_seats,
    t.status::text AS status,
    (ub.b_id IS NOT NULL) AS already_booked,
    ub.b_id AS booking_id,
    ub.b_seat_number AS seat_number,
    ub.b_qr_token AS qr_token,
    CASE
      WHEN ub.b_id IS NOT NULL THEN 'ALREADY_BOOKED'
      WHEN t.status = 'completed' OR t.departure_at <= v_now THEN 'DEPARTED'
      WHEN t.status = 'cancelled' THEN 'CANCELLED'
      WHEN t.booking_close_at <= v_now THEN 'BOOKING_CLOSED'
      WHEN tc.calc_available <= 0 THEN 'FULL'
      WHEN t.status IN ('scheduled', 'boarding') THEN 'AVAILABLE'
      ELSE 'UNAVAILABLE'
    END AS availability_status,
    (ub.b_id IS NULL AND
     t.status IN ('scheduled', 'boarding') AND
     t.departure_at > v_now AND
     t.booking_close_at > v_now AND
     tc.calc_available > 0) AS is_bookable
  FROM public.trips t
  JOIN public.routes r ON r.id = t.route_id
  JOIN trip_counts tc ON tc.c_trip_id = t.id
  LEFT JOIN user_bookings ub ON ub.b_trip_id = t.id
  LEFT JOIN default_fares df ON df.route_id = t.route_id
  LEFT JOIN pref_outbound_stops po ON po.route_id = t.route_id
  LEFT JOIN pref_outbound_dest pod ON pod.route_id = t.route_id
  LEFT JOIN pref_return_stops pr ON pr.route_id = t.route_id
  LEFT JOIN pref_return_dest prd ON prd.route_id = t.route_id
  WHERE (p_direction IS NULL OR r.direction = p_direction::public.route_direction)
    AND (v_stop_route_id IS NULL OR t.route_id = v_stop_route_id)
    AND t.service_date = v_cairo_today
  ORDER BY t.departure_at ASC;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) TO authenticated;

-- 5. UPDATE get_today_available_trips (ALLOW VIEWING TRIPS WITH AVAILABLE SEATS)
CREATE OR REPLACE FUNCTION public.get_today_available_trips(
  p_direction text,
  p_route_stop_id uuid DEFAULT NULL::uuid
)
RETURNS TABLE (
  trip_id uuid,
  route_id uuid,
  direction text,
  service_date date,
  origin_name_ar text,
  origin_name_en text,
  destination_name_ar text,
  destination_name_en text,
  departure_time text,
  departure_at timestamptz,
  fare_points numeric,
  total_seats integer,
  available_seats integer,
  available_seats_count integer,
  status text,
  is_active boolean
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_stop_fare numeric;
  v_stop_route_id uuid;
BEGIN
  IF p_direction NOT IN ('outbound', 'return') THEN
    RAISE EXCEPTION 'INVALID_DIRECTION';
  END IF;

  IF p_route_stop_id IS NOT NULL THEN
    SELECT fz.fare_points, rs.route_id
    INTO v_stop_fare, v_stop_route_id
    FROM public.route_stops rs
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    WHERE rs.id = p_route_stop_id
      AND rs.is_active = true
      AND fz.is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ROUTE_STOP_INVALID';
    END IF;
  END IF;

  RETURN QUERY
  WITH trip_counts AS (
    SELECT
      t.id AS c_trip_id,
      b.capacity AS c_total_seats,
      b.capacity - (
        SELECT COUNT(*)::integer
        FROM public.bookings bkg
        WHERE bkg.trip_id = t.id AND bkg.status = 'confirmed'
      ) - (
        SELECT COUNT(*)::integer
        FROM public.seat_holds sh
        WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > v_now
      ) AS calc_available
    FROM public.trips t
    JOIN public.buses b ON b.id = t.bus_id
    WHERE t.service_date = v_cairo_today
  )
  SELECT
    t.id AS trip_id,
    t.route_id,
    r.direction::text AS direction,
    t.service_date,
    r.origin_name_ar,
    r.origin_name_en,
    r.destination_name_ar,
    r.destination_name_en,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    COALESCE(v_stop_fare, t.fare_points) AS fare_points,
    tc.c_total_seats::integer AS total_seats,
    GREATEST(0, tc.calc_available)::integer AS available_seats,
    GREATEST(0, tc.calc_available)::integer AS available_seats_count,
    t.status::text AS status,
    (t.status IN ('scheduled', 'boarding')) AS is_active
  FROM public.trips t
  JOIN public.routes r ON r.id = t.route_id
  JOIN trip_counts tc ON tc.c_trip_id = t.id
  WHERE r.direction = p_direction::public.route_direction
    AND (v_stop_route_id IS NULL OR t.route_id = v_stop_route_id)
    AND t.service_date = v_cairo_today
    AND t.status IN ('scheduled', 'boarding')
    AND t.departure_at > v_now
    AND t.booking_close_at > v_now
    AND tc.calc_available > 0
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) TO authenticated;
