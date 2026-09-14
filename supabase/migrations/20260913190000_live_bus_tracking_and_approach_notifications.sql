-- Migration: 20260913190000_live_bus_tracking_and_approach_notifications.sql
-- Description: Authoritative live bus tracking, passenger RLS, stop progression, approach notifications, and QA telemetry simulation.

-- 1. USER PREFERENCE FOR APPROACH ALERTS
ALTER TABLE public.passenger_trip_preferences
  ADD COLUMN IF NOT EXISTS approach_alerts_enabled boolean NOT NULL DEFAULT true;

-- 2. PASSENGER RLS ON bus_live_locations
-- Allow all authenticated passengers to read active live location telemetry.
-- Do NOT allow any client-side inserts/updates (only service_role/internal can write).
DROP POLICY IF EXISTS passenger_can_read_booked_bus_live_location ON public.bus_live_locations;
DROP POLICY IF EXISTS authenticated_read_bus_live_locations ON public.bus_live_locations;

CREATE POLICY authenticated_read_bus_live_locations ON public.bus_live_locations
  FOR SELECT TO authenticated
  USING (true);

-- 3. BUS APPROACH NOTIFICATIONS (Strict Idempotency Table)
CREATE TABLE IF NOT EXISTS public.bus_approach_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  service_date date NOT NULL,
  service_run_time time NOT NULL,
  route_id uuid NOT NULL REFERENCES public.routes(id),
  target_stop_id uuid NOT NULL REFERENCES public.stops(id),
  notification_type text NOT NULL DEFAULT 'approaching',
  title_ar text NOT NULL,
  title_en text NOT NULL,
  body_ar text NOT NULL,
  body_en text NOT NULL,
  sent_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_bus_approach_notification_run 
    UNIQUE (user_id, service_date, service_run_time, route_id, target_stop_id, notification_type)
);

ALTER TABLE public.bus_approach_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_read_own_approach_notifications ON public.bus_approach_notifications;
CREATE POLICY user_read_own_approach_notifications ON public.bus_approach_notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS user_manage_own_approach_notifications ON public.bus_approach_notifications;
CREATE POLICY user_manage_own_approach_notifications ON public.bus_approach_notifications
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 4. PASSENGER APPROACH TARGET RESOLUTION
-- Priority 1: Today's booked boarding stop for the active run
-- Priority 2: Saved preferred boarding stop
-- Otherwise: NULL
CREATE OR REPLACE FUNCTION public.get_passenger_approach_target(
  p_user_id uuid,
  p_active_route_id uuid DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_target RECORD;
  v_pref RECORD;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- 1. Check for confirmed booking today on active route (or any route if not specified)
  SELECT 
    s.id AS stop_id,
    rs.id AS route_stop_id,
    rs.stop_order,
    s.name_ar,
    s.name_en,
    s.locality_ar,
    s.locality_en,
    s.latitude,
    s.longitude,
    'booking' AS source
  INTO v_target
  FROM public.bookings b
  JOIN public.trips t ON t.id = b.trip_id
  JOIN public.route_stops rs ON rs.id = b.route_stop_id
  JOIN public.stops s ON s.id = rs.stop_id
  WHERE b.user_id = p_user_id
    AND b.status = 'confirmed'
    AND t.service_date = v_cairo_today
    AND (p_active_route_id IS NULL OR t.route_id = p_active_route_id)
  ORDER BY t.departure_at ASC
  LIMIT 1;

  IF FOUND THEN
    RETURN to_jsonb(v_target);
  END IF;

  -- 2. Fallback to saved passenger preferred boarding stop
  SELECT 
    s.id AS stop_id,
    rs.id AS route_stop_id,
    COALESCE(rs.stop_order, 1) AS stop_order,
    s.name_ar,
    s.name_en,
    s.locality_ar,
    s.locality_en,
    s.latitude,
    s.longitude,
    'preference' AS source
  INTO v_pref
  FROM public.passenger_trip_preferences ptp
  JOIN public.stops s ON s.id = ptp.origin_stop_id
  LEFT JOIN public.route_stops rs ON rs.stop_id = s.id 
    AND (p_active_route_id IS NULL OR rs.route_id = p_active_route_id)
  WHERE ptp.user_id = p_user_id
  LIMIT 1;

  IF FOUND THEN
    RETURN to_jsonb(v_pref);
  END IF;

  RETURN NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_passenger_approach_target(uuid, uuid) TO authenticated;

-- 5. AUTHORITATIVE LIVE BUS TRACKING SUMMARY RPC
-- Evaluates Cairo time, operating windows, latest GPS freshness, active trip direction,
-- and stop coordinates.
CREATE OR REPLACE FUNCTION public.get_live_bus_tracking_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_now timestamp := (v_now AT TIME ZONE 'Africa/Cairo');
  v_cairo_time time := v_cairo_now::time;
  v_cairo_date date := v_cairo_now::date;

  -- Windows
  v_is_morning boolean := (v_cairo_time >= '08:00:00'::time AND v_cairo_time < '12:00:00'::time);
  v_is_afternoon boolean := (v_cairo_time >= '13:00:00'::time AND v_cairo_time < '17:00:00'::time);
  v_in_service_window boolean := (v_is_morning OR v_is_afternoon);

  v_tracking_status text;
  v_service_window text;
  v_active_direction text := NULL;
  v_active_route_id uuid := NULL;
  v_active_route_name_ar text := NULL;
  v_active_route_name_en text := NULL;
  v_active_run_time time := NULL;

  v_next_window_start text;
  v_next_window_is_tomorrow boolean := false;
  v_next_window_msg_ar text;
  v_next_window_msg_en text;

  -- Bus location
  v_bus RECORD;
  v_loc RECORD;
  v_is_stale boolean := true;
  v_age_seconds integer := NULL;
  v_bus_loc_json jsonb := NULL;

  -- Route stops
  v_stops_count integer := 0;
  v_stops_with_coords_count integer := 0;
  v_stops_json jsonb := '[]'::jsonb;
  v_target_json jsonb := NULL;
BEGIN
  -- Determine operating window and next resume time
  IF v_is_morning THEN
    v_service_window := 'morning';
    v_active_direction := 'outbound';
    v_active_route_id := '11111111-1111-1111-1111-111111111101'::uuid;
    v_active_route_name_ar := 'كوبرى عزت - بوابة توشكى';
    v_active_route_name_en := 'Ezzat Bridge - Toshka Gate';

    -- Determine active hourly run
    IF v_cairo_time < '09:00:00'::time THEN v_active_run_time := '08:00:00'::time;
    ELSIF v_cairo_time < '10:00:00'::time THEN v_active_run_time := '09:00:00'::time;
    ELSIF v_cairo_time < '11:00:00'::time THEN v_active_run_time := '10:00:00'::time;
    ELSE v_active_run_time := '11:00:00'::time;
    END IF;

  ELSIF v_is_afternoon THEN
    v_service_window := 'afternoon';
    v_active_direction := 'return';
    v_active_route_id := '11111111-1111-1111-1111-111111111102'::uuid;
    v_active_route_name_ar := 'بوابة توشكى - كوبرى عزت';
    v_active_route_name_en := 'Toshka Gate - Ezzat Bridge';

    -- Determine active hourly run
    IF v_cairo_time < '14:00:00'::time THEN v_active_run_time := '13:00:00'::time;
    ELSIF v_cairo_time < '15:00:00'::time THEN v_active_run_time := '14:00:00'::time;
    ELSIF v_cairo_time < '16:00:00'::time THEN v_active_run_time := '15:00:00'::time;
    ELSE v_active_run_time := '16:00:00'::time;
    END IF;

  ELSE
    v_service_window := 'offline';
    v_tracking_status := 'offline';

    IF v_cairo_time < '08:00:00'::time THEN
      v_next_window_start := '08:00';
      v_next_window_is_tomorrow := false;
      v_next_window_msg_ar := 'يستأنف تتبع الحافلة اليوم الساعة 08:00 صباحاً';
      v_next_window_msg_en := 'Bus tracking resumes today at 08:00 AM';
    ELSIF v_cairo_time >= '12:00:00'::time AND v_cairo_time < '13:00:00'::time THEN
      v_next_window_start := '13:00';
      v_next_window_is_tomorrow := false;
      v_next_window_msg_ar := 'يستأنف تتبع الحافلة الساعة 01:00 ظهراً';
      v_next_window_msg_en := 'Bus tracking resumes at 01:00 PM';
    ELSE
      v_next_window_start := '08:00';
      v_next_window_is_tomorrow := true;
      v_next_window_msg_ar := 'يستأنف تتبع الحافلة غداً الساعة 08:00 صباحاً';
      v_next_window_msg_en := 'Bus tracking resumes tomorrow at 08:00 AM';
    END IF;
  END IF;

  -- Pick latest live bus location
  SELECT 
    bll.bus_id,
    bll.latitude,
    bll.longitude,
    bll.speed_kmh,
    bll.heading,
    bll.gps_recorded_at,
    bll.updated_at
  INTO v_loc
  FROM public.bus_live_locations bll
  ORDER BY bll.gps_recorded_at DESC
  LIMIT 1;

  IF FOUND THEN
    v_age_seconds := GREATEST(0, EXTRACT(EPOCH FROM (v_now - v_loc.gps_recorded_at))::integer);
    -- Freshness threshold: 120 seconds
    v_is_stale := (v_age_seconds > 120);

    v_bus_loc_json := jsonb_build_object(
      'latitude', v_loc.latitude,
      'longitude', v_loc.longitude,
      'heading', v_loc.heading,
      'speed_kmh', v_loc.speed_kmh,
      'gps_recorded_at', v_loc.gps_recorded_at,
      'age_seconds', v_age_seconds,
      'is_stale', v_is_stale
    );

    IF v_in_service_window THEN
      IF v_is_stale THEN
        v_tracking_status := 'stale';
      ELSE
        v_tracking_status := 'online';
      END IF;
    END IF;
  ELSE
    IF v_in_service_window THEN
      v_tracking_status := 'stale';
    END IF;
  END IF;

  -- Load stops for active route (or default outbound if offline)
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL),
    COALESCE(jsonb_agg(
      jsonb_build_object(
        'route_stop_id', rs.id,
        'stop_id', s.id,
        'stop_order', rs.stop_order,
        'name_ar', s.name_ar,
        'name_en', s.name_en,
        'locality_ar', s.locality_ar,
        'locality_en', s.locality_en,
        'latitude', s.latitude,
        'longitude', s.longitude,
        'is_boarding', rs.is_boarding,
        'is_dropoff', rs.is_dropoff
      ) ORDER BY rs.stop_order ASC
    ), '[]'::jsonb)
  INTO v_stops_count, v_stops_with_coords_count, v_stops_json
  FROM public.route_stops rs
  JOIN public.stops s ON s.id = rs.stop_id
  WHERE rs.route_id = COALESCE(v_active_route_id, '11111111-1111-1111-1111-111111111101'::uuid)
    AND rs.is_active = true;

  -- Resolve passenger approach target if user is authenticated
  IF v_user_id IS NOT NULL THEN
    v_target_json := public.get_passenger_approach_target(v_user_id, v_active_route_id);
  END IF;

  RETURN jsonb_build_object(
    'tracking_status', v_tracking_status,
    'is_in_service_window', v_in_service_window,
    'service_window', v_service_window,
    'cairo_time', to_char(v_cairo_now, 'HH24:MI:SS'),
    'cairo_date', v_cairo_date,
    'active_direction', v_active_direction,
    'active_route_id', v_active_route_id,
    'active_route_name_ar', v_active_route_name_ar,
    'active_route_name_en', v_active_route_name_en,
    'active_run_time', CASE WHEN v_active_run_time IS NOT NULL THEN to_char(v_active_run_time, 'HH24:MI') ELSE NULL END,
    'next_window', CASE WHEN NOT v_in_service_window THEN jsonb_build_object(
      'start_time', v_next_window_start,
      'is_tomorrow', v_next_window_is_tomorrow,
      'message_ar', v_next_window_msg_ar,
      'message_en', v_next_window_msg_en
    ) ELSE NULL END,
    'bus_location', v_bus_loc_json,
    'stops_count', v_stops_count,
    'stops_with_coords_count', v_stops_with_coords_count,
    'has_stop_coordinates', (v_stops_with_coords_count > 0),
    'route_stops', v_stops_json,
    'passenger_target', v_target_json
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_live_bus_tracking_summary() TO authenticated;

-- 6. DISPATCH APPROACH NOTIFICATION RPC (Idempotent Server-Side Evaluation)
CREATE OR REPLACE FUNCTION public.record_approach_notification(
  p_route_id uuid,
  p_target_stop_id uuid,
  p_service_run_time time,
  p_title_ar text,
  p_title_en text,
  p_body_ar text,
  p_body_en text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_today date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_inserted_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'reason', 'UNAUTHENTICATED');
  END IF;

  -- Check if passenger enabled approach alerts
  IF EXISTS (
    SELECT 1 FROM public.passenger_trip_preferences 
    WHERE user_id = v_user_id AND approach_alerts_enabled = false
  ) THEN
    RETURN jsonb_build_object('success', false, 'reason', 'ALERTS_DISABLED');
  END IF;

  INSERT INTO public.bus_approach_notifications (
    user_id,
    service_date,
    service_run_time,
    route_id,
    target_stop_id,
    notification_type,
    title_ar,
    title_en,
    body_ar,
    body_en
  ) VALUES (
    v_user_id,
    v_cairo_today,
    p_service_run_time,
    p_route_id,
    p_target_stop_id,
    'approaching',
    p_title_ar,
    p_title_en,
    p_body_ar,
    p_body_en
  )
  ON CONFLICT ON CONSTRAINT uq_bus_approach_notification_run
  DO NOTHING
  RETURNING id INTO v_inserted_id;

  IF v_inserted_id IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', true,
      'dispatched', true,
      'notification_id', v_inserted_id
    );
  ELSE
    RETURN jsonb_build_object(
      'success', true,
      'dispatched', false,
      'reason', 'ALREADY_SENT_FOR_THIS_RUN'
    );
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.record_approach_notification(uuid, uuid, time, text, text, text, text) TO authenticated;

-- 7. QA LOCATION SIMULATION PROCEDURE (Phase 19)
-- Isolated, authorized for admin or active QA testers only.
CREATE OR REPLACE FUNCTION public.qa_simulate_bus_location(
  p_bus_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_heading integer DEFAULT 0,
  p_speed_kmh numeric DEFAULT 30
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_is_authorized boolean := false;
BEGIN
  -- Verify caller is admin or has QA override enabled
  IF app_private.is_admin() THEN
    v_is_authorized := true;
  ELSIF v_user_id IS NOT NULL THEN
    SELECT true INTO v_is_authorized
    FROM public.qa_booking_time_overrides
    WHERE user_id = v_user_id AND enabled = true;
  END IF;

  IF NOT COALESCE(v_is_authorized, false) THEN
    RAISE EXCEPTION 'UNAUTHORIZED_QA_SIMULATION: Requires admin or QA override privileges.';
  END IF;

  -- Validate coordinates
  IF p_latitude < -90 OR p_latitude > 90 OR p_longitude < -180 OR p_longitude > 180 THEN
    RAISE EXCEPTION 'INVALID_COORDINATES: Coordinates out of range.';
  END IF;

  -- Upsert bus_live_locations
  INSERT INTO public.bus_live_locations (
    bus_id,
    latitude,
    longitude,
    speed_kmh,
    heading,
    gps_recorded_at,
    last_synced_at,
    updated_at
  ) VALUES (
    p_bus_id,
    p_latitude,
    p_longitude,
    COALESCE(p_speed_kmh, 0),
    p_heading,
    v_now,
    now(),
    now()
  )
  ON CONFLICT (bus_id) DO UPDATE SET
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    speed_kmh = excluded.speed_kmh,
    heading = excluded.heading,
    gps_recorded_at = excluded.gps_recorded_at,
    last_synced_at = now(),
    updated_at = now();

  -- Insert history
  INSERT INTO public.bus_location_history (
    bus_id,
    latitude,
    longitude,
    speed_kmh,
    heading,
    gps_recorded_at
  ) VALUES (
    p_bus_id,
    p_latitude,
    p_longitude,
    COALESCE(p_speed_kmh, 0),
    p_heading,
    v_now
  )
  ON CONFLICT DO NOTHING;

  RETURN jsonb_build_object(
    'success', true,
    'bus_id', p_bus_id,
    'latitude', p_latitude,
    'longitude', p_longitude,
    'recorded_at', v_now
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.qa_simulate_bus_location(uuid, double precision, double precision, integer, numeric) TO authenticated;
