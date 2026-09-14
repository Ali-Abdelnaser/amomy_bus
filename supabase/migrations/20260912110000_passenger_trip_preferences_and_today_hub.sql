-- =============================================================================
-- Migration: 20260912110000_passenger_trip_preferences_and_today_hub.sql
-- Description:
--   1. Creates passenger_trip_preferences table (origin_stop_id, destination_stop_id, etc.).
--   2. Adds destination_route_stop_id to seat_holds and bookings.
--   3. Adds RPC get_my_trip_preferences() and set_my_trip_preferences().
--   4. Updates create_booking_hold to support optional p_destination_route_stop_id with ordering validation.
--   5. Updates confirm_booking to carry destination_route_stop_id and auto-upsert preferred journey.
--   6. Adds passenger-safe get_passenger_today_trips() returning today's schedules with intelligent
--      per-passenger states (AVAILABLE, ALREADY_BOOKED, FULL, BOOKING_CLOSED, DEPARTED).
-- =============================================================================

-- 1. PASSENGER TRIP PREFERENCES TABLE
CREATE TABLE IF NOT EXISTS public.passenger_trip_preferences (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  origin_stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE RESTRICT,
  destination_stop_id uuid NOT NULL REFERENCES public.stops(id) ON DELETE RESTRICT,
  origin_route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE SET NULL,
  destination_route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE SET NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.passenger_trip_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "passenger_trip_preferences_select" ON public.passenger_trip_preferences;
CREATE POLICY "passenger_trip_preferences_select"
  ON public.passenger_trip_preferences FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "passenger_trip_preferences_all" ON public.passenger_trip_preferences;
CREATE POLICY "passenger_trip_preferences_all"
  ON public.passenger_trip_preferences FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 2. DESTINATION STOP SUPPORT ON seat_holds & bookings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'seat_holds' AND column_name = 'destination_route_stop_id'
  ) THEN
    ALTER TABLE public.seat_holds ADD COLUMN destination_route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE RESTRICT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'destination_route_stop_id'
  ) THEN
    ALTER TABLE public.bookings ADD COLUMN destination_route_stop_id uuid REFERENCES public.route_stops(id) ON DELETE RESTRICT;
  END IF;
END $$;

-- 3. PASSENGER PREFERENCES RPCS
CREATE OR REPLACE FUNCTION public.get_my_trip_preferences()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_pref RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  SELECT
    p.origin_stop_id,
    p.destination_stop_id,
    p.origin_route_stop_id,
    p.destination_route_stop_id,
    s_orig.name_ar AS origin_name_ar,
    s_orig.name_en AS origin_name_en,
    s_orig.locality_ar AS origin_locality_ar,
    s_orig.locality_en AS origin_locality_en,
    s_dest.name_ar AS destination_name_ar,
    s_dest.name_en AS destination_name_en,
    s_dest.locality_ar AS destination_locality_ar,
    s_dest.locality_en AS destination_locality_en,
    p.updated_at
  INTO v_pref
  FROM public.passenger_trip_preferences p
  JOIN public.stops s_orig ON s_orig.id = p.origin_stop_id
  JOIN public.stops s_dest ON s_dest.id = p.destination_stop_id
  WHERE p.user_id = v_user_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'origin_stop_id', v_pref.origin_stop_id,
    'destination_stop_id', v_pref.destination_stop_id,
    'origin_route_stop_id', v_pref.origin_route_stop_id,
    'destination_route_stop_id', v_pref.destination_route_stop_id,
    'origin_name_ar', v_pref.origin_name_ar,
    'origin_name_en', v_pref.origin_name_en,
    'origin_locality_ar', v_pref.origin_locality_ar,
    'origin_locality_en', v_pref.origin_locality_en,
    'destination_name_ar', v_pref.destination_name_ar,
    'destination_name_en', v_pref.destination_name_en,
    'destination_locality_ar', v_pref.destination_locality_ar,
    'destination_locality_en', v_pref.destination_locality_en,
    'updated_at', v_pref.updated_at
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.get_my_trip_preferences() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_trip_preferences() TO authenticated;

CREATE OR REPLACE FUNCTION public.set_my_trip_preferences(
  p_origin_stop_id uuid,
  p_destination_stop_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_orig_stop RECORD;
  v_dest_stop RECORD;
  v_orig_rs_id uuid;
  v_dest_rs_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  IF p_origin_stop_id = p_destination_stop_id THEN
    RAISE EXCEPTION 'ORIGIN_AND_DESTINATION_IDENTICAL';
  END IF;

  SELECT * INTO v_orig_stop FROM public.stops WHERE id = p_origin_stop_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORIGIN_STOP_INVALID';
  END IF;

  SELECT * INTO v_dest_stop FROM public.stops WHERE id = p_destination_stop_id AND is_active = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'DESTINATION_STOP_INVALID';
  END IF;

  -- Check if they belong to an active route where destination order > origin order
  SELECT rs_orig.id, rs_dest.id
  INTO v_orig_rs_id, v_dest_rs_id
  FROM public.route_stops rs_orig
  JOIN public.route_stops rs_dest ON rs_dest.route_id = rs_orig.route_id
  JOIN public.routes r ON r.id = rs_orig.route_id
  WHERE rs_orig.stop_id = p_origin_stop_id
    AND rs_dest.stop_id = p_destination_stop_id
    AND rs_dest.stop_order > rs_orig.stop_order
    AND rs_orig.is_active = true
    AND rs_dest.is_active = true
    AND r.is_active = true
  LIMIT 1;

  IF v_orig_rs_id IS NULL THEN
    SELECT rs.id INTO v_orig_rs_id FROM public.route_stops rs WHERE rs.stop_id = p_origin_stop_id AND rs.is_active = true LIMIT 1;
    SELECT rs.id INTO v_dest_rs_id FROM public.route_stops rs WHERE rs.stop_id = p_destination_stop_id AND rs.is_active = true LIMIT 1;
  END IF;

  INSERT INTO public.passenger_trip_preferences (
    user_id,
    origin_stop_id,
    destination_stop_id,
    origin_route_stop_id,
    destination_route_stop_id,
    updated_at
  ) VALUES (
    v_user_id,
    p_origin_stop_id,
    p_destination_stop_id,
    v_orig_rs_id,
    v_dest_rs_id,
    now()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    origin_stop_id = EXCLUDED.origin_stop_id,
    destination_stop_id = EXCLUDED.destination_stop_id,
    origin_route_stop_id = EXCLUDED.origin_route_stop_id,
    destination_route_stop_id = EXCLUDED.destination_route_stop_id,
    updated_at = now();

  RETURN public.get_my_trip_preferences();
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.set_my_trip_preferences(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_my_trip_preferences(uuid, uuid) TO authenticated;

-- 4. UPDATE create_booking_hold: DESTINATION STOP SUPPORT
DROP FUNCTION IF EXISTS public.create_booking_hold(uuid, uuid, uuid);
DROP FUNCTION IF EXISTS public.create_booking_hold(uuid, uuid, uuid, uuid);

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
  v_cairo_today date := (current_timestamp AT TIME ZONE 'Africa/Cairo')::date;
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

  -- 4. TODAY-ONLY BOOKING ENFORCEMENT
  IF v_trip.service_date != v_cairo_today THEN
    RAISE EXCEPTION 'TODAY_ONLY_BOOKING';
  END IF;

  IF v_trip.status != 'scheduled' AND v_trip.status != 'boarding' THEN
    RAISE EXCEPTION 'TRIP_UNAVAILABLE';
  END IF;

  IF v_trip.departure_at <= now() OR v_trip.booking_close_at <= now() THEN
    RAISE EXCEPTION 'BOOKING_CLOSED';
  END IF;

  -- 5. Route Stop & Dynamic Fare Resolution (Boarding Stop determines price)
  IF p_route_stop_id IS NOT NULL THEN
    SELECT
      fz.fare_points,
      fz.id,
      s.name_ar,
      s.locality_ar,
      rs.stop_order
    INTO
      v_stop_fare,
      v_fare_zone_id,
      v_stop_name,
      v_stop_locality,
      v_orig_order
    FROM public.route_stops rs
    JOIN public.fare_zones fz ON fz.id = rs.fare_zone_id
    JOIN public.stops s ON s.id = rs.stop_id
    WHERE rs.id = p_route_stop_id
      AND rs.route_id = v_trip.route_id
      AND rs.is_active = true
      AND fz.is_active = true;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ROUTE_STOP_INVALID';
    END IF;

    v_effective_fare := v_stop_fare;
  ELSE
    -- Legacy trip fare fallback
    v_effective_fare := v_trip.fare_points;
  END IF;

  -- 5b. Destination Stop Validation if provided
  IF p_destination_route_stop_id IS NOT NULL THEN
    IF p_route_stop_id IS NOT NULL AND p_route_stop_id = p_destination_route_stop_id THEN
      RAISE EXCEPTION 'ORIGIN_AND_DESTINATION_IDENTICAL';
    END IF;

    SELECT
      s.name_ar,
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

  -- 6. Seat validation
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
    status,
    expires_at,
    created_at
  ) VALUES (
    p_trip_id,
    p_seat_id,
    v_user_id,
    p_route_stop_id,
    p_destination_route_stop_id,
    v_fare_zone_id,
    v_effective_fare,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_seat_hold_id;

  -- 9. Create point hold record
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
    v_effective_fare,
    'trip_booking',
    v_seat_hold_id,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_point_hold_id;

  UPDATE public.seat_holds
  SET point_hold_id = v_point_hold_id
  WHERE id = v_seat_hold_id;

  -- 10. Allocate hold points: Subscription points first, then cash points
  v_remaining_needed := v_effective_fare;

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

  IF v_remaining_needed > 0 THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- Update cached wallet balance
  UPDATE public.wallets
  SET cached_available_balance = cached_available_balance - v_effective_fare,
      cached_held_balance = cached_held_balance + v_effective_fare,
      updated_at = now()
  WHERE id = v_wallet.id;

  RETURN jsonb_build_object(
    'success', true,
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_effective_fare,
    'expires_at', v_hold_expires_at,
    'server_time', now(),
    'route_stop_id', p_route_stop_id,
    'destination_route_stop_id', p_destination_route_stop_id,
    'stop_name', v_stop_name,
    'destination_stop_name', v_dest_stop_name,
    'locality', v_stop_locality,
    'fare_zone_id', v_fare_zone_id
  );
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid, uuid) TO authenticated;

-- Backwards-compatible 3-arg overload
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid,
  p_route_stop_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
AS $$
BEGIN
  RETURN public.create_booking_hold(p_trip_id, p_seat_id, p_route_stop_id, NULL);
END;
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid, uuid) TO authenticated;

-- 5. UPDATE confirm_booking: CARRY DESTINATION AND AUTO-UPSERT PREFERRED JOURNEY
CREATE OR REPLACE FUNCTION public.confirm_booking(
  p_hold_id uuid
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
VOLATILE
AS $$
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

  -- Create confirmed booking
  INSERT INTO public.bookings (
    user_id,
    trip_id,
    seat_id,
    route_stop_id,
    destination_route_stop_id,
    fare_zone_id,
    fare_points,
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
        -- Fallback to terminal route stop
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
      -- Do not fail booking confirmation on preference recording failure
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
$$ LANGUAGE plpgsql;

REVOKE EXECUTE ON FUNCTION public.confirm_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;

-- 6. PASSENGER-SAFE TODAY'S TRIPS HUB RPC
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
      bkg.fare_points AS b_fare_points
    FROM public.bookings bkg
    JOIN public.bus_seats bs ON bs.id = bkg.seat_id
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
    r.origin_name_ar,
    r.origin_name_en,
    r.destination_name_ar,
    r.destination_name_en,
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
