-- Diagnostic query for Whole Foods Market in Jackson, Wyoming
-- This helps diagnose why the store isn't appearing in search results

-- 1. Check if Whole Foods in Jackson, Wyoming exists
SELECT 
    'WHOLE FOODS JACKSON WY CHECK' as info,
    id,
    "STORE",
    city,
    state,
    address,
    zip_code,
    is_active,
    banner,
    store_chain,
    CASE 
        WHEN LOWER(city) = 'jackson' AND state = 'WY' THEN '✅ Exact match Jackson, WY'
        WHEN LOWER(city) LIKE '%jackson%' AND state = 'WY' THEN '⚠️ Partial city match'
        WHEN state = 'WY' THEN '⚠️ Wyoming but different city'
        ELSE '❌ No match'
    END as match_status
FROM stores
WHERE (
    LOWER("STORE") LIKE '%whole foods%'
    OR LOWER(banner) LIKE '%whole foods%'
    OR LOWER(store_chain) LIKE '%whole foods%'
)
AND (
    LOWER(city) LIKE '%jackson%'
    OR state = 'WY'
    OR LOWER("STORE") LIKE '%jackson%'
)
ORDER BY 
    CASE WHEN LOWER(city) = 'jackson' AND state = 'WY' THEN 1 
         WHEN LOWER(city) LIKE '%jackson%' AND state = 'WY' THEN 2
         WHEN state = 'WY' THEN 3
         ELSE 4 END,
    city, state;

-- 2. Check all Whole Foods stores in Wyoming (any city)
SELECT 
    'ALL WHOLE FOODS IN WYOMING' as info,
    id,
    "STORE",
    city,
    state,
    address,
    is_active
FROM stores
WHERE is_active = TRUE
  AND (
    LOWER("STORE") LIKE '%whole foods%'
    OR LOWER(banner) LIKE '%whole foods%'
  )
  AND state = 'WY'
ORDER BY city;

-- 3. Check data format for Jackson, Wyoming stores (any banner)
SELECT 
    'JACKSON WY DATA FORMAT CHECK' as info,
    id,
    "STORE",
    city,
    state,
    address,
    banner,
    is_active,
    CASE 
        WHEN city IS NULL OR city = '' THEN '❌ City is NULL/empty'
        WHEN state IS NULL OR state = '' THEN '❌ State is NULL/empty'
        WHEN state != 'WY' AND LOWER(state) NOT LIKE '%wyoming%' THEN '⚠️ State format issue'
        WHEN is_active = FALSE THEN '⚠️ Store is inactive'
        ELSE '✅ Data looks good'
    END as data_quality
FROM stores
WHERE LOWER(city) LIKE '%jackson%'
  AND (state = 'WY' OR LOWER(state) LIKE '%wyoming%')
ORDER BY banner, city;

-- 4. Test new intent-based search logic for "Wyoming"
-- Should ONLY match state column, not address
SELECT 
    'WYOMING STATE SEARCH TEST' as info,
    id,
    "STORE",
    city,
    state,
    address,
    CASE 
        WHEN state = 'WY' THEN '✅ State match (should appear)'
        WHEN LOWER(state) LIKE '%wyoming%' THEN '✅ State name match (should appear)'
        WHEN LOWER(address) LIKE '%wyoming%' THEN '❌ Address match (should NOT appear with new logic)'
        ELSE 'Other'
    END as match_type
FROM stores
WHERE is_active = TRUE
  AND (
    state = 'WY'
    OR LOWER(state) LIKE '%wyoming%'
  )
ORDER BY 
    CASE WHEN state = 'WY' THEN 1 ELSE 2 END,
    city, state
LIMIT 20;

