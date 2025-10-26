-- One-Shot Smoke Test for job_store_skus
-- Tests duplicate handling and conflict resolution
-- Uses actual IDs from your database

-- First, let's see what stores we have available
SELECT id, name, store_chain 
FROM stores 
WHERE is_active = true 
ORDER BY store_chain, name 
LIMIT 10;

-- Get actual IDs for the test
WITH actual_ids AS (
    SELECT 
        (SELECT id FROM jobs WHERE title LIKE '%DJ%' ORDER BY created_at DESC LIMIT 1) as job_id,
        '9479a2f6-f4c8-4824-b017-968896fdb70d' as store_a,  -- H-E-B Plus San Antonio
        (SELECT id FROM stores WHERE is_active = true AND id != '9479a2f6-f4c8-4824-b017-968896fdb70d' LIMIT 1) as store_b,  -- Any other active store
        '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk' as sku_original  -- Original Boudain UUID
)
SELECT 
    job_id,
    store_a,
    store_b,
    sku_original,
    CASE 
        WHEN job_id IS NULL THEN 'No DJ jobs found'
        WHEN store_b IS NULL THEN 'Only one store available'
        ELSE 'All IDs found'
    END as status
FROM actual_ids;
-- Test 1: Insert original assignment
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_a, sku_original FROM actual_ids
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Test 2: Insert same assignment (should be no-op)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_a, sku_original FROM actual_ids
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Test 3: Insert different store (should create new row)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_b, sku_original FROM actual_ids
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Verification: Count rows for the job and SKU
WITH actual_ids AS (
    SELECT 
        (SELECT id FROM jobs WHERE title LIKE '%DJ%' ORDER BY created_at DESC LIMIT 1) as job_id,
        '9479a2f6-f4c8-4824-b017-968896fdb70d' as store_a,
        (SELECT id FROM stores WHERE name LIKE '%Whole Foods%' LIMIT 1) as store_b,
        '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk' as sku_original
)
SELECT 
    jss.job_id, 
    jss.store_id, 
    jss.sku_id, 
    COUNT(*) as row_count
FROM job_store_skus jss, actual_ids ai
WHERE jss.job_id = ai.job_id 
    AND jss.sku_id = ai.sku_original
    AND jss.store_id IN (ai.store_a, ai.store_b)
GROUP BY jss.job_id, jss.store_id, jss.sku_id
ORDER BY jss.store_id;

-- Expected result: 2 rows, each with count = 1
-- If you see more than 2 rows or any count > 1, there's an issue

-- Additional verification: Check total assignments for this job
WITH actual_ids AS (
    SELECT 
        (SELECT id FROM jobs WHERE title LIKE '%DJ%' ORDER BY created_at DESC LIMIT 1) as job_id
)
SELECT 
    COUNT(*) as total_assignments,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT sku_id) as unique_skus
FROM job_store_skus jss, actual_ids ai
WHERE jss.job_id = ai.job_id;
