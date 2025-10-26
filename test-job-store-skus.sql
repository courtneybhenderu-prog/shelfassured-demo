-- Test script for job_store_skus table
-- Tests the DJ's Boudain + Original Boudain reuse scenario

-- Test 1: Create a job with DJ's Boudain brand
INSERT INTO jobs (
    title,
    description,
    brand_id,
    contractor_id,
    created_by,
    payout_per_store,
    job_type,
    instructions,
    status,
    priority,
    due_date
) VALUES (
    'DJ''s Boudain Test Job 1',
    'Testing DJ''s Boudain Original across multiple stores',
    '6bfa5749-0c4b-4986-a010-622c258782cb',  -- DJ's Boudain brand ID
    (SELECT id FROM users WHERE role = 'contractor' AND is_active = true LIMIT 1),
    (SELECT id FROM users WHERE role = 'admin' AND is_active = true LIMIT 1),
    5.00,
    'photo_audit',
    'Test job for DJ''s Boudain Original',
    'pending',
    'normal',
    NOW() + INTERVAL '48 hours'
) RETURNING id as job_1_id;

-- Test 2: Assign Original Boudain to H-E-B Plus San Antonio (first assignment)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
VALUES (
    (SELECT id FROM jobs WHERE title = 'DJ''s Boudain Test Job 1' ORDER BY created_at DESC LIMIT 1),
    '9479a2f6-f4c8-4824-b017-968896fdb70d',  -- H-E-B Plus San Antonio
    '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk'   -- Original Boudain
) RETURNING id as assignment_1_id;

-- Test 3: Try to assign the SAME combination again (should not error due to UNIQUE constraint)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
VALUES (
    (SELECT id FROM jobs WHERE title = 'DJ''s Boudain Test Job 1' ORDER BY created_at DESC LIMIT 1),
    '9479a2f6-f4c8-4824-b017-968896fdb70d',  -- Same store
    '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk'   -- Same SKU
) ON CONFLICT (job_id, store_id, sku_id) DO NOTHING
RETURNING id as assignment_2_id;

-- Test 4: Assign Original Boudain to a DIFFERENT store (should create new record)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
VALUES (
    (SELECT id FROM jobs WHERE title = 'DJ''s Boudain Test Job 1' ORDER BY created_at DESC LIMIT 1),
    (SELECT id FROM stores WHERE name LIKE '%Whole Foods%' LIMIT 1),  -- Different store
    '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk'   -- Same SKU
) RETURNING id as assignment_3_id;

-- Test 5: Create a SECOND job with the SAME brand and SKU (should work)
INSERT INTO jobs (
    title,
    description,
    brand_id,
    contractor_id,
    created_by,
    payout_per_store,
    job_type,
    instructions,
    status,
    priority,
    due_date
) VALUES (
    'DJ''s Boudain Test Job 2',
    'Second job testing DJ''s Boudain Original reuse',
    '6bfa5749-0c4b-4986-a010-622c258782cb',  -- Same brand
    (SELECT id FROM users WHERE role = 'contractor' AND is_active = true LIMIT 1),
    (SELECT id FROM users WHERE role = 'admin' AND is_active = true LIMIT 1),
    5.00,
    'photo_audit',
    'Second test job for DJ''s Boudain Original',
    'pending',
    'normal',
    NOW() + INTERVAL '48 hours'
) RETURNING id as job_2_id;

-- Test 6: Assign Original Boudain to H-E-B Plus San Antonio for SECOND job (should work)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
VALUES (
    (SELECT id FROM jobs WHERE title = 'DJ''s Boudain Test Job 2' ORDER BY created_at DESC LIMIT 1),
    '9479a2f6-f4c8-4824-b017-968896fdb70d',  -- Same store
    '2f9d97a6-9a8e-44d7-bfbc-47722d2370bk'   -- Same SKU
) RETURNING id as assignment_4_id;

-- Verification: Show all assignments
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
WHERE j.title LIKE '%DJ''s Boudain Test%'
ORDER BY j.created_at, s.name, sk.name;

-- Cleanup: Remove test data
-- DELETE FROM job_store_skus WHERE job_id IN (SELECT id FROM jobs WHERE title LIKE '%DJ''s Boudain Test%');
-- DELETE FROM jobs WHERE title LIKE '%DJ''s Boudain Test%';

