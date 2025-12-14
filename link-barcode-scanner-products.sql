-- Link Products from Barcode Scanner to Brands via brand_products
-- These products have 'brand' text field but aren't linked yet

BEGIN;

-- Step 1: Show what we're working with
-- Products with brand names (from barcode scanner)
SELECT 
    'Products with brand names' as info,
    COUNT(*) as count
FROM products
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND brand IS NOT NULL 
AND TRIM(brand) != '';

-- Step 2: Attempt to link products to brands
-- Match by exact brand name (case-insensitive)
INSERT INTO brand_products (brand_id, product_id, created_at)
SELECT DISTINCT
    b.id as brand_id,
    p.id as product_id,
    p.created_at
FROM products p
JOIN brands b ON LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
LEFT JOIN brand_products bp ON bp.brand_id = b.id AND bp.product_id = p.id
WHERE 
    EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL 
    AND TRIM(p.brand) != ''
    -- Only link if not already linked
    AND bp.id IS NULL
ON CONFLICT (brand_id, product_id) DO NOTHING;

-- Step 3: Show results
DO $$
DECLARE
    linked_count INTEGER;
    total_products INTEGER;
    orphaned_count INTEGER;
    brands_found TEXT[];
BEGIN
    -- Count linked products
    SELECT COUNT(*) INTO linked_count FROM brand_products;
    
    -- Count total products with brand names
    SELECT COUNT(*) INTO total_products
    FROM products p
    WHERE EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL
    AND TRIM(p.brand) != '';
    
    -- Find orphaned products (brand names that don't match any brand)
    SELECT COUNT(*), array_agg(DISTINCT p.brand)
    INTO orphaned_count, brands_found
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
    
    RAISE NOTICE '✅ Total products with brand names: %', total_products;
    RAISE NOTICE '✅ Successfully linked products: %', linked_count;
    
    IF orphaned_count > 0 THEN
        RAISE NOTICE '⚠️ Orphaned products (brand names not found): %', orphaned_count;
        RAISE NOTICE '⚠️ Unmatched brand names: %', array_to_string(brands_found, ', ');
        RAISE NOTICE '💡 Create these brands or fix brand name typos to link products';
    END IF;
END $$;

COMMIT;

-- Step 4: Show detailed results (run separately)
-- See all products and their link status
SELECT 
    p.id,
    p.name as product_name,
    p.brand as scanner_brand_name,
    p.barcode,
    p.sku,
    b.name as linked_brand_name,
    CASE 
        WHEN bp.id IS NOT NULL THEN '✅ Linked'
        WHEN b.id IS NULL THEN '❌ Brand not found'
        ELSE '⚠️ Not linked'
    END as link_status
FROM products p
LEFT JOIN brands b ON LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
LEFT JOIN brand_products bp ON bp.brand_id = b.id AND bp.product_id = p.id
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL
ORDER BY link_status, p.brand, p.name
LIMIT 50;


