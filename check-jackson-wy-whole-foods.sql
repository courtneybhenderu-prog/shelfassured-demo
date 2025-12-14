-- ========================================
-- Check if Whole Foods Market in Jackson, Wyoming exists
-- ========================================

-- Search by city and state
SELECT 
    'WHOLE FOODS JACKSON WY' as search_criteria,
    id,
    "STORE",
    name,
    banner,
    address,
    city,
    state,
    zip_code,
    zip5,
    is_active,
    match_key,
    created_at
FROM stores
WHERE (
    LOWER(city) LIKE '%jackson%'
    AND (state = 'WY' OR state = 'Wyoming' OR UPPER(state) = 'WY')
)
AND (
    LOWER(COALESCE(banner, "STORE", name)) LIKE '%whole foods%'
    OR LOWER(banner_norm) LIKE '%whole foods%'
)
ORDER BY created_at DESC;

-- Also check stores_import to see if it's in the Excel data
SELECT 
    'WHOLE FOODS JACKSON WY - IN IMPORT' as search_criteria,
    id,
    "STORE",
    "BANNER",
    "ADDRESS",
    "CITY",
    "STATE",
    "ZIP",
    match_key
FROM stores_import
WHERE (
    LOWER("CITY") LIKE '%jackson%'
    AND ("STATE" = 'WY' OR "STATE" = 'Wyoming' OR UPPER("STATE") = 'WY')
)
AND (
    LOWER("BANNER") LIKE '%whole foods%'
    OR LOWER(banner_norm) LIKE '%whole foods%'
)
ORDER BY id;

-- Broader search - any Whole Foods in Wyoming
SELECT 
    'ALL WHOLE FOODS IN WYOMING' as search_criteria,
    id,
    "STORE",
    name,
    banner,
    city,
    state,
    zip_code,
    is_active
FROM stores
WHERE (state = 'WY' OR state = 'Wyoming' OR UPPER(state) = 'WY')
AND (
    LOWER(COALESCE(banner, "STORE", name)) LIKE '%whole foods%'
    OR LOWER(banner_norm) LIKE '%whole foods%'
)
ORDER BY city;

-- Check in stores_import too
SELECT 
    'ALL WHOLE FOODS IN WYOMING - IMPORT' as search_criteria,
    "BANNER",
    "CITY",
    "STATE",
    "ZIP",
    "ADDRESS"
FROM stores_import
WHERE ("STATE" = 'WY' OR "STATE" = 'Wyoming' OR UPPER("STATE") = 'WY')
AND LOWER("BANNER") LIKE '%whole foods%'
ORDER BY "CITY";

