-- Backfill banner_id for all stores
-- This matches stores to retailer_banners based on banner/store_chain values

-- Update stores to link banner_id based on existing banner/store_chain values
UPDATE stores s
SET banner_id = rb.id
FROM retailer_banners rb
WHERE 
  s.banner_id IS NULL
  AND (
    UPPER(TRIM(COALESCE(s.banner, ''))) = UPPER(TRIM(rb.name))
    OR UPPER(TRIM(COALESCE(s.store_chain, ''))) = UPPER(TRIM(rb.name))
    OR UPPER(TRIM(COALESCE(s.banner, ''))) LIKE '%' || UPPER(TRIM(rb.name)) || '%'
    OR UPPER(TRIM(COALESCE(s.store_chain, ''))) LIKE '%' || UPPER(TRIM(rb.name)) || '%'
  )
  AND s.is_active = true;

-- Report progress
SELECT 
  'Stores with banner_id' as status,
  COUNT(*) as count 
FROM stores 
WHERE banner_id IS NOT NULL AND is_active = true
UNION ALL
SELECT 
  'Stores without banner_id',
  COUNT(*)
FROM stores
WHERE banner_id IS NULL AND is_active = true;

-- Show banner breakdown
SELECT 
  rb.name AS banner_name,
  COUNT(*) AS store_count
FROM stores s
JOIN retailer_banners rb ON rb.id = s.banner_id
WHERE s.is_active = true
GROUP BY rb.name
ORDER BY store_count DESC;

