-- Debug why H-E-B stores aren't linking

-- 1. Check what H-E-B is named in retailer_banners
SELECT id, name FROM retailer_banners WHERE name LIKE '%H%';

-- 2. Check what stores have for H-E-B
SELECT DISTINCT banner, store_chain, COUNT(*) 
FROM stores 
WHERE UPPER(COALESCE(banner, '')) LIKE '%H%' 
   OR UPPER(COALESCE(store_chain, '')) LIKE '%H%'
GROUP BY banner, store_chain
ORDER BY COUNT(*) DESC;

-- 3. Check if any H-E-B stores got banner_id
SELECT COUNT(*) as heb_stores_with_banner_id
FROM stores 
WHERE banner_id IN (
  SELECT id FROM retailer_banners WHERE UPPER(name) LIKE '%H%'
);

-- 4. Manual test: try to match "HEB" to banners
SELECT 
  s.id,
  s.name,
  s.banner,
  s.store_chain,
  rb.id as banner_id,
  rb.name as banner_name
FROM stores s
CROSS JOIN retailer_banners rb
WHERE UPPER(COALESCE(s.banner, '')) LIKE '%H%'
  AND (UPPER(TRIM(rb.name)) = 'HEB' OR UPPER(TRIM(rb.name)) = 'H-E-B')
LIMIT 5;

