-- ========================================
-- Fix store normalization to remove suite/unit/building
-- This will make match keys consistent
-- ========================================

-- Re-normalize existing stores with improved address normalization
UPDATE stores SET
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(COALESCE(address, '')), 
                            '\s+(suite|ste|unit|building|bldg)\s*[a-z0-9]+\s*$', '', 'gi'),  -- Remove suite/unit/building at end
                        '\s+(suite|ste|unit|building|bldg)\s*[a-z0-9]+', '', 'gi'  -- Remove suite/unit/building in middle
                    ),
                    '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place|pkwy|parkway|hwy|highway)\b', '', 'gi'
                ),
                '[^\w\s]', '', 'g'  -- Remove punctuation
            ),
            '\s+', ' ', 'g'  -- Collapse spaces
        ),
        '^\s+|\s+$', '', 'g'  -- Trim
    )),
    match_key = banner_norm || '|' || address_norm || '|' || 
                city_norm || '|' || 
                state_norm || '|' || 
                COALESCE(zip5_norm, COALESCE(zip5::text, LPAD(SUBSTRING(COALESCE(zip_code, '') FROM '\d{5}'), 5, '0')))
WHERE match_key IS NOT NULL;

-- Verify the fix
SELECT 
    '✅ Store normalization updated' as status,
    COUNT(*) as stores_renormalized
FROM stores
WHERE match_key IS NOT NULL;

-- Show sample of fixed match keys
SELECT 
    address as original_address,
    address_norm,
    match_key
FROM stores
WHERE address LIKE '%Suite%' OR address LIKE '%Unit%' OR address LIKE '%Building%'
ORDER BY created_at DESC
LIMIT 10;

