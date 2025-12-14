-- Complete Status: All Brands and Their Products
-- Shows which brands have products linked and which don't

-- Step 1: Show all brands and their product counts
SELECT 
    b.id,
    b.name as brand_name,
    COUNT(bp.product_id) as linked_products_count,
    CASE 
        WHEN COUNT(bp.product_id) > 0 THEN '✅ Has products'
        ELSE '⚠️ No products linked'
    END as status
FROM brands b
LEFT JOIN brand_products bp ON bp.brand_id = b.id
GROUP BY b.id, b.name
ORDER BY linked_products_count DESC, b.name;

-- Step 2: Show products in products table by brand name
-- (from barcode scanner, may or may not be linked)
SELECT 
    p.brand as scanner_brand_name,
    COUNT(*) as product_count_in_products_table,
    COUNT(bp.id) as linked_via_brand_products
FROM products p
LEFT JOIN brands b ON LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
LEFT JOIN brand_products bp ON bp.brand_id = b.id AND bp.product_id = p.id
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL
AND TRIM(p.brand) != ''
GROUP BY p.brand
ORDER BY product_count_in_products_table DESC;

-- Step 3: Brands with NO products at all (from any source)
SELECT 
    b.id,
    b.name as brand_name,
    'No products in products table or brand_products' as reason
FROM brands b
LEFT JOIN brand_products bp ON bp.brand_id = b.id
WHERE bp.id IS NULL
AND NOT EXISTS (
    -- Check if any products in products table have this brand name
    SELECT 1 FROM products p
    WHERE EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'brand'
    )
    AND p.brand IS NOT NULL
    AND LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
)
ORDER BY b.name;

-- Step 4: Cross-reference - brands table vs products table
SELECT 
    'Brands in brands table' as source,
    COUNT(*) as count
FROM brands
UNION ALL
SELECT 
    'Distinct brand names in products table' as source,
    COUNT(DISTINCT p.brand)
FROM products p
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL;


