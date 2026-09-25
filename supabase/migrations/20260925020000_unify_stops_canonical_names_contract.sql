-- =============================================================================
-- Migration: 20260925020000_unify_stops_canonical_names_contract.sql
-- Description: Unify Stop Model and Stop Presentation across AMOMY Bus
--              Phase U1: Backend contract relaxation for public.stops
--              - Makes locality_ar and locality_en backward-compatible optional fields (DROP NOT NULL)
--              - Updates admin_create_station, admin_update_station, and admin_upsert_stop
--                to allow creating and updating stops without requiring locality.
--              - Preserves all stop IDs, coordinates, route_stops, bookings, and tracking.
--              - Does NOT modify existing stop records.
-- =============================================================================

-- 1. Relax NOT NULL constraints on locality fields in public.stops
ALTER TABLE public.stops ALTER COLUMN locality_ar DROP NOT NULL;
ALTER TABLE public.stops ALTER COLUMN locality_en DROP NOT NULL;

-- 2. Define/Update admin_create_station with default values for locality
CREATE OR REPLACE FUNCTION public.admin_create_station(
  p_name_ar text,
  p_latitude double precision,
  p_longitude double precision,
  p_position integer,
  p_name_en text DEFAULT NULL,
  p_locality_ar text DEFAULT NULL,
  p_locality_en text DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_stop_id uuid;
  v_outbound_route_id uuid;
  v_return_route_id uuid;
  v_default_fare_zone_id uuid;
BEGIN
  -- Security check: admin only
  IF NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_name_ar IS NULL OR trim(p_name_ar) = '' THEN
    RAISE EXCEPTION 'NAME_AR_REQUIRED';
  END IF;

  -- 1. Insert physical stop
  INSERT INTO public.stops (
    name_ar,
    name_en,
    locality_ar,
    locality_en,
    latitude,
    longitude,
    is_active
  ) VALUES (
    trim(p_name_ar),
    NULLIF(trim(p_name_en), ''),
    NULLIF(trim(p_locality_ar), ''),
    NULLIF(trim(p_locality_en), ''),
    p_latitude,
    p_longitude,
    true
  ) RETURNING id INTO v_stop_id;

  -- 2. Fetch routes if configured
  SELECT id INTO v_outbound_route_id FROM public.routes WHERE direction = 'outbound' LIMIT 1;
  SELECT id INTO v_return_route_id FROM public.routes WHERE direction = 'return' LIMIT 1;
  SELECT id INTO v_default_fare_zone_id FROM public.fare_zones WHERE is_active = true ORDER BY sort_order ASC LIMIT 1;

  -- 3. If routes and fare zones exist, link to route_stops at position
  IF v_outbound_route_id IS NOT NULL AND v_default_fare_zone_id IS NOT NULL THEN
    -- Shift later outbound stops
    UPDATE public.route_stops
    SET stop_order = stop_order + 1
    WHERE route_id = v_outbound_route_id AND stop_order >= p_position;

    INSERT INTO public.route_stops (
      route_id,
      stop_id,
      fare_zone_id,
      stop_order,
      is_active
    ) VALUES (
      v_outbound_route_id,
      v_stop_id,
      v_default_fare_zone_id,
      p_position,
      true
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'stop_id', v_stop_id
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.admin_create_station(text, double precision, double precision, integer, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_create_station(text, double precision, double precision, integer, text, text, text) TO authenticated;

-- 3. Define/Update admin_update_station with default values for locality
CREATE OR REPLACE FUNCTION public.admin_update_station(
  p_stop_id uuid,
  p_name_ar text,
  p_latitude double precision,
  p_longitude double precision,
  p_position integer,
  p_is_active boolean,
  p_name_en text DEFAULT NULL,
  p_locality_ar text DEFAULT NULL,
  p_locality_en text DEFAULT NULL,
  p_reason text DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_outbound_route_id uuid;
  v_old_order integer;
BEGIN
  -- Security check: admin only
  IF NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_name_ar IS NULL OR trim(p_name_ar) = '' THEN
    RAISE EXCEPTION 'NAME_AR_REQUIRED';
  END IF;

  -- 1. Update physical stop preserving unchanged legacy fields if not supplied
  UPDATE public.stops
  SET
    name_ar = trim(p_name_ar),
    name_en = COALESCE(NULLIF(trim(p_name_en), ''), name_en),
    locality_ar = CASE WHEN p_locality_ar IS NOT NULL THEN NULLIF(trim(p_locality_ar), '') ELSE locality_ar END,
    locality_en = CASE WHEN p_locality_en IS NOT NULL THEN NULLIF(trim(p_locality_en), '') ELSE locality_en END,
    latitude = p_latitude,
    longitude = p_longitude,
    is_active = p_is_active,
    updated_at = now()
  WHERE id = p_stop_id;

  -- 2. Adjust position in route_stops if needed
  SELECT id INTO v_outbound_route_id FROM public.routes WHERE direction = 'outbound' LIMIT 1;

  IF v_outbound_route_id IS NOT NULL THEN
    SELECT stop_order INTO v_old_order
    FROM public.route_stops
    WHERE route_id = v_outbound_route_id AND stop_id = p_stop_id;

    IF v_old_order IS NOT NULL AND v_old_order <> p_position THEN
      -- Reorder stops
      IF p_position > v_old_order THEN
        UPDATE public.route_stops
        SET stop_order = stop_order - 1
        WHERE route_id = v_outbound_route_id AND stop_order > v_old_order AND stop_order <= p_position;
      ELSE
        UPDATE public.route_stops
        SET stop_order = stop_order + 1
        WHERE route_id = v_outbound_route_id AND stop_order >= p_position AND stop_order < v_old_order;
      END IF;

      UPDATE public.route_stops
      SET stop_order = p_position,
          is_active = p_is_active,
          updated_at = now()
      WHERE route_id = v_outbound_route_id AND stop_id = p_stop_id;
    ELSIF v_old_order IS NOT NULL THEN
      UPDATE public.route_stops
      SET is_active = p_is_active,
          updated_at = now()
      WHERE route_id = v_outbound_route_id AND stop_id = p_stop_id;
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'stop_id', p_stop_id
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.admin_update_station(uuid, text, double precision, double precision, integer, boolean, text, text, text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_update_station(uuid, text, double precision, double precision, integer, boolean, text, text, text, text) TO authenticated;

-- 4. Define/Update admin_upsert_stop to handle optional locality
CREATE OR REPLACE FUNCTION public.admin_upsert_stop(
  p_name_ar text,
  p_stop_id uuid DEFAULT NULL,
  p_name_en text DEFAULT NULL,
  p_locality_ar text DEFAULT NULL,
  p_locality_en text DEFAULT NULL,
  p_latitude double precision DEFAULT NULL,
  p_longitude double precision DEFAULT NULL,
  p_is_active boolean DEFAULT true
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_stop_id uuid;
  v_result jsonb;
BEGIN
  IF NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED';
  END IF;

  IF p_name_ar IS NULL OR trim(p_name_ar) = '' THEN
    RAISE EXCEPTION 'NAME_AR_REQUIRED';
  END IF;

  IF p_stop_id IS NOT NULL THEN
    UPDATE public.stops
    SET
      name_ar = trim(p_name_ar),
      name_en = NULLIF(trim(p_name_en), ''),
      locality_ar = CASE WHEN p_locality_ar IS NOT NULL THEN NULLIF(trim(p_locality_ar), '') ELSE locality_ar END,
      locality_en = CASE WHEN p_locality_en IS NOT NULL THEN NULLIF(trim(p_locality_en), '') ELSE locality_en END,
      latitude = COALESCE(p_latitude, latitude),
      longitude = COALESCE(p_longitude, longitude),
      is_active = p_is_active,
      updated_at = now()
    WHERE id = p_stop_id
    RETURNING id INTO v_stop_id;
  ELSE
    INSERT INTO public.stops (
      name_ar,
      name_en,
      locality_ar,
      locality_en,
      latitude,
      longitude,
      is_active
    ) VALUES (
      trim(p_name_ar),
      NULLIF(trim(p_name_en), ''),
      NULLIF(trim(p_locality_ar), ''),
      NULLIF(trim(p_locality_en), ''),
      p_latitude,
      p_longitude,
      p_is_active
    ) RETURNING id INTO v_stop_id;
  END IF;

  SELECT jsonb_build_object(
    'id', s.id,
    'name_ar', s.name_ar,
    'name_en', s.name_en,
    'locality_ar', s.locality_ar,
    'locality_en', s.locality_en,
    'latitude', s.latitude,
    'longitude', s.longitude,
    'is_active', s.is_active,
    'created_at', s.created_at,
    'updated_at', s.updated_at,
    'route_count', (SELECT COUNT(*)::int FROM public.route_stops rs WHERE rs.stop_id = s.id)
  ) INTO v_result
  FROM public.stops s
  WHERE s.id = v_stop_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.admin_upsert_stop(text, uuid, text, text, text, double precision, double precision, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_upsert_stop(text, uuid, text, text, text, double precision, double precision, boolean) TO authenticated;
