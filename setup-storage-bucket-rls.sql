-- ========================================
-- Storage Bucket Setup and RLS Policies
-- Run this in Supabase SQL Editor
-- ========================================
-- Note: Bucket must be created via Dashboard first
-- Go to: Storage > Create Bucket > Name: job_submissions > Public: Yes

-- ========================================
-- STEP 1: Verify bucket exists
-- ========================================
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'job_submissions')
        THEN '✅ Bucket exists'
        ELSE '⚠️ Bucket does not exist - create it in Dashboard first'
    END as bucket_status;

-- ========================================
-- STEP 2: RLS Policies for Storage
-- ========================================
-- Note: DROP IF EXISTS first to avoid errors if policy already exists

-- Policy 1: Contractors can upload to their own submissions
DROP POLICY IF EXISTS "Contractors can upload job submission photos" ON storage.objects;
CREATE POLICY "Contractors can upload job submission photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'job_submissions' AND
    auth.uid() IN (
        SELECT contractor_id 
        FROM job_submissions 
        WHERE id::text = (storage.foldername(name))[1]
    )
);

-- Alternative simpler policy (allows any authenticated user to upload)
-- Uncomment if the above policy is too restrictive:
/*
DROP POLICY IF EXISTS "Authenticated users can upload job submission photos" ON storage.objects;
CREATE POLICY "Authenticated users can upload job submission photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'job_submissions');
*/

-- Policy 2: Admins can read all job submission photos
DROP POLICY IF EXISTS "Admins can read job submission photos" ON storage.objects;
CREATE POLICY "Admins can read job submission photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'job_submissions' AND
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
    )
);

-- Policy 3: Contractors can read their own submission photos
DROP POLICY IF EXISTS "Contractors can read own job submission photos" ON storage.objects;
CREATE POLICY "Contractors can read own job submission photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'job_submissions' AND
    auth.uid() IN (
        SELECT contractor_id 
        FROM job_submissions 
        WHERE id::text = (storage.foldername(name))[1]
    )
);

-- ========================================
-- STEP 3: Verify policies were created
-- ========================================
SELECT 
    policyname,
    cmd as operation,
    schemaname || '.' || tablename as table_name
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
  AND policyname LIKE '%job_submission%'
ORDER BY policyname;

-- ========================================
-- STEP 4: Verify review_outcome column exists
-- ========================================
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'job_submissions' 
  AND column_name = 'review_outcome';

-- If column doesn't exist, run this:
/*
ALTER TABLE job_submissions
ADD COLUMN IF NOT EXISTS review_outcome text
CHECK (review_outcome IN ('approved','rejected','superseded') OR review_outcome IS NULL);
*/

-- ========================================
-- SUMMARY
-- ========================================
SELECT 
    'Setup Complete' as status,
    'Check results above to verify bucket and policies' as note;

