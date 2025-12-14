-- ========================================
-- Fix Excel normalization to match store normalization
-- This ensures consistent address normalization
-- ========================================

-- Re-normalize Excel addresses with improved normalization
UPDATE stores_import SET
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(TRIM(COALESCE("ADDRESS", '')), 
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
                zip5
WHERE match_key IS NOT NULL;

-- Verify the fix
SELECT 
    '✅ Excel normalization updated' as status,
    COUNT(*) as rows_renormalized
FROM stores_import
WHERE match_key IS NOT NULL;

