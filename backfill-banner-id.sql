-- Backfill banner_id for all stores
-- This matches stores to retailer_banners based on banner/store_chain values

-- Update stores to link banner_id based on existing banner/store_chain values
-- Handle normalized matching (HEB = H-E-B, remove hyphens/spaces for comparison)

WITH normalized_banners AS (
  SELECT 
    s.id as store_id,
    rb.id as banner_id,
    rb.name as banner_name
  FROM stores s
  CROSS JOIN retailer_banners rb
  WHERE s.banner_id IS NULL AND s.is_active = true
  AND (
    -- Direct match
    UPPER(REGEXP_REPLACE(COALESCE(s.banner, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
    OR
    UPPER(REGEXP_REPLACE(COALESCE(s.store_chain, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
    OR
    -- Fuzzy match
    UPPER(REGEXP_REPLACE(COALESCE(s.banner, ''), '[^A-Z0-9]', '', 'g')) LIKE 
    '%' || UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g')) || '%'
    OR
    UPPER(REGEXP_REPLACE(COALESCE(s.store_chain, ''), '[^A-Z0-9]', '', 'g')) LIKE 
    '%' || UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g')) || '%'
  )
)
UPDATE stores s
SET banner_id = nb.banner_id
FROM normalized_banners nb
WHERE s.id = nb.store_id;

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

