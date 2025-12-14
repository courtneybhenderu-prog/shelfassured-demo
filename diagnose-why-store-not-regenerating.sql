-- ========================================
-- Diagnose why STORE values weren't regenerated
-- ========================================

-- Check 1: What data exists in stores table?
SELECT 
    'DATA AVAILABILITY CHECK' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '') as stores_with_banner,
    COUNT(*) FILTER (WHERE city IS NOT NULL AND city != '') as stores_with_city,
    COUNT(*) FILTER (WHERE state IS NOT NULL AND state != '') as stores_with_state,
    COUNT(*) FILTER (WHERE address IS NOT NULL AND address != '') as stores_with_address,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '' AND city IS NOT NULL AND city != '' AND state IS NOT NULL AND state != '') as stores_with_all_required
FROM stores;

-- Check 2: Sample of stores showing what data they have
SELECT 
    'SAMPLE: Stores data' as info,
    id,
    "STORE" as current_STORE,
    banner,
    city,
    state,
    address,
    "CHAIN" as CHAIN_column,
    "BANNER" as BANNER_column,
    "CITY" as CITY_column,
    "STATE" as STATE_column
FROM stores
LIMIT 10;

-- Check 3: Check if data is in uppercase columns (CHAIN, BANNER, CITY, STATE)
SELECT 
    'UPPERCASE COLUMNS CHECK' as info,
    COUNT(*) FILTER (WHERE "BANNER" IS NOT NULL AND "BANNER" != '') as stores_with_BANNER,
    COUNT(*) FILTER (WHERE "CITY" IS NOT NULL AND "CITY" != '') as stores_with_CITY,
    COUNT(*) FILTER (WHERE "STATE" IS NOT NULL AND "STATE" != '') as stores_with_STATE,
    COUNT(*) FILTER (WHERE "CHAIN" IS NOT NULL AND "CHAIN" != '') as stores_with_CHAIN
FROM stores;

-- Check 4: Check what the UPDATE would generate
SELECT 
    'WHAT UPDATE WOULD GENERATE' as info,
    id,
    COALESCE(banner, "BANNER", 'Unknown') as banner_value,
    COALESCE(city, "CITY", 'Unknown') as city_value,
    COALESCE(state, "STATE", 'Unknown') as state_value,
    COALESCE(banner, "BANNER", 'Unknown') || ' – ' || 
    COALESCE(city, "CITY", 'Unknown') || ' – ' || 
    COALESCE(state, "STATE", 'Unknown') as would_generate
FROM stores
WHERE "STORE" = 'Unknown – Unknown – Unknown'
LIMIT 10;

