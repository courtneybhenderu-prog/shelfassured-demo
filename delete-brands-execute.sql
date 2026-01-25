-- ========================================
-- Delete Specific Brands - EXECUTE VERSION
-- ========================================
-- WARNING: This will DELETE "Primal Kitchen" and "Oh, Sugar!" brands immediately!
-- 
-- Run delete-brands-safe.sql first to preview what will be deleted.
-- Only use this file if you're absolutely sure you want to delete these brands.
-- ========================================

BEGIN;

-- Step 1: Delete payments for jobs related to these brands (no cascade, must delete first)
DELETE FROM payments
WHERE job_id IN (
    SELECT id FROM jobs 
    WHERE brand_id IN (
        SELECT id FROM brands 
        WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
    )
);

SELECT '✅ Payments deleted: ' || COUNT(*) || ' records remaining' as status
FROM payments
WHERE job_id IN (
    SELECT id FROM jobs 
    WHERE brand_id IN (
        SELECT id FROM brands 
        WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
    )
);

-- Step 2: Delete jobs for these brands (cascades to job_submissions, job_stores, job_skus, etc.)
DELETE FROM jobs
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

SELECT '✅ Jobs deleted: ' || COUNT(*) || ' records remaining' as status
FROM jobs
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

-- Step 3: Delete products/SKUs for these brands
-- Delete from products table (if it exists)
-- Note: products table uses 'brand' (text) column, not 'brand_id'
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'products') THEN
        DELETE FROM products
        WHERE brand IN ('Primal Kitchen', 'Oh, Sugar!');
        RAISE NOTICE 'Products deleted';
    END IF;
END $$;

-- Delete from skus table
DELETE FROM skus
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

SELECT '✅ SKUs deleted: ' || COUNT(*) || ' records remaining' as status
FROM skus
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

-- Step 4: Delete brand relationships (these should cascade, but we'll delete explicitly to be safe)
DELETE FROM brand_products
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

DELETE FROM brand_stores
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

SELECT '✅ Brand relationships deleted' as status;

-- Step 5: Finally, delete the brands themselves
DELETE FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!');

SELECT '✅ Brands deleted: ' || COUNT(*) || ' records remaining' as status
FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!');

-- Step 6: Verify deletion
SELECT 
    'VERIFICATION' as check_type,
    'Brands' as table_name,
    COUNT(*) as remaining_count
FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
UNION ALL
SELECT 
    'VERIFICATION',
    'Jobs',
    COUNT(*)
FROM jobs
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'VERIFICATION',
    'SKUs',
    COUNT(*)
FROM skus
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'VERIFICATION',
    'Products',
    COUNT(*)
FROM products
WHERE brand IN ('Primal Kitchen', 'Oh, Sugar!')
UNION ALL
SELECT 
    'VERIFICATION',
    'brand_products',
    COUNT(*)
FROM brand_products
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'VERIFICATION',
    'brand_stores',
    COUNT(*)
FROM brand_stores
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'));

COMMIT;

SELECT '✅ Cleanup complete! Primal Kitchen and Oh, Sugar! brands and all related data have been deleted.' as final_status;
