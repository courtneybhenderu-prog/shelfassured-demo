-- Verify current status of jobs with submissions
-- Run this to check if everything is correct now

-- Check the SunnyGem job specifically
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as last_submission
FROM jobs j
LEFT JOIN job_submissions js ON js.job_id = j.id
WHERE j.id = 'e804a194-3543-4c26-b6f6-5d4cfa126234'
GROUP BY j.id, j.title, j.status;

-- Check all jobs with submissions and their current status
SELECT 
    j.id,
    j.title,
    j.status,
    COUNT(js.id) as submission_count,
    MAX(js.created_at) as last_submission,
    CASE 
        WHEN j.status = 'pending_review' THEN '✅ Correct'
        WHEN j.status = 'pending' THEN '❌ Still pending (needs fix)'
        ELSE '⚠️ Other status: ' || j.status
    END as status_check
FROM jobs j
INNER JOIN job_submissions js ON js.job_id = j.id
GROUP BY j.id, j.title, j.status
ORDER BY last_submission DESC;


