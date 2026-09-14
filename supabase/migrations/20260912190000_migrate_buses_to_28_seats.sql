-- ============================================================================
-- Migration: 20260912190000_migrate_buses_to_28_seats.sql
-- Description:
-- 1. Adds seat_number_snapshot to public.bookings and backfills legacy bookings
-- 2. Migrates existing 14 seats per bus in-place to final physical numbering (1..28)
--    preserving existing UUIDs and FK integrity.
-- 3. Inserts the 14 new physical seats per bus (bringing fleet to 28 seats each).
-- 4. Updates public.buses capacity to 28.
-- 5. Updates staff_get_today_trips to use dynamic b.capacity instead of 14.
-- 6. Updates confirm_booking, get_passenger_bookings, staff_lookup_booking_by_qr,
--    and get_passenger_today_trips to record/prefer seat_number_snapshot.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ADD seat_number_snapshot TO public.bookings AND BACKFILL
-- ----------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS seat_number_snapshot text;

-- Backfill historical bookings with current seat numbers (1A, 1B, etc.)
UPDATE public.bookings b
SET seat_number_snapshot = bs.seat_number
FROM public.bus_seats bs
WHERE b.seat_id = bs.id
  AND b.seat_number_snapshot IS NULL;

-- ----------------------------------------------------------------------------
-- 2. UPDATE EXISTING 14 SEATS PER BUS IN-PLACE (PRESERVING UUIDs)
-- ----------------------------------------------------------------------------
UPDATE public.bus_seats SET seat_number = '1',  row_index = 0, column_index = 3 WHERE seat_number = '1A';
UPDATE public.bus_seats SET seat_number = '2',  row_index = 1, column_index = 0 WHERE seat_number = '1B';
UPDATE public.bus_seats SET seat_number = '3',  row_index = 1, column_index = 1 WHERE seat_number = '1C';
UPDATE public.bus_seats SET seat_number = '4',  row_index = 2, column_index = 0 WHERE seat_number = '2A';
UPDATE public.bus_seats SET seat_number = '5',  row_index = 2, column_index = 1 WHERE seat_number = '2B';
UPDATE public.bus_seats SET seat_number = '6',  row_index = 3, column_index = 0 WHERE seat_number = '3A';
UPDATE public.bus_seats SET seat_number = '14', row_index = 1, column_index = 2 WHERE seat_number = '2C';
UPDATE public.bus_seats SET seat_number = '15', row_index = 1, column_index = 3 WHERE seat_number = '3B';
UPDATE public.bus_seats SET seat_number = '16', row_index = 2, column_index = 2 WHERE seat_number = '3C';
UPDATE public.bus_seats SET seat_number = '24', row_index = 7, column_index = 0 WHERE seat_number = '4A';
UPDATE public.bus_seats SET seat_number = '25', row_index = 7, column_index = 1 WHERE seat_number = '4B';
UPDATE public.bus_seats SET seat_number = '26', row_index = 7, column_index = 2 WHERE seat_number = '4C';
UPDATE public.bus_seats SET seat_number = '27', row_index = 7, column_index = 3 WHERE seat_number = '4D';
UPDATE public.bus_seats SET seat_number = '28', row_index = 7, column_index = 4 WHERE seat_number = '4E';

-- ----------------------------------------------------------------------------
-- 3. INSERT THE 14 NEW PHYSICAL SEATS FOR EACH BUS
-- ----------------------------------------------------------------------------
INSERT INTO public.bus_seats (bus_id, seat_number, row_index, column_index, seat_type, is_active)
SELECT 
  b.id,
  s.seat_number,
  s.row_index,
  s.column_index,
  'standard',
  true
FROM public.buses b
CROSS JOIN (
  VALUES
    ('7', 3, 1),
    ('8', 4, 0),
    ('9', 4, 1),
    ('10', 5, 0),
    ('11', 5, 1),
    ('12', 6, 0),
    ('13', 6, 1),
    ('17', 2, 3),
    ('18', 3, 2),
    ('19', 3, 3),
    ('20', 4, 2),
    ('21', 4, 3),
    ('22', 5, 2),
    ('23', 5, 3)
) AS s(seat_number, row_index, column_index)
ON CONFLICT (bus_id, seat_number) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. UPDATE ALL BUSES CAPACITY TO 28
-- ----------------------------------------------------------------------------
UPDATE public.buses
SET capacity = 28;

-- ----------------------------------------------------------------------------
-- 5. UPDATE staff_get_today_trips TO DYNAMIC BUS CAPACITY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_get_today_trips()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_staff_id uuid;
  v_result jsonb;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'trip_id', t.id,
      'service_date', t.service_date,
      'departure_at', t.departure_at,
      'status', t.status,
      'origin_name_ar', r.origin_name_ar,
      'origin_name_en', r.origin_name_en,
      'destination_name_ar', r.destination_name_ar,
      'destination_name_en', r.destination_name_en,
      'booked_count', COALESCE(b_counts.booked_count, 0),
      'checked_in_count', COALESCE(b_counts.checked_in_count, 0),
      'total_capacity', b.capacity
    ) ORDER BY t.departure_at ASC
  ) INTO v_result
  FROM public.trips t
  JOIN public.routes r ON t.route_id = r.id
  JOIN public.buses b ON b.id = t.bus_id
  LEFT JOIN (
    SELECT
      trip_id,
      COUNT(id) FILTER (WHERE status = 'confirmed') as booked_count,
      COUNT(id) FILTER (WHERE status = 'confirmed' AND checked_in_at IS NOT NULL) as checked_in_count
    FROM public.bookings
    GROUP BY trip_id
  ) b_counts ON b_counts.trip_id = t.id
  WHERE t.service_date = CURRENT_DATE
    AND t.status != 'cancelled';

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$function$;

-- ----------------------------------------------------------------------------
-- 6. UPDATE confirm_booking TO RECORD seat_number_snapshot
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
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
  v_pref_orig_stop_id uuid;
  v_pref_dest_stop_id uuid;
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

  -- Create confirmed booking with authoritative seat_number_snapshot
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

  -- Consume allocated point batches
  FOR v_alloc IN
    SELECT batch_id, amount
    FROM public.point_hold_allocations
    WHERE hold_id = v_point_hold.id
  LOOP
    UPDATE public.point_batches
    SET remaining_amount = remaining_amount - v_alloc.amount,
        updated_at = now()
    WHERE id = v_alloc.batch_id;

    INSERT INTO public.point_ledger (
      wallet_id,
      user_id,
      delta_points,
      balance_after,
      reason,
      reference_type,
      reference_id,
      created_at
    ) VALUES (
      v_wallet.id,
      v_user_id,
      -v_alloc.amount,
      v_wallet.cached_available_balance,
      'booking_payment',
      'booking',
      v_booking_id,
      now()
    );
  END LOOP;

  -- Mark holds as fulfilled
  UPDATE public.seat_holds SET status = 'fulfilled', updated_at = now() WHERE id = p_hold_id;
  UPDATE public.point_holds SET status = 'fulfilled', updated_at = now() WHERE id = v_point_hold.id;

  -- Update cached held balance in wallet
  UPDATE public.wallets
  SET cached_held_balance = cached_held_balance - v_fare_points,
      updated_at = now()
  WHERE id = v_wallet.id;

  -- AUTO-UPSERT PREFERRED JOURNEY
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
    'destination_name_en', (SELECT destination_name_en FROM public.routes WHERE id = v_trip.route_id)
  );
END;
$function$;

-- ----------------------------------------------------------------------------
-- 7. UPDATE get_passenger_bookings TO PREFER seat_number_snapshot
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_passenger_bookings()
 RETURNS TABLE(booking_id uuid, trip_id uuid, direction text, origin_name_ar text, origin_name_en text, destination_name_ar text, destination_name_en text, service_date date, departure_time text, departure_at timestamp with time zone, seat_number text, fare_points numeric, status text, qr_token text, booked_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  RETURN QUERY
  SELECT
    bkg.id AS booking_id,
    t.id AS trip_id,
    r.direction::text AS direction,
    r.origin_name_ar,
    r.origin_name_en,
    r.destination_name_ar,
    r.destination_name_en,
    t.service_date,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    COALESCE(bkg.seat_number_snapshot, bs.seat_number) AS seat_number,
    bkg.fare_points,
    bkg.status::text AS status,
    bkg.qr_token,
    bkg.booked_at
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.bus_seats bs ON bs.id = bkg.seat_id
  WHERE bkg.user_id = v_user_id
  ORDER BY t.departure_at DESC;
END;
$function$;

-- ----------------------------------------------------------------------------
-- 8. UPDATE staff_lookup_booking_by_qr TO PREFER seat_number_snapshot
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.staff_lookup_booking_by_qr(p_qr_token text, p_expected_trip_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_staff_id uuid;
  v_booking record;
  v_trip record;
  v_passenger record;
  v_seat record;
  v_route record;
  v_validation_code text;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  IF p_qr_token IS NULL OR trim(p_qr_token) = '' THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'QR token cannot be empty'
    );
  END IF;

  SELECT * INTO v_booking
  FROM public.bookings
  WHERE qr_token = trim(p_qr_token);

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'No booking found matching this QR code'
    );
  END IF;

  SELECT t.*, r.origin_name_ar, r.origin_name_en, r.destination_name_ar, r.destination_name_en
  INTO v_trip
  FROM public.trips t
  JOIN public.routes r ON t.route_id = r.id
  WHERE t.id = v_booking.trip_id;

  SELECT id, full_name, avatar_url, gender
  INTO v_passenger
  FROM public.profiles
  WHERE id = v_booking.user_id;

  SELECT seat_number
  INTO v_seat
  FROM public.bus_seats
  WHERE id = v_booking.seat_id;

  IF v_booking.status = 'cancelled' THEN
    v_validation_code := 'CANCELLED_BOOKING';
  ELSIF v_booking.checked_in_at IS NOT NULL THEN
    v_validation_code := 'ALREADY_CHECKED_IN';
  ELSIF p_expected_trip_id IS NOT NULL AND v_booking.trip_id != p_expected_trip_id THEN
    v_validation_code := 'WRONG_TRIP';
  ELSIF v_trip.status = 'completed' THEN
    v_validation_code := 'TRIP_COMPLETED';
  ELSIF v_trip.status = 'cancelled' THEN
    v_validation_code := 'CANCELLED_BOOKING';
  ELSIF v_trip.departure_at > (now() + interval '2 hours') THEN
    v_validation_code := 'TOO_EARLY';
  ELSE
    v_validation_code := 'VALID';
  END IF;

  RETURN jsonb_build_object(
    'validation_code', v_validation_code,
    'booking_id', v_booking.id,
    'passenger_id', v_passenger.id,
    'passenger_display_name', v_passenger.full_name,
    'passenger_avatar_url', v_passenger.avatar_url,
    'gender', v_passenger.gender,
    'seat_number', COALESCE(v_booking.seat_number_snapshot, v_seat.seat_number),
    'trip_id', v_trip.id,
    'route_origin_ar', v_trip.origin_name_ar,
    'route_origin_en', v_trip.origin_name_en,
    'route_destination_ar', v_trip.destination_name_ar,
    'route_destination_en', v_trip.destination_name_en,
    'departure_at', v_trip.departure_at,
    'service_date', v_trip.service_date,
    'trip_status', v_trip.status,
    'booking_status', v_booking.status,
    'checked_in_at', v_booking.checked_in_at
  );
END;
$function$;

-- ----------------------------------------------------------------------------
-- 9. UPDATE get_passenger_today_trips TO PREFER seat_number_snapshot
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_passenger_today_trips(p_direction text DEFAULT NULL::text, p_origin_route_stop_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(trip_id uuid, route_id uuid, direction text, service_date date, origin_name_ar text, origin_name_en text, destination_name_ar text, destination_name_en text, departure_time text, departure_at timestamp with time zone, booking_close_at timestamp with time zone, fare_points numeric, total_seats integer, available_seats integer, status text, already_booked boolean, booking_id uuid, seat_number text, qr_token text, availability_status text, is_bookable boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
AS $function$
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
      COALESCE(bkg.seat_number_snapshot, bs.seat_number) AS b_seat_number,
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
$function$;

-- ----------------------------------------------------------------------------
-- 10. UPDATE get_trip_seat_map TO ORDER BY seat_number NUMERICALLY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_trip_seat_map(p_trip_id uuid)
 RETURNS TABLE(seat_id uuid, seat_number text, row_index integer, column_index integer, seat_type text, status text, is_mine boolean, passenger_gender text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_bus_id uuid;
BEGIN
  SELECT bus_id INTO v_bus_id
  FROM public.trips
  WHERE id = p_trip_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  RETURN QUERY
  SELECT
    bs.id AS seat_id,
    bs.seat_number,
    bs.row_index,
    bs.column_index,
    bs.seat_type,
    CASE
      WHEN bkg.id IS NOT NULL THEN 'booked'
      WHEN sh.id IS NOT NULL THEN 'held'
      ELSE 'available'
    END AS status,
    CASE
      WHEN bkg.user_id = v_user_id THEN true
      WHEN sh.user_id = v_user_id THEN true
      ELSE false
    END AS is_mine,
    CASE
      WHEN bkg.id IS NOT NULL THEN prof.gender
      ELSE NULL
    END AS passenger_gender
  FROM public.bus_seats bs
  LEFT JOIN public.bookings bkg
    ON bkg.trip_id = p_trip_id
    AND bkg.seat_id = bs.id
    AND bkg.status = 'confirmed'
  LEFT JOIN public.profiles prof
    ON prof.id = bkg.user_id
  LEFT JOIN public.seat_holds sh
    ON sh.trip_id = p_trip_id
    AND sh.seat_id = bs.id
    AND sh.status = 'active'
    AND sh.expires_at > now()
  WHERE bs.bus_id = v_bus_id
    AND bs.is_active = true
  ORDER BY (bs.seat_number::integer) ASC;
END;
$function$;
