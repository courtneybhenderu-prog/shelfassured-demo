-- Check the specific job that's showing "Unknown Store" and "SODA"
-- Job title: SunnyGem Austin Audit

-- 1. Find the job by title
SELECT 
    j.id,
    j.title,
    j.description,
    j.brand_id,
    b.name as brand_name,
    j.assigned_user_id,
    j.status,
    j.created_at
FROM jobs j
LEFT JOIN brands b ON j.brand_id = b.id
WHERE j.title ILIKE '%SunnyGem%'
ORDER BY j.created_at DESC;

-- 2. Check stores linked to this job
SELECT 
    js.job_id,
    js.store_id,
    s.name as store_name,
    s.city,
    s.state,
    s.address
FROM job_stores js
LEFT JOIN stores s ON js.store_id = s.id
WHERE js.job_id IN (
    SELECT id FROM jobs WHERE title ILIKE '%SunnyGem%'
);

-- 3. Check SKUs linked to this job
SELECT 
    jsk.job_id,
    jsk.sku_id,
    sk.name as sku_name,
    sk.upc,
    sk.brand_id,
    b.name as brand_name
FROM job_skus jsk
LEFT JOIN skus sk ON jsk.sku_id = sk.id
LEFT JOIN brands b ON sk.brand_id = b.id
WHERE jsk.job_id IN (
    SELECT id FROM jobs WHERE title ILIKE '%SunnyGem%'
);

-- 4. Get full job details with all relationships
SELECT 
    j.id,
    j.title,
    j.description,
    b.name as brand_name,
    s.name as store_name,
    s.city,
    s.state,
    sk.name as sku_name,
    sk.upc,
    j.created_at
FROM jobs j
LEFT JOIN brands b ON j.brand_id = b.id
LEFT JOIN job_stores js ON j.id = js.job_id
LEFT JOIN stores s ON js.store_id = s.id
LEFT JOIN job_skus jsk ON j.id = jsk.job_id
LEFT JOIN skus sk ON jsk.sku_id = sk.id
WHERE j.title ILIKE '%SunnyGem%'
ORDER BY j.created_at DESC;
