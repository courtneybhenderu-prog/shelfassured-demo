-- ========================================
-- Delete Specific Brands - Safe Cleanup Script
-- ========================================
-- This script safely deletes "Primal Kitchen" and "Oh, Sugar!" brands
-- and all related data from the database.
-- 
-- IMPORTANT: This operation CANNOT be undone. Use with caution!
-- 
-- What gets deleted:
-- - The brands themselves
-- - All jobs for these brands (cascades to job_submissions, job_stores, job_skus, etc.)
-- - All products/SKUs for these brands
-- - All brand_products relationships (cascades automatically)
-- - All brand_stores relationships (cascades automatically)
-- - All payments related to jobs for these brands
--
-- What is NOT deleted:
-- - Other brands
-- - Stores (unless only linked to these brands)
-- - Users
--
-- ========================================

-- ========================================
-- STEP 1: PREVIEW - See what will be deleted
-- ========================================
-- Run this section first to see what you're about to delete

-- Find the brands
SELECT 
    '📊 PREVIEW: Brands to be deleted' as info,
    '' as spacer;

SELECT 
    id,
    name,
    website,
    created_at,
    (SELECT COUNT(*) FROM jobs WHERE brand_id = brands.id) as job_count,
    (SELECT COUNT(*) FROM skus WHERE brand_id = brands.id) as sku_count,
    (SELECT COUNT(*) FROM products WHERE brand = brands.name) as product_count
FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
ORDER BY name;

-- Show related jobs
SELECT 
    '📋 Related Jobs:' as info,
    '' as spacer;

SELECT 
    j.id,
    j.title,
    j.status,
    b.name as brand_name,
    COUNT(DISTINCT js.id) as submission_count,
    COUNT(DISTINCT p.id) as payment_count
FROM jobs j
JOIN brands b ON b.id = j.brand_id
LEFT JOIN job_submissions js ON js.job_id = j.id
LEFT JOIN payments p ON p.job_id = j.id
WHERE b.name IN ('Primal Kitchen', 'Oh, Sugar!')
GROUP BY j.id, j.title, j.status, b.name
ORDER BY j.created_at DESC;

-- Show related products/SKUs
SELECT 
    '📦 Related Products/SKUs:' as info,
    '' as spacer;

SELECT 
    'SKUs' as type,
    COUNT(*) as count
FROM skus
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'Products' as type,
    COUNT(*) as count
FROM products
WHERE brand IN ('Primal Kitchen', 'Oh, Sugar!');

-- Show brand relationships
SELECT 
    '🔗 Brand Relationships:' as info,
    '' as spacer;

SELECT 
    'brand_products' as table_name,
    COUNT(*) as count
FROM brand_products
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'brand_stores' as table_name,
    COUNT(*) as count
FROM brand_stores
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'));

-- ========================================
-- STEP 2: DELETE OPERATIONS
-- ========================================
-- Uncomment the sections below to execute the deletion
-- 
-- IMPORTANT: 
-- 1. Review the preview above first
-- 2. Make sure you have a backup if needed
-- 3. Uncomment one section at a time and run it

-- Step 2a: Delete payments for jobs related to these brands (no cascade, must delete manually)
-- Uncomment to execute:
/*
DELETE FROM payments
WHERE job_id IN (
    SELECT id FROM jobs 
    WHERE brand_id IN (
        SELECT id FROM brands 
        WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
    )
);

SELECT '✅ Payments deleted' as status;
*/

-- Step 2b: Delete jobs for these brands (this will cascade to job_submissions, job_stores, job_skus, etc.)
-- Uncomment to execute:
/*
DELETE FROM jobs
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

SELECT '✅ Jobs deleted (cascaded to related tables)' as status;
*/

-- Step 2c: Delete products/SKUs for these brands
-- Note: Some may have ON DELETE CASCADE, but we'll delete explicitly to be safe
-- Uncomment to execute:
/*
-- Delete from products table (if it exists)
-- Note: products table uses 'brand' (text) column, not 'brand_id'
DELETE FROM products
WHERE brand IN ('Primal Kitchen', 'Oh, Sugar!');

-- Delete from skus table
DELETE FROM skus
WHERE brand_id IN (
    SELECT id FROM brands 
    WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
);

SELECT '✅ Products/SKUs deleted' as status;
*/

-- Step 2d: Delete brand relationships (these should cascade, but we'll delete explicitly)
-- Uncomment to execute:
/*
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
*/

-- Step 2e: Finally, delete the brands themselves
-- Uncomment to execute:
/*
DELETE FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!');

SELECT '✅ Brands deleted' as status;
*/

-- ========================================
-- STEP 3: VERIFY DELETION
-- ========================================
-- Run this after deletion to confirm everything is gone

/*
SELECT 
    '✅ VERIFICATION: Remaining records' as info,
    '' as spacer;

-- Check if brands still exist
SELECT 
    'Brands' as table_name,
    COUNT(*) as remaining_count
FROM brands
WHERE name IN ('Primal Kitchen', 'Oh, Sugar!')
UNION ALL
-- Check related jobs
SELECT 
    'Jobs',
    COUNT(*)
FROM jobs
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
-- Check related products/SKUs
SELECT 
    'SKUs',
    COUNT(*)
FROM skus
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'Products',
    COUNT(*)
FROM products
WHERE brand IN ('Primal Kitchen', 'Oh, Sugar!')
UNION ALL
-- Check brand relationships
SELECT 
    'brand_products',
    COUNT(*)
FROM brand_products
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'))
UNION ALL
SELECT 
    'brand_stores',
    COUNT(*)
FROM brand_stores
WHERE brand_id IN (SELECT id FROM brands WHERE name IN ('Primal Kitchen', 'Oh, Sugar!'));

-- All counts should be 0 if deletion was successful
*/

-- ========================================
-- NOTES:
-- ========================================
-- This script handles:
-- 1. Exact brand names: 'Primal Kitchen' and 'Oh, Sugar!' (with exclamation mark)
-- 2. Foreign key relationships properly
-- 3. Cascading deletes where they exist
-- 4. Manual deletion of payments (no cascade)
--
-- The following tables are NOT affected:
-- - Other brands
-- - Stores (unless only linked via brand_stores)
-- - Users
-- - Any other unrelated tables
