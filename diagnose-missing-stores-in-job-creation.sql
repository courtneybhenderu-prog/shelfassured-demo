-- ========================================
-- Diagnose why stores aren't showing in job creation
-- ========================================

-- Check 1: Basic store counts
SELECT 
    'BASIC STORE COUNTS' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR "STORE" = '') as stores_missing_STORE,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_stores,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_stores
FROM stores;

-- Check 2: Sample stores to see what data exists
SELECT 
    'SAMPLE STORES (first 10)' as info,
    id,
    "STORE",
    name,
    banner,
    store_chain,
    city,
    state,
    is_active,
    created_at
FROM stores
ORDER BY created_at DESC
LIMIT 10;

-- Check 3: Check if STORE column has data
SELECT 
    'STORE COLUMN ANALYSIS' as info,
    COUNT(*) as total,
    COUNT(DISTINCT "STORE") as unique_STORE_values,
    MIN(LENGTH("STORE")) as min_STORE_length,
    MAX(LENGTH("STORE")) as max_STORE_length,
    COUNT(*) FILTER (WHERE "STORE" IS NULL) as null_count,
    COUNT(*) FILTER (WHERE "STORE" = '') as empty_string_count
FROM stores;

-- Check 4: Compare stores vs stores_import_new
SELECT 
    'COMPARISON: stores vs stores_import_new' as info,
    (SELECT COUNT(*) FROM stores) as stores_count,
    (SELECT COUNT(*) FROM stores_import_new) as stores_import_new_count,
    (SELECT COUNT(*) FROM stores WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE,
    (SELECT COUNT(*) FROM stores_import_new WHERE "STORE" IS NOT NULL AND "STORE" != '') as import_new_with_STORE;

-- Check 5: Check if stores from stores_import_new have STORE populated
SELECT 
    'STORES FROM IMPORT (sample)' as info,
    id,
    "STORE",
    name,
    banner,
    "CHAIN",
    city,
    state
FROM stores_import_new
WHERE "STORE" IS NOT NULL AND "STORE" != ''
ORDER BY id
LIMIT 10;

-- Check 6: Check if stores table has STORE populated (after copy)
SELECT 
    'STORES TABLE (sample after copy)' as info,
    id,
    "STORE",
    name,
    banner,
    store_chain,
    city,
    state
FROM stores
WHERE "STORE" IS NOT NULL AND "STORE" != ''
ORDER BY id
LIMIT 10;

-- Check 7: Verify the copy worked - check if any stores exist at all
SELECT 
    'VERIFICATION: Do stores exist?' as info,
    CASE 
        WHEN COUNT(*) = 0 THEN '❌ NO STORES IN TABLE - Copy may have failed'
        WHEN COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') = 0 THEN '❌ STORES EXIST BUT STORE COLUMN IS EMPTY'
        ELSE '✅ Stores exist with STORE populated'
    END as status,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE
FROM stores;

