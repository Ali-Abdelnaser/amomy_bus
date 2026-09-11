-- =============================================================================
-- Migration: 20260911190000_staff_checkin_and_attendance.sql
-- Description: Staff Check-in System, Attendance Logging, NFC Foundation,
--              Role Enforcement, and Staff Operation RPCs.
-- =============================================================================

-- 1. Helper function to verify staff or administrative role in app_private
CREATE OR REPLACE FUNCTION app_private.is_staff_or_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
BEGIN
  RETURN (
    app_private.has_role((select auth.uid()), 'staff') OR
    app_private.has_role((select auth.uid()), 'admin') OR
    app_private.has_role((select auth.uid()), 'super_admin')
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION app_private.is_staff_or_admin() TO authenticated, service_role, postgres;

-- 2. Create booking_checkins table for attendance audit
CREATE TABLE IF NOT EXISTS public.booking_checkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE RESTRICT,
  staff_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  method text NOT NULL CHECK (method IN ('qr', 'nfc')),
  checked_in_at timestamptz NOT NULL DEFAULT now(),
  device_metadata jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Index for staff activity lookup and trip analysis
CREATE INDEX IF NOT EXISTS idx_booking_checkins_staff_user ON public.booking_checkins(staff_user_id, checked_in_at DESC);
CREATE INDEX IF NOT EXISTS idx_booking_checkins_booking_id ON public.booking_checkins(booking_id);

-- 3. Create nfc_cards table for physical card credentials
CREATE TABLE IF NOT EXISTS public.nfc_cards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  last4 text NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'revoked')),
  issued_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_nfc_cards_user_id ON public.nfc_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_nfc_cards_token_hash ON public.nfc_cards(token_hash) WHERE status = 'active';

-- Enable RLS on both tables
ALTER TABLE public.booking_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.nfc_cards ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- booking_checkins: Staff/Admins can view and create via RPC. Direct insert is restricted.
CREATE POLICY "booking_checkins_select_staff_or_admin" ON public.booking_checkins
  FOR SELECT TO authenticated
  USING (app_private.is_staff_or_admin());

-- nfc_cards: Passenger cannot read card token hashes. Only Admin can manage. Staff reads via secure RPC.
CREATE POLICY "nfc_cards_admin_all" ON public.nfc_cards
  FOR ALL TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.booking_checkins FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON public.nfc_cards FROM anon, authenticated;

-- =============================================================================
-- 4. STAFF RPCS
-- =============================================================================

-- 4.1 staff_lookup_booking_by_qr
CREATE OR REPLACE FUNCTION public.staff_lookup_booking_by_qr(
  p_qr_token text,
  p_expected_trip_id uuid DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_staff_id uuid;
  v_booking record;
  v_trip record;
  v_passenger record;
  v_seat record;
  v_route record;
  v_validation_code text;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  IF p_qr_token IS NULL OR trim(p_qr_token) = '' THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'QR token cannot be empty'
    );
  END IF;

  -- 1. Find booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE qr_token = trim(p_qr_token);

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'No booking found matching this QR code'
    );
  END IF;

  -- 2. Fetch Trip & Route
  SELECT t.*, r.origin_name_ar, r.origin_name_en, r.destination_name_ar, r.destination_name_en
  INTO v_trip
  FROM public.trips t
  JOIN public.routes r ON t.route_id = r.id
  WHERE t.id = v_booking.trip_id;

  -- 3. Fetch Passenger Profile (Operational fields only)
  SELECT id, full_name, avatar_url, gender
  INTO v_passenger
  FROM public.profiles
  WHERE id = v_booking.user_id;

  -- 4. Fetch Seat
  SELECT seat_number
  INTO v_seat
  FROM public.bus_seats
  WHERE id = v_booking.seat_id;

  -- 5. Determine Validation Code
  IF v_booking.status = 'cancelled' THEN
    v_validation_code := 'CANCELLED_BOOKING';
  ELSIF v_booking.checked_in_at IS NOT NULL THEN
    v_validation_code := 'ALREADY_CHECKED_IN';
  ELSIF p_expected_trip_id IS NOT NULL AND v_booking.trip_id != p_expected_trip_id THEN
    v_validation_code := 'WRONG_TRIP';
  ELSIF v_trip.status = 'completed' THEN
    v_validation_code := 'TRIP_COMPLETED';
  ELSIF v_trip.status = 'cancelled' THEN
    v_validation_code := 'CANCELLED_BOOKING';
  ELSIF v_trip.departure_at > (now() + interval '2 hours') THEN
    v_validation_code := 'TOO_EARLY';
  ELSE
    v_validation_code := 'VALID';
  END IF;

  RETURN jsonb_build_object(
    'validation_code', v_validation_code,
    'booking_id', v_booking.id,
    'passenger_id', v_passenger.id,
    'passenger_display_name', v_passenger.full_name,
    'passenger_avatar_url', v_passenger.avatar_url,
    'gender', v_passenger.gender,
    'seat_number', v_seat.seat_number,
    'trip_id', v_trip.id,
    'route_origin_ar', v_trip.origin_name_ar,
    'route_origin_en', v_trip.origin_name_en,
    'route_destination_ar', v_trip.destination_name_ar,
    'route_destination_en', v_trip.destination_name_en,
    'departure_at', v_trip.departure_at,
    'service_date', v_trip.service_date,
    'trip_status', v_trip.status,
    'booking_status', v_booking.status,
    'checked_in_at', v_booking.checked_in_at
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.staff_lookup_booking_by_qr(text, uuid) TO authenticated;

-- 4.2 staff_confirm_attendance
CREATE OR REPLACE FUNCTION public.staff_confirm_attendance(
  p_booking_id uuid,
  p_method text,
  p_device_metadata jsonb DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_staff_id uuid;
  v_staff_role text;
  v_booking record;
  v_checkin_id uuid;
  v_checked_in_at timestamptz;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  IF p_method NOT IN ('qr', 'nfc') THEN
    RAISE EXCEPTION 'INVALID_CHECKIN_METHOD';
  END IF;

  -- Lock booking row for atomic update
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    RAISE EXCEPTION 'BOOKING_IS_CANCELLED';
  END IF;

  -- Check if already checked in
  IF v_booking.checked_in_at IS NOT NULL THEN
    -- Return idempotent ALREADY_CHECKED_IN state safely
    RETURN jsonb_build_object(
      'success', false,
      'code', 'ALREADY_CHECKED_IN',
      'booking_id', v_booking.id,
      'checked_in_at', v_booking.checked_in_at,
      'message', 'Passenger has already checked in.'
    );
  END IF;

  v_checked_in_at := now();

  -- 1. Insert checkin record
  INSERT INTO public.booking_checkins (
    booking_id,
    staff_user_id,
    method,
    checked_in_at,
    device_metadata
  ) VALUES (
    v_booking.id,
    v_staff_id,
    p_method,
    v_checked_in_at,
    p_device_metadata
  )
  RETURNING id INTO v_checkin_id;

  -- 2. Update booking checked_in_at
  UPDATE public.bookings
  SET checked_in_at = v_checked_in_at
  WHERE id = v_booking.id;

  -- Determine staff actor role
  IF app_private.has_role(v_staff_id, 'super_admin') THEN
    v_staff_role := 'super_admin';
  ELSIF app_private.has_role(v_staff_id, 'admin') THEN
    v_staff_role := 'admin';
  ELSE
    v_staff_role := 'staff';
  END IF;

  -- 3. Write immutable audit log
  INSERT INTO public.audit_logs (
    actor_user_id,
    actor_role,
    action,
    target_type,
    target_id,
    before_data,
    after_data,
    metadata
  ) VALUES (
    v_staff_id,
    v_staff_role,
    'PASSENGER_CHECKED_IN',
    'bookings',
    v_booking.id,
    jsonb_build_object('checked_in_at', null),
    jsonb_build_object('checked_in_at', v_checked_in_at, 'method', p_method),
    jsonb_build_object(
      'checkin_id', v_checkin_id,
      'trip_id', v_booking.trip_id,
      'passenger_id', v_booking.user_id,
      'method', p_method
    )
  );

  RETURN jsonb_build_object(
    'success', true,
    'code', 'SUCCESS',
    'booking_id', v_booking.id,
    'checkin_id', v_checkin_id,
    'checked_in_at', v_checked_in_at,
    'method', p_method
  );
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.staff_confirm_attendance(uuid, text, jsonb) TO authenticated;

-- 4.3 staff_lookup_by_nfc
CREATE OR REPLACE FUNCTION public.staff_lookup_by_nfc(
  p_token text,
  p_expected_trip_id uuid DEFAULT NULL
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
AS $$
DECLARE
  v_staff_id uuid;
  v_hash text;
  v_card record;
  v_booking record;
  v_qr_result jsonb;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  IF p_token IS NULL OR trim(p_token) = '' THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'NFC token is empty'
    );
  END IF;

  -- Token hash using sha256
  v_hash := encode(digest(trim(p_token), 'sha256'), 'hex');

  -- Find card
  SELECT * INTO v_card
  FROM public.nfc_cards
  WHERE token_hash = v_hash;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'validation_code', 'INVALID_TOKEN',
      'error_message', 'Unregistered or unrecognized NFC card'
    );
  END IF;

  IF v_card.status = 'revoked' THEN
    RETURN jsonb_build_object(
      'validation_code', 'CANCELLED_BOOKING',
      'error_message', 'NFC card has been revoked'
    );
  END IF;

  -- Find relevant confirmed booking for today / trip
  IF p_expected_trip_id IS NOT NULL THEN
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE user_id = v_card.user_id
      AND trip_id = p_expected_trip_id
      AND status = 'confirmed'
    ORDER BY created_at DESC
    LIMIT 1;
  ELSE
    SELECT b.* INTO v_booking
    FROM public.bookings b
    JOIN public.trips t ON b.trip_id = t.id
    WHERE b.user_id = v_card.user_id
      AND b.status = 'confirmed'
      AND t.service_date = CURRENT_DATE
    ORDER BY t.departure_at ASC
    LIMIT 1;
  END IF;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'validation_code', 'WRONG_TRIP',
      'error_message', 'No active booking found for this passenger today'
    );
  END IF;

  -- Re-use QR lookup function with booking qr_token
  RETURN public.staff_lookup_booking_by_qr(v_booking.qr_token, p_expected_trip_id);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.staff_lookup_by_nfc(text, uuid) TO authenticated;

-- 4.4 staff_get_today_trips
CREATE OR REPLACE FUNCTION public.staff_get_today_trips()
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_staff_id uuid;
  v_result jsonb;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'trip_id', t.id,
      'service_date', t.service_date,
      'departure_at', t.departure_at,
      'status', t.status,
      'origin_name_ar', r.origin_name_ar,
      'origin_name_en', r.origin_name_en,
      'destination_name_ar', r.destination_name_ar,
      'destination_name_en', r.destination_name_en,
      'booked_count', COALESCE(b_counts.booked_count, 0),
      'checked_in_count', COALESCE(b_counts.checked_in_count, 0),
      'total_capacity', 14
    ) ORDER BY t.departure_at ASC
  ) INTO v_result
  FROM public.trips t
  JOIN public.routes r ON t.route_id = r.id
  LEFT JOIN (
    SELECT
      trip_id,
      COUNT(id) FILTER (WHERE status = 'confirmed') as booked_count,
      COUNT(id) FILTER (WHERE status = 'confirmed' AND checked_in_at IS NOT NULL) as checked_in_count
    FROM public.bookings
    GROUP BY trip_id
  ) b_counts ON b_counts.trip_id = t.id
  WHERE t.service_date = CURRENT_DATE
    AND t.status != 'cancelled';

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.staff_get_today_trips() TO authenticated;

-- 4.5 staff_get_recent_activity
CREATE OR REPLACE FUNCTION public.staff_get_recent_activity(p_limit int DEFAULT 30)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, app_private
STABLE
AS $$
DECLARE
  v_staff_id uuid;
  v_result jsonb;
BEGIN
  v_staff_id := auth.uid();
  IF v_staff_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT app_private.is_staff_or_admin() THEN
    RAISE EXCEPTION 'FORBIDDEN_STAFF_ROLE_REQUIRED';
  END IF;

  SELECT jsonb_agg(
    jsonb_build_object(
      'checkin_id', c.id,
      'checked_in_at', c.checked_in_at,
      'method', c.method,
      'booking_id', b.id,
      'passenger_display_name', p.full_name,
      'passenger_avatar_url', p.avatar_url,
      'seat_number', bs.seat_number,
      'trip_id', t.id,
      'origin_name_ar', r.origin_name_ar,
      'origin_name_en', r.origin_name_en,
      'destination_name_ar', r.destination_name_ar,
      'destination_name_en', r.destination_name_en,
      'departure_at', t.departure_at
    ) ORDER BY c.checked_in_at DESC
  ) INTO v_result
  FROM (
    SELECT *
    FROM public.booking_checkins
    WHERE staff_user_id = v_staff_id
    ORDER BY checked_in_at DESC
    LIMIT LEAST(p_limit, 100)
  ) c
  JOIN public.bookings b ON c.booking_id = b.id
  JOIN public.profiles p ON b.user_id = p.id
  JOIN public.trips t ON b.trip_id = t.id
  JOIN public.routes r ON t.route_id = r.id
  JOIN public.bus_seats bs ON b.seat_id = bs.id;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.staff_get_recent_activity(int) TO authenticated;
