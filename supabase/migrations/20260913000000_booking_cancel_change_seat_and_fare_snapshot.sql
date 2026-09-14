-- =============================================================================
-- AMOMY BUS - BOOKING CANCELLATION, SEAT-CHANGE & FARE SNAPSHOT ARCHITECTURE
-- Migration: 20260913000000_booking_cancel_change_seat_and_fare_snapshot.sql
-- =============================================================================

-- 1. CANCEL PASSENGER BOOKING (With exact batch point refund)
CREATE OR REPLACE FUNCTION public.cancel_passenger_booking(
  p_booking_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_booking RECORD;
  v_trip RECORD;
  v_wallet RECORD;
  v_tx RECORD;
  v_total_refund numeric := 0;
BEGIN
  -- 1. Auth check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Lock and validate booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF v_booking.user_id != v_user_id AND NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  IF v_booking.status = 'cancelled' THEN
    -- Idempotent return
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', p_booking_id,
      'status', 'cancelled',
      'refund_points', 0,
      'already_cancelled', true
    );
  END IF;

  IF v_booking.status != 'confirmed' THEN
    RAISE EXCEPTION 'BOOKING_NOT_CANCELLABLE';
  END IF;

  -- 3. Lock trip and check 30-minute cutoff (departure_at - 30 minutes)
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = v_booking.trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.departure_at - interval '30 minutes' < v_now THEN
    RAISE EXCEPTION 'CANCELLATION_WINDOW_CLOSED';
  END IF;

  -- 4. Mark booking as cancelled
  UPDATE public.bookings
  SET status = 'cancelled',
      cancelled_at = now()
  WHERE id = v_booking.id;

  -- 5. Lock user wallet
  SELECT * INTO v_wallet
  FROM public.wallets
  WHERE user_id = v_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND';
  END IF;

  -- 6. Refund points back to the original point_batches using point_transactions history
  FOR v_tx IN
    SELECT pt.batch_id, pt.amount, pb.source_type
    FROM public.point_transactions pt
    JOIN public.point_batches pb ON pb.id = pt.batch_id
    WHERE pt.reference_type = 'booking'
      AND pt.reference_id = v_booking.id
      AND pt.transaction_type = 'debit'
  LOOP
    -- Increment remaining_amount in the exact original batch
    UPDATE public.point_batches
    SET remaining_amount = remaining_amount + v_tx.amount
    WHERE id = v_tx.batch_id;

    -- Record credit transaction reversal
    INSERT INTO public.point_transactions (
      wallet_id,
      user_id,
      batch_id,
      transaction_type,
      amount,
      balance_before,
      balance_after,
      reference_type,
      reference_id,
      description,
      actor_user_id,
      metadata,
      created_at
    ) VALUES (
      v_wallet.id,
      v_user_id,
      v_tx.batch_id,
      'credit',
      v_tx.amount,
      v_wallet.cached_available_balance + v_total_refund,
      v_wallet.cached_available_balance + v_total_refund + v_tx.amount,
      'booking_cancellation',
      v_booking.id,
      'Refund for cancelled booking of seat ' || COALESCE(v_booking.seat_number_snapshot, ''),
      v_user_id,
      jsonb_build_object(
        'booking_id', v_booking.id,
        'trip_id', v_trip.id,
        'seat_id', v_booking.seat_id,
        'refund_batch_id', v_tx.batch_id,
        'batch_source_type', v_tx.source_type
      ),
      now()
    );

    v_total_refund := v_total_refund + v_tx.amount;
  END LOOP;

  -- Fallback: If no debit tx records found (e.g. legacy seed booking), refund to latest active batch
  IF v_total_refund = 0 AND v_booking.fare_points > 0 THEN
    DECLARE
      v_fallback_batch RECORD;
    BEGIN
      SELECT id, source_type INTO v_fallback_batch
      FROM public.point_batches
      WHERE user_id = v_user_id
      ORDER BY created_at DESC
      LIMIT 1
      FOR UPDATE;

      IF FOUND THEN
        UPDATE public.point_batches
        SET remaining_amount = remaining_amount + v_booking.fare_points
        WHERE id = v_fallback_batch.id;

        INSERT INTO public.point_transactions (
          wallet_id,
          user_id,
          batch_id,
          transaction_type,
          amount,
          balance_before,
          balance_after,
          reference_type,
          reference_id,
          description,
          actor_user_id,
          metadata,
          created_at
        ) VALUES (
          v_wallet.id,
          v_user_id,
          v_fallback_batch.id,
          'credit',
          v_booking.fare_points,
          v_wallet.cached_available_balance,
          v_wallet.cached_available_balance + v_booking.fare_points,
          'booking_cancellation',
          v_booking.id,
          'Refund for cancelled booking',
          v_user_id,
          jsonb_build_object('booking_id', v_booking.id, 'fallback_batch', true),
          now()
        );

        v_total_refund := v_booking.fare_points;
      END IF;
    END;
  END IF;

  -- 7. Update wallet cached_available_balance atomically
  IF v_total_refund > 0 THEN
    UPDATE public.wallets
    SET cached_available_balance = cached_available_balance + v_total_refund,
        updated_at = now()
    WHERE id = v_wallet.id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking.id,
    'status', 'cancelled',
    'refund_points', v_total_refund
  );
END;
$function$;

-- 2. CHANGE BOOKING SEAT (Atomic seat swap within 30-minute cutoff)
CREATE OR REPLACE FUNCTION public.change_booking_seat(
  p_booking_id uuid,
  p_new_seat_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_now timestamptz := public.get_effective_booking_now();
  v_booking RECORD;
  v_trip RECORD;
  v_new_seat RECORD;
BEGIN
  -- 1. Auth check
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  -- 2. Lock and validate booking
  SELECT * INTO v_booking
  FROM public.bookings
  WHERE id = p_booking_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOOKING_NOT_FOUND';
  END IF;

  IF v_booking.user_id != v_user_id AND NOT app_private.is_admin() THEN
    RAISE EXCEPTION 'PERMISSION_DENIED';
  END IF;

  IF v_booking.status != 'confirmed' THEN
    RAISE EXCEPTION 'BOOKING_NOT_EDITABLE';
  END IF;

  -- 3. If new seat is identical to current seat, no-op return
  IF v_booking.seat_id = p_new_seat_id THEN
    RETURN jsonb_build_object(
      'success', true,
      'booking_id', v_booking.id,
      'seat_id', v_booking.seat_id,
      'seat_number', v_booking.seat_number_snapshot,
      'message', 'SEAT_UNCHANGED'
    );
  END IF;

  -- 4. Lock trip and check 30-minute cutoff
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = v_booking.trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'TRIP_NOT_FOUND';
  END IF;

  IF v_trip.departure_at - interval '30 minutes' < v_now THEN
    RAISE EXCEPTION 'CHANGE_SEAT_WINDOW_CLOSED';
  END IF;

  -- 5. Lock and validate new seat on same bus
  SELECT * INTO v_new_seat
  FROM public.bus_seats
  WHERE id = p_new_seat_id
    AND bus_id = v_trip.bus_id
    AND is_active = true
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SEAT_INVALID';
  END IF;

  -- 6. Check if new seat is booked by another active booking on this trip
  IF EXISTS (
    SELECT 1 FROM public.bookings
    WHERE trip_id = v_trip.id
      AND seat_id = p_new_seat_id
      AND status = 'confirmed'
      AND id != v_booking.id
  ) THEN
    RAISE EXCEPTION 'SEAT_ALREADY_BOOKED';
  END IF;

  -- 7. Canonically expire any stale holds on new seat
  DECLARE
    v_stale RECORD;
  BEGIN
    FOR v_stale IN
      SELECT id FROM public.seat_holds
      WHERE trip_id = v_trip.id
        AND seat_id = p_new_seat_id
        AND status = 'active'
        AND expires_at <= now()
    LOOP
      PERFORM app_private._release_booking_hold_internal(v_stale.id, 'expired');
    END LOOP;
  END;

  -- 8. Check if new seat is held by another user
  IF EXISTS (
    SELECT 1 FROM public.seat_holds
    WHERE trip_id = v_trip.id
      AND seat_id = p_new_seat_id
      AND status = 'active'
      AND expires_at > now()
      AND user_id != v_user_id
  ) THEN
    RAISE EXCEPTION 'SEAT_HELD_BY_ANOTHER_USER';
  END IF;

  -- 9. Atomically swap seat on booking row
  UPDATE public.bookings
  SET seat_id = v_new_seat.id,
      seat_number_snapshot = v_new_seat.seat_number
  WHERE id = v_booking.id;

  RETURN jsonb_build_object(
    'success', true,
    'booking_id', v_booking.id,
    'old_seat_number', v_booking.seat_number_snapshot,
    'new_seat_id', v_new_seat.id,
    'new_seat_number', v_new_seat.seat_number
  );
END;
$function$;

-- 3. ENHANCED get_passenger_bookings (Includes passenger's actual booked route stops)
CREATE OR REPLACE FUNCTION public.get_passenger_bookings()
RETURNS TABLE(
  booking_id uuid,
  trip_id uuid,
  direction text,
  origin_name_ar text,
  origin_name_en text,
  destination_name_ar text,
  destination_name_en text,
  service_date date,
  departure_time text,
  departure_at timestamp with time zone,
  seat_number text,
  fare_points numeric,
  status text,
  qr_token text,
  booked_at timestamp with time zone
)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public', 'app_private'
AS $function$
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
    COALESCE(NULLIF(s_orig.name_ar, ''), r.origin_name_ar) AS origin_name_ar,
    COALESCE(NULLIF(s_orig.name_en, ''), NULLIF(r.origin_name_en, ''), r.origin_name_ar) AS origin_name_en,
    COALESCE(NULLIF(s_dest.name_ar, ''), r.destination_name_ar) AS destination_name_ar,
    COALESCE(NULLIF(s_dest.name_en, ''), NULLIF(r.destination_name_en, ''), r.destination_name_ar) AS destination_name_en,
    t.service_date,
    to_char(t.departure_at AT TIME ZONE 'Africa/Cairo', 'HH24:MI') AS departure_time,
    t.departure_at,
    COALESCE(bkg.seat_number_snapshot, bs.seat_number) AS seat_number,
    bkg.fare_points,
    bkg.status::text AS status,
    bkg.qr_token,
    bkg.booked_at
  FROM public.bookings bkg
  JOIN public.trips t ON t.id = bkg.trip_id
  JOIN public.routes r ON r.id = t.route_id
  JOIN public.bus_seats bs ON bs.id = bkg.seat_id
  LEFT JOIN public.route_stops rs_orig ON rs_orig.id = bkg.route_stop_id
  LEFT JOIN public.stops s_orig ON s_orig.id = rs_orig.stop_id
  LEFT JOIN public.route_stops rs_dest ON rs_dest.id = bkg.destination_route_stop_id
  LEFT JOIN public.stops s_dest ON s_dest.id = rs_dest.stop_id
  WHERE bkg.user_id = v_user_id
  ORDER BY t.departure_at DESC;
END;
$function$;

-- 4. PERMISSIONS
REVOKE EXECUTE ON FUNCTION public.cancel_passenger_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.cancel_passenger_booking(uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.change_booking_seat(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.change_booking_seat(uuid, uuid) TO authenticated;

REVOKE EXECUTE ON FUNCTION public.get_passenger_bookings() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_passenger_bookings() TO authenticated;
