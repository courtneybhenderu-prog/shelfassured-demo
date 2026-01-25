-- ========================================
-- Delete All Jobs - EXECUTE VERSION
-- ========================================
-- WARNING: This will DELETE ALL JOBS immediately!
-- 
-- Run delete-all-jobs-safe.sql first to preview what will be deleted.
-- Only use this file if you're absolutely sure you want to delete everything.
-- ========================================

BEGIN;

-- Step 1: Delete payments (no cascade, must delete first)
DELETE FROM payments
WHERE job_id IS NOT NULL;

SELECT '✅ Payments deleted: ' || COUNT(*) || ' records' as status
FROM payments
WHERE job_id IS NOT NULL;

-- Step 2: Delete all jobs (cascades to related tables automatically)
DELETE FROM jobs;

SELECT '✅ Jobs deleted: ' || COUNT(*) || ' records remaining' as status
FROM jobs;

-- Step 3: Verify deletion
SELECT 
    'VERIFICATION' as check_type,
    'JOBS' as table_name,
    COUNT(*) as remaining_count
FROM jobs
UNION ALL
SELECT 
    'VERIFICATION',
    'JOB_SUBMISSIONS',
    COUNT(*)
FROM job_submissions
UNION ALL
SELECT 
    'VERIFICATION',
    'JOB_STORES',
    COUNT(*)
FROM job_stores
UNION ALL
SELECT 
    'VERIFICATION',
    'JOB_SKUS',
    COUNT(*)
FROM job_skus
UNION ALL
SELECT 
    'VERIFICATION',
    'PAYMENTS (job-related)',
    COUNT(*)
FROM payments
WHERE job_id IS NOT NULL;

-- If job_store_skus exists, check it too
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_store_skus') THEN
        RAISE NOTICE 'job_store_skus table exists, checking...';
    END IF;
END $$;

COMMIT;

SELECT '✅ Cleanup complete! All jobs and related data have been deleted.' as final_status;
