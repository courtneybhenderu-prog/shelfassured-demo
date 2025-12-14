-- ========================================
-- Step 1: EXECUTE - Merge True Duplicate Stores
-- WARNING: This will mark duplicate stores as inactive
-- Run merge-true-duplicate-stores-dry-run.sql first to review
-- ========================================

BEGIN;

-- Create normalized match key and identify duplicates
WITH normalized_stores AS (
    SELECT 
        id,
        COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), 'Unknown') as banner_val,
        COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), 'Unknown') as city_val,
        COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), 'Unknown') as state_val,
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
        )) as normalized_address,
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
        array_agg(id ORDER BY completeness_score DESC, id) as store_ids
    FROM normalized_stores
    GROUP BY LOWER(TRIM(banner_val)) || '|' || 
             LOWER(TRIM(city_val)) || '|' || 
             UPPER(LEFT(TRIM(state_val), 2)) || '|' || 
             normalized_address
    HAVING COUNT(*) > 1
),
ids_to_inactivate AS (
    SELECT unnest(store_ids[2:]) as id_to_inactivate
    FROM duplicate_groups
)
UPDATE stores
SET is_active = FALSE,
    updated_at = NOW()
FROM ids_to_inactivate
WHERE stores.id = ids_to_inactivate.id_to_inactivate;

-- Verify merge
SELECT 
    'MERGE EXECUTION COMPLETE' as info,
    COUNT(*) FILTER (WHERE is_active = TRUE) as active_stores,
    COUNT(*) FILTER (WHERE is_active = FALSE) as inactive_stores,
    COUNT(*) as total_stores
FROM stores;

-- Show summary of inactivated stores
WITH normalized_stores AS (
    SELECT 
        id,
        "STORE",
        COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), 'Unknown') as banner_val,
        COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), 'Unknown') as city_val,
        COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), 'Unknown') as state_val,
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
        )) as normalized_address
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
        array_agg(id ORDER BY id) as store_ids
    FROM normalized_stores
    GROUP BY LOWER(TRIM(banner_val)) || '|' || 
             LOWER(TRIM(city_val)) || '|' || 
             UPPER(LEFT(TRIM(state_val), 2)) || '|' || 
             normalized_address
    HAVING COUNT(*) > 1
)
SELECT 
    'INACTIVATED DUPLICATES' as info,
    s.id,
    s."STORE",
    s.address,
    s.is_active,
    dg.match_key
FROM stores s
INNER JOIN normalized_stores ns ON s.id = ns.id
INNER JOIN duplicate_groups dg ON 
    LOWER(TRIM(ns.banner_val)) || '|' || 
    LOWER(TRIM(ns.city_val)) || '|' || 
    UPPER(LEFT(TRIM(ns.state_val), 2)) || '|' || 
    ns.normalized_address = dg.match_key
WHERE s.is_active = FALSE
  AND s.id != dg.store_ids[1]  -- Not the survivor
ORDER BY dg.match_key, s.id
LIMIT 50;

COMMIT;

