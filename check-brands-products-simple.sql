-- Simple step-by-step diagnostics
-- Run these queries ONE AT A TIME to see results

-- Query 1: Just count brands
SELECT COUNT(*) as total_brands FROM brands;

-- Query 2: List all brands
SELECT id, name FROM brands ORDER BY name;

-- Query 3: Count products linked via brand_products
SELECT COUNT(*) as total_brand_product_links FROM brand_products;

-- Query 4: Brands with their linked product counts
SELECT 
    b.name as brand_name,
    COUNT(bp.product_id) as linked_products
FROM brands b
LEFT JOIN brand_products bp ON bp.brand_id = b.id
GROUP BY b.id, b.name
ORDER BY linked_products DESC, b.name;

-- Query 5: Check if products table has 'brand' column
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- Query 6: If 'brand' column exists, show products by brand name
SELECT 
    brand as scanner_brand_name,
    COUNT(*) as product_count
FROM products
WHERE brand IS NOT NULL
GROUP BY brand
ORDER BY product_count DESC;


