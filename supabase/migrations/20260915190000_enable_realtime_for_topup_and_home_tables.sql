-- Migration: 20260915190000_enable_realtime_for_topup_and_home_tables.sql
-- Description: Ensure public.topup_requests, public.wallets, and public.bus_live_locations
--              are safely and idempotently enrolled in the 'supabase_realtime' publication
--              with FULL replica identity so Supabase stream filters operate without errors.

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    -- 1. public.topup_requests
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'topup_requests'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.topup_requests;
    END IF;

    -- 2. public.wallets
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'wallets'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.wallets;
    END IF;

    -- 3. public.bus_live_locations
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'bus_live_locations'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.bus_live_locations;
    END IF;
  END IF;
END $$;

-- Set replica identity to full to ensure downstream change streams carry row states
DO $$
BEGIN
  ALTER TABLE public.topup_requests REPLICA IDENTITY FULL;
  ALTER TABLE public.wallets REPLICA IDENTITY FULL;
  ALTER TABLE public.bus_live_locations REPLICA IDENTITY FULL;
EXCEPTION
  WHEN undefined_table THEN
    NULL;
END $$;

