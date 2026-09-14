-- =============================================================================
-- Migration: 20260911220000_dynamic_route_stop_fares.sql
-- Description: Dynamic Stop / Fare Zone Pricing Architecture
--   1. Reuses and hardens fare_zones, stops, and route_stops.
--   2. Seeds 3 Fare Zones (30, 25, 20 pts) & 34 stops (outbound & return).
--   3. Adds route_stop_id, fare_zone_id, and fare_points_snapshot to seat_holds.
--   4. Adds route_stop_id, fare_zone_id to bookings (with fare_points as frozen snapshot).
--   5. Implements get_route_stops(p_direction text).
--   6. Implements get_available_trips(p_direction text, p_date date, p_route_stop_id uuid).
--   7. Updates create_booking_hold(p_trip_id uuid, p_seat_id uuid, p_route_stop_id uuid)
--      with atomic zone resolution, snapshot recording, and point holds.
--   8. Updates confirm_booking(p_hold_id uuid) to use frozen fare_points_snapshot.
--   9. Updates get_passenger_bookings() and get_passenger_home_summary() to include stop info.
-- =============================================================================

-- =============================================================================
-- 1. TABLES DEFINITIONS & HARDENING (fare_zones, stops, route_stops)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.fare_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name text NOT NULL,
  fare_points numeric NOT NULL CHECK (fare_points > 0),
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ar text NOT NULL,
  name_en text,
  locality_ar text NOT NULL,
  locality_en text,
  latitude double precision,
  longitude double precision,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  fare_zone_id uuid NOT NULL REFERENCES public.fare_zones(id) ON DELETE RESTRICT,
  stop_order integer NOT NULL CHECK (stop_order >= 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_route_stop_order UNIQUE (route_id, stop_order),
  CONSTRAINT uq_route_stop_id UNIQUE (route_id, stop_id)
);

-- Triggers for updated_at
DROP TRIGGER IF EXISTS tr_fare_zones_updated_at ON public.fare_zones;
CREATE TRIGGER tr_fare_zones_updated_at
  BEFORE UPDATE ON public.fare_zones
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_stops_updated_at ON public.stops;
CREATE TRIGGER tr_stops_updated_at
  BEFORE UPDATE ON public.stops
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS tr_route_stops_updated_at ON public.route_stops;
CREATE TRIGGER tr_route_stops_updated_at
  BEFORE UPDATE ON public.route_stops
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 2. ALTER seat_holds & bookings WITH FARE SNAPSHOT COLUMNS
-- =============================================================================

DO $$
BEGIN
  -- Add route_stop_id, fare_zone_id, fare_points_snapshot to seat_holds
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

  -- Add route_stop_id, fare_zone_id to bookings
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

-- Indexes on route_stop_id
CREATE INDEX IF NOT EXISTS idx_seat_holds_route_stop_id ON public.seat_holds(route_stop_id);
CREATE INDEX IF NOT EXISTS idx_bookings_route_stop_id ON public.bookings(route_stop_id);
CREATE INDEX IF NOT EXISTS idx_route_stops_lookup ON public.route_stops(route_id, is_active, stop_order);

-- =============================================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- =============================================================================

ALTER TABLE public.fare_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;

-- 3.1 fare_zones RLS
DROP POLICY IF EXISTS "fare_zones_select_active" ON public.fare_zones;
CREATE POLICY "fare_zones_select_active" ON public.fare_zones
  FOR SELECT TO authenticated
  USING (is_active = true OR app_private.is_admin());

DROP POLICY IF EXISTS "fare_zones_admin_all" ON public.fare_zones;
CREATE POLICY "fare_zones_admin_all" ON public.fare_zones
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 3.2 stops RLS
DROP POLICY IF EXISTS "stops_select_active" ON public.stops;
CREATE POLICY "stops_select_active" ON public.stops
  FOR SELECT TO authenticated
  USING (is_active = true OR app_private.is_admin());

DROP POLICY IF EXISTS "stops_admin_all" ON public.stops;
CREATE POLICY "stops_admin_all" ON public.stops
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 3.3 route_stops RLS
DROP POLICY IF EXISTS "route_stops_select_active" ON public.route_stops;
CREATE POLICY "route_stops_select_active" ON public.route_stops
  FOR SELECT TO authenticated
  USING (is_active = true OR app_private.is_admin());

DROP POLICY IF EXISTS "route_stops_admin_all" ON public.route_stops;
CREATE POLICY "route_stops_admin_all" ON public.route_stops
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- Revoke direct DML from regular users
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.fare_zones FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.stops FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.route_stops FROM anon, authenticated;

-- =============================================================================
-- 4. SEED DATA: 3 FARE ZONES & 34 ROUTE STOPS (OUTBOUND & RETURN)
-- =============================================================================

DO $$
DECLARE
  v_zone_30_id uuid := '11111111-0000-0000-0000-000000000030'::uuid;
  v_zone_25_id uuid := '11111111-0000-0000-0000-000000000025'::uuid;
  v_zone_20_id uuid := '11111111-0000-0000-0000-000000000020'::uuid;
  v_route_outbound_id uuid := '11111111-1111-1111-1111-111111111111'::uuid;
  v_route_return_id uuid := '22222222-2222-2222-2222-222222222222'::uuid;
  v_stop_id uuid;
  i int;

  -- Array of stops: name_ar, locality_ar, zone_id, outbound_order
  v_stops RECORD;
BEGIN
  -- 4.1 Upsert Fare Zones
  INSERT INTO public.fare_zones (id, code, name, fare_points, is_active, sort_order)
  VALUES
    (v_zone_30_id, 'ZONE_30', 'Zone 30', 30, true, 1),
    (v_zone_25_id, 'ZONE_25', 'Zone 25', 25, true, 2),
    (v_zone_20_id, 'ZONE_20', 'Zone 20', 20, true, 3)
  ON CONFLICT (id) DO UPDATE
    SET fare_points = EXCLUDED.fare_points,
        code = EXCLUDED.code,
        name = EXCLUDED.name,
        is_active = EXCLUDED.is_active,
        sort_order = EXCLUDED.sort_order;

  -- 4.2 Seed Stops and Link to Routes
  -- Temporary table to hold 34 stops configuration
  CREATE TEMP TABLE temp_seed_stops (
    stop_num int PRIMARY KEY,
    name_ar text NOT NULL,
    locality_ar text NOT NULL,
    zone_id uuid NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO temp_seed_stops (stop_num, name_ar, locality_ar, zone_id) VALUES
    -- ZONE 30 (1-5)
    (1,  'كوبرى عزت', 'ميت فضالة', v_zone_30_id),
    (2,  'كوبرى الزغبي', 'ميت أبو الحسين', v_zone_30_id),
    (3,  'البريد', 'ميت أبو الحسين', v_zone_30_id),
    (4,  'البنزينة', 'ميت أبو الحسين', v_zone_30_id),
    (5,  'صيدلية حسونة', 'أبو داوود العنب', v_zone_30_id),

    -- ZONE 25 (6-17)
    (6,  'القنطرة البيضة', 'ميت العامل', v_zone_25_id),
    (7,  'الكوخ الخشب', 'ميت العامل', v_zone_25_id),
    (8,  'مسجد النور', 'ميت العامل', v_zone_25_id),
    (9,  'منشار الجوهرى', 'ميت العامل', v_zone_25_id),
    (10, 'قصر حنان حسني', 'ميت العامل', v_zone_25_id),
    (11, 'ماركت قزامل', 'ميت العامل', v_zone_25_id),
    (12, 'كوبرى السوق', 'ميت العامل', v_zone_25_id),
    (13, 'قاعة اللؤلؤة', 'ميت العامل', v_zone_25_id),
    (14, 'الوحدة الصحية', 'ميت العامل', v_zone_25_id),
    (15, 'جيم الجوكر', 'ميت العامل', v_zone_25_id),
    (16, 'المدخل الرئيسي', 'سنجيد', v_zone_25_id),
    (17, 'معرض السيراميك', 'سنجيد', v_zone_25_id),

    -- ZONE 20 (18-34)
    (18, 'ماركت المراعي', 'برج النور الحمص', v_zone_20_id),
    (19, 'شركة الحرمين', 'برج النور الحمص', v_zone_20_id),
    (20, 'كوبرى الملعب', 'البهو فريك', v_zone_20_id),
    (21, 'المدخل الرئيسي', 'البهو فريك', v_zone_20_id),
    (22, 'مصنع الرخام', 'البهو فريك', v_zone_20_id),
    (23, 'اليافطة', 'شبرا البهو', v_zone_20_id),
    (24, 'المرشح', 'شبرا البهو', v_zone_20_id),
    (25, 'المدرسة', 'شبرا البهو', v_zone_20_id),
    (26, 'المدخل الرئيسي', 'قرموط البهو', v_zone_20_id),
    (27, 'المدخل الرئيسي', 'السبخا', v_zone_20_id),
    (28, 'سندوب', 'المنصورة', v_zone_20_id),
    (29, 'جامعة السلاب', 'المنصورة', v_zone_20_id),
    (30, 'احمد ماهر', 'المنصورة', v_zone_20_id),
    (31, 'جيهان', 'المنصورة', v_zone_20_id),
    (32, 'الصينية', 'المنصورة', v_zone_20_id),
    (33, 'بوابة حاسبات', 'المنصورة', v_zone_20_id),
    (34, 'بوابة توشكى', 'المنصورة', v_zone_20_id);

  FOR v_stops IN SELECT * FROM temp_seed_stops ORDER BY stop_num ASC
  LOOP
    -- Deterministic UUID for each stop based on stop_num
    v_stop_id := ('aaaaaaaa-0000-0000-0000-' || lpad(v_stops.stop_num::text, 12, '0'))::uuid;

    INSERT INTO public.stops (id, name_ar, locality_ar, is_active)
    VALUES (v_stop_id, v_stops.name_ar, v_stops.locality_ar, true)
    ON CONFLICT (id) DO UPDATE
      SET name_ar = EXCLUDED.name_ar,
          locality_ar = EXCLUDED.locality_ar,
          is_active = true;

    -- Outbound Route Stop: order 1..34
    INSERT INTO public.route_stops (route_id, stop_id, fare_zone_id, stop_order, is_active)
    VALUES (v_route_outbound_id, v_stop_id, v_stops.zone_id, v_stops.stop_num, true)
    ON CONFLICT (route_id, stop_id) DO UPDATE
      SET fare_zone_id = EXCLUDED.fare_zone_id,
          stop_order = EXCLUDED.stop_order,
          is_active = true;

    -- Return Route Stop: reverse order (35 - stop_num)
    INSERT INTO public.route_stops (route_id, stop_id, fare_zone_id, stop_order, is_active)
    VALUES (v_route_return_id, v_stop_id, v_stops.zone_id, 35 - v_stops.stop_num, true)
    ON CONFLICT (route_id, stop_id) DO UPDATE
      SET fare_zone_id = EXCLUDED.fare_zone_id,
          stop_order = EXCLUDED.stop_order,
          is_active = true;
  END LOOP;

END $$;

-- =============================================================================
-- 5. RPC: get_route_stops(p_direction text)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_route_stops(p_direction text)
RETURNS TABLE (
  route_stop_id uuid,
  stop_id uuid,
  stop_order integer,
  stop_name_ar text,
  stop_name_en text,
  locality_ar text,
  locality_en text,
  fare_zone_id uuid,
  fare_points numeric
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
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
    fz.fare_points
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

-- =============================================================================
-- 6. RPC: get_available_trips(p_direction, p_date, p_route_stop_id)
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
  origin_name_ar text,
  origin_name_en text,
  destination_name_ar text,
  destination_name_en text,
  departure_time text,
  departure_at timestamptz,
  fare_points numeric,
  available_seats_count integer,
  status text
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_stop_fare numeric;
  v_stop_route_id uuid;
BEGIN
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
    r.origin_name_ar,
    r.origin_name_en,
    r.destination_name_ar,
    r.destination_name_en,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    -- Dynamic fare zone price if route stop provided; fallback to trip.fare_points for legacy
    COALESCE(v_stop_fare, t.fare_points) AS fare_points,
    GREATEST(0, tc.calc_available)::integer AS available_seats_count,
    t.status::text AS status
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

-- =============================================================================
-- 7. RPC: create_booking_hold(p_trip_id, p_seat_id, p_route_stop_id)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_profile RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_route_stop RECORD;
  v_stop RECORD;
  v_fare_zone RECORD;
  v_fare_points numeric;
  v_wallet RECORD;
  v_hold_expires_at timestamptz;
  v_seat_hold_id uuid;
  v_point_hold_id uuid;
  v_batch RECORD;
  v_remaining_needed numeric;
  v_take numeric;
  v_existing_hold RECORD;
BEGIN
  -- 1. Authenticate user
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Validate profile completeness
  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  IF NOT FOUND OR
     v_profile.full_name IS NULL OR length(trim(v_profile.full_name)) < 3 OR
     v_profile.phone IS NULL OR length(trim(v_profile.phone)) < 10 OR
     v_profile.gender IS NULL OR
     v_profile.date_of_birth IS NULL THEN
    RAISE EXCEPTION 'PROFILE_INCOMPLETE';
  END IF;

  -- 3. Lock & validate trip
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  IF v_trip.booking_close_at <= now() THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  -- 4. Route stop validation & dynamic fare resolution
  IF p_route_stop_id IS NOT NULL THEN
    -- Load route stop
    SELECT * INTO v_route_stop
    FROM public.route_stops
    WHERE id = p_route_stop_id;

    IF NOT FOUND OR NOT v_route_stop.is_active THEN
      RAISE EXCEPTION 'ROUTE_STOP_INACTIVE';
    END IF;

    -- Verify route stop belongs to trip's route
    IF v_route_stop.route_id != v_trip.route_id THEN
      RAISE EXCEPTION 'ROUTE_STOP_ROUTE_MISMATCH';
    END IF;

    -- Resolve stop details
    SELECT * INTO v_stop
    FROM public.stops
    WHERE id = v_route_stop.stop_id;

    IF NOT FOUND OR NOT v_stop.is_active THEN
      RAISE EXCEPTION 'STOP_INACTIVE';
    END IF;

    -- Resolve fare zone
    SELECT * INTO v_fare_zone
    FROM public.fare_zones
    WHERE id = v_route_stop.fare_zone_id;

    IF NOT FOUND OR NOT v_fare_zone.is_active THEN
      RAISE EXCEPTION 'FARE_ZONE_INACTIVE';
    END IF;

    v_fare_points := v_fare_zone.fare_points;
  ELSE
    -- Legacy fallback only if no stop provided
    v_fare_points := v_trip.fare_points;
  END IF;

  IF v_fare_points IS NULL OR v_fare_points <= 0 THEN
    RAISE EXCEPTION 'FARE_INVALID';
  END IF;

  -- 5. Validate seat belongs to this trip's bus
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = p_seat_id
    AND bus_id = v_trip.bus_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_INVALID';
  END IF;

  -- 6. Concurrency check: Ensure seat is not already confirmed booked
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status = 'confirmed'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- 7. Concurrency check: Clean up expired holds for this seat first
  UPDATE public.seat_holds
  SET status = 'expired'
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at <= now();

  -- Verify no active unexpired hold by another user
  SELECT * INTO v_existing_hold
  FROM public.seat_holds
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at > now()
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_hold.user_id = v_user_id THEN
      -- Already held by this user: return existing hold info with frozen snapshot
      RETURN jsonb_build_object(
        'success', true,
        'hold_id', v_existing_hold.id,
        'trip_id', p_trip_id,
        'seat_id', p_seat_id,
        'seat_number', v_seat.seat_number,
        'route_stop_id', v_existing_hold.route_stop_id,
        'stop_name', COALESCE(v_stop.name_ar, ''),
        'locality', COALESCE(v_stop.locality_ar, ''),
        'fare_zone_id', v_existing_hold.fare_zone_id,
        'fare_points', v_existing_hold.fare_points_snapshot,
        'expires_at', v_existing_hold.expires_at,
        'server_time', now()
      );
    ELSE
      RAISE EXCEPTION 'SEAT_UNAVAILABLE';
    END IF;
  END IF;

  -- If user currently has another active hold for this trip, release it cleanly first
  FOR v_existing_hold IN
    SELECT id FROM public.seat_holds
    WHERE trip_id = p_trip_id
      AND user_id = v_user_id
      AND status = 'active'
  LOOP
    PERFORM public.release_booking_hold(v_existing_hold.id);
  END LOOP;

  -- 8. Wallet balance check against calculated dynamic fare
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_wallet.cached_available_balance < v_fare_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- 9. Server-owned expiry: 5 minutes from now
  v_hold_expires_at := now() + interval '5 minutes';

  -- 10. Insert seat hold with FROZEN FARE SNAPSHOT
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
    v_fare_zone.id,
    v_fare_points,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_seat_hold_id;

  -- 11. Reserve Points (Create point_hold) using calculated dynamic fare
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
    v_fare_points,
    'trip_booking',
    v_seat_hold_id,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_point_hold_id;

  -- Link point hold to seat hold
  UPDATE public.seat_holds
  SET point_hold_id = v_point_hold_id
  WHERE id = v_seat_hold_id;

  -- 12. Allocate points across batches:
  -- Spending Rule: 1) Subscription points first (earliest expiring first), 2) Cash points second
  v_remaining_needed := v_fare_points;

  -- Subscription batches ordered by expires_at ASC
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

  -- Cash batches if subscription points were not enough
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

  -- Verify all required points were allocated
  IF v_remaining_needed > 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- 13. Update wallet cached balances with dynamic fare
  UPDATE public.wallets
  SET cached_available_balance = cached_available_balance - v_fare_points,
      cached_held_balance = cached_held_balance + v_fare_points,
      updated_at = now()
  WHERE id = v_wallet.id;

  RETURN jsonb_build_object(
    'success', true,
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'route_stop_id', p_route_stop_id,
    'stop_name', COALESCE(v_stop.name_ar, ''),
    'locality', COALESCE(v_stop.locality_ar, ''),
    'fare_zone_id', v_fare_zone.id,
    'fare_points', v_fare_points,
    'expires_at', v_hold_expires_at,
    'server_time', now()
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) TO authenticated;

-- =============================================================================
-- 8. RPC: confirm_booking(p_hold_id) USING FROZEN FARE SNAPSHOT
-- =============================================================================

CREATE OR REPLACE FUNCTION public.confirm_booking(p_hold_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private, extensions
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_seat_hold RECORD;
  v_trip RECORD;
  v_seat RECORD;
  v_stop RECORD;
  v_point_hold RECORD;
  v_allocation RECORD;
  v_wallet RECORD;
  v_booking_id uuid;
  v_qr_token text;
  v_batch RECORD;
  v_new_wallet_held numeric;
  v_confirmed_fare numeric;
BEGIN
  -- 1. Must be authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Lock & validate active seat hold
  SELECT * INTO v_seat_hold
  FROM public.seat_holds
  WHERE id = p_hold_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'HOLD_NOT_FOUND';
  END IF;

  IF v_seat_hold.user_id != v_user_id THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  IF v_seat_hold.status != 'active' THEN
    RAISE EXCEPTION 'HOLD_NOT_ACTIVE';
  END IF;

  IF v_seat_hold.expires_at <= now() THEN
    PERFORM public.release_booking_hold(p_hold_id);
    RAISE EXCEPTION 'HOLD_EXPIRED';
  END IF;

  -- 3. Lock & validate trip
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = v_seat_hold.trip_id
  FOR SHARE;

  IF NOT FOUND OR v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  -- 4. Get seat info
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = v_seat_hold.seat_id;

  -- 5. Read FROZEN FARE SNAPSHOT from seat hold (NEVER recalculate from live zone)
  v_confirmed_fare := COALESCE(v_seat_hold.fare_points_snapshot, v_trip.fare_points);

  -- 6. Lock point hold
  SELECT * INTO v_point_hold
  FROM public.point_holds
  WHERE id = v_seat_hold.point_hold_id
  FOR UPDATE;

  IF NOT FOUND OR v_point_hold.status != 'active' THEN
    RAISE EXCEPTION 'POINT_HOLD_INVALID';
  END IF;

  -- 7. Lock wallet
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  -- 8. Generate secure QR token
  v_qr_token := 'AMY_' || encode(gen_random_bytes(20), 'hex');

  -- 9. Create Confirmed Booking record with permanent price snapshot
  INSERT INTO public.bookings (
    user_id,
    trip_id,
    seat_id,
    route_stop_id,
    fare_zone_id,
    fare_points,
    status,
    qr_token,
    booked_at
  ) VALUES (
    v_user_id,
    v_trip.id,
    v_seat.id,
    v_seat_hold.route_stop_id,
    v_seat_hold.fare_zone_id,
    v_confirmed_fare,
    'confirmed',
    v_qr_token,
    now()
  ) RETURNING id INTO v_booking_id;

  -- 10. Consume allocated held points from batches & record point transactions
  FOR v_allocation IN
    SELECT pha.batch_id, pha.amount
    FROM public.point_hold_allocations pha
    WHERE pha.hold_id = v_point_hold.id
    FOR UPDATE
  LOOP
    -- Lock batch
    SELECT * INTO v_batch
    FROM public.point_batches
    WHERE id = v_allocation.batch_id
    FOR UPDATE;

    -- Deduct remaining from batch
    UPDATE public.point_batches
    SET remaining_amount = GREATEST(0, remaining_amount - v_allocation.amount)
    WHERE id = v_batch.id;

    -- Record debit transaction with real fare
    INSERT INTO public.point_transactions (
      user_id,
      wallet_id,
      batch_id,
      transaction_type,
      amount,
      balance_before,
      balance_after,
      reference_type,
      reference_id,
      description,
      actor_user_id,
      metadata
    ) VALUES (
      v_user_id,
      v_wallet.id,
      v_batch.id,
      'debit',
      v_allocation.amount,
      v_wallet.cached_available_balance,
      v_wallet.cached_available_balance,
      'booking',
      v_booking_id,
      'Fare for booking ' || v_seat.seat_number || ' (' || v_confirmed_fare || ' pts)',
      v_user_id,
      jsonb_build_object(
        'booking_id', v_booking_id,
        'trip_id', v_trip.id,
        'seat_id', v_seat.id,
        'seat_number', v_seat.seat_number,
        'route_stop_id', v_seat_hold.route_stop_id,
        'fare_points', v_confirmed_fare,
        'batch_source_type', v_batch.source_type
      )
    );
  END LOOP;

  -- 11. Update wallet: Decrement cached_held_balance
  v_new_wallet_held := GREATEST(0, v_wallet.cached_held_balance - v_point_hold.amount);
  UPDATE public.wallets
  SET cached_held_balance = v_new_wallet_held,
      updated_at = now()
  WHERE id = v_wallet.id;

  -- 12. Convert point hold & seat hold
  UPDATE public.point_holds
  SET status = 'consumed',
      consumed_at = now()
  WHERE id = v_point_hold.id;

  DELETE FROM public.point_hold_allocations
  WHERE hold_id = v_point_hold.id;

  UPDATE public.seat_holds
  SET status = 'converted',
      booking_id = v_booking_id
  WHERE id = v_seat_hold.id;

  -- 13. Audit Log
  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    metadata
  ) VALUES (
    v_user_id,
    'passenger',
    'BOOKING_CONFIRMED',
    'bookings',
    v_booking_id,
    jsonb_build_object(
      'trip_id', v_trip.id,
      'seat_id', v_seat.id,
      'seat_number', v_seat.seat_number,
      'route_stop_id', v_seat_hold.route_stop_id,
      'fare_points', v_confirmed_fare,
      'booking_id', v_booking_id
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'qr_token', v_qr_token,
    'trip_id', v_trip.id,
    'seat', v_seat.seat_number,
    'route_stop_id', v_seat_hold.route_stop_id,
    'fare_points', v_confirmed_fare,
    'booked_at', now()
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;

-- =============================================================================
-- 9. RPC: get_passenger_bookings() WITH STOP & PERMANENT FARE SNAPSHOT
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_passenger_bookings()
RETURNS TABLE (
  booking_id uuid,
  trip_id uuid,
  direction text,
  origin_name_ar text,
  origin_name_en text,
  destination_name_ar text,
  destination_name_en text,
  service_date date,
  departure_time text,
  departure_at timestamptz,
  seat_number text,
  fare_points numeric,
  status text,
  qr_token text,
  booked_at timestamptz,
  route_stop_id uuid,
  stop_name_ar text,
  locality_ar text
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
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
    bs.seat_number,
    bkg.fare_points, -- frozen permanent price snapshot
    bkg.status::text AS status,
    bkg.qr_token,
    bkg.booked_at,
    bkg.route_stop_id,
    s.name_ar AS stop_name_ar,
    s.locality_ar
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.bus_seats bs ON bs.id = bkg.seat_id
  LEFT JOIN public.route_stops rs ON rs.id = bkg.route_stop_id
  LEFT JOIN public.stops s ON s.id = rs.stop_id
  WHERE bkg.user_id = v_user_id
  ORDER BY t.departure_at DESC;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_passenger_bookings() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_bookings() TO authenticated;

-- =============================================================================
-- 10. RPC: get_passenger_home_summary() WITH STOP DETAILS
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

  -- 3. Nearest future active booking (Upcoming Trip)
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
    AND t.departure_at >= now()
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
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'completed';

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
GRANT EXECUTE ON FUNCTION public.get_active_announcements() TO anon, authenticated, service_role;
