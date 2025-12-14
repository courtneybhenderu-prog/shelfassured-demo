-- Quick Database Checks - Run these one at a time
-- ========================================

-- 1. Check notifications table schema
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- 2. Check if storage bucket has objects
SELECT COUNT(*) as object_count
FROM storage.objects
WHERE bucket_id = 'job_submissions';

-- 3. Check if RPC functions exist
SELECT proname as function_name
FROM pg_proc
WHERE proname IN ('approve_submission', 'reject_submission');

-- 4. Check review_outcome column
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'job_submissions' 
  AND column_name = 'review_outcome';

-- 5. Quick status check
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'type')
        THEN '✅ New notifications schema'
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notifications' AND column_name = 'title')
        THEN '⚠️ Old notifications schema'
        ELSE '❌ No notifications table'
    END as notifications_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.objects WHERE bucket_id = 'job_submissions')
        THEN '✅ Storage bucket exists'
        ELSE '⚠️ Storage bucket missing or empty'
    END as storage_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_submission')
         AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'reject_submission')
        THEN '✅ Both RPC functions exist'
        ELSE '⚠️ RPC functions missing'
    END as rpc_status;


