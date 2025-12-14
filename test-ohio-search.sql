-- Test search for "Ohio" to see what stores match
SELECT 
    id,
    "STORE",
    city,
    state,
    address,
    CASE 
        WHEN LOWER(city) LIKE '%ohio%' THEN 'City match'
        WHEN LOWER(state) LIKE '%ohio%' THEN 'State match'
        WHEN LOWER("STORE") LIKE '%ohio%' THEN 'STORE match'
        WHEN LOWER(address) LIKE '%ohio%' THEN 'Address match'
        ELSE 'Other'
    END as match_type
FROM stores
WHERE is_active = TRUE
  AND (
    LOWER(city) LIKE '%ohio%' 
    OR LOWER(state) LIKE '%ohio%'
    OR LOWER("STORE") LIKE '%ohio%'
    OR LOWER(address) LIKE '%ohio%'
  )
ORDER BY 
    CASE WHEN LOWER(state) LIKE '%ohio%' THEN 1 ELSE 2 END,
    city, state
LIMIT 20;

