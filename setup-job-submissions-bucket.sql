-- ========================================
-- SETUP: job_submissions Storage Bucket
-- ========================================
-- This bucket stores photos uploaded by shelfers when completing jobs
-- 
-- IMPORTANT: Storage buckets cannot be created via SQL!
-- You must create the bucket manually in Supabase Dashboard first.
--
-- After creating the bucket, run the RLS policies below.
-- ========================================

-- ========================================
-- STEP 1: Create Bucket in Supabase Dashboard
-- ========================================
-- 1. Go to Supabase Dashboard → Storage → Buckets
-- 2. Click "New bucket"
-- 3. Name: job_submissions
-- 4. Public: YES (so photos can be accessed)
-- 5. File size limit: 10MB (default is fine, but you can increase if needed)
-- 6. Allowed MIME types: image/* (or leave empty to allow all)
-- 7. Click "Create bucket"
-- ========================================

-- ========================================
-- STEP 2: Storage Bucket RLS Policies
-- ========================================
-- Run these AFTER creating the bucket in the dashboard
-- ========================================

-- Policy 1: Allow shelfers (contractors) to upload photos
CREATE POLICY IF NOT EXISTS "Contractors can upload job photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'shelfer'
  )
);

-- Policy 2: Allow users to read photos they uploaded
CREATE POLICY IF NOT EXISTS "Users can read their uploads"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'job_submissions' AND
  (
    -- Users can read files they uploaded (check owner)
    owner = auth.uid()
    OR
    -- Or if the file path matches a job they submitted
    EXISTS (
      SELECT 1 FROM job_submissions js
      WHERE js.contractor_id = auth.uid()
      AND (storage.objects.name)::text LIKE '%' || js.job_id::text || '%'
    )
  )
);

-- Policy 3: Allow admins to read all job photos
CREATE POLICY IF NOT EXISTS "Admins can read all job photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
);

-- Policy 4: Allow brand clients to read photos from their jobs
CREATE POLICY IF NOT EXISTS "Brand clients can read their job photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM jobs j
    INNER JOIN job_submissions js ON js.job_id = j.id
    WHERE j.client_id = auth.uid()
    AND (storage.objects.name)::text LIKE '%' || js.job_id::text || '%'
  )
);

-- Policy 5: Allow users to update/delete their own uploads (for corrections)
CREATE POLICY IF NOT EXISTS "Users can update their uploads"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'job_submissions' AND
  owner = auth.uid()
)
WITH CHECK (
  bucket_id = 'job_submissions' AND
  owner = auth.uid()
);

CREATE POLICY IF NOT EXISTS "Users can delete their uploads"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'job_submissions' AND
  owner = auth.uid()
);

-- ========================================
-- STEP 3: Verify Setup
-- ========================================
-- Check if bucket exists (must be done manually in dashboard)
-- Check policies were created:
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'objects'
AND schemaname = 'storage'
AND policyname LIKE '%job_submissions%'
ORDER BY policyname;

-- ========================================
-- NOTES:
-- ========================================
-- - Photos are stored at: job_submissions/jobs/{job_id}/{filename}
-- - File naming: {photo_type}_{timestamp}.{extension}
-- - Photo types: product_closeup, section_context, wide_angle
-- - If bucket doesn't exist, code falls back to base64 storage (not ideal)
-- ========================================


