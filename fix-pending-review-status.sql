-- Fix jobs that have submissions but status is still 'pending'
-- Run this in Supabase SQL editor

-- 1. Find jobs with submissions but wrong status
SELECT 
    j.id,
    j.title,
    j.status as current_status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as last_submission,
    'Should be pending_review' as issue
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
WHERE j.status != 'pending_review'
GROUP BY j.id, j.title, j.status
ORDER BY last_submission DESC;

-- 2. Update these jobs to pending_review
UPDATE jobs
SET 
    status = 'pending_review',
    updated_at = NOW()
WHERE id IN (
    SELECT DISTINCT j.id
    FROM jobs j
    INNER JOIN job_submissions js ON js.job_id = j.id
    WHERE j.status != 'pending_review'
);

-- 3. Verify the update
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count
FROM jobs j
LEFT JOIN job_submissions js ON js.job_id = j.id
WHERE j.status = 'pending_review'
GROUP BY j.id, j.title, j.status
ORDER BY j.updated_at DESC
LIMIT 10;


