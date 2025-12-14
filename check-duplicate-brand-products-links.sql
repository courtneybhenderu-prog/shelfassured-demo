-- Check for duplicate brand_products links (same product linked to same brand multiple times)
-- This shouldn't happen due to unique constraint, but let's verify

SELECT 
    brand_id,
    product_id,
    COUNT(*) as link_count,
    b.name as brand_name,
    p.name as product_name,
    p.sku,
    array_agg(bp.id ORDER BY bp.created_at) as link_ids
FROM brand_products bp
JOIN brands b ON b.id = bp.brand_id
JOIN products p ON p.id = bp.product_id
GROUP BY brand_id, product_id, b.name, p.name, p.sku
HAVING COUNT(*) > 1;


