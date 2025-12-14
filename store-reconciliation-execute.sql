-- ========================================
-- Store Reconciliation - Execute Import
-- Run this AFTER reviewing diagnostics and confirming matches
-- ========================================
-- This script:
-- 1. Matches existing stores (preserves STORE and id)
-- 2. Inserts new stores with generated display names
-- 3. Marks stores as inactive if not in Excel
-- 4. Updates store_number column

BEGIN;

-- Step 1: Ensure store_number column exists
ALTER TABLE stores ADD COLUMN IF NOT EXISTS store_number VARCHAR(50);
CREATE INDEX IF NOT EXISTS idx_stores_store_number ON stores(store_number);

-- Step 2: Update existing stores
-- CRITICAL: Preserve stores.id and stores.STORE values exactly - never update STORE field
-- Only update other fields (banner, address, city, state, zip, etc.)
UPDATE stores s
SET 
    banner = COALESCE(si."BANNER", s.banner),
    store_chain = COALESCE(si."CHAIN", s.store_chain),
    address = COALESCE(si."ADDRESS", s.address),
    city = COALESCE(si."CITY", s.city),
    state = COALESCE(UPPER(LEFT(TRIM(si."STATE"), 2)), s.state),
    zip_code = COALESCE(si."ZIP", s.zip_code),
    -- zip5 is a generated column - cannot be updated directly, will auto-update from zip_code
    metro = COALESCE(NULLIF(si."METRO", ''), s.metro),  -- Optional field, preserve existing if not in Excel
    phone = COALESCE(NULLIF(si."PHONE", ''), s.phone),
    store_number = COALESCE(NULLIF(si."Store #", ''), s.store_number),
    is_active = TRUE,
    updated_at = NOW(),
    -- Re-normalize after update (for matching only, not for display)
    banner_norm = LOWER(TRIM(COALESCE(si."BANNER", s.banner, s."STORE", s.name, ''))),
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(COALESCE(si."ADDRESS", s.address, '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
            ),
            '[^\w\s]', '', 'g'
        ),
        '\s+', ' ', 'g'
    )),
    city_norm = LOWER(TRIM(COALESCE(si."CITY", s.city, ''))),
    state_norm = UPPER(LEFT(TRIM(COALESCE(si."STATE", s.state, '')), 2)),
    match_key = LOWER(TRIM(COALESCE(si."BANNER", s.banner, s."STORE", s.name, ''))) || '|' || 
                LOWER(REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(TRIM(COALESCE(si."ADDRESS", s.address, '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                            '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
                        ),
                        '[^\w\s]', '', 'g'
                    ),
                    '\s+', ' ', 'g'
                )) || '|' || 
                LOWER(TRIM(COALESCE(si."CITY", s.city, ''))) || '|' || 
                UPPER(LEFT(TRIM(COALESCE(si."STATE", s.state, '')), 2)) || '|' || 
                LPAD(SUBSTRING(COALESCE(si."ZIP", s.zip_code, '') FROM '\d{5}'), 5, '0')
FROM stores_import si
WHERE s.match_key = si.match_key
  AND si.match_key IS NOT NULL
  AND ((si."BANNER" IS NOT NULL AND si."BANNER" != '') 
       OR (si."ADDRESS" IS NOT NULL AND si."ADDRESS" != ''));

-- Step 3: Insert new stores with generated display names
-- CRITICAL: Ignore spreadsheet STORE column - generate new display names
-- Display name format: {Banner} – {City} – {State} – {Disambiguator}
INSERT INTO stores (
    "STORE",
    name,
    banner,
    store_chain,
    address,
    city,
    state,
    zip_code,
    -- zip5 is a generated column - will auto-populate from zip_code
    metro,
    phone,
    store_number,
    is_active,
    banner_norm,
    address_norm,
    city_norm,
    state_norm,
    match_key,
    created_at,
    updated_at
)
SELECT 
    -- Generate display name for NEW stores only: {Banner} – {City} – {State} – {Disambiguator}
    -- Ignore spreadsheet STORE column, use generated name
    COALESCE(si."BANNER", 'Unknown') || ' – ' || 
    COALESCE(si."CITY", 'Unknown') || ' – ' || 
    UPPER(LEFT(TRIM(COALESCE(si."STATE", '')), 2)) || ' – ' ||
    COALESCE(
        -- Extract first significant word from address as disambiguator (skip numbers, directions)
        (SELECT word 
         FROM unnest(string_to_array(REGEXP_REPLACE(si."ADDRESS", '[^\w\s]', '', 'g'), ' ')) AS word
         WHERE word !~ '^\d+$' 
           AND UPPER(word) NOT IN ('N', 'S', 'E', 'W', 'NE', 'NW', 'SE', 'SW')
           AND LENGTH(word) > 1
         LIMIT 1),
        'Unknown'
    ) as "STORE",
    -- Also set name for compatibility (same as STORE)
    COALESCE(si."BANNER", 'Unknown') || ' – ' || 
    COALESCE(si."CITY", 'Unknown') || ' – ' || 
    UPPER(LEFT(TRIM(COALESCE(si."STATE", '')), 2)) || ' – ' ||
    COALESCE(
        (SELECT word 
         FROM unnest(string_to_array(REGEXP_REPLACE(si."ADDRESS", '[^\w\s]', '', 'g'), ' ')) AS word
         WHERE word !~ '^\d+$' 
           AND UPPER(word) NOT IN ('N', 'S', 'E', 'W', 'NE', 'NW', 'SE', 'SW')
           AND LENGTH(word) > 1
         LIMIT 1),
        'Unknown'
    ) as name,
    si."BANNER" as banner,
    si."CHAIN" as store_chain,
    si."ADDRESS" as address,
    si."CITY" as city,
    UPPER(LEFT(TRIM(COALESCE(si."STATE", '')), 2)) as state,
    si."ZIP" as zip_code,
    -- zip5 will be auto-generated from zip_code (generated column)
    NULLIF(si."METRO", '') as metro,  -- Optional field, NULL is acceptable (CBSA lookup out of scope)
    NULLIF(si."PHONE", '') as phone,
    NULLIF(si."Store #", '') as store_number,
    TRUE as is_active,
    LOWER(TRIM(COALESCE(si."BANNER", ''))) as banner_norm,
    LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(COALESCE(si."ADDRESS", '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
            ),
            '[^\w\s]', '', 'g'
        ),
        '\s+', ' ', 'g'
    )) as address_norm,
    LOWER(TRIM(COALESCE(si."CITY", ''))) as city_norm,
    UPPER(LEFT(TRIM(COALESCE(si."STATE", '')), 2)) as state_norm,
    si.match_key,
    NOW() as created_at,
    NOW() as updated_at
FROM stores_import si
WHERE NOT EXISTS (
    SELECT 1 FROM stores s WHERE s.match_key = si.match_key
)
AND si.match_key IS NOT NULL
AND (si."BANNER" IS NOT NULL AND si."BANNER" != '') 
OR (si."ADDRESS" IS NOT NULL AND si."ADDRESS" != '');

-- Step 4: Mark stores as inactive if not in Excel
UPDATE stores
SET 
    is_active = FALSE,
    updated_at = NOW()
WHERE match_key IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM stores_import si WHERE si.match_key = stores.match_key
  );

-- Step 5: Summary
SELECT 
    'RECONCILIATION COMPLETE' as status,
    (SELECT COUNT(*) FROM stores WHERE is_active = TRUE) as active_stores,
    (SELECT COUNT(*) FROM stores WHERE is_active = FALSE) as inactive_stores,
    (SELECT COUNT(*) FROM stores WHERE store_number IS NOT NULL) as stores_with_number;

COMMIT;

-- ========================================
-- Verification Queries
-- ========================================
-- Check new stores
SELECT COUNT(*) as new_stores_inserted
FROM stores
WHERE created_at >= NOW() - INTERVAL '1 minute';

-- Check updated stores
SELECT COUNT(*) as stores_updated
FROM stores
WHERE updated_at >= NOW() - INTERVAL '1 minute'
  AND created_at < NOW() - INTERVAL '1 minute';

-- Check inactive stores
SELECT COUNT(*) as stores_marked_inactive
FROM stores
WHERE is_active = FALSE
  AND updated_at >= NOW() - INTERVAL '1 minute';

