-- ========================================
-- Check why match keys aren't being created
-- ========================================

-- Check if normalization columns exist and have data
SELECT 
    'stores_import normalization check' as check_type,
    COUNT(*) as total_rows,
    COUNT(banner_norm) as rows_with_banner_norm,
    COUNT(address_norm) as rows_with_address_norm,
    COUNT(city_norm) as rows_with_city_norm,
    COUNT(state_norm) as rows_with_state_norm,
    COUNT(zip5) as rows_with_zip5,
    COUNT(match_key) as rows_with_match_key
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Sample rows showing raw data vs normalized
SELECT 
    id,
    "BANNER" as banner_raw,
    banner_norm,
    "ADDRESS" as address_raw,
    address_norm,
    "CITY" as city_raw,
    city_norm,
    "STATE" as state_raw,
    state_norm,
    "ZIP" as zip_raw,
    zip5,
    match_key
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '')
ORDER BY id
LIMIT 10;

-- Check if normalization UPDATE ran
SELECT 
    'Normalization status' as info,
    CASE 
        WHEN COUNT(banner_norm) = 0 THEN '❌ Normalization NOT run - run diagnostics script'
        WHEN COUNT(banner_norm) < COUNT(*) * 0.9 THEN '⚠️ Partial normalization'
        ELSE '✅ Normalization complete'
    END as status
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

