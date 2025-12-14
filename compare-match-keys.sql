-- ========================================
-- Compare Excel match keys vs Existing store match keys
-- This will show why they're not matching
-- ========================================

-- Show Excel match keys (first 10)
SELECT 
    'EXCEL' as source,
    si.match_key as excel_match_key,
    si."BANNER" as banner,
    si."ADDRESS" as address,
    si."CITY" as city,
    si."STATE" as state,
    si."ZIP" as zip,
    si.banner_norm,
    si.address_norm,
    si.city_norm,
    si.state_norm,
    si.zip5
FROM stores_import si
WHERE si.match_key IS NOT NULL
ORDER BY si.id
LIMIT 10;

-- Show Existing store match keys (first 10)
SELECT 
    'EXISTING STORE' as source,
    s.match_key as store_match_key,
    COALESCE(s.banner, s."STORE", s.name) as banner,
    s.address,
    s.city,
    s.state,
    s.zip_code as zip,
    s.banner_norm,
    s.address_norm,
    s.city_norm,
    s.state_norm,
    COALESCE(s.zip5_norm, s.zip5::text, LPAD(SUBSTRING(COALESCE(s.zip_code, '') FROM '\d{5}'), 5, '0')) as zip5
FROM stores s
WHERE s.match_key IS NOT NULL
ORDER BY s.created_at DESC
LIMIT 10;

-- Try to find potential matches (same banner, city, state, zip but different address normalization)
SELECT 
    'POTENTIAL MATCHES' as info,
    si."BANNER" as excel_banner,
    si."ADDRESS" as excel_address,
    si."CITY" as excel_city,
    si."ZIP" as excel_zip,
    si.match_key as excel_match_key,
    s.banner as store_banner,
    s.address as store_address,
    s.city as store_city,
    s.zip_code as store_zip,
    s.match_key as store_match_key,
    CASE 
        WHEN si.banner_norm = s.banner_norm 
         AND si.city_norm = s.city_norm 
         AND si.state_norm = s.state_norm 
         AND si.zip5 = COALESCE(s.zip5_norm, s.zip5::text, LPAD(SUBSTRING(COALESCE(s.zip_code, '') FROM '\d{5}'), 5, '0'))
         AND si.address_norm != s.address_norm
        THEN '⚠️ Address normalization mismatch'
        WHEN si.banner_norm != s.banner_norm
        THEN '⚠️ Banner normalization mismatch'
        ELSE 'Other'
    END as mismatch_reason
FROM stores_import si
CROSS JOIN stores s
WHERE si.match_key IS NOT NULL
  AND s.match_key IS NOT NULL
  AND si.city_norm = s.city_norm
  AND si.state_norm = s.state_norm
  AND si.zip5 = COALESCE(s.zip5_norm, s.zip5::text, LPAD(SUBSTRING(COALESCE(s.zip_code, '') FROM '\d{5}'), 5, '0'))
  AND (si.banner_norm = s.banner_norm OR si.address_norm = s.address_norm)
LIMIT 20;

