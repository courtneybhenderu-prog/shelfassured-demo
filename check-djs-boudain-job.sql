-- Check if DJ's Boudain job was created
-- This query will show all jobs and look for DJ's Boudain specifically

-- Show all jobs
SELECT 
    id,
    title,
    status,
    total_payout,
    created_at,
    brands.name as brand_name
FROM jobs 
LEFT JOIN brands ON jobs.brand_id = brands.id
ORDER BY created_at DESC;

-- Look specifically for DJ's Boudain
SELECT 
    id,
    title,
    status,
    total_payout,
    created_at,
    brands.name as brand_name
FROM jobs 
LEFT JOIN brands ON jobs.brand_id = brands.id
WHERE brands.name ILIKE '%djs%' 
   OR brands.name ILIKE '%boudain%'
   OR title ILIKE '%djs%'
   OR title ILIKE '%boudain%';

-- Count total jobs
SELECT COUNT(*) as total_jobs FROM jobs;
