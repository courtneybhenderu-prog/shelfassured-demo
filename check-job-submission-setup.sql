-- Diagnostic script to check job submission setup
-- Run this in Supabase SQL editor to troubleshoot job submission issues

-- 1. Check if job_submissions table exists
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_submissions' AND table_schema = 'public')
        THEN '✅ job_submissions table exists'
        ELSE '❌ job_submissions table MISSING - needs to be created'
    END as table_status;

-- 2. Check job_submissions table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_submissions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check if job_submissions bucket exists in storage
-- Note: This requires checking Storage directly in Supabase Dashboard
-- Go to Storage → Buckets and look for 'job_submissions'

-- 4. Check RLS policies on job_submissions table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'job_submissions'
AND schemaname = 'public';

-- 5. Check for recent job submissions
SELECT 
    id,
    job_id,
    contractor_id,
    submission_type,
    created_at,
    CASE 
        WHEN files::text LIKE '%error%' THEN '⚠️ Has errors'
        WHEN files::text LIKE '%file_data%' THEN '⚠️ Using base64 fallback (bucket issue)'
        ELSE '✅ Normal'
    END as file_status
FROM job_submissions
ORDER BY created_at DESC
LIMIT 10;

-- 6. Check jobs that should be pending_review but aren't
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as last_submission
FROM jobs j
LEFT JOIN job_submissions js ON js.job_id = j.id
WHERE js.id IS NOT NULL
GROUP BY j.id, j.title, j.status
HAVING j.status != 'pending_review'
ORDER BY last_submission DESC
LIMIT 10;


