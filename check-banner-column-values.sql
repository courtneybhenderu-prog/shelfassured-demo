-- Check if stores have banner column populated or if it's using STORE
-- This helps diagnose why dropdown shows full STORE names instead of just banners

-- Check banner column values
SELECT 
    'BANNER COLUMN CHECK' as info,
    COUNT(*) as total_stores,
    COUNT(banner) as stores_with_banner,
    COUNT(*) FILTER (WHERE banner IS NULL OR banner = '') as stores_without_banner,
    COUNT(DISTINCT banner) as unique_banners
FROM stores
WHERE is_active = TRUE;

-- Sample of stores showing banner vs STORE
SELECT 
    'BANNER VS STORE COMPARISON' as info,
    id,
    banner,
    "STORE",
    CASE 
        WHEN banner IS NULL OR banner = '' THEN '❌ Banner is NULL/empty'
        WHEN "STORE" LIKE banner || ' - %' THEN '✅ STORE starts with banner'
        ELSE '⚠️ STORE does not start with banner'
    END as relationship
FROM stores
WHERE is_active = TRUE
  AND (
    LOWER("STORE") LIKE '%whole foods%'
    OR LOWER(banner) LIKE '%whole foods%'
  )
LIMIT 10;

-- Check what distinct banners exist
SELECT 
    'DISTINCT BANNERS' as info,
    banner,
    COUNT(*) as store_count
FROM stores
WHERE is_active = TRUE
  AND banner IS NOT NULL
  AND banner != ''
GROUP BY banner
ORDER BY banner
LIMIT 20;

