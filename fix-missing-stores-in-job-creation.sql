-- ========================================
-- Fix missing stores in job creation
-- The issue is likely that STORE column is empty after copy
-- ========================================

-- Step 1: Check current state
SELECT 
    'CURRENT STATE' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR "STORE" = '') as stores_missing_STORE
FROM stores;

-- Step 2: Check what columns have data in stores_import_new
SELECT 
    'STORES_IMPORT_NEW COLUMNS' as info,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as has_STORE,
    COUNT(*) FILTER (WHERE name IS NOT NULL AND name != '') as has_name,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '') as has_banner
FROM stores_import_new;

-- Step 3: Update stores to populate STORE column if it's empty
-- Use name, banner, or generated value as fallback
UPDATE stores
SET "STORE" = COALESCE(
    NULLIF("STORE", ''),  -- Keep existing STORE if not empty
    name,                 -- Use name if STORE is empty
    banner,               -- Use banner if name is also empty
    COALESCE(banner, 'Unknown') || ' – ' || COALESCE(city, 'Unknown') || ' – ' || COALESCE(state, 'Unknown')  -- Generate if all empty
)
WHERE "STORE" IS NULL OR "STORE" = '';

-- Step 4: Verify STORE column is now populated
SELECT 
    'AFTER FIX: STORE COLUMN STATUS' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as stores_with_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR "STORE" = '') as stores_still_missing_STORE,
    CASE 
        WHEN COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') = COUNT(*)
        THEN '✅ All stores now have STORE populated'
        ELSE '⚠️ Some stores still missing STORE'
    END as status
FROM stores;

-- Step 5: Sample of stores that should now be visible
SELECT 
    'SAMPLE: Stores that should be visible now' as info,
    id,
    "STORE",
    name,
    banner,
    city,
    state,
    is_active
FROM stores
WHERE "STORE" IS NOT NULL AND "STORE" != ''
ORDER BY "STORE"
LIMIT 20;

-- Step 6: Check if stores_import_new has STORE column with data
-- If it does, we might need to re-copy or update
SELECT 
    'CHECK: stores_import_new STORE column' as info,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND "STORE" != '') as has_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR "STORE" = '') as missing_STORE
FROM stores_import_new;

