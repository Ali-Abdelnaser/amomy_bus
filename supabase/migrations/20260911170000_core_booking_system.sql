-- =============================================================================
-- Migration: 20260911170000_core_booking_system.sql
-- Description: Core AMOMY Transportation Booking System
--   1. Schema: routes, buses, bus_seats, trip_schedules, trips, seat_holds, bookings
--   2. Strict server-side security: no passenger exposure of bus/driver/PII
--   3. Concurrency-safe 5-minute seat holds + atomic point reservations
--   4. Point spending order: subscription points first (earliest expiry first), then cash
--   5. Full transaction rollback on failure
--   6. Idempotent hold expiration & auto-cleanup via pg_cron
--   7. Realtime publications for seat_holds and bookings
--   8. Seed data: routes, buses (14-seat microbuses), schedules, upcoming trips
-- =============================================================================

-- =============================================================================
-- 1. ENUMS & CORE TABLES
-- =============================================================================

-- 1.1 Route Direction Enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'route_direction') THEN
    CREATE TYPE public.route_direction AS ENUM ('outbound', 'return');
  END IF;
END $$;

-- 1.2 Trip Status Enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'trip_status') THEN
    CREATE TYPE public.trip_status AS ENUM ('scheduled', 'boarding', 'departed', 'completed', 'cancelled');
  END IF;
END $$;

-- 1.3 Seat Hold Status Enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'seat_hold_status') THEN
    CREATE TYPE public.seat_hold_status AS ENUM ('active', 'released', 'expired', 'converted');
  END IF;
END $$;

-- 1.4 Booking Status Enum
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE public.booking_status AS ENUM ('confirmed', 'cancelled', 'completed', 'no_show');
  END IF;
END $$;

-- =============================================================================
-- 2. TABLES DEFINITIONS
-- =============================================================================

-- 2.1 routes
CREATE TABLE IF NOT EXISTS public.routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  direction public.route_direction NOT NULL,
  origin_name_ar text NOT NULL,
  origin_name_en text NOT NULL,
  destination_name_ar text NOT NULL,
  destination_name_en text NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.2 buses (Internal fleet entity - strictly protected from passenger direct read)
CREATE TABLE IF NOT EXISTS public.buses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  internal_code text NOT NULL UNIQUE,
  plate_number text NOT NULL,
  capacity integer NOT NULL CHECK (capacity > 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.3 bus_seats (Physical 2D seating coordinates per bus)
CREATE TABLE IF NOT EXISTS public.bus_seats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
  seat_number text NOT NULL,
  row_index integer NOT NULL CHECK (row_index >= 0),
  column_index integer NOT NULL CHECK (column_index >= 0),
  seat_type text NOT NULL DEFAULT 'standard',
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_bus_seat UNIQUE (bus_id, seat_number)
);

-- 2.4 trip_schedules (Configurable recurring departure configuration)
CREATE TABLE IF NOT EXISTS public.trip_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  departure_local_time time NOT NULL,
  bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE RESTRICT,
  fare_points numeric NOT NULL CHECK (fare_points > 0),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.5 trips (Dated trip instances)
CREATE TABLE IF NOT EXISTS public.trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id uuid REFERENCES public.trip_schedules(id) ON DELETE SET NULL,
  route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE RESTRICT,
  service_date date NOT NULL,
  departure_at timestamptz NOT NULL,
  bus_id uuid NOT NULL REFERENCES public.buses(id) ON DELETE RESTRICT,
  fare_points numeric NOT NULL CHECK (fare_points > 0),
  status public.trip_status NOT NULL DEFAULT 'scheduled',
  booking_open_at timestamptz NOT NULL DEFAULT now(),
  booking_close_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_trip_schedule_date UNIQUE (schedule_id, service_date)
);

-- 2.6 seat_holds (Server-owned 5-minute atomic seat holds)
CREATE TABLE IF NOT EXISTS public.seat_holds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  seat_id uuid NOT NULL REFERENCES public.bus_seats(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  point_hold_id uuid REFERENCES public.point_holds(id) ON DELETE SET NULL,
  status public.seat_hold_status NOT NULL DEFAULT 'active',
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  released_at timestamptz,
  booking_id uuid
);

-- Concurrency protection: A seat may have ONLY ONE ACTIVE hold for a trip
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_seat_hold
  ON public.seat_holds (trip_id, seat_id)
  WHERE (status = 'active');

-- 2.7 bookings (Confirmed passenger ticket records)
CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  trip_id uuid NOT NULL REFERENCES public.trips(id) ON DELETE RESTRICT,
  seat_id uuid NOT NULL REFERENCES public.bus_seats(id) ON DELETE RESTRICT,
  fare_points numeric NOT NULL CHECK (fare_points > 0),
  status public.booking_status NOT NULL DEFAULT 'confirmed',
  qr_token text NOT NULL UNIQUE,
  booked_at timestamptz NOT NULL DEFAULT now(),
  cancelled_at timestamptz,
  checked_in_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Add foreign key constraint for seat_holds.booking_id -> bookings.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'fk_seat_holds_booking'
  ) THEN
    ALTER TABLE public.seat_holds
      ADD CONSTRAINT fk_seat_holds_booking
      FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE SET NULL;
  END IF;
END $$;

-- One seat cannot have two active/confirmed bookings on the same trip
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_trip_seat_booking
  ON public.bookings (trip_id, seat_id)
  WHERE (status = 'confirmed');

-- =============================================================================
-- 3. INDEXES FOR HIGH-THROUGHPUT QUERIES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_trips_service_date_route ON public.trips(service_date, route_id);
CREATE INDEX IF NOT EXISTS idx_trips_departure_at ON public.trips(departure_at);
CREATE INDEX IF NOT EXISTS idx_bus_seats_bus_id ON public.bus_seats(bus_id);
CREATE INDEX IF NOT EXISTS idx_trip_schedules_route ON public.trip_schedules(route_id);
CREATE INDEX IF NOT EXISTS idx_seat_holds_user ON public.seat_holds(user_id);
CREATE INDEX IF NOT EXISTS idx_seat_holds_trip_status ON public.seat_holds(trip_id, status);
CREATE INDEX IF NOT EXISTS idx_seat_holds_expires_at ON public.seat_holds(expires_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_bookings_user_status ON public.bookings(user_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_trip_id ON public.bookings(trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_qr_token ON public.bookings(qr_token);

-- =============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bus_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trip_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seat_holds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 4.1 routes
CREATE POLICY "routes_select_active" ON public.routes
  FOR SELECT TO authenticated
  USING (is_active = true OR app_private.is_admin());

CREATE POLICY "routes_admin_all" ON public.routes
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 4.2 buses (Admin only! Passengers must NOT read buses table directly)
CREATE POLICY "buses_admin_only" ON public.buses
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 4.3 bus_seats (Admin only for direct query; passenger reads via get_trip_seat_map RPC)
CREATE POLICY "bus_seats_admin_only" ON public.bus_seats
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 4.4 trip_schedules
CREATE POLICY "trip_schedules_select_active" ON public.trip_schedules
  FOR SELECT TO authenticated
  USING (is_active = true OR app_private.is_admin());

CREATE POLICY "trip_schedules_admin_all" ON public.trip_schedules
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 4.5 trips (Passenger can see non-cancelled trips; detailed DTO stripped of bus ID via RPC)
CREATE POLICY "trips_select_passenger" ON public.trips
  FOR SELECT TO authenticated
  USING (status != 'cancelled' OR app_private.is_admin());

CREATE POLICY "trips_admin_all" ON public.trips
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 4.6 seat_holds (Passenger can view own holds; all passenger mutations via RPC)
CREATE POLICY "seat_holds_select_own_or_admin" ON public.seat_holds
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- 4.7 bookings (Passenger can view own bookings; passenger mutations via RPC)
CREATE POLICY "bookings_select_own_or_admin" ON public.bookings
  FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id OR app_private.is_admin());

-- Revoke direct DML from authenticated and anon
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.routes FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.buses FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.bus_seats FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.trip_schedules FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.trips FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.seat_holds FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.bookings FROM anon, authenticated;

-- Allow select on safe passenger entities
GRANT SELECT ON public.routes TO authenticated;
GRANT SELECT ON public.trips TO authenticated;
GRANT SELECT ON public.seat_holds TO authenticated;
GRANT SELECT ON public.bookings TO authenticated;

-- =============================================================================
-- 5. RPCs: PASSENGER-SAFE PROCEDURES
-- =============================================================================

-- 5.1 get_available_trips (Passenger-safe trip listing with available seats count)
CREATE OR REPLACE FUNCTION public.get_available_trips(
  p_direction text,
  p_date date
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
BEGIN
  -- Validate direction
  IF p_direction NOT IN ('outbound', 'return') THEN
    RAISE EXCEPTION 'INVALID_DIRECTION';
  END IF;

  RETURN QUERY
  WITH trip_counts AS (
    SELECT
      t.id AS c_trip_id,
      b.capacity - (
        -- Booked seats
        (SELECT COUNT(*)::integer FROM public.bookings bkg WHERE bkg.trip_id = t.id AND bkg.status = 'confirmed') +
        -- Actively held unexpired seats
        (SELECT COUNT(*)::integer FROM public.seat_holds sh WHERE sh.trip_id = t.id AND sh.status = 'active' AND sh.expires_at > now())
      ) AS calc_available
    FROM public.trips t
    JOIN public.buses b ON b.id = t.bus_id
    WHERE t.service_date = p_date
  )
  SELECT
    t.id AS trip_id,
    r.id AS route_id,
    r.direction::text AS direction,
    r.origin_name_ar,
    r.origin_name_en,
    r.destination_name_ar,
    r.destination_name_en,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    t.fare_points,
    GREATEST(0, tc.calc_available)::integer AS available_seats_count,
    t.status::text AS status
  FROM public.trips t
  JOIN public.routes r ON r.id = t.route_id
  JOIN trip_counts tc ON tc.c_trip_id = t.id
  WHERE r.direction = p_direction::public.route_direction
    AND t.service_date = p_date
    AND t.status IN ('scheduled', 'boarding')
    AND t.booking_close_at > now()
  ORDER BY t.departure_at ASC;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_available_trips(text, date) TO authenticated;

-- 5.2 get_trip_seat_map (Passenger-safe seat layout & state)
CREATE OR REPLACE FUNCTION public.get_trip_seat_map(p_trip_id uuid)
RETURNS TABLE (
  seat_id uuid,
  seat_number text,
  row_index integer,
  column_index integer,
  seat_type text,
  status text,       -- 'available', 'held', 'booked'
  is_mine boolean,
  passenger_gender text
)
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_bus_id uuid;
BEGIN
  -- Get bus_id for trip
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
      -- Confirmed booking
      WHEN bkg.id IS NOT NULL THEN 'booked'
      -- Active unexpired hold
      WHEN sh.id IS NOT NULL THEN 'held'
      -- Otherwise available
      ELSE 'available'
    END AS status,
    CASE
      WHEN bkg.user_id = v_user_id THEN true
      WHEN sh.user_id = v_user_id THEN true
      ELSE false
    END AS is_mine,
    -- Gender indication only for confirmed seats (never expose name/phone/email/user_id)
    CASE
      WHEN bkg.id IS NOT NULL THEN prof.gender
      ELSE NULL
    END AS passenger_gender
  FROM public.bus_seats bs
  -- Join confirmed booking if exists
  LEFT JOIN public.bookings bkg
    ON bkg.trip_id = p_trip_id
    AND bkg.seat_id = bs.id
    AND bkg.status = 'confirmed'
  -- Join passenger gender safely
  LEFT JOIN public.profiles prof
    ON prof.id = bkg.user_id
  -- Join active hold if exists
  LEFT JOIN public.seat_holds sh
    ON sh.trip_id = p_trip_id
    AND sh.seat_id = bs.id
    AND sh.status = 'active'
    AND sh.expires_at > now()
  WHERE bs.bus_id = v_bus_id
    AND bs.is_active = true
  ORDER BY bs.row_index ASC, bs.column_index ASC;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_trip_seat_map(uuid) TO authenticated;

-- 5.3 create_booking_hold (Atomic 5-minute Seat Hold + Points Reservation)
CREATE OR REPLACE FUNCTION public.create_booking_hold(
  p_trip_id uuid,
  p_seat_id uuid
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
  v_wallet RECORD;
  v_hold_expires_at timestamptz;
  v_seat_hold_id uuid;
  v_point_hold_id uuid;
  v_batch RECORD;
  v_remaining_needed numeric;
  v_take numeric;
  v_existing_hold RECORD;
BEGIN
  -- 1. Must be authenticated
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Server-side profile completeness check
  SELECT full_name, email, phone, gender, date_of_birth INTO v_profile
  FROM public.profiles
  WHERE id = v_user_id;

  IF NOT FOUND OR
     v_profile.phone IS NULL OR trim(v_profile.phone) = '' OR
     v_profile.gender IS NULL OR v_profile.gender NOT IN ('male', 'female') OR
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

  -- 4. Validate seat belongs to this trip's bus
  SELECT * INTO v_seat
  FROM public.bus_seats
  WHERE id = p_seat_id
    AND bus_id = v_trip.bus_id
    AND is_active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_INVALID';
  END IF;

  -- 5. Concurrency check: Ensure seat is not already confirmed booked
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = p_trip_id
      AND seat_id = p_seat_id
      AND status = 'confirmed'
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- 6. Concurrency check: Ensure seat is not actively held by someone else
  -- Check and clean up expired holds for this seat first
  UPDATE public.seat_holds
  SET status = 'expired'
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at <= now();

  -- Now verify no active unexpired hold
  SELECT * INTO v_existing_hold
  FROM public.seat_holds
  WHERE trip_id = p_trip_id
    AND seat_id = p_seat_id
    AND status = 'active'
    AND expires_at > now()
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_hold.user_id = v_user_id THEN
      -- Already held by this user: return existing hold info
      RETURN jsonb_build_object(
        'success', true,
        'hold_id', v_existing_hold.id,
        'trip_id', p_trip_id,
        'seat_id', p_seat_id,
        'seat_number', v_seat.seat_number,
        'fare_points', v_trip.fare_points,
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

  -- 7. Wallet balance check
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND OR v_wallet.cached_available_balance < v_trip.fare_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  -- 8. Calculate server-owned expiry: 5 minutes from now
  v_hold_expires_at := now() + interval '5 minutes';

  -- 9. Insert seat hold
  INSERT INTO public.seat_holds (
    trip_id,
    seat_id,
    user_id,
    status,
    expires_at,
    created_at
  ) VALUES (
    p_trip_id,
    p_seat_id,
    v_user_id,
    'active',
    v_hold_expires_at,
    now()
  ) RETURNING id INTO v_seat_hold_id;

  -- 10. Reserve Points (Create point_hold)
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
    v_trip.fare_points,
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

  -- 11. Allocate points across batches:
  -- Spending Rule: 1) Subscription points first (earliest expiring first), 2) Cash points second
  v_remaining_needed := v_trip.fare_points;

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

  -- 12. Update wallet cached balances
  UPDATE public.wallets
  SET cached_available_balance = cached_available_balance - v_trip.fare_points,
      cached_held_balance = cached_held_balance + v_trip.fare_points,
      updated_at = now()
  WHERE id = v_wallet.id;

  RETURN jsonb_build_object(
    'success', true,
    'hold_id', v_seat_hold_id,
    'trip_id', p_trip_id,
    'seat_id', p_seat_id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_trip.fare_points,
    'expires_at', v_hold_expires_at,
    'server_time', now()
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.create_booking_hold(uuid, uuid) TO authenticated;

-- 5.4 release_booking_hold (Releases active seat hold and refunds held points)
CREATE OR REPLACE FUNCTION public.release_booking_hold(p_hold_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_seat_hold RECORD;
  v_point_hold RECORD;
  v_wallet RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- Lock seat hold
  SELECT * INTO v_seat_hold
  FROM public.seat_holds
  WHERE id = p_hold_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'reason', 'HOLD_NOT_FOUND');
  END IF;

  -- Verify ownership or admin
  IF v_seat_hold.user_id != v_user_id AND NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  -- If not active, already released/converted
  IF v_seat_hold.status != 'active' THEN
    RETURN jsonb_build_object('success', true, 'status', v_seat_hold.status);
  END IF;

  -- Mark seat hold released
  UPDATE public.seat_holds
  SET status = 'released',
      released_at = now()
  WHERE id = p_hold_id;

  -- Release point hold if attached
  IF v_seat_hold.point_hold_id IS NOT NULL THEN
    SELECT * INTO v_point_hold
    FROM public.point_holds
    WHERE id = v_seat_hold.point_hold_id
    FOR UPDATE;

    IF FOUND AND v_point_hold.status = 'active' THEN
      -- Delete allocations
      DELETE FROM public.point_hold_allocations
      WHERE hold_id = v_point_hold.id;

      -- Mark point hold released
      UPDATE public.point_holds
      SET status = 'released',
          released_at = now()
      WHERE id = v_point_hold.id;

      -- Update wallet cached balances
      SELECT * INTO v_wallet
      FROM public.wallets
      WHERE user_id = v_seat_hold.user_id
      FOR UPDATE;

      IF FOUND THEN
        UPDATE public.wallets
        SET cached_available_balance = cached_available_balance + v_point_hold.amount,
            cached_held_balance = GREATEST(0, cached_held_balance - v_point_hold.amount),
            updated_at = now()
        WHERE id = v_wallet.id;
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.release_booking_hold(uuid) TO authenticated;

-- 5.5 confirm_booking (Atomic conversion: Hold -> Booking -> Points Deduction -> QR Token)
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
  v_point_hold RECORD;
  v_allocation RECORD;
  v_wallet RECORD;
  v_booking_id uuid;
  v_qr_token text;
  v_batch RECORD;
  v_new_wallet_held numeric;
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
    -- Expired: trigger release and abort
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

  -- 5. Lock point hold
  SELECT * INTO v_point_hold
  FROM public.point_holds
  WHERE id = v_seat_hold.point_hold_id
  FOR UPDATE;

  IF NOT FOUND OR v_point_hold.status != 'active' THEN
    RAISE EXCEPTION 'POINT_HOLD_INVALID';
  END IF;

  -- 6. Lock wallet
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  -- 7. Generate secure QR token (cryptographically random hex string)
  v_qr_token := 'AMY_' || encode(gen_random_bytes(20), 'hex');

  -- 8. Create Confirmed Booking record
  INSERT INTO public.bookings (
    user_id,
    trip_id,
    seat_id,
    fare_points,
    status,
    qr_token,
    booked_at
  ) VALUES (
    v_user_id,
    v_trip.id,
    v_seat.id,
    v_trip.fare_points,
    'confirmed',
    v_qr_token,
    now()
  ) RETURNING id INTO v_booking_id;

  -- 9. Consume allocated held points from batches & record point transactions
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

    -- Record debit transaction
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
      v_wallet.cached_available_balance, -- available was already decremented at hold
      v_wallet.cached_available_balance,
      'booking',
      v_booking_id,
      'Trip Seat Booking ' || v_seat.seat_number,
      v_user_id,
      jsonb_build_object(
        'booking_id', v_booking_id,
        'trip_id', v_trip.id,
        'seat_id', v_seat.id,
        'seat_number', v_seat.seat_number,
        'batch_source_type', v_batch.source_type
      )
    );
  END LOOP;

  -- 10. Update wallet: Decrement cached_held_balance
  v_new_wallet_held := GREATEST(0, v_wallet.cached_held_balance - v_point_hold.amount);
  UPDATE public.wallets
  SET cached_held_balance = v_new_wallet_held,
      updated_at = now()
  WHERE id = v_wallet.id;

  -- 11. Convert point hold & seat hold to completed/converted
  UPDATE public.point_holds
  SET status = 'consumed',
      consumed_at = now()
  WHERE id = v_point_hold.id;

  -- Delete allocations
  DELETE FROM public.point_hold_allocations
  WHERE hold_id = v_point_hold.id;

  -- 12. Mark seat hold converted to booking
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
      'fare_points', v_trip.fare_points,
      'booking_id', v_booking_id
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking_id,
    'qr_token', v_qr_token,
    'trip_id', v_trip.id,
    'seat_number', v_seat.seat_number,
    'fare_points', v_trip.fare_points,
    'booked_at', now()
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.confirm_booking(uuid) TO authenticated;

-- 5.6 expire_booking_holds (Idempotent server cleanup for expired seat and point holds)
CREATE OR REPLACE FUNCTION public.expire_booking_holds()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_hold RECORD;
  v_expired_count int := 0;
BEGIN
  FOR v_hold IN
    SELECT id
    FROM public.seat_holds
    WHERE status = 'active'
      AND expires_at <= now()
    FOR UPDATE SKIP LOCKED
  LOOP
    PERFORM public.release_booking_hold(v_hold.id);
    -- Ensure marked expired if release marked released
    UPDATE public.seat_holds
    SET status = 'expired'
    WHERE id = v_hold.id;
    v_expired_count := v_expired_count + 1;
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'expired_count', v_expired_count,
    'executed_at', now()
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.expire_booking_holds() TO authenticated, service_role;

-- 5.7 get_passenger_bookings (Passenger trips: upcoming & history)
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
  booked_at timestamptz
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
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_passenger_bookings() TO authenticated;

-- =============================================================================
-- 6. REALTIME REPLICATION CONFIGURATION
-- =============================================================================
-- Ensure tables are added to realtime publication safely
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.seat_holds;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;
EXCEPTION
  WHEN duplicate_object THEN
    NULL;
END $$;

-- Set replica identity to full so update/delete broadcasts carry previous row state
ALTER TABLE public.seat_holds REPLICA IDENTITY FULL;
ALTER TABLE public.bookings REPLICA IDENTITY FULL;

-- =============================================================================
-- 7. PG_CRON SCHEDULE: EXPIRE HOLDS EVERY MINUTE
-- =============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Unshed existing if already created
    PERFORM cron.unschedule('expire-booking-holds-minutely')
    WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'expire-booking-holds-minutely');

    PERFORM cron.schedule(
      'expire-booking-holds-minutely',
      '* * * * *',
      'SELECT public.expire_booking_holds();'
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    -- If cron extension permissions in sub-environment, skip gracefully
    NULL;
END $$;

-- =============================================================================
-- 8. SEED DATA: ROUTES, BUSES, SEATS, SCHEDULES & UPCOMING TRIPS
-- =============================================================================
DO $$
DECLARE
  v_route_outbound_id uuid := '11111111-1111-1111-1111-111111111101'::uuid;
  v_route_return_id   uuid := '11111111-1111-1111-1111-111111111102'::uuid;
  v_bus_1_id          uuid := '22222222-2222-2222-2222-222222222201'::uuid;
  v_bus_2_id          uuid := '22222222-2222-2222-2222-222222222202'::uuid;
  v_bus_3_id          uuid := '22222222-2222-2222-2222-222222222203'::uuid;
  v_bus_record RECORD;
  v_row int;
  v_col int;
  v_seat_num int;
  v_day_offset int;
  v_curr_date date;
  v_dep_cairo timestamptz;
  v_schedule_record RECORD;
BEGIN
  -- 8.1 Routes
  INSERT INTO public.routes (id, direction, origin_name_ar, origin_name_en, destination_name_ar, destination_name_en, is_active)
  VALUES
    (v_route_outbound_id, 'outbound', 'محطة القاهرة', 'Cairo Station', 'العاصمة الإدارية', 'New Administrative Capital', true),
    (v_route_return_id,   'return',   'العاصمة الإدارية', 'New Administrative Capital', 'محطة القاهرة', 'Cairo Station', true)
  ON CONFLICT (id) DO UPDATE
    SET origin_name_ar = EXCLUDED.origin_name_ar,
        destination_name_ar = EXCLUDED.destination_name_ar;

  -- 8.2 Buses (~3 buses, 14-passenger modern commuter microbus)
  INSERT INTO public.buses (id, internal_code, plate_number, capacity, is_active)
  VALUES
    (v_bus_1_id, 'BUS-AMY-01', 'ق ج 1423', 14, true),
    (v_bus_2_id, 'BUS-AMY-02', 'ق ج 1895', 14, true),
    (v_bus_3_id, 'BUS-AMY-03', 'ق ج 2410', 14, true)
  ON CONFLICT (id) DO NOTHING;

  -- 8.3 Bus Seats (14 seats layout: 4 rows x 4 cols with aisle, top-view)
  -- Row 0: Row behind driver (col 0: 1A, col 2: 1B, col 3: 1C)
  -- Row 1: (col 0: 2A, col 2: 2B, col 3: 2C)
  -- Row 2: (col 0: 3A, col 2: 3B, col 3: 3C)
  -- Row 3: Back row (col 0: 4A, col 1: 4B, col 2: 4C, col 3: 4D, col 4: 4E)
  FOR v_bus_record IN SELECT id FROM public.buses WHERE id IN (v_bus_1_id, v_bus_2_id, v_bus_3_id)
  LOOP
    -- Insert 14 seats per bus if not already present
    INSERT INTO public.bus_seats (bus_id, seat_number, row_index, column_index, seat_type)
    VALUES
      (v_bus_record.id, '1A', 0, 0, 'standard'),
      (v_bus_record.id, '1B', 0, 2, 'standard'),
      (v_bus_record.id, '1C', 0, 3, 'standard'),
      (v_bus_record.id, '2A', 1, 0, 'standard'),
      (v_bus_record.id, '2B', 1, 2, 'standard'),
      (v_bus_record.id, '2C', 1, 3, 'standard'),
      (v_bus_record.id, '3A', 2, 0, 'standard'),
      (v_bus_record.id, '3B', 2, 2, 'standard'),
      (v_bus_record.id, '3C', 2, 3, 'standard'),
      (v_bus_record.id, '4A', 3, 0, 'standard'),
      (v_bus_record.id, '4B', 3, 1, 'standard'),
      (v_bus_record.id, '4C', 3, 2, 'standard'),
      (v_bus_record.id, '4D', 3, 3, 'standard'),
      (v_bus_record.id, '4E', 3, 4, 'standard')
    ON CONFLICT (bus_id, seat_number) DO NOTHING;
  END LOOP;

  -- 8.4 Trip Schedules (Outbound: 08:00, 09:00, 10:00, 11:00; Return: 13:00, 14:00, 15:00, 16:00)
  -- Fare: 50 points per trip
  INSERT INTO public.trip_schedules (id, route_id, departure_local_time, bus_id, fare_points, is_active)
  VALUES
    -- Outbound schedules
    ('33333333-3333-3333-3333-333333330800'::uuid, v_route_outbound_id, '08:00:00'::time, v_bus_1_id, 50, true),
    ('33333333-3333-3333-3333-333333330900'::uuid, v_route_outbound_id, '09:00:00'::time, v_bus_2_id, 50, true),
    ('33333333-3333-3333-3333-333333331000'::uuid, v_route_outbound_id, '10:00:00'::time, v_bus_3_id, 50, true),
    ('33333333-3333-3333-3333-333333331100'::uuid, v_route_outbound_id, '11:00:00'::time, v_bus_1_id, 50, true),
    -- Return schedules
    ('33333333-3333-3333-3333-333333331300'::uuid, v_route_return_id,   '13:00:00'::time, v_bus_2_id, 50, true),
    ('33333333-3333-3333-3333-333333331400'::uuid, v_route_return_id,   '14:00:00'::time, v_bus_3_id, 50, true),
    ('33333333-3333-3333-3333-333333331500'::uuid, v_route_return_id,   '15:00:00'::time, v_bus_1_id, 50, true),
    ('33333333-3333-3333-3333-333333331600'::uuid, v_route_return_id,   '16:00:00'::time, v_bus_2_id, 50, true)
  ON CONFLICT (id) DO NOTHING;

  -- 8.5 Generate Trips for the next 7 days based on schedules
  FOR v_day_offset IN 0..7 LOOP
    v_curr_date := (CURRENT_DATE AT TIME ZONE 'Africa/Cairo')::date + v_day_offset;

    FOR v_schedule_record IN SELECT * FROM public.trip_schedules WHERE is_active = true LOOP
      -- Calculate timestamp in Cairo timezone
      v_dep_cairo := (v_curr_date || ' ' || v_schedule_record.departure_local_time)::timestamp AT TIME ZONE 'Africa/Cairo';

      INSERT INTO public.trips (
        schedule_id,
        route_id,
        service_date,
        departure_at,
        bus_id,
        fare_points,
        status,
        booking_open_at,
        booking_close_at
      ) VALUES (
        v_schedule_record.id,
        v_schedule_record.route_id,
        v_curr_date,
        v_dep_cairo,
        v_schedule_record.bus_id,
        v_schedule_record.fare_points,
        'scheduled',
        now() - interval '1 day',
        v_dep_cairo -- booking closes at departure
      )
      ON CONFLICT (schedule_id, service_date) DO UPDATE
        SET departure_at = EXCLUDED.departure_at,
            booking_close_at = EXCLUDED.booking_close_at;
    END LOOP;
  END LOOP;

END $$;
