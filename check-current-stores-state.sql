-- ========================================
-- Check Current State of Stores Table
-- ========================================

-- Overall summary
SELECT 
    'STORES TABLE SUMMARY' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_stores,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_stores,
    COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 hour') as stores_created_recently,
    COUNT(*) FILTER (WHERE updated_at >= NOW() - INTERVAL '1 hour') as stores_updated_recently,
    COUNT(*) FILTER (WHERE store_number IS NOT NULL) as stores_with_number;

-- Check if Whole Foods Jackson WY is active
SELECT 
    'JACKSON WY WHOLE FOODS STATUS' as info,
    id,
    "STORE",
    banner,
    city,
    state,
    zip_code,
    is_active,
    created_at,
    updated_at,
    CASE 
        WHEN created_at >= NOW() - INTERVAL '1 hour' THEN 'NEWLY INSERTED'
        WHEN updated_at >= NOW() - INTERVAL '1 hour' THEN 'RECENTLY UPDATED'
        ELSE 'EXISTING'
    END as status_type
FROM stores
WHERE LOWER(city) LIKE '%jackson%'
  AND (state = 'WY' OR UPPER(state) = 'WY')
  AND LOWER(COALESCE(banner, "STORE", name)) LIKE '%whole foods%';

-- Sample of recently created stores (new from import)
SELECT 
    'SAMPLE NEW STORES' as info,
    "STORE",
    banner,
    city,
    state,
    zip_code,
    is_active,
    created_at
FROM stores
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;

-- Sample of recently updated stores (matched from import)
SELECT 
    'SAMPLE UPDATED STORES' as info,
    "STORE",
    banner,
    city,
    state,
    zip_code,
    is_active,
    updated_at,
    created_at
FROM stores
WHERE updated_at >= NOW() - INTERVAL '1 hour'
  AND created_at < NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC
LIMIT 10;

-- Check for any issues: stores that should be active but aren't
SELECT 
    'POTENTIAL ISSUES: INACTIVE STORES WITH RECENT DATA' as info,
    "STORE",
    banner,
    city,
    state,
    is_active,
    updated_at
FROM stores
WHERE is_active = FALSE
  AND updated_at >= NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC
LIMIT 20;

