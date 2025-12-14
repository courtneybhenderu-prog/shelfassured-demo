-- Diagnostic: Check what's actually in the products table
-- Run this to see what products exist and their structure

-- 1. Check what columns exist in products table
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Count total products
SELECT COUNT(*) as total_products FROM products;

-- 3. Sample products (first 10 rows)
SELECT * FROM products 
ORDER BY created_at DESC NULLS LAST 
LIMIT 10;

-- 4. Check if products have 'brand' column (text field) or 'brand_id' column
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'brand') 
        THEN 'Has brand (text) column'
        ELSE 'No brand (text) column'
    END as brand_column_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'brand_id') 
        THEN 'Has brand_id column'
        ELSE 'No brand_id column'
    END as brand_id_column_status;

-- 5. If brand column exists, show distinct brand names
SELECT 
    brand as brand_name,
    COUNT(*) as product_count
FROM products
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND brand IS NOT NULL
GROUP BY brand
ORDER BY product_count DESC;

-- 6. Check existing brand_products links
SELECT COUNT(*) as existing_links FROM brand_products;

-- 7. Products that could be linked (if brand column exists)
SELECT 
    p.id,
    p.name,
    p.brand,
    p.barcode,
    p.sku,
    CASE 
        WHEN EXISTS (SELECT 1 FROM brands b WHERE LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))) 
        THEN 'Brand exists - can link'
        ELSE 'Brand not found'
    END as link_status
FROM products p
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'brand'
)
AND p.brand IS NOT NULL
LIMIT 20;


