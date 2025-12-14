-- ========================================
-- Compare stores table vs stores_import table
-- Shows differences in data, structure, and content
-- ========================================

-- 1. Count comparison
SELECT 
    'COUNT COMPARISON' as comparison_type,
    (SELECT COUNT(*) FROM stores) as stores_table_count,
    (SELECT COUNT(*) FROM stores_import) as stores_import_count,
    (SELECT COUNT(*) FROM stores WHERE is_active = TRUE) as stores_active,
    (SELECT COUNT(*) FROM stores WHERE is_active = FALSE) as stores_inactive,
    (SELECT COUNT(*) FROM stores_import 
     WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
        OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '')) as import_with_data;

-- 2. Column structure comparison
SELECT 
    'COLUMN STRUCTURE' as comparison_type,
    'stores' as table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'COLUMN STRUCTURE' as comparison_type,
    'stores_import' as table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

-- 3. Banner comparison (what banners exist in each)
SELECT 
    'BANNER COMPARISON' as comparison_type,
    'stores' as source,
    COUNT(DISTINCT COALESCE(banner, "STORE", name)) as unique_banners,
    COUNT(DISTINCT banner_norm) as unique_normalized_banners
FROM stores
WHERE banner_norm IS NOT NULL;

SELECT 
    'BANNER COMPARISON' as comparison_type,
    'stores_import' as source,
    COUNT(DISTINCT "BANNER") as unique_banners,
    COUNT(DISTINCT banner_norm) as unique_normalized_banners
FROM stores_import
WHERE banner_norm IS NOT NULL;

-- 4. Top banners in each table
SELECT 
    'TOP BANNERS - stores' as info,
    COALESCE(banner, "STORE", name) as banner_name,
    banner_norm,
    COUNT(*) as store_count
FROM stores
WHERE banner_norm IS NOT NULL
GROUP BY COALESCE(banner, "STORE", name), banner_norm
ORDER BY store_count DESC
LIMIT 10;

SELECT 
    'TOP BANNERS - stores_import' as info,
    "BANNER" as banner_name,
    banner_norm,
    COUNT(*) as import_count
FROM stores_import
WHERE banner_norm IS NOT NULL
GROUP BY "BANNER", banner_norm
ORDER BY import_count DESC
LIMIT 10;

-- 5. State comparison
SELECT 
    'STATE COMPARISON' as comparison_type,
    'stores' as source,
    state_norm as state,
    COUNT(*) as count
FROM stores
WHERE state_norm IS NOT NULL
GROUP BY state_norm
ORDER BY count DESC;

SELECT 
    'STATE COMPARISON' as comparison_type,
    'stores_import' as source,
    state_norm as state,
    COUNT(*) as count
FROM stores_import
WHERE state_norm IS NOT NULL
GROUP BY state_norm
ORDER BY count DESC;

-- 6. ZIP code range comparison
SELECT 
    'ZIP CODE RANGE' as comparison_type,
    'stores' as source,
    MIN(zip5) as min_zip,
    MAX(zip5) as max_zip,
    COUNT(DISTINCT zip5) as unique_zips
FROM stores
WHERE zip5 IS NOT NULL AND zip5 != '';

SELECT 
    'ZIP CODE RANGE' as comparison_type,
    'stores_import' as source,
    MIN(zip5) as min_zip,
    MAX(zip5) as max_zip,
    COUNT(DISTINCT zip5) as unique_zips
FROM stores_import
WHERE zip5 IS NOT NULL AND zip5 != '';

-- 7. Match key overlap
SELECT 
    'MATCH KEY OVERLAP' as comparison_type,
    (SELECT COUNT(DISTINCT match_key) FROM stores WHERE match_key IS NOT NULL) as unique_store_keys,
    (SELECT COUNT(DISTINCT match_key) FROM stores_import WHERE match_key IS NOT NULL) as unique_import_keys,
    (SELECT COUNT(DISTINCT s.match_key)
     FROM stores s
     INNER JOIN stores_import si ON s.match_key = si.match_key
     WHERE s.match_key IS NOT NULL) as overlapping_keys;

-- 8. Sample stores that exist in stores but NOT in stores_import (would be marked inactive)
SELECT 
    'STORES NOT IN IMPORT (would be inactive)' as info,
    s."STORE",
    COALESCE(s.banner, s.name) as banner,
    s.city,
    s.state,
    s.zip_code,
    s.is_active,
    s.match_key
FROM stores s
WHERE s.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM stores_import si WHERE si.match_key = s.match_key
  )
ORDER BY s.created_at DESC
LIMIT 20;

-- 9. Sample stores that exist in import but NOT in stores (would be inserted as new)
SELECT 
    'IMPORT ROWS NOT IN STORES (would be new stores)' as info,
    si."BANNER" as banner,
    si."ADDRESS" as address,
    si."CITY" as city,
    si."STATE" as state,
    si."ZIP" as zip,
    si.match_key
FROM stores_import si
WHERE si.match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM stores s WHERE s.match_key = si.match_key
  )
  AND ((si."BANNER" IS NOT NULL AND si."BANNER" != '') 
       OR (si."ADDRESS" IS NOT NULL AND si."ADDRESS" != ''))
ORDER BY si.id
LIMIT 20;

-- 10. Stores that match (would be updated)
SELECT 
    'MATCHING STORES (would be updated)' as info,
    s."STORE" as existing_store_name,
    si."BANNER" as import_banner,
    s.city as existing_city,
    si."CITY" as import_city,
    s.match_key
FROM stores s
INNER JOIN stores_import si ON s.match_key = si.match_key
WHERE s.match_key IS NOT NULL
ORDER BY s."STORE"
LIMIT 20;

