-- Find all Callie's Hot Little Biscuit products to see which one is missing from the array

-- All products with Callie's brand
SELECT 
    p.id,
    p.brand,
    p.name as product_name,
    p.sku,
    p.created_at,
    bp.id as brand_product_link_id
FROM products p
LEFT JOIN brand_products bp ON bp.product_id = p.id
WHERE p.brand LIKE '%Callie%'
ORDER BY p.created_at;

-- Count products by brand value
SELECT 
    brand,
    COUNT(*) as count,
    array_agg(id ORDER BY created_at) as all_product_ids
FROM products
WHERE brand LIKE '%Callie%'
GROUP BY brand;


