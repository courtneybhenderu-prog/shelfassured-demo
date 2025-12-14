-- ========================================
-- Populate lowercase columns (banner, city, state, address) in stores
-- from uppercase columns (BANNER, CITY, STATE, ADDRESS) or from stores_import_new
-- ========================================

-- Step 1: Check current state
SELECT 
    'BEFORE: Current column state in stores' as info,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '') as stores_with_banner,
    COUNT(*) FILTER (WHERE "BANNER" IS NOT NULL AND "BANNER" != '') as stores_with_BANNER,
    COUNT(*) FILTER (WHERE city IS NOT NULL AND city != '') as stores_with_city,
    COUNT(*) FILTER (WHERE "CITY" IS NOT NULL AND "CITY" != '') as stores_with_CITY,
    COUNT(*) FILTER (WHERE state IS NOT NULL AND state != '') as stores_with_state,
    COUNT(*) FILTER (WHERE "STATE" IS NOT NULL AND "STATE" != '') as stores_with_STATE
FROM stores;

-- Step 2: Update lowercase columns from uppercase columns (if they exist in stores)
UPDATE stores
SET 
    banner = COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), banner),
    city = COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), city),
    state = COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), state),
    address = COALESCE(NULLIF(address, ''), NULLIF("ADDRESS", ''), address),
    store_chain = COALESCE(NULLIF(store_chain, ''), NULLIF("CHAIN", ''), store_chain)
WHERE banner IS NULL OR banner = ''
   OR city IS NULL OR city = ''
   OR state IS NULL OR state = ''
   OR (address IS NULL OR address = '')
   OR (store_chain IS NULL OR store_chain = '');

-- Step 3: If uppercase columns don't exist in stores, update from stores_import_new by matching ID
UPDATE stores s
SET 
    banner = COALESCE(s.banner, si.banner, si."BANNER"),
    city = COALESCE(s.city, si.city, si."CITY"),
    state = COALESCE(s.state, si.state, si."STATE"),
    address = COALESCE(s.address, si.address, si."ADDRESS"),
    store_chain = COALESCE(s.store_chain, si.store_chain, si."CHAIN"),
    store_number = COALESCE(s.store_number, si.store_number, si."Store #"),
    phone = COALESCE(s.phone, si.phone, si."PHONE")
FROM stores_import_new si
WHERE s.id = si.id
  AND (s.banner IS NULL OR s.banner = '' OR s.city IS NULL OR s.city = '' OR s.state IS NULL OR s.state = '');

-- Step 4: Verify after update
SELECT 
    'AFTER: Column state in stores' as info,
    COUNT(*) FILTER (WHERE banner IS NOT NULL AND banner != '') as stores_with_banner,
    COUNT(*) FILTER (WHERE city IS NOT NULL AND city != '') as stores_with_city,
    COUNT(*) FILTER (WHERE state IS NOT NULL AND state != '') as stores_with_state,
    COUNT(*) FILTER (WHERE address IS NOT NULL AND address != '') as stores_with_address,
    COUNT(*) FILTER (WHERE store_chain IS NOT NULL AND store_chain != '') as stores_with_chain
FROM stores;

-- Step 5: Sample to verify data is populated
SELECT 
    'SAMPLE: Stores with populated columns' as info,
    id,
    "STORE",
    banner,
    city,
    state,
    address,
    store_chain,
    store_number
FROM stores
WHERE banner IS NOT NULL AND city IS NOT NULL AND state IS NOT NULL
ORDER BY "STORE"
LIMIT 20;

