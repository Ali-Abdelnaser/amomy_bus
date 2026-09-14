-- =============================================================================
-- Migration: 20260912180000_qa_booking_time_override.sql
-- Description:
--   Implements a safe, user-specific QA / development booking time override.
--
-- Key features:
--   1. qa_booking_time_overrides table:
--      - Attached strictly per user_id (primary key references auth.users).
--      - Default disabled.
--      - Supports 'override_time' (time-of-day, e.g. 07:30 or 12:30) which
--        dynamically anchors to TODAY's Africa/Cairo date.
--      - Supports explicit 'effective_at' (timestamptz).
--      - Protected by RLS: read-only for own user, NO insert/update/delete
--        for normal passengers. Only trusted admin / SQL console can configure.
--
--   2. get_effective_booking_now() helper:
--      - Returns configured QA time if user has an active enabled override.
--      - Returns real current_timestamp for production passengers.
--
--   3. Consistent effective booking clock across all booking RPCs:
--      - get_today_available_trips
--      - get_passenger_today_trips
--      - get_available_trips
--      - create_booking_hold
--      - get_passenger_home_summary
-- =============================================================================

-- 1. QA BOOKING TIME OVERRIDES TABLE
CREATE TABLE IF NOT EXISTS public.qa_booking_time_overrides (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT false,
  override_time time DEFAULT NULL,
  effective_at timestamptz DEFAULT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.qa_booking_time_overrides IS
  'Secure user-specific QA time override table for development and QA testing of time-sensitive booking flows.';

-- Enable Row Level Security
ALTER TABLE public.qa_booking_time_overrides ENABLE ROW LEVEL SECURITY;

-- Deny normal passengers from modifying QA records
REVOKE ALL ON public.qa_booking_time_overrides FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.qa_booking_time_overrides TO authenticated;

DROP POLICY IF EXISTS qa_booking_time_overrides_select_own ON public.qa_booking_time_overrides;
CREATE POLICY qa_booking_time_overrides_select_own
  ON public.qa_booking_time_overrides
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- =============================================================================
-- 2. get_effective_booking_now() HELPER
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_effective_booking_now()
RETURNS timestamptz
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_override RECORD;
  v_cairo_today date := (current_timestamp AT TIME ZONE 'Africa/Cairo')::date;
BEGIN
  IF v_user_id IS NOT NULL THEN
    SELECT enabled, override_time, effective_at
    INTO v_override
    FROM public.qa_booking_time_overrides
    WHERE user_id = v_user_id
      AND enabled = true;

    IF FOUND THEN
      -- If time-of-day provided, combine with today's Cairo calendar date
      IF v_override.override_time IS NOT NULL THEN
        RETURN (v_cairo_today + v_override.override_time) AT TIME ZONE 'Africa/Cairo';
      ELSIF v_override.effective_at IS NOT NULL THEN
        RETURN v_override.effective_at;
      END IF;
    END IF;
  END IF;

  -- Default production behavior: real server timestamp
  RETURN current_timestamp;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_effective_booking_now() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_effective_booking_now() TO authenticated;

-- =============================================================================
-- 3. UPDATE get_today_available_trips WITH EFFECTIVE BOOKING NOW
-- =============================================================================

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
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
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
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_today_available_trips(text, uuid) TO authenticated;

-- =============================================================================
-- 4. UPDATE get_passenger_today_trips WITH EFFECTIVE BOOKING NOW
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_passenger_today_trips(
  p_direction text DEFAULT NULL,
  p_origin_route_stop_id uuid DEFAULT NULL
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
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_stop_fare numeric;
  v_stop_route_id uuid;
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
  END IF;

  RETURN QUERY
  WITH user_bookings AS (
    SELECT
      bkg.id AS b_id,
      bkg.trip_id AS b_trip_id,
      bs.seat_number AS b_seat_number,
      bkg.qr_token AS b_qr_token,
      bkg.fare_points AS b_fare_points,
      s_orig.name_ar AS b_origin_name_ar,
      COALESCE(NULLIF(s_orig.name_en, ''), s_orig.name_ar) AS b_origin_name_en,
      s_dest.name_ar AS b_destination_name_ar,
      COALESCE(NULLIF(s_dest.name_en, ''), s_dest.name_ar) AS b_destination_name_en
    FROM public.bookings bkg
    JOIN public.bus_seats bs ON bs.id = bkg.seat_id
    LEFT JOIN public.route_stops rs_orig ON rs_orig.id = bkg.route_stop_id
    LEFT JOIN public.stops s_orig ON s_orig.id = rs_orig.stop_id
    LEFT JOIN public.route_stops rs_dest ON rs_dest.id = bkg.destination_route_stop_id
    LEFT JOIN public.stops s_dest ON s_dest.id = rs_dest.stop_id
    WHERE bkg.user_id = v_user_id
      AND bkg.status = 'confirmed'
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
  )
  SELECT
    t.id AS trip_id,
    t.route_id,
    r.direction::text AS direction,
    t.service_date,
    COALESCE(NULLIF(ub.b_origin_name_ar, ''), r.origin_name_ar) AS origin_name_ar,
    COALESCE(NULLIF(ub.b_origin_name_en, ''), NULLIF(r.origin_name_en, ''), r.origin_name_ar) AS origin_name_en,
    COALESCE(NULLIF(ub.b_destination_name_ar, ''), r.destination_name_ar) AS destination_name_ar,
    COALESCE(NULLIF(ub.b_destination_name_en, ''), NULLIF(r.destination_name_en, ''), r.destination_name_ar) AS destination_name_en,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    t.booking_close_at,
    COALESCE(ub.b_fare_points, v_stop_fare, t.fare_points) AS fare_points,
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
  WHERE (p_direction IS NULL OR r.direction = p_direction::public.route_direction)
    AND (v_stop_route_id IS NULL OR t.route_id = v_stop_route_id)
    AND t.service_date = v_cairo_today
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) TO authenticated;

-- =============================================================================
-- 5. UPDATE get_available_trips WITH EFFECTIVE BOOKING NOW
-- =============================================================================

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
  v_now timestamptz := public.get_effective_booking_now();
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
    AND t.booking_close_at > v_now
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_available_trips(text, date, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_available_trips(text, date, uuid) TO authenticated;

-- =============================================================================
-- 6. UPDATE create_booking_hold WITH EFFECTIVE BOOKING NOW
-- =============================================================================

CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL,
  p_destination_route_stop_id uuid DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
AS $$
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
  ELSE
    SELECT id, fare_points INTO v_fare_zone_id, v_stop_fare
    FROM public.fare_zones
    WHERE route_id = v_trip.route_id AND is_active = true
    ORDER BY zone_order ASC
    LIMIT 1;

    v_effective_fare := COALESCE(v_stop_fare, v_trip.fare_points);
  END IF;

  v_effective_fare := COALESCE(v_stop_fare, v_trip.fare_points);

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

  -- Expire any previous active holds by THIS user for this trip
  FOR v_existing_hold IN
    SELECT id, point_hold_id FROM public.seat_holds
    WHERE trip_id = p_trip_id
      AND user_id = v_user_id
      AND status = 'active'
  LOOP
    UPDATE public.seat_holds SET status = 'cancelled' WHERE id = v_existing_hold.id;
    IF v_existing_hold.point_hold_id IS NOT NULL THEN
      UPDATE public.point_holds SET status = 'cancelled' WHERE id = v_existing_hold.point_hold_id;
      DELETE FROM public.point_hold_allocations WHERE hold_id = v_existing_hold.point_hold_id;
    END IF;
  END LOOP;

  -- 7. Wallet & Balance check
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

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

  -- 9. Create point hold record
  INSERT INTO public.point_holds (
    user_id,
    wallet_id,
    trip_id,
    amount,
    expires_at,
    status
  ) VALUES (
    v_user_id,
    v_wallet.id,
    p_trip_id,
    v_effective_fare,
    v_hold_expires_at,
    'active'
  ) RETURNING id INTO v_point_hold_id;

  -- Link point hold to seat hold
  UPDATE public.seat_holds
  SET point_hold_id = v_point_hold_id
  WHERE id = v_seat_hold_id;

  -- 10. FIFO Batch allocation
  v_remaining_needed := v_effective_fare;

  FOR v_batch IN
    SELECT id, remaining_points
    FROM public.point_batches
    WHERE wallet_id = v_wallet.id
      AND is_active = true
      AND remaining_points > 0
      AND expires_at > now()
    ORDER BY expires_at ASC
    FOR UPDATE
  LOOP
    EXIT WHEN v_remaining_needed <= 0;

    v_take := LEAST(v_batch.remaining_points, v_remaining_needed);

    INSERT INTO public.point_hold_allocations (
      hold_id,
      batch_id,
      allocated_points
    ) VALUES (
      v_point_hold_id,
      v_batch.id,
      v_take
    );

    v_remaining_needed := v_remaining_needed - v_take;
  END LOOP;

  IF v_remaining_needed > 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_UNEXPIRED_POINTS';
  END IF;

  -- 11. Recalculate cached wallet balances
  PERFORM public.recalculate_wallet_balance(v_wallet.id);

  RETURN jsonb_build_object(
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'route_stop_id', p_route_stop_id,
    'destination_route_stop_id', p_destination_route_stop_id,
    'stop_name', v_stop_name,
    'destination_stop_name', v_dest_stop_name,
    'fare_points', v_effective_fare,
    'expires_at', v_hold_expires_at
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) TO authenticated;

-- =============================================================================
-- 7. UPDATE get_passenger_home_summary WITH EFFECTIVE BOOKING NOW
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_passenger_home_summary()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_profile record;
  v_available_points numeric := 0;
  v_upcoming_trip jsonb := NULL;
  v_activity jsonb;
  v_month_start timestamptz;
  v_trips_this_month bigint := 0;
  v_completed_trips bigint := 0;
  v_points_spent_this_month numeric := 0;
  v_missed_trips bigint := 0;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'profile', jsonb_build_object(
        'full_name', 'Passenger',
        'avatar_url', NULL
      ),
      'wallet', jsonb_build_object(
        'available_points', 0
      ),
      'upcoming_trip', NULL,
      'activity', jsonb_build_object(
        'trips_this_month', 0,
        'completed_trips', 0,
        'points_spent_this_month', 0,
        'missed_trips', 0
      )
    );
  END IF;

  -- 1. Profile information
  SELECT full_name, avatar_url
  INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  -- 2. Wallet balance
  SELECT COALESCE(cached_available_balance, 0)
  INTO v_available_points
  FROM public.wallets
  WHERE user_id = v_user_id;

  -- 3. Nearest future active booking (Upcoming Trip) evaluated against effective now
  SELECT jsonb_build_object(
    'booking_id', bkg.id,
    'trip_id', t.id,
    'direction', r.direction::text,
    'origin_name_ar', r.origin_name_ar,
    'origin_name_en', r.origin_name_en,
    'destination_name_ar', r.destination_name_ar,
    'destination_name_en', r.destination_name_en,
    'service_date', t.service_date,
    'departure_at', t.departure_at,
    'departure_time', to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI'),
    'seat_number', bs.seat_number,
    'fare_points', bkg.fare_points,
    'booking_status', bkg.status::text,
    'qr_token', bkg.qr_token,
    'route_stop_id', bkg.route_stop_id,
    'stop_name_ar', s.name_ar,
    'locality_ar', s.locality_ar
  )
  INTO v_upcoming_trip
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.bus_seats bs ON bs.id = bkg.seat_id
  LEFT JOIN public.route_stops rs ON rs.id = bkg.route_stop_id
  LEFT JOIN public.stops s ON s.id = rs.stop_id
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'confirmed'
    AND t.status IN ('scheduled', 'boarding')
    AND t.departure_at >= v_now
  ORDER BY t.departure_at ASC
  LIMIT 1;

  -- 4. Activity metrics
  v_month_start := date_trunc('month', now() AT TIME ZONE 'Africa/Cairo') AT TIME ZONE 'Africa/Cairo';

  SELECT COUNT(*)
  INTO v_trips_this_month
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  WHERE bkg.user_id = v_user_id
    AND bkg.status != 'cancelled'
    AND t.departure_at >= v_month_start;

  SELECT COUNT(*)
  INTO v_completed_trips
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'confirmed'
    AND t.status = 'completed';

  SELECT COALESCE(SUM(pt.amount), 0)
  INTO v_points_spent_this_month
  FROM public.point_transactions pt
  WHERE pt.user_id = v_user_id
    AND pt.transaction_type = 'debit'
    AND pt.reference_type = 'booking'
    AND pt.created_at >= v_month_start;

  SELECT COUNT(*)
  INTO v_missed_trips
  FROM public.bookings bkg
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'no_show'
    AND bkg.booked_at >= v_month_start;

  v_activity := jsonb_build_object(
    'trips_this_month', v_trips_this_month,
    'completed_trips', v_completed_trips,
    'points_spent_this_month', v_points_spent_this_month,
    'missed_trips', v_missed_trips
  );

  RETURN jsonb_build_object(
    'profile', jsonb_build_object(
      'full_name', COALESCE(v_profile.full_name, 'Passenger'),
      'avatar_url', v_profile.avatar_url
    ),
    'wallet', jsonb_build_object(
      'available_points', v_available_points
    ),
    'upcoming_trip', v_upcoming_trip,
    'activity', v_activity
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_passenger_home_summary() TO anon, authenticated, service_role;
