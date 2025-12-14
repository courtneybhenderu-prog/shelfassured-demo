-- ========================================
-- Restore STORE column and populate with generated display names
-- IMPORTANT: Only fills NULL/empty STORE values, preserves existing ones
-- Format: {Banner} – {City} – {State} – {Disambiguator}
-- ========================================

-- Step 1: Check if STORE column exists
SELECT 
    'CHECK: STORE COLUMN EXISTS' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'stores' AND column_name = 'STORE'
        ) THEN '✅ STORE column exists'
        ELSE '❌ STORE column missing - will create it'
    END as status;

-- Step 2: Add STORE column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores' AND column_name = 'STORE'
    ) THEN
        ALTER TABLE stores ADD COLUMN "STORE" TEXT;
        RAISE NOTICE 'Added STORE column';
    ELSE
        RAISE NOTICE 'STORE column already exists';
    END IF;
END $$;

-- Step 3: Check current state before update
SELECT 
    'BEFORE UPDATE: Current STORE column state' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown') as stores_with_existing_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR btrim("STORE") = '' OR "STORE" = 'Unknown – Unknown – Unknown') as stores_needing_STORE,
    COUNT(*) FILTER (WHERE "STORE" = 'Unknown – Unknown – Unknown') as stores_with_placeholder
FROM stores;

-- Step 4: Identify stores that need disambiguator (multiple stores with same banner+city+state)
WITH store_groups AS (
    SELECT 
        COALESCE(banner, 'Unknown') as banner,
        COALESCE(city, 'Unknown') as city,
        COALESCE(state, 'Unknown') as state,
        COUNT(*) as store_count
    FROM stores
    WHERE "STORE" IS NULL OR btrim("STORE") = '' OR "STORE" = 'Unknown – Unknown – Unknown'
    GROUP BY COALESCE(banner, 'Unknown'), COALESCE(city, 'Unknown'), COALESCE(state, 'Unknown')
    HAVING COUNT(*) > 1
)
SELECT 
    'STORES NEEDING DISAMBIGUATOR' as info,
    COUNT(*) as groups_with_duplicates,
    SUM(store_count) as total_stores_needing_disambiguator
FROM store_groups;

-- Step 5: Update STORE column ONLY for rows where STORE is NULL, empty, whitespace-only, or placeholder
-- CRITICAL: This will regenerate STORE for placeholder values ('Unknown – Unknown – Unknown') and empty values
-- After regeneration, the preservation rule applies: Once STORE is set (non-null, non-empty, non-whitespace, non-placeholder), it remains unchanged forever
UPDATE stores
SET "STORE" = (
    -- Generate: Banner – City – State – Disambiguator (if needed)
    -- Check both lowercase and uppercase columns (banner/BANNER, city/CITY, state/STATE)
    COALESCE(NULLIF(banner, ''), NULLIF("BANNER", ''), 'Unknown') || ' – ' || 
    COALESCE(NULLIF(city, ''), NULLIF("CITY", ''), 'Unknown') || ' – ' || 
    COALESCE(NULLIF(state, ''), NULLIF("STATE", ''), 'Unknown') ||
    CASE 
        -- Only add disambiguator if there are multiple stores with same banner+city+state
        WHEN EXISTS (
            SELECT 1 
            FROM stores s2 
            WHERE s2.id != stores.id
              AND COALESCE(NULLIF(s2.banner, ''), NULLIF(s2."BANNER", ''), 'Unknown') = COALESCE(NULLIF(stores.banner, ''), NULLIF(stores."BANNER", ''), 'Unknown')
              AND COALESCE(NULLIF(s2.city, ''), NULLIF(s2."CITY", ''), 'Unknown') = COALESCE(NULLIF(stores.city, ''), NULLIF(stores."CITY", ''), 'Unknown')
              AND COALESCE(NULLIF(s2.state, ''), NULLIF(s2."STATE", ''), 'Unknown') = COALESCE(NULLIF(stores.state, ''), NULLIF(stores."STATE", ''), 'Unknown')
              AND (s2."STORE" IS NULL OR btrim(s2."STORE") = '' OR s2."STORE" = 'Unknown – Unknown – Unknown' OR s2."STORE" LIKE COALESCE(NULLIF(stores.banner, ''), NULLIF(stores."BANNER", ''), 'Unknown') || ' – ' || COALESCE(NULLIF(stores.city, ''), NULLIF(stores."CITY", ''), 'Unknown') || ' – ' || COALESCE(NULLIF(stores.state, ''), NULLIF(stores."STATE", ''), 'Unknown') || '%')
        ) AND COALESCE(stores.address, stores."ADDRESS", '') != '' THEN
            -- Extract disambiguator from address
            ' – ' || UPPER(
                -- Extract first meaningful word from cleaned address
                COALESCE(
                    (regexp_match(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    REGEXP_REPLACE(LOWER(TRIM(COALESCE(stores.address, stores."ADDRESS", ''))), 
                                        '^\d+\s*', '', 'g'),  -- Remove leading street number
                                    '\b(unit|suite|ste|building|bldg|apt|apartment|#)\s*\w*\b', '', 'gi'  -- Remove unit/suite
                                ),
                                '\b(n|s|e|w|north|south|east|west|ne|nw|se|sw)\b', '', 'gi'  -- Remove directions
                            ),
                            '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place|pkwy|parkway|hwy|highway)\b', '', 'gi'  -- Remove street suffixes
                        ),
                        '^([a-z]{3,})'  -- Extract first word of 3+ letters
                    ))[1],
                    -- Fallback: use first 3-4 meaningful characters
                    SUBSTRING(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(LOWER(TRIM(COALESCE(stores.address, stores."ADDRESS", ''))), 
                                    '^\d+\s*', '', 'g'),
                                '\b(unit|suite|ste|building|bldg|apt|apartment|#)\s*\w*\b', '', 'gi'
                            ),
                            '\s+', ' ', 'g'
                        ),
                        1, 4
                    )
                )
            )
        ELSE ''
    END
)
WHERE "STORE" IS NULL OR btrim("STORE") = '' OR "STORE" = 'Unknown – Unknown – Unknown';  -- CRITICAL: Regenerate for null, empty, whitespace-only, or placeholder. After regeneration, preservation rule applies.

-- Step 6: Verify STORE column is now populated
SELECT 
    'AFTER UPDATE: STORE COLUMN STATUS' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown') as stores_with_valid_STORE,
    COUNT(*) FILTER (WHERE "STORE" IS NULL OR btrim("STORE") = '' OR "STORE" = 'Unknown – Unknown – Unknown') as stores_still_missing_STORE,
    COUNT(*) FILTER (WHERE "STORE" = 'Unknown – Unknown – Unknown') as stores_with_placeholder_remaining,
    CASE 
        WHEN COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown') = COUNT(*)
        THEN '✅ All stores now have valid STORE populated (no placeholders)'
        ELSE '⚠️ Some stores still missing STORE or have placeholder'
    END as status
FROM stores;

-- Step 7: Preview sample of generated STORE values
SELECT 
    'PREVIEW: Sample generated STORE values' as info,
    id,
    "STORE" as generated_display_name,
    banner,
    city,
    state,
    address,
    CASE 
        WHEN "STORE" LIKE banner || ' – ' || city || ' – ' || state || ' – %' THEN 'Has disambiguator'
        ELSE 'No disambiguator'
    END as has_disambiguator
FROM stores
WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown'
ORDER BY "STORE"
LIMIT 30;

-- Step 8: Check for duplicates in STORE column (should be minimal)
SELECT 
    'DUPLICATE CHECK: Generated STORE values' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids
FROM stores
WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown'
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;

-- Step 9: Verify regeneration completed and preservation rule will apply going forward
SELECT 
    'VERIFICATION: STORE regeneration complete' as info,
    COUNT(*) as total_stores,
    COUNT(*) FILTER (WHERE "STORE" IS NOT NULL AND btrim("STORE") != '' AND "STORE" != 'Unknown – Unknown – Unknown') as stores_with_valid_STORE,
    COUNT(*) FILTER (WHERE "STORE" = 'Unknown – Unknown – Unknown') as stores_with_placeholder_remaining,
    'Placeholder values were regenerated. Going forward, preservation rule applies: Once STORE is set (non-null, non-empty, non-whitespace, non-placeholder), it will NEVER be modified by this script' as preservation_rule
FROM stores;
