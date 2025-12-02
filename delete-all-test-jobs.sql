-- ========================================
-- Delete All Test Jobs - Clean Slate
-- ========================================
-- WARNING: This will delete ALL jobs and related data
-- Use with caution! This cannot be undone.

-- STEP 1: Show what will be deleted (review this first!)
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
    'PAYMENTS' as table_name,
    COUNT(*) as record_count
FROM payments
UNION ALL
SELECT 
    'JOB_STORE_SKUS' as table_name,
    COUNT(*) as record_count
FROM job_store_skus;

-- STEP 2: Show job details that will be deleted
SELECT 
    j.id,
    j.title,
    j.status,
    j.brand_id,
    b.name as brand_name,
    COUNT(js.id) as submission_count,
    COUNT(p.id) as payment_count
FROM jobs j
LEFT JOIN brands b ON b.id = j.brand_id
LEFT JOIN job_submissions js ON js.job_id = j.id
LEFT JOIN payments p ON p.job_id = j.id
GROUP BY j.id, j.title, j.status, j.brand_id, b.name
ORDER BY j.created_at DESC;

-- STEP 3: Delete related records first (to avoid foreign key constraints)
-- Uncomment the sections below to execute

-- Delete payments
/*
DELETE FROM payments;
SELECT '✅ Payments deleted' as status;
*/

-- Delete job submissions
/*
DELETE FROM job_submissions;
SELECT '✅ Job submissions deleted' as status;
*/

-- Delete job_store_skus relationships
/*
DELETE FROM job_store_skus;
SELECT '✅ Job-store-SKU relationships deleted' as status;
*/

-- Delete jobs
/*
DELETE FROM jobs;
SELECT '✅ All jobs deleted' as status;
*/

-- STEP 4: Verify deletion
/*
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
    'PAYMENTS' as table_name,
    COUNT(*) as remaining_count
FROM payments
UNION ALL
SELECT 
    'JOB_STORE_SKUS' as table_name,
    COUNT(*) as remaining_count
FROM job_store_skus;
*/

