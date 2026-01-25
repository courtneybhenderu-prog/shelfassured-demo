-- Safe query to check DJ's Boudain stores (works regardless of column names)
-- Run this in Supabase SQL editor

-- First, let's check what columns exist in the stores table
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'stores' 
  AND table_schema = 'public'
  AND column_name IN ('STORE', 'store', 'name')
ORDER BY column_name;

-- Quick count and list of stores (using name column which should always exist)
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

-- Detailed list of all stores (using name column)
SELECT 
    b.name as brand_name,
    s.id as store_id,
    s.name as store_name,
    s.address,
    s.city,
    s.state,
    s.zip_code,
    rb.name as banner_name,
    bs.source as link_source,
    bs.created_at as linked_at
FROM brands b
INNER JOIN brand_stores bs ON bs.brand_id = b.id
INNER JOIN stores s ON s.id = bs.store_id
LEFT JOIN retailer_banners rb ON rb.id = s.banner_id
WHERE LOWER(b.name) LIKE '%dj%' 
   OR LOWER(b.name) LIKE '%boudain%'
   OR LOWER(b.name) LIKE '%boudin%'
ORDER BY s.state, s.city, s.name;

-- Summary with store locations grouped by state/city
SELECT 
    s.state,
    s.city,
    COUNT(*) as store_count,
    STRING_AGG(s.name, ', ' ORDER BY s.name) as store_names
FROM brands b
INNER JOIN brand_stores bs ON bs.brand_id = b.id
INNER JOIN stores s ON s.id = bs.store_id
WHERE LOWER(b.name) LIKE '%dj%' 
   OR LOWER(b.name) LIKE '%boudain%'
   OR LOWER(b.name) LIKE '%boudin%'
GROUP BY s.state, s.city
ORDER BY s.state, s.city;
