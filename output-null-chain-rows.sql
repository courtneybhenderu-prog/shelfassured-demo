-- ========================================
-- Output all rows from stores_import_new where CHAIN is NULL
-- ========================================

-- Query 1: Output all rows where CHAIN is NULL
SELECT 
    id,
    "STORE",
    name,
    banner,
    store_chain,
    "CHAIN",
    address,
    "ADDRESS",
    city,
    "CITY",
    state,
    "STATE",
    zip_code,
    "ZIP",
    metro,
    "METRO",
    phone,
    "PHONE",
    created_at,
    updated_at
FROM stores_import_new
WHERE "CHAIN" IS NULL
ORDER BY id;

-- Query 2: Count and summary
SELECT 
    'SUMMARY' as info,
    COUNT(*) as total_rows_with_null_CHAIN,
    COUNT(DISTINCT COALESCE(banner, "BANNER")) as unique_banners,
    COUNT(DISTINCT COALESCE(city, "CITY")) as unique_cities,
    COUNT(DISTINCT COALESCE(state, "STATE")) as unique_states
FROM stores_import_new
WHERE "CHAIN" IS NULL;

-- Query 3: Group by banner to see distribution
SELECT 
    'BY BANNER' as info,
    COALESCE(banner, "BANNER", 'Unknown') as banner_name,
    COUNT(*) as null_chain_count
FROM stores_import_new
WHERE "CHAIN" IS NULL
GROUP BY COALESCE(banner, "BANNER")
ORDER BY null_chain_count DESC;

-- Query 4: Group by state to see geographic distribution
SELECT 
    'BY STATE' as info,
    COALESCE(state, "STATE", 'Unknown') as state_name,
    COUNT(*) as null_chain_count
FROM stores_import_new
WHERE "CHAIN" IS NULL
GROUP BY COALESCE(state, "STATE")
ORDER BY null_chain_count DESC;

