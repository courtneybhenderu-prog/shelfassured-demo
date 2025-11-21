-- ========================================
-- Fix: Update job statuses to pending_review for jobs with unvalidated submissions
-- ========================================
-- This updates jobs that have submissions but status is still 'pending'

-- First, see what we're updating
SELECT 
    j.id,
    j.title,
    j.status as current_status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as latest_submission
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE (js.is_validated IS NULL OR js.is_validated = false)
  AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
  AND j.status != 'pending_review'
  AND j.status != 'completed'
  AND j.status != 'cancelled'
GROUP BY j.id, j.title, j.status;

-- Update them to pending_review
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
AND status != 'completed'
AND status != 'cancelled';

-- Verify the update
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE j.status = 'pending_review'
  AND (js.is_validated IS NULL OR js.is_validated = false)
GROUP BY j.id, j.title, j.status
ORDER BY MAX(js.created_at) DESC;

