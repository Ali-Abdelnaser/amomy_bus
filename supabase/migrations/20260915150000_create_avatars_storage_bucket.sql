-- =============================================================================
-- Migration: 20260915150000_create_avatars_storage_bucket.sql
-- Description: Create public avatars storage bucket with user-isolated RLS policies.
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  2097152, -- 2 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- Storage RLS: Anyone can view avatars (public read for profile pictures)
DO $$ BEGIN
  CREATE POLICY "avatars_public_view" ON storage.objects
    FOR SELECT USING (
      bucket_id = 'avatars'
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Storage RLS: Authenticated user can upload only to their own directory: avatars/{auth.uid()}/*
DO $$ BEGIN
  CREATE POLICY "avatars_user_upload" ON storage.objects
    FOR INSERT WITH CHECK (
      bucket_id = 'avatars' AND
      auth.uid() IS NOT NULL AND
      (storage.foldername(name))[1] = (auth.uid())::text
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Storage RLS: Authenticated user can update only their own directory: avatars/{auth.uid()}/*
DO $$ BEGIN
  CREATE POLICY "avatars_user_update" ON storage.objects
    FOR UPDATE USING (
      bucket_id = 'avatars' AND
      auth.uid() IS NOT NULL AND
      (storage.foldername(name))[1] = (auth.uid())::text
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- Storage RLS: Authenticated user can delete only their own directory: avatars/{auth.uid()}/*
DO $$ BEGIN
  CREATE POLICY "avatars_user_delete" ON storage.objects
    FOR DELETE USING (
      bucket_id = 'avatars' AND
      auth.uid() IS NOT NULL AND
      (storage.foldername(name))[1] = (auth.uid())::text
    );
EXCEPTION WHEN duplicate_object THEN null;
END $$;
