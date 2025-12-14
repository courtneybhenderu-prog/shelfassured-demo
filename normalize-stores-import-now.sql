-- ========================================
-- Manually normalize stores_import data
-- Run this to create match keys
-- ========================================

-- Step 1: Normalize stores_import data
UPDATE stores_import SET
    banner_norm = LOWER(TRIM(COALESCE("BANNER", ''))),
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(COALESCE("ADDRESS", '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
            ),
            '[^\w\s]', '', 'g'
        ),
        '\s+', ' ', 'g'
    )),
    city_norm = LOWER(TRIM(COALESCE("CITY", ''))),
    state_norm = UPPER(LEFT(TRIM(COALESCE("STATE", '')), 2)),
    zip5 = LPAD(SUBSTRING(COALESCE("ZIP", '') FROM '\d{5}'), 5, '0')
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Step 2: Create match keys
UPDATE stores_import SET
    match_key = banner_norm || '|' || address_norm || '|' || city_norm || '|' || state_norm || '|' || zip5
WHERE match_key IS NULL
  AND (("BANNER" IS NOT NULL AND "BANNER" != '') 
       OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != ''));

-- Step 3: Verify normalization
SELECT 
    '✅ Normalization complete' as status,
    COUNT(*) as total_rows,
    COUNT(banner_norm) as rows_with_banner_norm,
    COUNT(match_key) as rows_with_match_key,
    COUNT(DISTINCT match_key) as unique_match_keys
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Step 4: Sample normalized data
SELECT 
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
WHERE match_key IS NOT NULL
ORDER BY id
LIMIT 5;

