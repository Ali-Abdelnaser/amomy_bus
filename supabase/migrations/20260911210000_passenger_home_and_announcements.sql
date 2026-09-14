-- Migration: 20260911210000_passenger_home_and_announcements.sql
-- Description: Creates announcements table, active announcements RPC, and passenger home summary RPC with strict RLS and role security.

-- 1. Create announcements table
CREATE TABLE IF NOT EXISTS public.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title_ar text NOT NULL,
  title_en text,
  description_ar text NOT NULL,
  description_en text,
  type text NOT NULL DEFAULT 'announcement' CHECK (type IN ('announcement', 'offer')),
  is_active boolean NOT NULL DEFAULT true,
  starts_at timestamptz,
  ends_at timestamptz,
  sort_order integer NOT NULL DEFAULT 0,
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Index for efficient active announcement filtering and ordering
CREATE INDEX IF NOT EXISTS idx_announcements_active_dates
  ON public.announcements (is_active, sort_order ASC, created_at DESC)
  WHERE is_active = true;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trg_announcements_updated_at ON public.announcements;
CREATE TRIGGER trg_announcements_updated_at
  BEFORE UPDATE ON public.announcements
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 2. Enable RLS on announcements
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "announcements_select_active" ON public.announcements;
DROP POLICY IF EXISTS "announcements_admin_all" ON public.announcements;

-- Select policy: authenticated users can read active announcements within valid timeframe
CREATE POLICY "announcements_select_active"
  ON public.announcements
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    AND (starts_at IS NULL OR starts_at <= now())
    AND (ends_at IS NULL OR ends_at >= now())
  );

-- Admin policy: Admin / Super Admin can manage all announcement records
CREATE POLICY "announcements_admin_all"
  ON public.announcements
  FOR ALL
  TO authenticated
  USING (app_private.is_admin())
  WITH CHECK (app_private.is_admin());

-- 3. Passenger RPC: get_active_announcements()
CREATE OR REPLACE FUNCTION public.get_active_announcements()
RETURNS TABLE (
  id uuid,
  title_ar text,
  title_en text,
  description_ar text,
  description_en text,
  type text,
  sort_order integer,
  starts_at timestamptz,
  ends_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT
    a.id,
    a.title_ar,
    a.title_en,
    a.description_ar,
    a.description_en,
    a.type,
    a.sort_order,
    a.starts_at,
    a.ends_at
  FROM public.announcements a
  WHERE a.is_active = true
    AND (a.starts_at IS NULL OR a.starts_at <= now())
    AND (a.ends_at IS NULL OR a.ends_at >= now())
  ORDER BY a.sort_order ASC, a.created_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_active_announcements() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_active_announcements() TO authenticated;

-- 4. Passenger RPC: get_passenger_home_summary()
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
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
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
    'qr_token', bkg.qr_token
  )
  INTO v_upcoming_trip
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.bus_seats bs ON bs.id = bkg.seat_id
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'confirmed'
    AND t.status IN ('scheduled', 'boarding')
    AND t.departure_at >= now()
  ORDER BY t.departure_at ASC
  LIMIT 1;

  -- 4. Activity metrics
  -- Current month start in Africa/Cairo timezone
  v_month_start := date_trunc('month', now() AT TIME ZONE 'Africa/Cairo') AT TIME ZONE 'Africa/Cairo';

  -- trips_this_month: count bookings for current calendar month excluding cancelled bookings
  SELECT COUNT(*)
  INTO v_trips_this_month
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  WHERE bkg.user_id = v_user_id
    AND bkg.status != 'cancelled'
    AND t.departure_at >= v_month_start;

  -- completed_trips: all-time bookings where status = completed
  SELECT COUNT(*)
  INTO v_completed_trips
  FROM public.bookings bkg
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'completed';

  -- points_spent_this_month: sum trip-booking debit transactions during current calendar month
  SELECT COALESCE(SUM(pt.amount), 0)
  INTO v_points_spent_this_month
  FROM public.point_transactions pt
  WHERE pt.user_id = v_user_id
    AND pt.transaction_type = 'debit'
    AND pt.created_at >= v_month_start
    AND (pt.reference_type IN ('bookings', 'trip_booking') OR pt.reference_type IS NULL);

  -- missed_trips: count bookings where status = no_show
  SELECT COUNT(*)
  INTO v_missed_trips
  FROM public.bookings bkg
  WHERE bkg.user_id = v_user_id
    AND bkg.status = 'no_show';

  v_activity := jsonb_build_object(
    'trips_this_month', v_trips_this_month,
    'completed_trips', v_completed_trips,
    'points_spent_this_month', v_points_spent_this_month,
    'missed_trips', v_missed_trips
  );

  RETURN jsonb_build_object(
    'profile', jsonb_build_object(
      'full_name', COALESCE(v_profile.full_name, ''),
      'avatar_url', v_profile.avatar_url
    ),
    'wallet', jsonb_build_object(
      'available_points', COALESCE(v_available_points, 0)
    ),
    'upcoming_trip', v_upcoming_trip,
    'activity', v_activity
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_passenger_home_summary() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_home_summary() TO authenticated;

-- 5. Dev / Test Seed Announcements (Harmless general passenger guidance)
INSERT INTO public.announcements (
  title_ar,
  title_en,
  description_ar,
  description_en,
  type,
  is_active,
  sort_order
) VALUES
(
  'تنبيه الرحلات',
  'Trip Alert',
  'تابع مواعيد رحلاتك من التطبيق قبل التحرك.',
  'Track your trip schedules from the app before departure.',
  'announcement',
  true,
  1
),
(
  'عروض عمومي',
  'Amomy Offers',
  'ترقب عروض ونقاط إضافية قريباً.',
  'Stay tuned for exclusive offers and bonus points soon.',
  'offer',
  true,
  2
);
