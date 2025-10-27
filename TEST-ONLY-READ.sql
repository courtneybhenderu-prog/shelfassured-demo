-- TEST ONLY - Does not make changes, just shows what would happen
-- Run this FIRST to preview results

-- 1. Show what retailers exist
SELECT 'Existing Retailers' as info, name FROM retailers ORDER BY name;

-- 2. Show what banners exist  
SELECT rb.name as banner_name, r.name as parent_retailer
FROM retailer_banners rb
JOIN retailers r ON r.id = rb.retailer_id
ORDER BY rb.name;

-- 3. Show stores WITHOUT banner_id (what would be linked)
SELECT 
  COALESCE(banner, store_chain, 'Unknown') as store_name,
  COUNT(*) as stores_to_link
FROM stores
WHERE banner_id IS NULL AND is_active = true
GROUP BY store_name
ORDER BY stores_to_link DESC
LIMIT 20;

-- 4. Show sample matches that would be created
SELECT 
  COALESCE(s.banner, s.store_chain) as current_store_name,
  rb.name as would_match_to_banner,
  COUNT(*) as store_count
FROM stores s
CROSS JOIN retailer_banners rb
WHERE s.banner_id IS NULL 
  AND s.is_active = true
  AND (
    UPPER(REGEXP_REPLACE(COALESCE(s.banner, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
    OR
    UPPER(REGEXP_REPLACE(COALESCE(s.store_chain, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
  )
GROUP BY current_store_name, rb.name
ORDER BY store_count DESC
LIMIT 20;

