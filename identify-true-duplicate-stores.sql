-- ========================================
-- Step 1: Identify True Duplicate Stores
-- Match by: normalized banner + city + state + normalized street address
-- ========================================

-- Create normalized match key for true duplicates
-- This matches stores that are the same physical location
WITH normalized_stores AS (
    SELECT 
        id,
        "STORE",
        COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), 'Unknown') as banner_val,
        COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), 'Unknown') as city_val,
        COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), 'Unknown') as state_val,
        -- Normalize address: remove suite/unit/building, strip punctuation, lowercase
        LOWER(REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(TRIM(COALESCE(address, "ADDRESS", '')), 
                        '\s+(suite|ste|unit|building|bldg|apt|apartment|#)\s*[a-z0-9]+\s*$', '', 'gi'),  -- Remove suite/unit at end
                    '\s+(suite|ste|unit|building|bldg|apt|apartment|#)\s*[a-z0-9]+', '', 'gi'  -- Remove suite/unit in middle
                ),
                '[^\w\s]', '', 'g'  -- Remove punctuation
            ),
            '\s+', ' ', 'g'  -- Collapse spaces
        )) as normalized_address,
        address,
        "ADDRESS",
        store_number,
        phone,
        zip_code,
        metro,
        -- Calculate completeness score (more complete = higher score)
        (CASE WHEN store_number IS NOT NULL AND store_number != '' THEN 1 ELSE 0 END +
         CASE WHEN phone IS NOT NULL AND phone != '' THEN 1 ELSE 0 END +
         CASE WHEN zip_code IS NOT NULL AND zip_code != '' THEN 1 ELSE 0 END +
         CASE WHEN metro IS NOT NULL AND metro != '' THEN 1 ELSE 0 END) as completeness_score
    FROM stores
    WHERE COALESCE(address, "ADDRESS", '') IS NOT NULL 
      AND COALESCE(address, "ADDRESS", '') != ''
),
duplicate_groups AS (
    SELECT 
        LOWER(TRIM(banner_val)) || '|' || 
        LOWER(TRIM(city_val)) || '|' || 
        UPPER(LEFT(TRIM(state_val), 2)) || '|' || 
        normalized_address as match_key,
        COUNT(*) as duplicate_count,
        array_agg(id ORDER BY completeness_score DESC, id) as store_ids,
        array_agg(completeness_score ORDER BY completeness_score DESC, id) as scores
    FROM normalized_stores
    GROUP BY LOWER(TRIM(banner_val)) || '|' || 
             LOWER(TRIM(city_val)) || '|' || 
             UPPER(LEFT(TRIM(state_val), 2)) || '|' || 
             normalized_address
    HAVING COUNT(*) > 1
)
SELECT 
    'SUSPECTED TRUE DUPLICATES' as info,
    dg.match_key,
    dg.duplicate_count,
    dg.store_ids[1] as survivor_id,
    ns_survivor."STORE" as survivor_store_name,
    ns_survivor.address as survivor_address,
    ns_survivor.store_number as survivor_store_number,
    ns_survivor.completeness_score as survivor_score,
    dg.store_ids[2:] as duplicate_ids_to_merge,
    string_agg(ns."STORE" || ' (' || ns.id::text || ')', ' | ' ORDER BY ns.completeness_score DESC, ns.id) as all_duplicate_stores
FROM duplicate_groups dg
CROSS JOIN LATERAL (
    SELECT * FROM normalized_stores WHERE id = dg.store_ids[1]
) ns_survivor
LEFT JOIN normalized_stores ns ON ns.id = ANY(dg.store_ids[2:])
GROUP BY dg.match_key, dg.duplicate_count, dg.store_ids, ns_survivor."STORE", ns_survivor.address, ns_survivor.store_number, ns_survivor.completeness_score
ORDER BY dg.duplicate_count DESC, dg.match_key;

-- Summary of true duplicates
WITH normalized_stores AS (
    SELECT 
        id,
        LOWER(TRIM(COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), 'Unknown'))) || '|' || 
        LOWER(TRIM(COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), 'Unknown'))) || '|' || 
        UPPER(LEFT(TRIM(COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), 'Unknown')), 2)) || '|' || 
        LOWER(REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(TRIM(COALESCE(address, "ADDRESS", '')), 
                        '\s+(suite|ste|unit|building|bldg|apt|apartment|#)\s*[a-z0-9]+\s*$', '', 'gi'),
                    '\s+(suite|ste|unit|building|bldg|apt|apartment|#)\s*[a-z0-9]+', '', 'gi'
                ),
                '[^\w\s]', '', 'g'
            ),
            '\s+', ' ', 'g'
        )) as match_key
    FROM stores
    WHERE COALESCE(address, "ADDRESS", '') IS NOT NULL 
      AND COALESCE(address, "ADDRESS", '') != ''
)
SELECT 
    'TRUE DUPLICATES SUMMARY' as info,
    COUNT(DISTINCT match_key) as duplicate_groups,
    SUM(duplicate_count - 1) as stores_to_merge,
    SUM(duplicate_count) as total_stores_in_duplicate_groups
FROM (
    SELECT match_key, COUNT(*) as duplicate_count
    FROM normalized_stores
    GROUP BY match_key
    HAVING COUNT(*) > 1
) dupes;

