-- Fix Orphaned Barcode Scanner Products
-- Identifies products with brand names that don't match existing brands
-- Provides options to either create missing brands or normalize brand names

BEGIN;

-- Step 1: Show all orphaned products (brand names that don't match)
SELECT 
    p.brand as scanner_brand_name,
    COUNT(*) as product_count,
    array_agg(p.name ORDER BY p.name LIMIT 3) as sample_products
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
)
GROUP BY p.brand
ORDER BY product_count DESC;

-- Step 2: Try fuzzy matching (common variations)
-- This attempts to match with slight differences (case, punctuation, etc.)
INSERT INTO brand_products (brand_id, product_id, created_at)
SELECT DISTINCT
    b.id as brand_id,
    p.id as product_id,
    p.created_at
FROM products p
JOIN brands b ON 
    -- Exact match (already tried, but include for completeness)
    LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
    OR
    -- Common variations:
    -- Remove common suffixes/prefixes
    LOWER(REPLACE(REPLACE(REPLACE(TRIM(p.brand), ' inc', ''), ' llc', ''), ',', '')) = 
    LOWER(REPLACE(REPLACE(REPLACE(TRIM(b.name), ' inc', ''), ' llc', ''), ',', ''))
    OR
    -- Match if one contains the other (for partial matches)
    LOWER(TRIM(b.name)) LIKE '%' || LOWER(TRIM(p.brand)) || '%'
    OR LOWER(TRIM(p.brand)) LIKE '%' || LOWER(TRIM(b.name)) || '%'
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

-- Step 3: For truly unmatched brands, create them automatically
-- (Optional - comment out if you prefer manual creation)
INSERT INTO brands (name, created_at)
SELECT DISTINCT
    p.brand as name,
    MIN(p.created_at) as created_at
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
GROUP BY p.brand
ON CONFLICT (name) DO NOTHING;

-- Step 4: Link products to newly created brands
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

-- Step 5: Report final status
DO $$
DECLARE
    linked_count INTEGER;
    orphaned_count INTEGER;
    brands_created INTEGER;
BEGIN
    -- Count total linked products
    SELECT COUNT(*) INTO linked_count FROM brand_products;
    
    -- Count still-orphaned products
    SELECT COUNT(*) INTO orphaned_count
    FROM products p
    WHERE EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL
    AND TRIM(p.brand) != ''
    AND NOT EXISTS (
        SELECT 1 FROM brand_products bp WHERE bp.product_id = p.id
    );
    
    -- Count brands created in this run
    SELECT COUNT(*) INTO brands_created
    FROM brands
    WHERE created_at >= NOW() - INTERVAL '1 minute';
    
    RAISE NOTICE '✅ Total products linked: %', linked_count;
    
    IF brands_created > 0 THEN
        RAISE NOTICE '✅ Brands auto-created: %', brands_created;
    END IF;
    
    IF orphaned_count > 0 THEN
        RAISE NOTICE '⚠️ Still orphaned (need manual review): %', orphaned_count;
    ELSE
        RAISE NOTICE '🎉 All products successfully linked!';
    END IF;
END $$;

COMMIT;

-- Step 6: Manual review query (run separately if needed)
-- Shows products that still need manual linking
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.brand as scanner_brand_name,
    p.barcode,
    p.sku,
    'Needs manual brand creation or name normalization' as action_needed
FROM products p
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL
AND TRIM(p.brand) != ''
AND NOT EXISTS (
    SELECT 1 FROM brand_products bp WHERE bp.product_id = p.id
)
ORDER BY p.brand, p.name;


