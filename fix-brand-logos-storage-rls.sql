-- Fix RLS policies for brand_logos storage bucket
-- This allows authenticated users to upload and read logo files

-- First, check if storage policies exist (we can't directly query, but we can create/update)
-- Note: Storage bucket policies must be set via Supabase Dashboard or Storage API

-- Storage bucket RLS policies need to be set in Supabase Dashboard:
-- 1. Go to Storage → brand_logos bucket → Policies
-- 2. Add these policies:

-- Policy 1: Allow authenticated users to upload files
-- Name: "Authenticated users can upload brand logos"
-- Policy: INSERT
-- Target roles: authenticated
-- USING expression: bucket_id = 'brand_logos' AND auth.role() = 'authenticated'
-- WITH CHECK expression: bucket_id = 'brand_logos' AND auth.role() = 'authenticated'

-- Policy 2: Allow public read access (since bucket is public)
-- Name: "Public can read brand logos"
-- Policy: SELECT
-- Target roles: public (or anon)
-- USING expression: bucket_id = 'brand_logos'

-- Policy 3: Allow authenticated users to delete their own uploads (optional)
-- Name: "Authenticated users can delete brand logos"
-- Policy: DELETE
-- Target roles: authenticated
-- USING expression: bucket_id = 'brand_logos' AND auth.role() = 'authenticated'

-- Since we can't create storage policies via SQL, here's a manual process:

/*
MANUAL SETUP INSTRUCTIONS:

1. Go to Supabase Dashboard → Storage
2. Click on the "brand_logos" bucket
3. Click on "Policies" tab
4. Click "New Policy"
5. Use "For full customization" option

Policy 1: Allow Uploads
- Name: Allow authenticated uploads
- Allowed operation: INSERT
- Policy definition (Paste this):
  (
    bucket_id = 'brand_logos'::text
  )
- With check expression: Same as above

Policy 2: Allow Public Reads (if bucket is public, this may already be enabled)
- Name: Allow public reads  
- Allowed operation: SELECT
- Policy definition:
  (
    bucket_id = 'brand_logos'::text
  )

Policy 3: Allow Updates (for replacing existing logos)
- Name: Allow authenticated updates
- Allowed operation: UPDATE
- Policy definition:
  (
    bucket_id = 'brand_logos'::text
  )

Policy 4: Allow Deletes (optional, for cleanup)
- Name: Allow authenticated deletes
- Allowed operation: DELETE
- Policy definition:
  (
    bucket_id = 'brand_logos'::text
  )
*/

-- Alternative: Use Supabase Dashboard UI
-- Storage → brand_logos → Policies → New Policy
-- Select "For full customization"
-- Copy the expressions above


