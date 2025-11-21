-- ========================================
-- Diagnostic: Check Job Statuses for Submissions
-- ========================================
-- This script checks if jobs with submissions have the correct status

-- 1. Check all submissions and their job statuses
SELECT 
    js.id as submission_id,
    js.job_id,
    js.created_at as submission_created,
    js.is_validated,
    js.review_outcome,
    j.id as job_id_verify,
    j.title,
    j.status as job_status,
    j.brand_id,
    b.name as brand_name
FROM job_submissions js
LEFT JOIN jobs j ON j.id = js.job_id
LEFT JOIN brands b ON b.id = j.brand_id
ORDER BY js.created_at DESC
LIMIT 20;

-- 2. Count submissions by job status
SELECT 
    j.status as job_status,
    COUNT(js.id) as submission_count,
    COUNT(CASE WHEN js.is_validated IS NULL OR js.is_validated = false THEN 1 END) as unvalidated_count,
    COUNT(CASE WHEN js.review_outcome IS NULL THEN 1 END) as no_outcome_count
FROM job_submissions js
LEFT JOIN jobs j ON j.id = js.job_id
GROUP BY j.status
ORDER BY submission_count DESC;

-- 3. Find submissions that SHOULD be in pending_review but aren't
SELECT 
    js.id as submission_id,
    js.job_id,
    j.title,
    j.status as current_job_status,
    js.is_validated,
    js.review_outcome,
    CASE 
        WHEN j.status = 'pending_review' 
            AND (js.is_validated IS NULL OR js.is_validated = false)
            AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
        THEN '✅ Should show in Pending Review'
        WHEN j.status != 'pending_review' 
            AND (js.is_validated IS NULL OR js.is_validated = false)
        THEN '⚠️ Job status needs update to pending_review'
        ELSE '❌ Should NOT show in Pending Review'
    END as filter_status
FROM job_submissions js
LEFT JOIN jobs j ON j.id = js.job_id
ORDER BY js.created_at DESC;

-- 4. Fix jobs that have submissions but status is not pending_review
-- (Only run this if you want to fix the statuses)
/*
UPDATE jobs
SET 
    status = 'pending_review',
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT js.job_id
    FROM job_submissions js
    WHERE js.job_id IS NOT NULL
      AND (js.is_validated IS NULL OR js.is_validated = false)
      AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
)
AND status != 'pending_review'
AND status != 'completed';
*/

