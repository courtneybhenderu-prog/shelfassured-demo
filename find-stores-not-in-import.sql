-- ========================================
-- Find stores that exist in stores table but NOT in stores_import table
-- These are stores that would be marked as inactive during reconciliation
-- ========================================

-- Method 1: Using match_key (most accurate - what the reconciliation script uses)
SELECT 
    'STORES NOT IN IMPORT (by match_key)' as search_type,
    s.id,
    s."STORE",
    s.name,
    s.banner,
    s.address,
    s.city,
    s.state,
    s.zip_code,
    s.zip5,
    s.is_active,
    s.match_key,
    s.created_at,
    s.updated_at
FROM stores s
WHERE s.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM stores_import si 
      WHERE si.match_key = s.match_key
        AND si.match_key IS NOT NULL
  )
ORDER BY s.created_at DESC;

-- Method 2: Count summary
SELECT 
    'SUMMARY: STORES NOT IN IMPORT' as info,
    COUNT(*) as total_stores_not_in_import,
    COUNT(*) FILTER (WHERE is_active = TRUE) as currently_active,
    COUNT(*) FILTER (WHERE is_active = FALSE) as currently_inactive,
    COUNT(*) FILTER (WHERE match_key IS NULL) as stores_without_match_key
FROM stores s
WHERE NOT EXISTS (
    SELECT 1 
    FROM stores_import si 
    WHERE si.match_key = s.match_key
      AND si.match_key IS NOT NULL
)
OR s.match_key IS NULL;

-- Method 3: Grouped by banner/chain
SELECT 
    'STORES NOT IN IMPORT - BY BANNER' as info,
    COALESCE(s.banner, s."STORE", s.name) as banner_name,
    COUNT(*) as store_count,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_count,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_count
FROM stores s
WHERE s.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM stores_import si 
      WHERE si.match_key = s.match_key
        AND si.match_key IS NOT NULL
  )
GROUP BY COALESCE(s.banner, s."STORE", s.name)
ORDER BY store_count DESC;

-- Method 4: Grouped by state
SELECT 
    'STORES NOT IN IMPORT - BY STATE' as info,
    s.state,
    COUNT(*) as store_count,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_count,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_count
FROM stores s
WHERE s.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM stores_import si 
      WHERE si.match_key = s.match_key
        AND si.match_key IS NOT NULL
  )
GROUP BY s.state
ORDER BY store_count DESC;

-- Method 5: Stores without match_key (can't be matched)
SELECT 
    'STORES WITHOUT MATCH_KEY (cannot be matched)' as info,
    s.id,
    s."STORE",
    s.banner,
    s.address,
    s.city,
    s.state,
    s.zip_code,
    s.is_active
FROM stores s
WHERE s.match_key IS NULL
ORDER BY s.created_at DESC;

-- Method 6: Sample of stores not in import (first 50)
SELECT 
    'SAMPLE: STORES NOT IN IMPORT (first 50)' as info,
    s."STORE",
    s.banner,
    s.city,
    s.state,
    s.zip_code,
    s.is_active,
    s.match_key
FROM stores s
WHERE s.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM stores_import si 
      WHERE si.match_key = s.match_key
        AND si.match_key IS NOT NULL
  )
ORDER BY s."STORE"
LIMIT 50;

