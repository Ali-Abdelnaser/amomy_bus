-- ============================================================================
-- MIGRATION: 20260921230000_fix_passenger_today_trips_checkin_state.sql
-- Description: Expose checked_in_at and is_checked_in in get_passenger_today_trips
--              and prioritize FINISHED / DEPARTED over ALREADY_BOOKED.
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_passenger_today_trips(text, uuid);

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
  is_bookable boolean,
  checked_in_at timestamptz,
  is_checked_in boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_real_now timestamptz := now();
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
      bkg.checked_in_at AS b_raw_checked_in_at,
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
      (ARRAY_AGG(b_destination_name_en ORDER BY created_at ASC))[1] AS b_destination_name_en,
      COALESCE((ARRAY_AGG(b_raw_checked_in_at ORDER BY created_at ASC))[1], MAX(b_raw_checked_in_at)) AS b_checked_in_at,
      bool_or(b_raw_checked_in_at IS NOT NULL) AS b_is_checked_in
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
        WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > v_real_now
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
      WHEN ub.b_id IS NOT NULL AND (ub.b_checked_in_at IS NOT NULL OR ub.b_is_checked_in = true) THEN 'FINISHED'
      WHEN t.status = 'completed' THEN 'DEPARTED'
      WHEN t.status = 'cancelled' THEN 'CANCELLED'
      WHEN ub.b_id IS NOT NULL THEN 'ALREADY_BOOKED'
      WHEN t.departure_at <= v_now THEN 'DEPARTED'
      WHEN t.booking_close_at <= v_now THEN 'BOOKING_CLOSED'
      WHEN tc.calc_available <= 0 THEN 'FULL'
      WHEN t.status IN ('scheduled', 'boarding') THEN 'AVAILABLE'
      ELSE 'UNAVAILABLE'
    END AS availability_status,
    (ub.b_id IS NULL AND
     t.status IN ('scheduled', 'boarding') AND
     t.departure_at > v_now AND
     t.booking_close_at > v_now AND
     tc.calc_available > 0) AS is_bookable,
    ub.b_checked_in_at AS checked_in_at,
    COALESCE(ub.b_is_checked_in, false) AS is_checked_in
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
    AND public.is_service_day(t.service_date)
    AND (t.schedule_id IS NULL OR EXISTS (SELECT 1 FROM public.trip_schedules ts WHERE ts.id = t.schedule_id AND ts.is_active = true))
  ORDER BY t.departure_at ASC;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) TO authenticated;
