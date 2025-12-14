-- Check if Primal Kitchen brand exists and has products linked
-- Run this in Supabase SQL Editor

-- 1. Find Primal Kitchen brand
SELECT id, name, website, created_at
FROM brands
WHERE LOWER(name) LIKE '%primal%kitchen%' OR LOWER(name) LIKE '%primal kitchen%'
ORDER BY created_at DESC;

-- 2. Check products linked to Primal Kitchen (replace BRAND_ID with actual ID from above)
SELECT 
    bp.id as brand_product_id,
    bp.brand_id,
    bp.product_id,
    bp.product_label,
    p.id as product_id,
    p.name as product_name,
    p.sku,
    p.upc
FROM brand_products bp
LEFT JOIN products p ON p.id = bp.product_id
WHERE bp.brand_id = (
    SELECT id FROM brands 
    WHERE LOWER(name) LIKE '%primal%kitchen%' OR LOWER(name) LIKE '%primal kitchen%'
    ORDER BY created_at DESC
    LIMIT 1
);

-- 3. Check total products in brand_products for Primal Kitchen
SELECT 
    COUNT(*) as total_linked_products,
    COUNT(DISTINCT product_id) as unique_products
FROM brand_products
WHERE brand_id = (
    SELECT id FROM brands 
    WHERE LOWER(name) LIKE '%primal%kitchen%' OR LOWER(name) LIKE '%primal kitchen%'
    ORDER BY created_at DESC
    LIMIT 1
);

-- 4. Check RLS policies on brand_products (should allow SELECT for authenticated)
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'brand_products'
ORDER BY policyname;


