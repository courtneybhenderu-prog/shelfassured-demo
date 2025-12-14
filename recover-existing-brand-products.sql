-- Recover and Link Existing Products to Brands
-- This script finds products that were saved during development
-- and links them to brands via the brand_products junction table
-- Run this AFTER create-brand-products-stores-relations.sql

BEGIN;

-- Step 1: Verify products exist with old structure
-- Check if products have 'brand' column (text) or 'brand_id' column
DO $$
DECLARE
    has_brand_text BOOLEAN;
    has_brand_id_col BOOLEAN;
    product_count INTEGER;
BEGIN
    -- Check for brand text column
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    ) INTO has_brand_text;
    
    -- Check for brand_id column (new structure)
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand_id'
    ) INTO has_brand_id_col;
    
    -- Count products
    SELECT COUNT(*) INTO product_count FROM products;
    
    RAISE NOTICE 'Products with brand (text): %', has_brand_text;
    RAISE NOTICE 'Products with brand_id: %', has_brand_id_col;
    RAISE NOTICE 'Total products: %', product_count;
END $$;

-- Step 2: Link products to brands based on brand name matching
-- This creates brand_products entries for products that have a brand name but no brand_products link
INSERT INTO brand_products (brand_id, product_id, product_label, created_at)
SELECT DISTINCT
    b.id as brand_id,
    p.id as product_id,
    NULL as product_label,  -- Can set product_label if needed
    p.created_at
FROM products p
JOIN brands b ON LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
LEFT JOIN brand_products bp ON bp.brand_id = b.id AND bp.product_id = p.id
WHERE 
    -- Only if products have 'brand' column (text field)
    EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL 
    AND TRIM(p.brand) != ''
    -- Only link if not already linked
    AND bp.id IS NULL
ON CONFLICT (brand_id, product_id) DO NOTHING;

-- Step 3: Report results
DO $$
DECLARE
    linked_count INTEGER;
    orphaned_count INTEGER;
BEGIN
    -- Count newly linked products
    SELECT COUNT(*) INTO linked_count
    FROM brand_products;
    
    -- Count products with brand name but no matching brand
    SELECT COUNT(*) INTO orphaned_count
    FROM products p
    WHERE EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL
    AND TRIM(p.brand) != ''
    AND NOT EXISTS (
        SELECT 1 FROM brands b 
        WHERE LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
    )
    AND NOT EXISTS (
        SELECT 1 FROM brand_products bp WHERE bp.product_id = p.id
    );
    
    RAISE NOTICE '✅ Successfully linked products: %', linked_count;
    IF orphaned_count > 0 THEN
        RAISE NOTICE '⚠️ Products with brand names that dont match any brand: %', orphaned_count;
        RAISE NOTICE 'Review these products and brands manually to create links';
    END IF;
END $$;

COMMIT;

-- Step 4: Verification queries (run separately to review)
-- 
-- See all products and their brand links:
-- SELECT 
--     p.id,
--     p.name,
--     p.barcode as old_barcode,
--     p.sku,
--     p.brand as old_brand_text,
--     b.name as linked_brand_name,
--     bp.product_label
-- FROM products p
-- LEFT JOIN brand_products bp ON bp.product_id = p.id
-- LEFT JOIN brands b ON b.id = bp.brand_id
-- ORDER BY p.created_at DESC;
--
-- Find orphaned products (brand text but no brand match):
-- SELECT DISTINCT
--     p.brand as brand_name,
--     COUNT(*) as product_count
-- FROM products p
-- WHERE EXISTS (
--     SELECT 1 FROM information_schema.columns 
--     WHERE table_name = 'products' AND column_name = 'brand'
-- )
-- AND p.brand IS NOT NULL
-- AND TRIM(p.brand) != ''
-- AND NOT EXISTS (
--     SELECT 1 FROM brands b 
--     WHERE LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
-- )
-- GROUP BY p.brand
-- ORDER BY product_count DESC;
--
-- Check brand_products links:
-- SELECT 
--     b.name as brand_name,
--     COUNT(bp.product_id) as linked_products
-- FROM brands b
-- LEFT JOIN brand_products bp ON bp.brand_id = b.id
-- GROUP BY b.id, b.name
-- ORDER BY linked_products DESC;


