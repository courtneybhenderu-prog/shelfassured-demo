-- Debug job data to find the issue
-- Check recent jobs and their relationships

-- 1. Check recent jobs
SELECT 
    j.id,
    j.title,
    j.description,
    j.created_at,
    b.name as brand_name
FROM jobs j
LEFT JOIN brands b ON j.brand_id = b.id
ORDER BY j.created_at DESC
LIMIT 5;

-- 2. Check job_stores relationships
SELECT 
    js.job_id,
    js.store_id,
    s.name as store_name,
    s.city,
    s.state
FROM job_stores js
LEFT JOIN stores s ON js.store_id = s.id
ORDER BY js.job_id DESC
LIMIT 10;

-- 3. Check job_skus relationships  
SELECT 
    jsk.job_id,
    jsk.sku_id,
    sk.name as sku_name,
    sk.upc
FROM job_skus jsk
LEFT JOIN skus sk ON jsk.sku_id = sk.id
ORDER BY jsk.job_id DESC
LIMIT 10;

-- 4. Check for jobs with no stores linked
SELECT 
    j.id,
    j.title,
    COUNT(js.store_id) as store_count
FROM jobs j
LEFT JOIN job_stores js ON j.id = js.job_id
GROUP BY j.id, j.title
HAVING COUNT(js.store_id) = 0
ORDER BY j.created_at DESC;

-- 5. Check for jobs with no SKUs linked
SELECT 
    j.id,
    j.title,
    COUNT(jsk.sku_id) as sku_count
FROM jobs j
LEFT JOIN job_skus jsk ON j.id = jsk.job_id
GROUP BY j.id, j.title
HAVING COUNT(jsk.sku_id) = 0
ORDER BY j.created_at DESC;
