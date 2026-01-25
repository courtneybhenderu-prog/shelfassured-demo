-- Simple query to check DJ's Boudain stores
-- Run this in Supabase SQL editor

-- Quick count and list of stores
SELECT 
    b.name as brand_name,
    COUNT(bs.id) as total_stores,
    COUNT(DISTINCT bs.store_id) as unique_stores
FROM brands b
LEFT JOIN brand_stores bs ON bs.brand_id = b.id
WHERE LOWER(b.name) LIKE '%dj%' 
   OR LOWER(b.name) LIKE '%boudain%'
   OR LOWER(b.name) LIKE '%boudin%'
GROUP BY b.id, b.name;

-- Detailed list of all stores
SELECT 
    b.name as brand_name,
    s.name as store_name,
    s.address,
    s.city,
    s.state,
    s.zip_code,
    rb.name as banner_name,
    bs.source as link_source
FROM brands b
INNER JOIN brand_stores bs ON bs.brand_id = b.id
INNER JOIN stores s ON s.id = bs.store_id
LEFT JOIN retailer_banners rb ON rb.id = s.banner_id
WHERE LOWER(b.name) LIKE '%dj%' 
   OR LOWER(b.name) LIKE '%boudain%'
   OR LOWER(b.name) LIKE '%boudin%'
ORDER BY s.state, s.city, s.name;
