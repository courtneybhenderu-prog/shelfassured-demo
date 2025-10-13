-- Check if DJ's Boudain job was created
-- This query will show all jobs and look for DJ's Boudain specifically

-- Show all jobs
SELECT 
    jobs.id,
    jobs.title,
    jobs.status,
    jobs.total_payout,
    jobs.created_at,
    brands.name as brand_name
FROM jobs 
LEFT JOIN brands ON jobs.brand_id = brands.id
ORDER BY jobs.created_at DESC;

-- Look specifically for DJ's Boudain
SELECT 
    jobs.id,
    jobs.title,
    jobs.status,
    jobs.total_payout,
    jobs.created_at,
    brands.name as brand_name
FROM jobs 
LEFT JOIN brands ON jobs.brand_id = brands.id
WHERE brands.name ILIKE '%djs%' 
   OR brands.name ILIKE '%boudain%'
   OR jobs.title ILIKE '%djs%'
   OR jobs.title ILIKE '%boudain%';

-- Count total jobs
SELECT COUNT(*) as total_jobs FROM jobs;
