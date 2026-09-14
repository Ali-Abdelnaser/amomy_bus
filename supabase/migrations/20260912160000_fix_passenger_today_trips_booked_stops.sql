-- =============================================================================
-- Migration: 20260912160000_fix_passenger_today_trips_booked_stops.sql
-- Description:
--   Updates get_passenger_today_trips RPC so that booked trips return the
--   passenger's actual selected boarding and drop-off stops (from bookings.route_stop_id
--   and bookings.destination_route_stop_id joined through route_stops and stops),
--   while unbooked trips safely fall back to the route's default origin/destination.
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_passenger_today_trips(text, uuid);

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
  v_cairo_today date := (current_timestamp AT TIME ZONE 'Africa/Cairo')::date;
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
      WHEN t.status = 'completed' OR t.departure_at <= now() THEN 'DEPARTED'
      WHEN t.status = 'cancelled' THEN 'CANCELLED'
      WHEN t.booking_close_at <= now() THEN 'BOOKING_CLOSED'
      WHEN tc.calc_available <= 0 THEN 'FULL'
      WHEN t.status IN ('scheduled', 'boarding') THEN 'AVAILABLE'
      ELSE 'UNAVAILABLE'
    END AS availability_status,
    (ub.b_id IS NULL AND
     t.status IN ('scheduled', 'boarding') AND
     t.departure_at > now() AND
     t.booking_close_at > now() AND
     tc.calc_available > 0) AS is_bookable
  FROM public.trips t
  JOIN public.routes r ON r.id = t.route_id
  JOIN trip_counts tc ON tc.c_trip_id = t.id
  LEFT JOIN user_bookings ub ON ub.b_trip_id = t.id
  WHERE (p_direction IS NULL OR r.direction = p_direction::public.route_direction)
    AND (v_stop_route_id IS NULL OR t.route_id = v_stop_route_id)
    AND t.service_date = v_cairo_today
  ORDER BY r.direction ASC, t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_today_trips(text, uuid) TO authenticated;
