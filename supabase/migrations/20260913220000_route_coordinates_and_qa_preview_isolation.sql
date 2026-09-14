-- Migration: 20260913220000_route_coordinates_and_qa_preview_isolation.sql
-- Description: Populate verified coordinates for stops 18-34, create isolated public.qa_stop_coordinates
-- for temporary QA stops 1-17, and update tracking summary RPC to support secure QA preview.

-- 1. Create isolated storage for temporary QA stop coordinates
CREATE TABLE IF NOT EXISTS public.qa_stop_coordinates (
  stop_id uuid PRIMARY KEY REFERENCES public.stops(id) ON DELETE CASCADE,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  source text NOT NULL DEFAULT 'temporary_qa',
  is_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.qa_stop_coordinates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated read for qa_stop_coordinates" ON public.qa_stop_coordinates;
CREATE POLICY "Allow authenticated read for qa_stop_coordinates"
  ON public.qa_stop_coordinates
  FOR SELECT
  TO authenticated
  USING (true);

COMMENT ON TABLE public.qa_stop_coordinates IS 'Isolated storage for temporary unverified coordinates used strictly for QA visual preview. Production progression and passenger approach notifications MUST NEVER query or consume rows from this table.';

-- 2. Populate REAL VERIFIED coordinates for Stops 18–34 in public.stops
-- Stop 18 | ماركت المراعي — برج النور الحمص
UPDATE public.stops
SET latitude = 30.9350382, longitude = 31.34714024, updated_at = now()
WHERE id = '8147c0e4-90a2-4bc0-bd91-5a79f174e47a';

-- Stop 19 | شركة الحرمين — برج النور الحمص
UPDATE public.stops
SET latitude = 30.93629209, longitude = 31.34753022, updated_at = now()
WHERE id = 'c3e8eea4-2290-4a35-b9eb-565a28c145e9';

-- Stop 20 | كوبرى الملعب — البهو فريك
UPDATE public.stops
SET latitude = 30.94818275, longitude = 31.35129625, updated_at = now()
WHERE id = '8d825ac2-f320-48b9-bb77-fe29013b90a4';

-- Stop 21 | المدخل الرئيسي — البهو فريك
UPDATE public.stops
SET latitude = 30.94908008, longitude = 31.35149649, updated_at = now()
WHERE id = '9ee6bfff-24e7-4e94-a405-ef512d7079db';

-- Stop 22 | مصنع الرخام — البهو فريك
UPDATE public.stops
SET latitude = 30.94978181, longitude = 31.35179821, updated_at = now()
WHERE id = '9df9b76e-b52a-4e29-b2e1-ad933e8cc3e2';

-- Stop 23 | اليافطة — شبرا البهو
UPDATE public.stops
SET latitude = 30.95627689, longitude = 31.35380514, updated_at = now()
WHERE id = '84633fd0-b7f0-4856-ac49-b911f8e29505';

-- Stop 24 | المرشح — شبرا البهو
UPDATE public.stops
SET latitude = 30.9575651, longitude = 31.3542808, updated_at = now()
WHERE id = '0619c0f8-2d8e-4a31-90cd-d33e5516f8db';

-- Stop 25 | المدرسة — شبرا البهو
UPDATE public.stops
SET latitude = 30.9589021, longitude = 31.35476645, updated_at = now()
WHERE id = '2525f50a-af9c-45d7-873e-d1a42c10f768';

-- Stop 26 | المدخل الرئيسي — قرموط البهو
UPDATE public.stops
SET latitude = 30.96044129, longitude = 31.35588672, updated_at = now()
WHERE id = '48e6a6ea-0778-45f8-bacf-c4739e1efe0a';

-- Stop 27 | المدخل الرئيسي — السبخا
UPDATE public.stops
SET latitude = 30.96719212, longitude = 31.36465835, updated_at = now()
WHERE id = '98dbb38e-0df0-4c43-857c-bc64ee329f7d';

-- Stop 28 | سندوب
UPDATE public.stops
SET latitude = 31.01661639, longitude = 31.39293879, updated_at = now()
WHERE id = '58a3ef1f-fca6-4e6d-939c-fa5ce396390f';

-- Stop 29 | جامعة السلاب
UPDATE public.stops
SET latitude = 31.01645752, longitude = 31.37868744, updated_at = now()
WHERE id = '071010a4-0947-4df5-bed3-c30e59877854';

-- Stop 30 | أحمد ماهر
UPDATE public.stops
SET latitude = 31.02967635, longitude = 31.36001066, updated_at = now()
WHERE id = '4739fb91-55d6-4d51-8f2e-6eefc9619157';

-- Stop 31 | جيهان
UPDATE public.stops
SET latitude = 31.03229595, longitude = 31.355514, updated_at = now()
WHERE id = 'd1b7ad7e-f82b-4808-8f21-6fbcea42f0b9';

-- Stop 32 | الصينية
UPDATE public.stops
SET latitude = 31.04064902, longitude = 31.34980101, updated_at = now()
WHERE id = '99057403-5002-41bb-bed0-ff0bed6dc53b';

-- Stop 33 | بوابة حاسبات
UPDATE public.stops
SET latitude = 31.04111627, longitude = 31.35194156, updated_at = now()
WHERE id = '99008d30-b8ea-44a3-99c6-42d80f50a415';

-- Stop 34 | بوابة توشكى
UPDATE public.stops
SET latitude = 31.03889288, longitude = 31.35506674, updated_at = now()
WHERE id = '9ceeeb81-aecf-4927-98de-55b9a6ccc3c5';

-- 3. Ensure stops 1–17 in public.stops remain strictly NULL in production
UPDATE public.stops
SET latitude = NULL, longitude = NULL, updated_at = now()
WHERE id IN (
  'bea8e6e9-2d62-4c98-8547-99ad189c283d',
  '9748eb63-2858-485a-ab2e-72ea195343b0',
  'bd3f7bf9-5b49-41d1-ae6f-84670fcc44e8',
  '1a36092d-cb74-4732-9f9a-c9da701fcaa0',
  'd894150e-902c-46f7-8347-626172dac1b1',
  '195de71b-69e7-4bb4-8453-a31397db0240',
  'a48a7238-01d9-4904-bc71-b02870b22162',
  '70c23415-e10c-4861-8439-e3ae6ea859ca',
  'b472d16e-ac18-481a-804c-a3b61b64f61f',
  '9844ae5f-2c4f-443c-83cb-b21904bae133',
  '7f03dd68-5571-4b8f-b7cd-0737eadac813',
  '4c6a7761-c37e-481a-aa60-1af9b4dbe752',
  'af013a6b-357c-41dc-b440-6f5da3adf877',
  '0e829916-ed79-4c9a-991f-b7a62850aec7',
  '8611771f-a37c-4170-9277-db28063bcc7c',
  '3e010eb8-d5fe-4419-a3b2-34e3797356ea',
  '89287167-b700-4ee4-bf41-8de13ca12d14'
);

-- 4. Populate TEMPORARY QA-ONLY coordinates into public.qa_stop_coordinates
INSERT INTO public.qa_stop_coordinates (stop_id, latitude, longitude, source, is_verified)
VALUES
  ('bea8e6e9-2d62-4c98-8547-99ad189c283d', 30.8870000, 31.3100000, 'temporary_qa', false),
  ('9748eb63-2858-485a-ab2e-72ea195343b0', 30.8901404, 31.3126327, 'temporary_qa', false),
  ('bd3f7bf9-5b49-41d1-ae6f-84670fcc44e8', 30.8932717, 31.3152071, 'temporary_qa', false),
  ('1a36092d-cb74-4732-9f9a-c9da701fcaa0', 30.8963854, 31.3176739, 'temporary_qa', false),
  ('d894150e-902c-46f7-8347-626172dac1b1', 30.8994735, 31.3200000, 'temporary_qa', false),
  ('195de71b-69e7-4bb4-8453-a31397db0240', 30.9025290, 31.3221739, 'temporary_qa', false),
  ('a48a7238-01d9-4904-bc71-b02870b22162', 30.9055462, 31.3242071, 'temporary_qa', false),
  ('70c23415-e10c-4861-8439-e3ae6ea859ca', 30.9085207, 31.3261327, 'temporary_qa', false),
  ('b472d16e-ac18-481a-804c-a3b61b64f61f', 30.9114500, 31.3280000, 'temporary_qa', false),
  ('9844ae5f-2c4f-443c-83cb-b21904bae133', 30.9143332, 31.3298673, 'temporary_qa', false),
  ('7f03dd68-5571-4b8f-b7cd-0737eadac813', 30.9171712, 31.3317929, 'temporary_qa', false),
  ('4c6a7761-c37e-481a-aa60-1af9b4dbe752', 30.9199665, 31.3338261, 'temporary_qa', false),
  ('af013a6b-357c-41dc-b440-6f5da3adf877', 30.9227235, 31.3360000, 'temporary_qa', false),
  ('0e829916-ed79-4c9a-991f-b7a62850aec7', 30.9254479, 31.3383261, 'temporary_qa', false),
  ('8611771f-a37c-4170-9277-db28063bcc7c', 30.9281467, 31.3407929, 'temporary_qa', false),
  ('3e010eb8-d5fe-4419-a3b2-34e3797356ea', 30.9308279, 31.3433673, 'temporary_qa', false),
  ('89287167-b700-4ee4-bf41-8de13ca12d14', 30.9335000, 31.3460000, 'temporary_qa', false)
ON CONFLICT (stop_id) DO UPDATE SET
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude,
  source = EXCLUDED.source,
  is_verified = EXCLUDED.is_verified,
  updated_at = now();

-- 5. Drop old 0-arg get_live_bus_tracking_summary and replace with secure optional QA preview parameter
DROP FUNCTION IF EXISTS public.get_live_bus_tracking_summary();

CREATE OR REPLACE FUNCTION public.get_live_bus_tracking_summary(p_include_qa boolean DEFAULT false)
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
  v_allow_qa boolean := false;
BEGIN
  -- Strict permission check for QA coordinate overlay:
  -- Only allowed if caller is admin/super_admin or has QA override
  IF p_include_qa THEN
    IF app_private.is_admin() THEN
      v_allow_qa := true;
    ELSIF v_user_id IS NOT NULL THEN
      SELECT true INTO v_allow_qa
      FROM public.qa_booking_time_overrides
      WHERE user_id = v_user_id AND enabled = true;

      IF NOT COALESCE(v_allow_qa, false) THEN
        SELECT true INTO v_allow_qa
        FROM public.user_roles
        WHERE user_id = v_user_id AND role IN ('admin', 'super_admin');
      END IF;
    END IF;
  END IF;

  IF v_user_id IS NOT NULL THEN
    SELECT COALESCE(approach_alerts_enabled, true)
    INTO v_approach_alerts_enabled
    FROM public.passenger_trip_preferences
    WHERE user_id = v_user_id;
    IF NOT FOUND THEN
      v_approach_alerts_enabled := true;
    END IF;
  END IF;

  -- Operating Windows (08:00-12:00, 13:00-17:00 Cairo time)
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

  -- Build Route Stops JSON with strict QA isolation
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
        'latitude', COALESCE(s.latitude, CASE WHEN v_allow_qa THEN qa.latitude ELSE NULL END),
        'longitude', COALESCE(s.longitude, CASE WHEN v_allow_qa THEN qa.longitude ELSE NULL END),
        'is_boarding', rs.is_boarding,
        'is_dropoff', rs.is_dropoff,
        'is_qa_coord', (s.latitude IS NULL AND qa.latitude IS NOT NULL AND v_allow_qa),
        'coordinate_source', CASE 
          WHEN s.latitude IS NOT NULL THEN 'verified'
          WHEN (v_allow_qa AND qa.latitude IS NOT NULL) THEN qa.source
          ELSE 'none'
        END
      ) ORDER BY rs.stop_order ASC
    ), '[]'::jsonb)
  INTO v_stops_count, v_stops_with_coords_count, v_stops_json
  FROM public.route_stops rs
  JOIN public.stops s ON s.id = rs.stop_id
  LEFT JOIN public.qa_stop_coordinates qa ON qa.stop_id = s.id
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
    'approach_alerts_enabled', v_approach_alerts_enabled,
    'is_qa_preview_active', v_allow_qa
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_live_bus_tracking_summary(boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_live_bus_tracking_summary(boolean) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_live_bus_tracking_summary(boolean) TO authenticated, service_role;
