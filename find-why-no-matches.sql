-- ========================================
-- Find WHY matches aren't working
-- Compare Excel vs Stores side-by-side
-- Conservative matching: Only exact matches on normalized fields
-- Purpose: Understand matching behavior, not to maximize matches
-- ========================================

-- Find stores that SHOULD match (same city, state, zip, similar banner)
-- but don't because of address or banner differences
SELECT 
    'SHOULD MATCH BUT DOESNT' as issue_type,
    si."BANNER" as excel_banner,
    si.banner_norm as excel_banner_norm,
    si."ADDRESS" as excel_address,
    si.address_norm as excel_address_norm,
    si."CITY" as excel_city,
    si."ZIP" as excel_zip,
    si.match_key as excel_match_key,
    COALESCE(s.banner, s."STORE", s.name) as store_banner,
    s.banner_norm as store_banner_norm,
    s.address as store_address,
    s.address_norm as store_address_norm,
    s.city as store_city,
    s.zip_code as store_zip,
    s.match_key as store_match_key,
    CASE 
        WHEN si.banner_norm != s.banner_norm THEN 'Banner mismatch: ' || si.banner_norm || ' vs ' || s.banner_norm
        WHEN si.address_norm != s.address_norm THEN 'Address mismatch: ' || si.address_norm || ' vs ' || s.address_norm
        WHEN si.city_norm != s.city_norm THEN 'City mismatch'
        WHEN si.zip5 != COALESCE(s.zip5_norm, s.zip5::text, LPAD(SUBSTRING(COALESCE(s.zip_code, '') FROM '\d{5}'), 5, '0')) THEN 'ZIP mismatch'
        ELSE 'Unknown'
    END as why_no_match
FROM stores_import si
CROSS JOIN stores s
WHERE si.match_key IS NOT NULL
  AND s.match_key IS NOT NULL
  AND si.city_norm = s.city_norm
  AND si.state_norm = s.state_norm
  AND si.zip5 = COALESCE(s.zip5_norm, s.zip5::text, LPAD(SUBSTRING(COALESCE(s.zip_code, '') FROM '\d{5}'), 5, '0'))
  AND si.match_key != s.match_key
  AND (
    si.banner_norm = s.banner_norm 
    OR si.address_norm = s.address_norm
    OR si.banner_norm LIKE '%' || s.banner_norm || '%'
    OR s.banner_norm LIKE '%' || si.banner_norm || '%'
  )
LIMIT 20;

-- Show the 3 that DO match (to see what's working)
SELECT 
    'ACTUAL MATCHES' as issue_type,
    si."BANNER" as excel_banner,
    si.match_key as excel_match_key,
    COALESCE(s.banner, s."STORE", s.name) as store_banner,
    s.match_key as store_match_key
FROM stores_import si
JOIN stores s ON s.match_key = si.match_key
LIMIT 10;

