-- Simple Smoke Test for job_store_skus
-- Tests duplicate handling and conflict resolution
-- Uses existing data from your database

-- Step 1: Check what data we have
SELECT 'Available stores:' as info;
SELECT id, name, store_chain 
FROM stores 
WHERE is_active = true 
ORDER BY store_chain, name 
LIMIT 5;

SELECT 'Available DJ jobs:' as info;
SELECT id, title, created_at 
FROM jobs 
WHERE title LIKE '%DJ%' 
ORDER BY created_at DESC 
LIMIT 3;

SELECT 'Available SKUs:' as info;
SELECT id, name, upc 
FROM skus 
WHERE name LIKE '%Boudain%' 
ORDER BY name 
LIMIT 3;

-- Step 2: Simple test with existing data
-- Use the first available job, store, and SKU
WITH test_data AS (
    SELECT 
        (SELECT id FROM jobs WHERE title LIKE '%DJ%' ORDER BY created_at DESC LIMIT 1) as job_id,
        (SELECT id FROM stores WHERE is_active = true LIMIT 1) as store_id,
        (SELECT id FROM skus WHERE name LIKE '%Boudain%' LIMIT 1) as sku_id
)
-- Test 1: Insert assignment
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_id, sku_id FROM test_data
WHERE job_id IS NOT NULL AND store_id IS NOT NULL AND sku_id IS NOT NULL
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Test 2: Try to insert the same assignment again (should be no-op)
WITH test_data AS (
    SELECT 
        (SELECT id FROM jobs WHERE title LIKE '%DJ%' ORDER BY created_at DESC LIMIT 1) as job_id,
        (SELECT id FROM stores WHERE is_active = true LIMIT 1) as store_id,
        (SELECT id FROM skus WHERE name LIKE '%Boudain%' LIMIT 1) as sku_id
)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_id, sku_id FROM test_data
WHERE job_id IS NOT NULL AND store_id IS NOT NULL AND sku_id IS NOT NULL
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Step 3: Verify the test worked
SELECT 'Test Results:' as info;
SELECT 
    COUNT(*) as total_assignments,
    COUNT(DISTINCT job_id) as unique_jobs,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT sku_id) as unique_skus
FROM job_store_skus;

-- Step 4: Show recent assignments
SELECT 'Recent assignments:' as info;
SELECT 
    j.title as job_title,
    s.name as store_name,
    sk.name as sku_name,
    jss.status,
    jss.created_at
FROM job_store_skus jss
JOIN jobs j ON j.id = jss.job_id
JOIN stores s ON s.id = jss.store_id
JOIN skus sk ON sk.id = jss.sku_id
ORDER BY jss.created_at DESC
LIMIT 5;


