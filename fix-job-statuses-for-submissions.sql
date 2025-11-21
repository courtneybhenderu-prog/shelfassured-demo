-- ========================================
-- Fix: Update job statuses to pending_review for jobs with submissions
-- ========================================
-- This script updates jobs that have unvalidated submissions to pending_review status

-- First, let's see what we're about to update
SELECT 
    j.id,
    j.title,
    j.status as current_status,
    COUNT(js.id) as submission_count,
    COUNT(CASE WHEN js.is_validated IS NULL OR js.is_validated = false THEN 1 END) as unvalidated_count
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE (js.is_validated IS NULL OR js.is_validated = false)
  AND (js.review_outcome IS NULL OR js.review_outcome != 'superseded')
  AND j.status != 'pending_review'
  AND j.status != 'completed'
GROUP BY j.id, j.title, j.status;

-- Now update them
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

-- Verify the update
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE j.status = 'pending_review'
GROUP BY j.id, j.title, j.status;

