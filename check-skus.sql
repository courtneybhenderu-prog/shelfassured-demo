-- Check for default SKUs in the database
SELECT 
    s.id,
    s.name,
    s.upc,
    s.brand_id,
    b.name as brand_name
FROM skus s
LEFT JOIN brands b ON s.brand_id = b.id
WHERE s.name ILIKE '%soda%' OR s.name ILIKE '%default%'
ORDER BY s.created_at DESC;

-- Check recent SKUs
SELECT 
    s.id,
    s.name,
    s.upc,
    s.brand_id,
    b.name as brand_name,
    s.created_at
FROM skus s
LEFT JOIN brands b ON s.brand_id = b.id
ORDER BY s.created_at DESC
LIMIT 10;
