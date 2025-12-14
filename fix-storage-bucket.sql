-- ========================================
-- Storage Bucket Creation (if needed)
-- ========================================
-- Note: Bucket creation via SQL may require special permissions
-- If this doesn't work, use Supabase Dashboard > Storage > Create Bucket

-- Check if bucket exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'job_submissions')
        THEN '✅ Bucket already exists'
        ELSE '⚠️ Bucket does not exist - needs to be created via Dashboard'
    END as bucket_status;

-- If bucket doesn't exist, try to create it (may require service_role key)
-- Uncomment and run if you have the necessary permissions:
/*
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'job_submissions',
    'job_submissions',
    true,  -- Public bucket (admins need to view photos)
    5242880,  -- 5MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;
*/

-- ========================================
-- Verify review_outcome column
-- ========================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'job_submissions' 
  AND column_name = 'review_outcome';

-- If column doesn't exist, create it:
/*
ALTER TABLE job_submissions
ADD COLUMN IF NOT EXISTS review_outcome text
CHECK (review_outcome IN ('approved','rejected','superseded') OR review_outcome IS NULL);
*/


