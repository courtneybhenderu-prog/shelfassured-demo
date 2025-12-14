-- ========================================
-- Diagnostic: Check approved submission and job status
-- ========================================
-- This checks if approved submissions have their jobs marked as completed

-- 1. Check approved submissions and their job statuses
SELECT 
    js.id as submission_id,
    js.job_id,
    js.is_validated,
    js.review_outcome,
    js.validated_at,
    j.id as job_id_verify,
    j.title,
    j.status as job_status,
    j.updated_at as job_updated,
    CASE 
        WHEN j.status = 'completed' THEN '✅ Job correctly marked as completed'
        WHEN j.status = 'pending_review' THEN '⚠️ Job still pending_review (should be completed)'
        ELSE '❌ Job status is: ' || j.status
    END as status_check
FROM job_submissions js
JOIN jobs j ON j.id = js.job_id
WHERE js.review_outcome = 'approved'
   OR js.is_validated = true
ORDER BY js.validated_at DESC
LIMIT 10;

-- 2. Find approved submissions where job is NOT completed
SELECT 
    js.id as submission_id,
    js.job_id,
    j.title,
    j.status as current_job_status,
    js.review_outcome,
    js.validated_at
FROM job_submissions js
JOIN jobs j ON j.id = js.job_id
WHERE (js.review_outcome = 'approved' OR js.is_validated = true)
  AND j.status != 'completed'
ORDER BY js.validated_at DESC;

-- 3. Fix jobs that should be completed but aren't
-- (Uncomment to run)
/*
UPDATE jobs
SET 
    status = 'completed',
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT js.job_id
    FROM job_submissions js
    WHERE (js.review_outcome = 'approved' OR js.is_validated = true)
      AND js.job_id IS NOT NULL
)
AND status != 'completed';
*/


