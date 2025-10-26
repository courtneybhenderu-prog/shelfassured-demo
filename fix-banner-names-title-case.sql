-- Fix banner names to be title case and correct H-E-B
-- Run this in Supabase SQL Editor

-- 1. Update HEB to H-E-B in retailer_banners
UPDATE retailer_banners
SET name = 'H-E-B'
WHERE UPPER(name) IN ('HEB', 'H-E-B', 'H E B');

-- 2. Update names to title case (Albertsons not ALBERTSONS)
UPDATE retailer_banners
SET name = INITCAP(name);

-- Verify the updates
SELECT id, name as banner_name, 
  (SELECT name FROM retailers WHERE id = retailer_banners.retailer_id) as parent
FROM retailer_banners
ORDER BY name;

