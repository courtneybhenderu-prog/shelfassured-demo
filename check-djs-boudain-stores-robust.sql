-- Robust query to check DJ's Boudain stores (handles missing columns gracefully)
-- Run this in Supabase SQL editor

-- Step 1: Find the brand ID for DJ's Boudain
SELECT 
    id,
    name,
    created_at
FROM brands
WHERE LOWER(name) LIKE '%dj%' 
   OR LOWER(name) LIKE '%boudain%'
   OR LOWER(name) LIKE '%boudin%'
ORDER BY name;

-- Step 2: Count stores for DJ's Boudain
WITH brand_info AS (
    SELECT id, name
    FROM brands
    WHERE LOWER(name) LIKE '%dj%' 
       OR LOWER(name) LIKE '%boudain%'
       OR LOWER(name) LIKE '%boudin%'
    LIMIT 1
)
SELECT 
    bi.name as brand_name,
    COUNT(bs.id) as total_stores,
    COUNT(DISTINCT bs.store_id) as unique_stores
FROM brand_info bi
LEFT JOIN brand_stores bs ON bs.brand_id = bi.id
GROUP BY bi.id, bi.name;

-- Step 3: List all stores for DJ's Boudain with details (safe version)
WITH brand_info AS (
    SELECT id, name
    FROM brands
    WHERE LOWER(name) LIKE '%dj%' 
       OR LOWER(name) LIKE '%boudain%'
       OR LOWER(name) LIKE '%boudin%'
    LIMIT 1
)
SELECT 
    bi.name as brand_name,
    s.id as store_id,
    s.name as store_name,
    s.address,
    s.city,
    s.state,
    s.zip_code,
    rb.name as banner_name,
    bs.created_at as linked_at
FROM brand_info bi
INNER JOIN brand_stores bs ON bs.brand_id = bi.id
INNER JOIN stores s ON s.id = bs.store_id
LEFT JOIN retailer_banners rb ON rb.id = s.banner_id
ORDER BY s.name, s.city, s.state;

-- Step 4: Summary with store locations grouped by state/city
WITH brand_info AS (
    SELECT id, name
    FROM brands
    WHERE LOWER(name) LIKE '%dj%' 
       OR LOWER(name) LIKE '%boudain%'
       OR LOWER(name) LIKE '%boudin%'
    LIMIT 1
)
SELECT 
    s.state,
    s.city,
    COUNT(*) as store_count,
    STRING_AGG(s.name, ', ' ORDER BY s.name) as store_names
FROM brand_info bi
INNER JOIN brand_stores bs ON bs.brand_id = bi.id
INNER JOIN stores s ON s.id = bs.store_id
GROUP BY s.state, s.city
ORDER BY s.state, s.city;
