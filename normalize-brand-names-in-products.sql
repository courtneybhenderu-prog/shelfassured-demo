-- Normalize Brand Names in Products Table
-- Fixes cases like "Callie's Hot Little Biscuit" appearing twice
-- by normalizing whitespace and consolidating to canonical brand names

BEGIN;

-- Step 1: Identify brand name variations in products table
-- Show products with similar brand names that should match
SELECT 
    brand as raw_brand_name,
    TRIM(brand) as trimmed_brand_name,
    COUNT(*) as product_count,
    array_agg(id ORDER BY created_at) as product_ids  -- Removed LIMIT - show all
FROM products
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND brand IS NOT NULL
GROUP BY brand, TRIM(brand)
ORDER BY product_count DESC;

-- Step 2: Normalize brand names 
-- - Normalize apostrophes: curly apostrophe (U+2019) to straight apostrophe (')
-- - Trim whitespace
-- - Collapse multiple spaces
-- This consolidates "Callie's Hot Little Biscuit" vs "Callie's Hot Little Biscuit"
-- Normalize apostrophes, tabs, and collapse spaces
UPDATE products
SET brand = TRIM(
    REPLACE(
        REPLACE(
            REPLACE(brand, CHR(8217), CHR(39)),
            CHR(9), ' '
        ),
        '  ', ' '
    )
)
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND brand IS NOT NULL
AND brand != TRIM(
    REPLACE(
        REPLACE(
            REPLACE(brand, CHR(8217), CHR(39)),
            CHR(9), ' '
        ),
        '  ', ' '
    )
);

-- Step 3: Link all normalized products to their brands
-- Re-run the linking logic after normalization
INSERT INTO brand_products (brand_id, product_id, created_at)
SELECT DISTINCT
    b.id as brand_id,
    p.id as product_id,
    p.created_at
FROM products p
JOIN brands b ON LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
LEFT JOIN brand_products bp ON bp.brand_id = b.id AND bp.product_id = p.id
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL 
AND TRIM(p.brand) != ''
AND bp.id IS NULL  -- Only link if not already linked
ON CONFLICT (brand_id, product_id) DO NOTHING;

-- Step 4: Report results
DO $$
DECLARE
    normalized_count INTEGER;
    linked_count INTEGER;
    still_orphaned INTEGER;
BEGIN
    -- Count how many brand names were normalized
    SELECT COUNT(DISTINCT TRIM(
        REPLACE(
            REPLACE(
                REPLACE(brand, CHR(8217), CHR(39)),
                CHR(9), ' '
            ),
            '  ', ' '
        )
    )) 
    INTO normalized_count
    FROM products
    WHERE EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND brand IS NOT NULL;
    
    -- Count linked products
    SELECT COUNT(*) INTO linked_count FROM brand_products;
    
    -- Count products still not linked
    SELECT COUNT(*) INTO still_orphaned
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
    
    RAISE NOTICE '✅ Brand names normalized';
    RAISE NOTICE '✅ Products linked to brands: %', linked_count;
    
    IF still_orphaned > 0 THEN
        RAISE NOTICE '⚠️ % products still not linked (brand names may not match)', still_orphaned;
    END IF;
END $$;

COMMIT;

-- Verification: After running, check if brand names are consolidated
-- SELECT 
--     brand as brand_name,
--     COUNT(*) as product_count
-- FROM products
-- WHERE brand IS NOT NULL
-- GROUP BY brand
-- ORDER BY product_count DESC;

