-- Check if Whole Foods Market in Jackson, Wyoming exists in database
-- This helps diagnose why the store isn't appearing in search results

-- Search for Whole Foods stores in Wyoming
SELECT 
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
        WHEN LOWER(city) LIKE '%jackson%' AND (LOWER(state) LIKE '%wyoming%' OR state = 'WY') THEN '✅ Should match Jackson, WY'
        WHEN LOWER(state) LIKE '%wyoming%' OR state = 'WY' THEN '⚠️ Wyoming state but different city'
        WHEN LOWER("STORE") LIKE '%jackson%' AND (LOWER(state) LIKE '%wyoming%' OR state = 'WY') THEN '✅ STORE field matches'
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
    OR LOWER(state) LIKE '%wyoming%'
    OR state = 'WY'
    OR LOWER("STORE") LIKE '%jackson%'
    OR LOWER("STORE") LIKE '%wyoming%'
)
ORDER BY 
    CASE WHEN LOWER(city) LIKE '%jackson%' AND (LOWER(state) LIKE '%wyoming%' OR state = 'WY') THEN 1 ELSE 2 END,
    city, state;

-- Also check all Whole Foods stores in Wyoming (any city)
SELECT 
    id,
    "STORE",
    city,
    state,
    address,
    is_active
FROM stores
WHERE (
    LOWER("STORE") LIKE '%whole foods%'
    OR LOWER(banner) LIKE '%whole foods%'
)
AND (
    LOWER(state) LIKE '%wyoming%'
    OR state = 'WY'
)
ORDER BY city;

-- Check what happens when we search for "Wyoming" (current search logic simulation)
SELECT 
    id,
    "STORE",
    city,
    state,
    address,
    CASE 
        WHEN LOWER(state) LIKE '%wyoming%' OR state = 'WY' THEN '✅ State match (correct)'
        WHEN LOWER(address) LIKE '%wyoming%' THEN '❌ Address match (false positive)'
        WHEN LOWER("STORE") LIKE '%wyoming%' THEN '⚠️ STORE field match'
        ELSE 'Other'
    END as match_type
FROM stores
WHERE is_active = TRUE
  AND (
    LOWER(state) LIKE '%wyoming%'
    OR state = 'WY'
    OR LOWER(address) LIKE '%wyoming%'
    OR LOWER("STORE") LIKE '%wyoming%'
  )
ORDER BY 
    CASE WHEN LOWER(state) LIKE '%wyoming%' OR state = 'WY' THEN 1 ELSE 2 END,
    city, state
LIMIT 20;

