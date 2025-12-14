-- ========================================
-- Diagnose why banner, city, state, address are NULL in stores
-- ========================================

-- Check 1: Compare stores vs stores_import_new to see if data exists in import
SELECT 
    'COMPARISON: stores vs stores_import_new' as info,
    (SELECT COUNT(*) FROM stores WHERE banner IS NOT NULL) as stores_with_banner,
    (SELECT COUNT(*) FROM stores_import_new WHERE banner IS NOT NULL OR "BANNER" IS NOT NULL) as import_with_banner,
    (SELECT COUNT(*) FROM stores WHERE city IS NOT NULL) as stores_with_city,
    (SELECT COUNT(*) FROM stores_import_new WHERE city IS NOT NULL OR "CITY" IS NOT NULL) as import_with_city,
    (SELECT COUNT(*) FROM stores WHERE state IS NOT NULL) as stores_with_state,
    (SELECT COUNT(*) FROM stores_import_new WHERE state IS NOT NULL OR "STATE" IS NOT NULL) as import_with_state;

-- Check 2: Sample from stores_import_new to see what data exists there
SELECT 
    'SAMPLE: stores_import_new data' as info,
    id,
    banner,
    "BANNER",
    city,
    "CITY",
    state,
    "STATE",
    address,
    "ADDRESS",
    "CHAIN"
FROM stores_import_new
LIMIT 10;

-- Check 3: Sample from stores to see what's there
SELECT 
    'SAMPLE: stores data' as info,
    id,
    banner,
    "BANNER",
    city,
    "CITY",
    state,
    "STATE",
    address,
    "ADDRESS",
    "STORE"
FROM stores
LIMIT 10;

-- Check 4: Check if data is in uppercase columns in stores_import_new
SELECT 
    'DATA LOCATION CHECK' as info,
    COUNT(*) FILTER (WHERE "BANNER" IS NOT NULL AND "BANNER" != '') as has_BANNER_uppercase,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '') as has_banner_lowercase,
    COUNT(*) FILTER (WHERE "CITY" IS NOT NULL AND "CITY" != '') as has_CITY_uppercase,
    COUNT(*) FILTER (WHERE city IS NOT NULL AND city != '') as has_city_lowercase,
    COUNT(*) FILTER (WHERE "STATE" IS NOT NULL AND "STATE" != '') as has_STATE_uppercase,
    COUNT(*) FILTER (WHERE state IS NOT NULL AND state != '') as has_state_lowercase
FROM stores_import_new;

