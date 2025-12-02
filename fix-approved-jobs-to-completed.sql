-- ========================================
-- Fix: Update job statuses to 'completed' for approved submissions
-- ========================================
-- This updates jobs that have approved submissions but status is still pending_review

-- First, see what we're updating
SELECT 
    j.id,
    j.title,
    j.status as current_status,
    COUNT(js.id) as approved_submission_count,
    MAX(js.validated_at) as last_approved
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE (js.review_outcome = 'approved' OR js.is_validated = true)
  AND j.status != 'completed'
GROUP BY j.id, j.title, j.status;

-- Update them to completed
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

-- Verify the update
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as approved_submission_count
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE j.status = 'completed'
  AND (js.review_outcome = 'approved' OR js.is_validated = true)
GROUP BY j.id, j.title, j.status
ORDER BY MAX(js.validated_at) DESC;

