-- Migration: 20260913210000_etrack_edge_function_ingestion_and_source_separation.sql
-- Description: ETrack Edge Function ingestion support, telemetry source separation (etrack vs qa), and sync health tracking

-- 1. Add source and is_valid columns to public.bus_live_locations
ALTER TABLE public.bus_live_locations
  ADD COLUMN IF NOT EXISTS source text NOT NULL DEFAULT 'etrack',
  ADD COLUMN IF NOT EXISTS is_valid boolean NOT NULL DEFAULT true;

-- 2. Add source column to public.bus_location_history
ALTER TABLE public.bus_location_history
  ADD COLUMN IF NOT EXISTS source text NOT NULL DEFAULT 'etrack';

-- 3. Create sync health table in app_private
CREATE TABLE IF NOT EXISTS app_private.sync_health (
  id boolean PRIMARY KEY DEFAULT true,
  last_sync_attempt timestamptz,
  last_successful_sync timestamptz,
  last_error_code text,
  last_error_message text,
  devices_synced integer DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT sync_health_singleton CHECK (id = true)
);

INSERT INTO app_private.sync_health (id, last_sync_attempt, last_successful_sync)
VALUES (true, now(), NULL)
ON CONFLICT (id) DO NOTHING;

-- 4. Function to record sync health safely
CREATE OR REPLACE FUNCTION app_private.record_sync_health(
  p_success boolean,
  p_devices integer,
  p_error_code text,
  p_error_message text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO app_private.sync_health (
    id,
    last_sync_attempt,
    last_successful_sync,
    last_error_code,
    last_error_message,
    devices_synced,
    updated_at
  ) VALUES (
    true,
    now(),
    CASE WHEN p_success THEN now() ELSE NULL END,
    p_error_code,
    p_error_message,
    COALESCE(p_devices, 0),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    last_sync_attempt = EXCLUDED.last_sync_attempt,
    last_successful_sync = CASE WHEN p_success THEN EXCLUDED.last_successful_sync ELSE app_private.sync_health.last_successful_sync END,
    last_error_code = EXCLUDED.last_error_code,
    last_error_message = EXCLUDED.last_error_message,
    devices_synced = EXCLUDED.devices_synced,
    updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION app_private.record_sync_health(boolean, integer, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_private.record_sync_health(boolean, integer, text, text) TO service_role, postgres;

-- 5. Secure credential getter for Edge Function service_role
CREATE OR REPLACE FUNCTION app_private.get_etrack_credentials()
RETURNS TABLE (account text, password text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, app_private
AS $$
BEGIN
  IF current_user NOT IN ('postgres', 'service_role', 'supabase_admin') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: service_role required';
  END IF;

  RETURN QUERY
  SELECT 
    (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'etrack_account' LIMIT 1),
    (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'etrack_password' LIMIT 1);
END;
$$;

REVOKE ALL ON FUNCTION app_private.get_etrack_credentials() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION app_private.get_etrack_credentials() TO service_role, postgres;

-- 6. Update QA Simulation to explicitly tag telemetry as source = 'qa'
CREATE OR REPLACE FUNCTION public.qa_simulate_bus_location(
  p_bus_id uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_speed_kmh numeric DEFAULT 30.0,
  p_heading integer DEFAULT 0
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
  -- Strict permission check: Admin or QA override required
  IF app_private.is_admin() THEN
    v_is_authorized := true;
  ELSIF v_user_id IS NOT NULL THEN
    SELECT true INTO v_is_authorized
    FROM public.qa_booking_time_overrides
    WHERE user_id = v_user_id AND enabled = true;

    IF NOT COALESCE(v_is_authorized, false) THEN
      SELECT true INTO v_is_authorized
      FROM public.user_roles
      WHERE user_id = v_user_id AND role IN ('admin', 'super_admin');
    END IF;
  END IF;

  IF NOT COALESCE(v_is_authorized, false) THEN
    RAISE EXCEPTION 'UNAUTHORIZED_QA_SIMULATION: Ordinary passengers cannot simulate bus telemetry.';
  END IF;

  IF p_latitude < -90 OR p_latitude > 90 OR p_longitude < -180 OR p_longitude > 180 THEN
    RAISE EXCEPTION 'INVALID_COORDINATES: Coordinates out of geographic range.';
  END IF;

  -- Upsert simulated location marked explicitly as source = 'qa'
  INSERT INTO public.bus_live_locations (
    bus_id,
    latitude,
    longitude,
    speed_kmh,
    heading,
    gps_recorded_at,
    last_synced_at,
    updated_at,
    source,
    is_valid
  ) VALUES (
    p_bus_id,
    p_latitude,
    p_longitude,
    p_speed_kmh,
    p_heading,
    v_now,
    v_now,
    v_now,
    'qa',
    true
  )
  ON CONFLICT (bus_id) DO UPDATE SET
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    speed_kmh = EXCLUDED.speed_kmh,
    heading = EXCLUDED.heading,
    gps_recorded_at = EXCLUDED.gps_recorded_at,
    last_synced_at = EXCLUDED.last_synced_at,
    updated_at = EXCLUDED.updated_at,
    source = 'qa',
    is_valid = true;

  PERFORM app_private.compute_bus_progression(p_bus_id);

  RETURN jsonb_build_object(
    'success', true,
    'bus_id', p_bus_id,
    'simulated_at', v_now,
    'source', 'qa'
  );
END;
$$;

-- 7. Update get_live_bus_tracking_summary to expose source and prioritize real etrack telemetry
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
  IF v_user_id IS NOT NULL THEN
    SELECT COALESCE(approach_alerts_enabled, true)
    INTO v_approach_alerts_enabled
    FROM public.passenger_trip_preferences
    WHERE user_id = v_user_id;
    IF NOT FOUND THEN
      v_approach_alerts_enabled := true;
    END IF;
  END IF;

  -- Operating Windows (08:00-12:00, 13:00-17:00)
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

  IF v_active_direction = 'outbound' THEN
    v_active_route_id := '11111111-1111-1111-1111-111111111101'::uuid;
    v_active_route_name_ar := 'كوبرى عزت - بوابة توشكى';
    v_active_route_name_en := 'Ezzat Bridge - Toshka Gate';
  ELSE
    v_active_route_id := '11111111-1111-1111-1111-111111111102'::uuid;
    v_active_route_name_ar := 'بوابة توشكى - كوبرى عزت';
    v_active_route_name_en := 'Toshka Gate - Ezzat Bridge';
  END IF;

  -- Prioritize real 'etrack' telemetry; fallback to recent valid location
  SELECT bll.*
  INTO v_loc
  FROM public.bus_live_locations bll
  WHERE bll.latitude IS NOT NULL AND bll.longitude IS NOT NULL
  ORDER BY 
    CASE WHEN bll.source = 'etrack' THEN 1 ELSE 2 END ASC,
    bll.gps_recorded_at DESC
  LIMIT 1;

  IF FOUND THEN
    PERFORM app_private.compute_bus_progression(v_loc.bus_id);

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
      'is_stale', v_is_stale,
      'source', COALESCE(v_loc.source, 'etrack')
    );

    IF v_in_service_window THEN
      IF v_is_stale THEN
        v_tracking_status := 'stale';
      ELSE
        v_tracking_status := 'online';
      END IF;
    END IF;

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

-- 8. Cleanly stop the broken PostgreSQL HTTP polling worker
SELECT cron.unschedule('etrack-live-location-sync');

-- 9. Schedule authoritative Edge Function invocation via pg_cron (10-second interval)
SELECT cron.schedule(
  'etrack-edge-sync',
  '10 seconds',
  $$SELECT extensions.http_post(
    'https://vexqglrlwfallmjfhisv.supabase.co/functions/v1/etrack-sync',
    '{}',
    'application/json'
  );$$
);
