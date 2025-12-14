-- ========================================
-- Verify stores will appear in job creation form
-- ========================================

-- The store selector queries stores with:
-- - STORE IS NOT NULL
-- - STORE != ''
-- - No is_active filter (so all stores with STORE populated should appear)

-- Check 1: Stores that WILL appear (have STORE populated)
SELECT 
    'STORES THAT WILL APPEAR IN JOB CREATION' as info,
    COUNT(*) as total_visible_stores,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_stores,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_stores,
    COUNT(*) FILTER (WHERE is_active IS NULL) as null_active_stores
FROM stores
WHERE "STORE" IS NOT NULL 
  AND "STORE" != '';

-- Check 2: Stores that will NOT appear (missing STORE)
SELECT 
    'STORES THAT WILL NOT APPEAR (missing STORE)' as info,
    COUNT(*) as count
FROM stores
WHERE "STORE" IS NULL 
   OR "STORE" = '';

-- Check 3: Sample of stores that will appear
SELECT 
    'SAMPLE: Stores visible in job creation' as info,
    id,
    "STORE",
    banner,
    city,
    state,
    is_active
FROM stores
WHERE "STORE" IS NOT NULL 
  AND "STORE" != ''
ORDER BY "STORE"
LIMIT 20;

-- Check 4: Verify stores from stores_import_new have STORE populated
SELECT 
    'VERIFICATION: Stores from import have STORE populated' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR "STORE" = '') as stores_missing_STORE,
    CASE 
        WHEN COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') = COUNT(*)
        THEN '✅ All stores have STORE populated - will be visible'
        ELSE '⚠️ Some stores missing STORE - will not be visible'
    END as visibility_status
FROM stores;

