-- ========================================
-- Diagnostic: Check Today's Submissions
-- ========================================
-- This script checks submissions created today and their job statuses

-- 1. Check all submissions from today
SELECT 
    js.id as submission_id,
    js.job_id,
    js.created_at as submission_created,
    js.is_validated,
    js.review_outcome,
    js.store_id,
    js.sku_id,
    j.id as job_id_verify,
    j.title,
    j.status as job_status,
    j.brand_id,
    b.name as brand_name,
    CASE 
        WHEN j.status = 'pending_review' 
            AND (js.is_validated IS NULL OR js.is_validated = false)
            AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
        THEN '✅ Should show in Pending Review'
        WHEN j.status != 'pending_review' 
            AND j.status != 'completed'
            AND j.status != 'cancelled'
            AND (js.is_validated IS NULL OR js.is_validated = false)
        THEN '⚠️ Should show (lenient filter) but job status is: ' || j.status
        ELSE '❌ Should NOT show in Pending Review'
    END as filter_status
FROM job_submissions js
LEFT JOIN jobs j ON j.id = js.job_id
LEFT JOIN brands b ON b.id = j.brand_id
WHERE js.created_at >= CURRENT_DATE
ORDER BY js.created_at DESC;

-- 2. Check if job status was updated when submission was created
SELECT 
    j.id,
    j.title,
    j.status,
    j.updated_at as job_updated,
    MAX(js.created_at) as latest_submission,
    COUNT(js.id) as submission_count
FROM jobs j
LEFT JOIN job_submissions js ON js.job_id = j.id
WHERE j.updated_at >= CURRENT_DATE
   OR js.created_at >= CURRENT_DATE
GROUP BY j.id, j.title, j.status, j.updated_at
ORDER BY j.updated_at DESC, latest_submission DESC;

-- 3. Find jobs that have submissions but wrong status
SELECT 
    j.id,
    j.title,
    j.status as current_status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as latest_submission,
    CASE 
        WHEN j.status != 'pending_review' 
            AND j.status != 'completed'
            AND j.status != 'cancelled'
        THEN '⚠️ Should be pending_review'
        ELSE '✅ Status OK'
    END as status_check
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE js.created_at >= CURRENT_DATE
GROUP BY j.id, j.title, j.status
HAVING j.status != 'pending_review' AND j.status != 'completed' AND j.status != 'cancelled';

-- 4. Fix jobs from today that should be pending_review
-- (Uncomment to run)
/*
UPDATE jobs
SET 
    status = 'pending_review',
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT js.job_id
    FROM job_submissions js
    WHERE js.created_at >= CURRENT_DATE
      AND js.job_id IS NOT NULL
      AND (js.is_validated IS NULL OR js.is_validated = false)
      AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
)
AND status != 'pending_review'
AND status != 'completed'
AND status != 'cancelled';
*/


