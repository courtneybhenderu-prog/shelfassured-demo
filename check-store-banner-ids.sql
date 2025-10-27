-- Check if stores with specific locations have banner_id

-- 1. Check Bridgeland specifically
SELECT id, name, banner_id, city, state, zip_code, banner, store_chain
FROM stores 
WHERE UPPER(city) LIKE '%BRIDGELAND%' OR UPPER(name) LIKE '%BRIDGELAND%'
LIMIT 10;

-- 2. Check Austin H-E-B stores
SELECT id, name, banner_id, city, state, banner, store_chain
FROM stores 
WHERE UPPER(city) LIKE '%AUSTIN%' 
  AND (UPPER(name) LIKE '%H%E%B%' OR UPPER(banner) LIKE '%H%E%B%' OR UPPER(store_chain) LIKE '%H%E%B%')
  AND banner_id IS NOT NULL
LIMIT 10;

-- 3. Check Austin Sprouts stores
SELECT id, name, banner_id, city, state, banner, store_chain
FROM stores 
WHERE UPPER(city) LIKE '%AUSTIN%' 
  AND (UPPER(name) LIKE '%SPROUTS%' OR UPPER(banner) LIKE '%SPROUTS%' OR UPPER(store_chain) LIKE '%SPROUTS%')
  AND banner_id IS NOT NULL
LIMIT 10;

