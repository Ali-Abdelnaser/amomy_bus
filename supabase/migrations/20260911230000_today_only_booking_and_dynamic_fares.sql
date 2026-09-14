-- =============================================================================
-- Migration: 20260911230000_today_only_booking_and_dynamic_fares.sql
-- Description:
--   1. Adds route_stop_id, fare_zone_id, fare_points_snapshot to seat_holds and bookings.
--   2. Updates get_route_stops to return route_stop_id and fare_zone_id.
--   3. Adds get_today_available_trips(p_direction, p_route_stop_id) strictly enforced to Africa/Cairo today.
--   4. Updates get_available_trips for backwards compatibility with dynamic stop fares.
--   5. Hardens create_booking_hold with TODAY_ONLY_BOOKING check and dynamic stop fare snapshot.
--   6. Hardens confirm_booking to carry frozen dynamic fare snapshot to booking.
-- =============================================================================

-- 1. ALTER seat_holds & bookings FOR FARE SNAPSHOT
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'seat_holds' AND column_name = 'route_stop_id'
  ) THEN
    ALTER TABLE public.seat_holds ADD COLUMN route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'seat_holds' AND column_name = 'fare_zone_id'
  ) THEN
    ALTER TABLE public.seat_holds ADD COLUMN fare_zone_id uuid REFERENCES public.fare_zones(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'seat_holds' AND column_name = 'fare_points_snapshot'
  ) THEN
    ALTER TABLE public.seat_holds ADD COLUMN fare_points_snapshot numeric CHECK (fare_points_snapshot > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'route_stop_id'
  ) THEN
    ALTER TABLE public.bookings ADD COLUMN route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'fare_zone_id'
  ) THEN
    ALTER TABLE public.bookings ADD COLUMN fare_zone_id uuid REFERENCES public.fare_zones(id) ON DELETE RESTRICT;
  END IF;
END $$;

-- 2. UPDATE get_route_stops TO RETURN route_stop_id AND fare_zone_id
DROP FUNCTION IF EXISTS public.get_route_stops(text);

CREATE OR REPLACE FUNCTION public.get_route_stops(
  p_direction text
)
RETURNS TABLE (
  route_stop_id uuid,
  stop_id uuid,
  stop_order integer,
  stop_name_ar text,
  stop_name_en text,
  locality_ar text,
  locality_en text,
  fare_zone_id uuid,
  fare_zone_code text,
  fare_points numeric,
  latitude double precision,
  longitude double precision
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
  IF p_direction NOT IN ('outbound', 'return') THEN
    RAISE EXCEPTION 'INVALID_DIRECTION';
  END IF;

  RETURN QUERY
  SELECT
    rs.id AS route_stop_id,
    s.id AS stop_id,
    rs.stop_order,
    s.name_ar AS stop_name_ar,
    s.name_en AS stop_name_en,
    s.locality_ar,
    s.locality_en,
    fz.id AS fare_zone_id,
    fz.code AS fare_zone_code,
    fz.fare_points,
    s.latitude,
    s.longitude
  FROM public.route_stops rs
  JOIN public.routes r ON r.id = rs.route_id
  JOIN public.stops s ON s.id = rs.stop_id
  JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
  WHERE r.direction = p_direction::public.route_direction
    AND rs.is_active = true
    AND s.is_active = true
    AND fz.is_active = true
    AND r.is_active = true
  ORDER BY rs.stop_order ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_route_stops(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_route_stops(text) TO authenticated;

-- 3. PASSENGER-SAFE RPC: get_today_available_trips(p_direction, p_route_stop_id)
DROP FUNCTION IF EXISTS public.get_today_available_trips(text, uuid);

CREATE OR REPLACE FUNCTION public.get_today_available_trips(
  p_direction text,
  p_route_stop_id uuid DEFAULT NULL
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
  v_cairo_today date := (current_timestamp AT TIME ZONE 'Africa/Cairo')::date;
  v_stop_fare numeric;
  v_stop_route_id uuid;
BEGIN
  IF p_direction NOT IN ('outbound', 'return') THEN
    RAISE EXCEPTION 'INVALID_DIRECTION';
  END IF;

  -- If route stop provided, validate and get its zone's current fare_points
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
        WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > now()
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
    AND t.departure_at > now()
    AND t.booking_close_at > now()
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) TO authenticated;

-- 4. UPDATE get_available_trips (For admin / compatibility / date-specific queries)
DROP FUNCTION IF EXISTS public.get_available_trips(text, date);
DROP FUNCTION IF EXISTS public.get_available_trips(text, date, uuid);

CREATE OR REPLACE FUNCTION public.get_available_trips(
  p_direction text,
  p_date date,
  p_route_stop_id uuid DEFAULT NULL
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
        WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > now()
      ) AS calc_available
    FROM public.trips t
    JOIN public.buses b ON b.id = t.bus_id
    WHERE t.service_date = p_date
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
    AND t.service_date = p_date
    AND t.status IN ('scheduled', 'boarding')
    AND t.booking_close_at > now()
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_available_trips(text, date, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_available_trips(text, date, uuid) TO authenticated;

-- 5. HARDEN create_booking_hold: TODAY ONLY ENFORCEMENT & DYNAMIC FARE
DROP FUNCTION IF EXISTS public.create_booking_hold(uuid, uuid);
DROP FUNCTION IF EXISTS public.create_booking_hold(uuid, uuid, uuid);

CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_profile RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_wallet RECORD;
  v_stop_fare numeric;
  v_stop_name text;
  v_stop_locality text;
  v_fare_zone_id uuid;
  v_effective_fare numeric;
  v_hold_expires_at timestamptz;
  v_seat_hold_id uuid;
  v_point_hold_id uuid;
  v_batch RECORD;
  v_remaining_needed numeric;
  v_take numeric;
  v_existing_hold RECORD;
  v_cairo_today date := (current_timestamp AT TIME ZONE 'Africa/Cairo')::date;
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

  IF v_trip.departure_at <= now() OR v_trip.booking_close_at <= now() THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  -- 5. Route Stop & Dynamic Fare Resolution
  IF p_route_stop_id IS NOT NULL THEN
    SELECT
      fz.fare_points,
      fz.id,
      s.name_ar,
      s.locality_ar
    INTO
      v_stop_fare,
      v_fare_zone_id,
      v_stop_name,
      v_stop_locality
    FROM public.route_stops rs
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.id = p_route_stop_id
      AND rs.route_id = v_trip.route_id
      AND rs.is_active = true
      AND fz.is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ROUTE_STOP_INVALID';
    END IF;

    v_effective_fare := v_stop_fare;
  ELSE
    -- Legacy trip fare fallback
    v_effective_fare := v_trip.fare_points;
  END IF;

  -- 6. Seat validation
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
  SELECT * INTO v_existing_hold
  FROM public.seat_holds
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at > now()
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_hold.user_id = v_user_id THEN
      RETURN jsonb_build_object(
        'success', true,
        'hold_id', v_existing_hold.id,
        'trip_id', p_trip_id,
        'seat_id', p_seat_id,
        'seat_number', v_seat.seat_number,
        'fare_points', COALESCE(v_existing_hold.fare_points_snapshot, v_effective_fare),
        'expires_at', v_existing_hold.expires_at,
        'server_time', now(),
        'route_stop_id', v_existing_hold.route_stop_id,
        'fare_zone_id', v_existing_hold.fare_zone_id
      );
    ELSE
      RAISE EXCEPTION 'SEAT_UNAVAILABLE';
    END IF;
  END IF;

  -- Release any other active holds for this user on this trip
  FOR v_existing_hold IN
    SELECT id FROM public.seat_holds
    WHERE trip_id = p_trip_id
      AND user_id = v_user_id
      AND status = 'active'
  LOOP
    PERFORM public.release_booking_hold(v_existing_hold.id);
  END LOOP;

  -- 7. Wallet balance check
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_wallet.cached_available_balance < v_effective_fare THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  v_hold_expires_at := now() + interval '5 minutes';

  -- 8. Create seat hold record with dynamic fare snapshot
  INSERT INTO public.seat_holds (
    trip_id,
    seat_id,
    user_id,
    route_stop_id,
    fare_zone_id,
    fare_points_snapshot,
    status,
    expires_at,
    created_at
  ) VALUES (
    p_trip_id,
    p_seat_id,
    v_user_id,
    p_route_stop_id,
    v_fare_zone_id,
    v_effective_fare,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_seat_hold_id;

  -- 9. Create point hold record
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

  UPDATE public.seat_holds
  SET point_hold_id = v_point_hold_id
  WHERE id = v_seat_hold_id;

  -- 10. Allocate hold points: Subscription points first, then cash points
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

  -- Update cached wallet balance
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
    'stop_name', v_stop_name,
    'locality', v_stop_locality,
    'fare_zone_id', v_fare_zone_id
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) TO authenticated;

-- 6. HARDEN confirm_booking TO PRESERVE DYNAMIC FARE SNAPSHOT
CREATE OR REPLACE FUNCTION public.confirm_booking(
  p_hold_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
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
  v_alloc RECORD;
  v_fare_points numeric;
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

  IF v_hold.status = 'expired' OR v_hold.expires_at <= now() THEN
    UPDATE public.seat_holds SET status = 'expired' WHERE id = p_hold_id;
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
  FOR SHARE;

  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = v_hold.seat_id;

  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  -- Use frozen fare_points_snapshot if available
  v_fare_points := COALESCE(v_hold.fare_points_snapshot, v_point_hold.amount, v_trip.fare_points);

  -- Generate secure QR token
  v_qr_token := encode(digest(gen_random_uuid()::text || now()::text, 'sha256'), 'hex');

  -- Create confirmed booking
  INSERT INTO public.bookings (
    user_id,
    trip_id,
    seat_id,
    route_stop_id,
    fare_zone_id,
    fare_points,
    status,
    qr_token,
    booked_at,
    created_at
  ) VALUES (
    v_user_id,
    v_hold.trip_id,
    v_hold.seat_id,
    v_hold.route_stop_id,
    v_hold.fare_zone_id,
    v_fare_points,
    'confirmed',
    v_qr_token,
    now(),
    now()
  ) RETURNING id INTO v_booking_id;

  -- Consume held points from allocated batches
  FOR v_alloc IN
    SELECT batch_id, amount
    FROM public.point_hold_allocations
    WHERE hold_id = v_hold.point_hold_id
    FOR UPDATE
  LOOP
    UPDATE public.point_batches
    SET remaining_amount = remaining_amount - v_alloc.amount
    WHERE id = v_alloc.batch_id;

    INSERT INTO public.point_transactions (
      user_id,
      batch_id,
      amount,
      transaction_type,
      reference_type,
      reference_id,
      notes,
      created_at
    ) VALUES (
      v_user_id,
      v_alloc.batch_id,
      v_alloc.amount,
      'debit',
      'trip_booking',
      v_booking_id,
      'Trip seat confirmed ' || v_seat.seat_number,
      now()
    );
  END LOOP;

  -- Update wallet balances: release held points (deducted from total)
  UPDATE public.wallets
  SET cached_held_balance = cached_held_balance - v_point_hold.amount,
      cached_total_balance = cached_total_balance - v_point_hold.amount,
      updated_at = now()
  WHERE id = v_wallet.id;

  -- Close holds
  UPDATE public.point_holds
  SET status = 'captured'
  WHERE id = v_hold.point_hold_id;

  UPDATE public.seat_holds
  SET status = 'converted',
      booking_id = v_booking_id
  WHERE id = p_hold_id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'trip_id', v_hold.trip_id,
    'seat', v_seat.seat_number,
    'seat_number', v_seat.seat_number,
    'fare_points', v_fare_points,
    'qr_token', v_qr_token,
    'route_stop_id', v_hold.route_stop_id
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;
