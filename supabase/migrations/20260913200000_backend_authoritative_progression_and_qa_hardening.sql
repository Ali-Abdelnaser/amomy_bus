-- Migration: 20260913200000_backend_authoritative_progression_and_qa_hardening.sql
-- Purpose: 
-- 1. Extend bus_live_locations with backend-authoritative progression, active trip identity, and service run state.
-- 2. Implement app_private.compute_bus_progression() with monotonic forward progression and dual-radius hysteresis (80m enter / 130m leave).
-- 3. Gracefully flag coordinates_unavailable when stop coordinates are missing in DB without fabricating data.
-- 4. Harden qa_simulate_bus_location so ordinary passengers cannot simulate fake bus telemetry.
-- 5. Update get_live_bus_tracking_summary() to deliver canonical progression to all passengers.

-- 1. Schema Extensions for bus_live_locations
ALTER TABLE public.bus_live_locations
  ADD COLUMN IF NOT EXISTS active_trip_id uuid REFERENCES public.trips(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS service_run_time text,
  ADD COLUMN IF NOT EXISTS direction text DEFAULT 'outbound',
  ADD COLUMN IF NOT EXISTS service_state text DEFAULT 'offline',
  ADD COLUMN IF NOT EXISTS current_stop_id uuid REFERENCES public.stops(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS next_stop_id uuid REFERENCES public.stops(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS current_stop_order integer,
  ADD COLUMN IF NOT EXISTS next_stop_order integer,
  ADD COLUMN IF NOT EXISTS progress_state text DEFAULT 'idle',
  ADD COLUMN IF NOT EXISTS stop_arrival_radius_m numeric DEFAULT 80.0,
  ADD COLUMN IF NOT EXISTS stop_departure_radius_m numeric DEFAULT 130.0;

-- 2. Function: compute_bus_progression
CREATE OR REPLACE FUNCTION app_private.compute_bus_progression(p_bus_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_time time := (v_now AT TIME ZONE 'Africa/Cairo')::time;
  v_cairo_date date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_loc record;
  v_active_trip_id uuid := null;
  v_direction text := 'outbound';
  v_service_state text := 'offline';
  v_progress_state text := 'idle';
  v_service_run_time text := null;
  v_in_service_window boolean := false;
  v_is_stale boolean := false;
  v_age_seconds integer := 0;
  v_stops_count integer := 0;
  v_stops_with_coords integer := 0;
  v_current_stop_id uuid := null;
  v_next_stop_id uuid := null;
  v_current_stop_order integer := null;
  v_next_stop_order integer := null;
  v_prev_stop_order integer := null;
  v_min_dist numeric := 99999999;
  v_stop record;
  v_route_id uuid := null;
  v_elapsed_minutes integer := 0;
  v_trip_rec record;
BEGIN
  -- 1. Fetch current live location row
  SELECT * INTO v_loc
  FROM public.bus_live_locations
  WHERE bus_id = p_bus_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'reason', 'BUS_LOCATION_NOT_FOUND');
  END IF;

  -- 2. Determine Service Window & Direction
  IF v_cairo_time >= '08:00:00'::time AND v_cairo_time < '12:00:00'::time THEN
    v_in_service_window := true;
    v_direction := 'outbound';
    IF v_cairo_time < '09:00:00'::time THEN
      v_service_run_time := '08:00';
    ELSIF v_cairo_time < '10:00:00'::time THEN
      v_service_run_time := '09:00';
    ELSIF v_cairo_time < '11:00:00'::time THEN
      v_service_run_time := '10:00';
    ELSE
      v_service_run_time := '11:00';
    END IF;
  ELSIF v_cairo_time >= '13:00:00'::time AND v_cairo_time < '17:00:00'::time THEN
    v_in_service_window := true;
    v_direction := 'return';
    IF v_cairo_time < '14:00:00'::time THEN
      v_service_run_time := '13:00';
    ELSIF v_cairo_time < '15:00:00'::time THEN
      v_service_run_time := '14:00';
    ELSIF v_cairo_time < '16:00:00'::time THEN
      v_service_run_time := '15:00';
    ELSE
      v_service_run_time := '16:00';
    END IF;
  ELSE
    v_in_service_window := false;
    v_service_state := 'offline';
    v_progress_state := 'offline';
  END IF;

  -- 3. Match Authoritative Scheduled Trip for this bus & run
  IF v_in_service_window THEN
    SELECT t.id, t.route_id, t.departure_at, t.service_date, r.direction
    INTO v_trip_rec
    FROM public.trips t
    JOIN public.routes r ON r.id = t.route_id
    WHERE t.bus_id = p_bus_id
      AND t.service_date = v_cairo_date
      AND to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') = v_service_run_time
    LIMIT 1;

    -- Fallback: if no bus-specific trip row is assigned for this exact minute, find scheduled trip on the route
    IF v_trip_rec.id IS NULL THEN
      SELECT t.id, t.route_id, t.departure_at, t.service_date, r.direction
      INTO v_trip_rec
      FROM public.trips t
      JOIN public.routes r ON r.id = t.route_id
      WHERE t.service_date = v_cairo_date
        AND r.direction::text = v_direction
        AND to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') = v_service_run_time
      LIMIT 1;
    END IF;

    IF v_trip_rec.id IS NOT NULL THEN
      v_active_trip_id := v_trip_rec.id;
      v_route_id := v_trip_rec.route_id;
      v_direction := v_trip_rec.direction::text;
    ELSE
      -- Fallback to canonical routes if no trips scheduled for date
      IF v_direction = 'outbound' THEN
        v_route_id := '11111111-1111-1111-1111-111111111101'::uuid;
      ELSE
        v_route_id := '11111111-1111-1111-1111-111111111102'::uuid;
      END IF;
    END IF;

    -- 4. Check Freshness
    v_age_seconds := GREATEST(0, EXTRACT(EPOCH FROM (v_now - v_loc.gps_recorded_at))::integer);
    v_is_stale := (v_age_seconds > 120);

    -- 5. Calculate Between-Run vs In-Service State
    -- Standard run window is ~45 minutes. Minutes 45-60 represent between-runs recovery/repositioning.
    v_elapsed_minutes := EXTRACT(MINUTE FROM v_cairo_time)::integer;
    IF v_elapsed_minutes >= 48 THEN
      v_service_state := 'between_runs';
      v_progress_state := 'between_runs';
    ELSIF v_is_stale THEN
      v_service_state := 'stale';
      v_progress_state := 'stale';
    ELSE
      v_service_state := 'in_service';
      v_progress_state := 'in_transit';
    END IF;
  END IF;

  -- 6. Stop Progression Evaluation
  IF v_in_service_window AND v_route_id IS NOT NULL THEN
    -- Check if coordinates exist
    SELECT COUNT(*), COUNT(*) FILTER (WHERE s.latitude IS NOT NULL AND s.longitude IS NOT NULL)
    INTO v_stops_count, v_stops_with_coords
    FROM public.route_stops rs
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.route_id = v_route_id AND rs.is_active = true;

    IF v_stops_with_coords < v_stops_count OR v_stops_with_coords = 0 THEN
      -- Coordinates are not yet populated in backend
      v_progress_state := 'coordinates_unavailable';
      v_current_stop_id := null;
      v_next_stop_id := null;
      v_current_stop_order := null;
      v_next_stop_order := null;
    ELSE
      -- Coordinates are present: compute geodesic distance with monotonic forward progression
      v_prev_stop_order := COALESCE(v_loc.current_stop_order, 1);

      FOR v_stop IN
        SELECT rs.stop_order, s.id as stop_id, s.latitude, s.longitude,
               (6371000 * acos(
                 cos(radians(v_loc.latitude)) * cos(radians(s.latitude)) *
                 cos(radians(s.longitude) - radians(v_loc.longitude)) +
                 sin(radians(v_loc.latitude)) * sin(radians(s.latitude))
               )) as dist_m
        FROM public.route_stops rs
        JOIN public.stops s ON s.id = rs.stop_id
        WHERE rs.route_id = v_route_id AND rs.is_active = true
          AND s.latitude IS NOT NULL AND s.longitude IS NOT NULL
        ORDER BY rs.stop_order ASC
      LOOP
        -- Enforce monotonic progression: cannot drop below previous stop order in the same run
        IF v_stop.stop_order >= v_prev_stop_order THEN
          IF v_stop.dist_m < v_min_dist THEN
            v_min_dist := v_stop.dist_m;
            v_current_stop_order := v_stop.stop_order;
            v_current_stop_id := v_stop.stop_id;
          END IF;
        END IF;
      END LOOP;

      -- Apply Hysteresis:
      -- <= 80m: at_stop
      -- > 130m: departed / in_transit
      IF v_min_dist <= COALESCE(v_loc.stop_arrival_radius_m, 80.0) THEN
        v_progress_state := 'at_stop';
      ELSIF v_min_dist > COALESCE(v_loc.stop_departure_radius_m, 130.0) THEN
        v_progress_state := 'departed';
      ELSE
        v_progress_state := 'in_transit';
      END IF;

      -- Next Stop resolution
      IF v_current_stop_order IS NOT NULL AND v_current_stop_order < v_stops_count THEN
        v_next_stop_order := v_current_stop_order + 1;
        SELECT s.id INTO v_next_stop_id
        FROM public.route_stops rs
        JOIN public.stops s ON s.id = rs.stop_id
        WHERE rs.route_id = v_route_id AND rs.stop_order = v_next_stop_order
        LIMIT 1;
      ELSE
        v_next_stop_id := null;
        v_next_stop_order := null;
        IF v_current_stop_order = v_stops_count THEN
          v_service_state := 'between_runs';
          v_progress_state := 'between_runs';
        END IF;
      END IF;
    END IF;
  END IF;

  -- 7. Persist authoritative progression back to bus_live_locations
  UPDATE public.bus_live_locations
  SET
    active_trip_id = v_active_trip_id,
    service_run_time = v_service_run_time,
    direction = v_direction,
    service_state = v_service_state,
    current_stop_id = v_current_stop_id,
    next_stop_id = v_next_stop_id,
    current_stop_order = v_current_stop_order,
    next_stop_order = v_next_stop_order,
    progress_state = v_progress_state,
    updated_at = now()
  WHERE bus_id = p_bus_id;

  RETURN jsonb_build_object(
    'success', true,
    'bus_id', p_bus_id,
    'active_trip_id', v_active_trip_id,
    'service_run_time', v_service_run_time,
    'direction', v_direction,
    'service_state', v_service_state,
    'progress_state', v_progress_state,
    'current_stop_id', v_current_stop_id,
    'next_stop_id', v_next_stop_id,
    'current_stop_order', v_current_stop_order,
    'next_stop_order', v_next_stop_order
  );
END;
$$;

-- 3. Security Hardening for QA Location Simulation
-- Enforce: ADMIN or explicit QA override ONLY. Reject ordinary passengers.
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
  -- Strict permission check
  IF app_private.is_admin() THEN
    v_is_authorized := true;
  ELSIF v_user_id IS NOT NULL THEN
    -- Check explicit QA override
    SELECT true INTO v_is_authorized
    FROM public.qa_booking_time_overrides
    WHERE user_id = v_user_id AND enabled = true;

    -- Or check admin/super_admin user role
    IF NOT COALESCE(v_is_authorized, false) THEN
      SELECT true INTO v_is_authorized
      FROM public.user_roles
      WHERE user_id = v_user_id AND role IN ('admin', 'super_admin');
    END IF;
  END IF;

  IF NOT COALESCE(v_is_authorized, false) THEN
    RAISE EXCEPTION 'UNAUTHORIZED_QA_SIMULATION: Ordinary passengers cannot simulate bus telemetry.';
  END IF;

  -- Validate coordinate sanity
  IF p_latitude < -90 OR p_latitude > 90 OR p_longitude < -180 OR p_longitude > 180 THEN
    RAISE EXCEPTION 'INVALID_COORDINATES: Coordinates out of geographic range.';
  END IF;

  -- Upsert simulated location
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
    p_speed_kmh,
    p_heading,
    v_now,
    v_now,
    v_now
  )
  ON CONFLICT (bus_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    speed_kmh = EXCLUDED.speed_kmh,
    heading = EXCLUDED.heading,
    gps_recorded_at = EXCLUDED.gps_recorded_at,
    last_synced_at = EXCLUDED.last_synced_at,
    updated_at = EXCLUDED.updated_at;

  -- Trigger progression recalculation
  PERFORM app_private.compute_bus_progression(p_bus_id);

  RETURN jsonb_build_object(
    'success', true,
    'bus_id', p_bus_id,
    'simulated_at', v_now
  );
END;
$$;

REVOKE ALL ON FUNCTION public.qa_simulate_bus_location(uuid, double precision, double precision, integer, numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.qa_simulate_bus_location(uuid, double precision, double precision, integer, numeric) FROM anon;
GRANT EXECUTE ON FUNCTION public.qa_simulate_bus_location(uuid, double precision, double precision, integer, numeric) TO authenticated;

-- 4. Update get_live_bus_tracking_summary() to include backend progression
CREATE OR REPLACE FUNCTION public.get_live_bus_tracking_summary()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_cairo_time time := (v_now AT TIME ZONE 'Africa/Cairo')::time;
  v_cairo_date date := (v_now AT TIME ZONE 'Africa/Cairo')::date;
  v_in_service_window boolean := false;
  v_service_window text := 'offline';
  v_active_direction text := 'outbound';
  v_tracking_status text := 'offline';
  v_service_state text := 'offline';
  v_progress_state text := 'idle';
  v_active_run_time text := null;
  v_service_run_time text := null;
  v_active_route_id uuid := null;
  v_active_trip_id uuid := null;
  v_active_route_name_ar text := null;
  v_active_route_name_en text := null;
  v_bus_loc_json jsonb := null;
  v_next_window_json jsonb := null;
  v_stops_json jsonb := '[]'::jsonb;
  v_stops_count integer := 0;
  v_stops_with_coords_count integer := 0;
  v_target_json jsonb := null;
  v_loc record;
  v_age_seconds integer := 0;
  v_is_stale boolean := true;
  v_current_stop record;
  v_next_stop record;
  v_current_stop_json jsonb := null;
  v_next_stop_json jsonb := null;
  v_approach_alerts_enabled boolean := true;
BEGIN
  -- Check Passenger approach preference
  IF v_user_id IS NOT NULL THEN
    SELECT COALESCE(approach_alerts_enabled, true)
    INTO v_approach_alerts_enabled
    FROM public.passenger_trip_preferences
    WHERE user_id = v_user_id;
    IF NOT FOUND THEN
      v_approach_alerts_enabled := true;
    END IF;
  END IF;

  -- 1. Determine Window & Active Direction
  IF v_cairo_time >= '08:00:00'::time AND v_cairo_time < '12:00:00'::time THEN
    v_in_service_window := true;
    v_service_window := 'morning';
    v_active_direction := 'outbound';
    IF v_cairo_time < '09:00:00'::time THEN
      v_active_run_time := '08:00';
    ELSIF v_cairo_time < '10:00:00'::time THEN
      v_active_run_time := '09:00';
    ELSIF v_cairo_time < '11:00:00'::time THEN
      v_active_run_time := '10:00';
    ELSE
      v_active_run_time := '11:00';
    END IF;
  ELSIF v_cairo_time >= '13:00:00'::time AND v_cairo_time < '17:00:00'::time THEN
    v_in_service_window := true;
    v_service_window := 'afternoon';
    v_active_direction := 'return';
    IF v_cairo_time < '14:00:00'::time THEN
      v_active_run_time := '13:00';
    ELSIF v_cairo_time < '15:00:00'::time THEN
      v_active_run_time := '14:00';
    ELSIF v_cairo_time < '16:00:00'::time THEN
      v_active_run_time := '15:00';
    ELSE
      v_active_run_time := '16:00';
    END IF;
  ELSE
    v_in_service_window := false;
    v_service_window := 'offline';
    v_tracking_status := 'offline';
    v_service_state := 'offline';
    v_progress_state := 'offline';

    IF v_cairo_time < '08:00:00'::time THEN
      v_next_window_json := jsonb_build_object(
        'start_time', '08:00',
        'is_tomorrow', false,
        'message_ar', 'يستأنف تتبع الحافلة اليوم في تمام الساعة 08:00 صباحاً',
        'message_en', 'Bus tracking resumes today at 08:00 AM'
      );
    ELSIF v_cairo_time >= '12:00:00'::time AND v_cairo_time < '13:00:00'::time THEN
      v_next_window_json := jsonb_build_object(
        'start_time', '13:00',
        'is_tomorrow', false,
        'message_ar', 'يستأنف تتبع الحافلة لرحلات العودة الساعة 01:00 ظهراً',
        'message_en', 'Bus tracking resumes for return trips at 01:00 PM'
      );
    ELSE
      v_next_window_json := jsonb_build_object(
        'start_time', '08:00',
        'is_tomorrow', true,
        'message_ar', 'انتهت رحلات اليوم. يستأنف تتبع الحافلة غداً الساعة 08:00 صباحاً',
        'message_en', 'Service completed today. Bus tracking resumes tomorrow at 08:00 AM'
      );
    END IF;
  END IF;

  -- 2. Route details
  IF v_active_direction = 'outbound' THEN
    v_active_route_id := '11111111-1111-1111-1111-111111111101'::uuid;
    v_active_route_name_ar := 'كوبرى عزت - بوابة توشكى';
    v_active_route_name_en := 'Ezzat Bridge - Toshka Gate';
  ELSE
    v_active_route_id := '11111111-1111-1111-1111-111111111102'::uuid;
    v_active_route_name_ar := 'بوابة توشكى - كوبرى عزت';
    v_active_route_name_en := 'Toshka Gate - Ezzat Bridge';
  END IF;

  -- 3. Authoritative Latest Bus Location & Progression
  SELECT bll.*
  INTO v_loc
  FROM public.bus_live_locations bll
  WHERE bll.latitude IS NOT NULL AND bll.longitude IS NOT NULL
  ORDER BY bll.gps_recorded_at DESC
  LIMIT 1;

  IF FOUND THEN
    -- Ensure backend progression is refreshed
    PERFORM app_private.compute_bus_progression(v_loc.bus_id);

    -- Re-read refreshed progression fields
    SELECT * INTO v_loc
    FROM public.bus_live_locations
    WHERE bus_id = v_loc.bus_id;

    v_age_seconds := GREATEST(0, EXTRACT(EPOCH FROM (v_now - v_loc.gps_recorded_at))::integer);
    v_is_stale := (v_age_seconds > 120);
    v_service_state := COALESCE(v_loc.service_state, 'offline');
    v_progress_state := COALESCE(v_loc.progress_state, 'idle');
    v_active_trip_id := v_loc.active_trip_id;

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

    -- Fetch current and next stop details if available
    IF v_loc.current_stop_id IS NOT NULL THEN
      SELECT s.id, s.name_ar, s.name_en, s.locality_ar, s.locality_en, s.latitude, s.longitude, v_loc.current_stop_order as stop_order
      INTO v_current_stop
      FROM public.stops s
      WHERE s.id = v_loc.current_stop_id;

      IF FOUND THEN
        v_current_stop_json := jsonb_build_object(
          'id', v_current_stop.id,
          'name_ar', v_current_stop.name_ar,
          'name_en', v_current_stop.name_en,
          'locality_ar', v_current_stop.locality_ar,
          'locality_en', v_current_stop.locality_en,
          'latitude', v_current_stop.latitude,
          'longitude', v_current_stop.longitude,
          'stop_order', v_current_stop.stop_order
        );
      END IF;
    END IF;

    IF v_loc.next_stop_id IS NOT NULL THEN
      SELECT s.id, s.name_ar, s.name_en, s.locality_ar, s.locality_en, s.latitude, s.longitude, v_loc.next_stop_order as stop_order
      INTO v_next_stop
      FROM public.stops s
      WHERE s.id = v_loc.next_stop_id;

      IF FOUND THEN
        v_next_stop_json := jsonb_build_object(
          'id', v_next_stop.id,
          'name_ar', v_next_stop.name_ar,
          'name_en', v_next_stop.name_en,
          'locality_ar', v_next_stop.locality_ar,
          'locality_en', v_next_stop.locality_en,
          'latitude', v_next_stop.latitude,
          'longitude', v_next_stop.longitude,
          'stop_order', v_next_stop.stop_order
        );
      END IF;
    END IF;
  ELSE
    IF v_in_service_window THEN
      v_tracking_status := 'stale';
      v_service_state := 'stale';
      v_progress_state := 'coordinates_unavailable';
    END IF;
  END IF;

  -- 4. Route Stops
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
  WHERE rs.route_id = v_active_route_id AND rs.is_active = true;

  -- 5. Passenger target
  IF v_user_id IS NOT NULL THEN
    v_target_json := public.get_passenger_approach_target(v_user_id, v_active_route_id);
  END IF;

  RETURN jsonb_build_object(
    'tracking_status', v_tracking_status,
    'service_state', v_service_state,
    'progress_state', v_progress_state,
    'is_in_service_window', v_in_service_window,
    'service_window', v_service_window,
    'cairo_time', to_char(v_cairo_time, 'HH24:MI:SS'),
    'cairo_date', to_char(v_cairo_date, 'YYYY-MM-DD'),
    'active_direction', v_active_direction,
    'active_route_id', v_active_route_id,
    'active_trip_id', v_active_trip_id,
    'active_route_name_ar', v_active_route_name_ar,
    'active_route_name_en', v_active_route_name_en,
    'active_run_time', v_active_run_time,
    'bus_location', v_bus_loc_json,
    'current_stop', v_current_stop_json,
    'next_stop', v_next_stop_json,
    'current_stop_id', v_loc.current_stop_id,
    'next_stop_id', v_loc.next_stop_id,
    'next_window', v_next_window_json,
    'stops_count', v_stops_count,
    'stops_with_coords_count', v_stops_with_coords_count,
    'has_stop_coordinates', (v_stops_with_coords_count > 0 AND v_stops_with_coords_count = v_stops_count),
    'route_stops', v_stops_json,
    'passenger_target', v_target_json,
    'approach_alerts_enabled', v_approach_alerts_enabled
  );
END;
$$;
