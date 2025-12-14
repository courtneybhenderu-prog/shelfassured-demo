-- ========================================
-- Check if stores will be visible in job creation form
-- ========================================

-- Check 1: Total stores and active stores
SELECT 
    'STORE VISIBILITY CHECK' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_stores,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_stores,
    COUNT(*) FILTER (WHERE is_active IS NULL) as null_active_stores
FROM stores;

-- Check 2: Sample of active stores (these should be visible)
SELECT 
    'ACTIVE STORES (should be visible in job creation)' as info,
    id,
    "STORE",
    banner,
    city,
    state,
    is_active
FROM stores
WHERE is_active = TRUE
ORDER BY "STORE"
LIMIT 10;

-- Check 3: Sample of inactive stores (these will NOT be visible)
SELECT 
    'INACTIVE STORES (will NOT be visible in job creation)' as info,
    id,
    "STORE",
    banner,
    city,
    state,
    is_active
FROM stores
WHERE is_active = FALSE
ORDER BY "STORE"
LIMIT 10;

-- Check 4: Stores with NULL is_active (may or may not be visible depending on query)
SELECT 
    'STORES WITH NULL is_active' as info,
    COUNT(*) as count,
    CASE 
        WHEN COUNT(*) > 0 THEN '⚠️ These may not be visible if query filters for is_active = TRUE'
        ELSE '✅ No NULL values'
    END as status
FROM stores
WHERE is_active IS NULL;

-- Check 5: Verify stores from stores_import_new were copied correctly
SELECT 
    'VERIFICATION: Stores copied from stores_import_new' as info,
    (SELECT COUNT(*) FROM stores) as stores_count,
    (SELECT COUNT(*) FROM stores_import_new) as stores_import_new_count,
    (SELECT COUNT(*) FROM stores WHERE is_active = TRUE) as active_stores_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM stores) = (SELECT COUNT(*) FROM stores_import_new)
        THEN '✅ All stores copied'
        ELSE '⚠️ Count mismatch'
    END as copy_status;

