-- Check the job and its submissions
-- Use the job_id from the URL: 5a579921-c70a-4c48-8def-fb2cda70aac6

-- 1. Check if job exists
SELECT 
    id,
    title,
    status,
    created_at,
    updated_at
FROM jobs
WHERE id = '5a579921-c70a-4c48-8def-fb2cda70aac6';

-- 2. Check submissions for this job
SELECT 
    id,
    job_id,
    contractor_id,
    submission_type,
    created_at,
    is_validated,
    review_outcome
FROM job_submissions
WHERE job_id = '5a579921-c70a-4c48-8def-fb2cda70aac6'
ORDER BY created_at DESC;

-- 3. If job doesn't exist, find jobs with similar ID or recent submissions
SELECT 
    j.id,
    j.title,
    j.status,
    js.id as submission_id,
    js.created_at as submission_created
FROM jobs j
LEFT JOIN job_submissions js ON js.job_id = j.id
WHERE js.created_at > NOW() - INTERVAL '1 hour'
ORDER BY js.created_at DESC
LIMIT 10;


