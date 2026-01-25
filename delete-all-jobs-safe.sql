-- ========================================
-- Delete All Jobs - Safe Cleanup Script
-- ========================================
-- This script safely deletes all jobs and related data from the database.
-- 
-- IMPORTANT: This operation CANNOT be undone. Use with caution!
-- 
-- What gets deleted:
-- - All jobs
-- - All job submissions (cascades automatically)
-- - All job_stores relationships (cascades automatically)
-- - All job_skus relationships (cascades automatically)
-- - All job_store_skus relationships (cascades automatically)
-- - All payments related to jobs (must delete manually first)
--
-- What is NOT deleted:
-- - Brands, stores, SKUs, users (these remain intact)
--
-- ========================================

-- ========================================
-- STEP 1: PREVIEW - See what will be deleted
-- ========================================
-- Run this section first to see what you're about to delete

SELECT 
    '📊 PREVIEW: Records that will be deleted' as info,
    '' as spacer;

SELECT 
    'JOBS' as table_name,
    COUNT(*) as record_count
FROM jobs
UNION ALL
SELECT 
    'JOB_SUBMISSIONS' as table_name,
    COUNT(*) as record_count
FROM job_submissions
UNION ALL
SELECT 
    'JOB_STORES' as table_name,
    COUNT(*) as record_count
FROM job_stores
UNION ALL
SELECT 
    'JOB_SKUS' as table_name,
    COUNT(*) as record_count
FROM job_skus
UNION ALL
SELECT 
    'PAYMENTS' as table_name,
    COUNT(*) as record_count
FROM payments
WHERE job_id IS NOT NULL
UNION ALL
SELECT 
    'JOB_STORE_SKUS' as table_name,
    COUNT(*) as record_count
FROM job_store_skus
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_store_skus');

-- Show job details
SELECT 
    '📋 Job Details:' as info,
    '' as spacer;

SELECT 
    j.id,
    j.title,
    j.status,
    j.job_type,
    b.name as brand_name,
    COUNT(DISTINCT js.id) as submission_count,
    COUNT(DISTINCT p.id) as payment_count,
    COUNT(DISTINCT jst.id) as store_count,
    COUNT(DISTINCT jsk.id) as sku_count,
    j.created_at
FROM jobs j
LEFT JOIN brands b ON b.id = j.brand_id
LEFT JOIN job_submissions js ON js.job_id = j.id
LEFT JOIN payments p ON p.job_id = j.id
LEFT JOIN job_stores jst ON jst.job_id = j.id
LEFT JOIN job_skus jsk ON jsk.job_id = j.id
GROUP BY j.id, j.title, j.status, j.job_type, j.brand_id, b.name, j.created_at
ORDER BY j.created_at DESC;

-- ========================================
-- STEP 2: DELETE OPERATIONS
-- ========================================
-- Uncomment the sections below to execute the deletion
-- 
-- IMPORTANT: 
-- 1. Review the preview above first
-- 2. Make sure you have a backup if needed
-- 3. Uncomment one section at a time and run it

-- Step 2a: Delete payments first (no cascade, must delete manually)
-- Uncomment to execute:
/*
DELETE FROM payments
WHERE job_id IS NOT NULL;

SELECT '✅ Payments deleted' as status;
*/

-- Step 2b: Delete all jobs (this will cascade to related tables)
-- Uncomment to execute:
/*
DELETE FROM jobs;

SELECT '✅ All jobs deleted (cascaded to related tables)' as status;
*/

-- ========================================
-- STEP 3: VERIFY DELETION
-- ========================================
-- Run this after deletion to confirm everything is gone

/*
SELECT 
    '✅ VERIFICATION: Remaining records' as info,
    '' as spacer;

SELECT 
    'JOBS' as table_name,
    COUNT(*) as remaining_count
FROM jobs
UNION ALL
SELECT 
    'JOB_SUBMISSIONS' as table_name,
    COUNT(*) as remaining_count
FROM job_submissions
UNION ALL
SELECT 
    'JOB_STORES' as table_name,
    COUNT(*) as remaining_count
FROM job_stores
UNION ALL
SELECT 
    'JOB_SKUS' as table_name,
    COUNT(*) as remaining_count
FROM job_skus
UNION ALL
SELECT 
    'PAYMENTS (job-related)' as table_name,
    COUNT(*) as remaining_count
FROM payments
WHERE job_id IS NOT NULL
UNION ALL
SELECT 
    'JOB_STORE_SKUS' as table_name,
    COUNT(*) as remaining_count
FROM job_store_skus
WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_store_skus');

-- All counts should be 0 if deletion was successful
*/

-- ========================================
-- NOTES:
-- ========================================
-- This script is safe because:
-- 1. It shows a preview first so you know what will be deleted
-- 2. It handles foreign key constraints properly (payments first)
-- 3. It uses CASCADE relationships where they exist
-- 4. It includes verification queries
--
-- The following tables are NOT affected:
-- - brands
-- - stores  
-- - skus
-- - users
-- - notifications (unless they reference jobs)
-- - Any other unrelated tables
