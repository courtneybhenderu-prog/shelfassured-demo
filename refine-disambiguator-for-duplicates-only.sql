-- ========================================
-- Refine disambiguator logic for duplicate STORE values only
-- Extends generic prefixes (San, Saint, St, North, South, etc.) to include next token
-- Preserves all non-duplicated STORE values
-- ========================================

-- Step 1: Identify stores with duplicate STORE values
SELECT 
    'DUPLICATE STORE VALUES' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids
FROM stores
WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, "STORE";

-- Step 2: For each duplicate, check if disambiguator needs refinement
-- This shows which stores have generic prefix disambiguators
WITH duplicates AS (
    SELECT "STORE", COUNT(*) as cnt
    FROM stores
    WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
    GROUP BY "STORE"
    HAVING COUNT(*) > 1
),
store_analysis AS (
    SELECT 
        s.id,
        s."STORE",
        s.address,
        s."ADDRESS",
        -- Extract current disambiguator (part after last " – ")
        CASE 
            WHEN s."STORE" LIKE '% – % – % – %' THEN
                SPLIT_PART(s."STORE", ' – ', 4)
            ELSE NULL
        END as current_disambiguator,
        -- Check if it starts with generic prefix
        CASE 
            WHEN SPLIT_PART(s."STORE", ' – ', 4) ~* '^(san|saint|st|north|south|east|west|new|old|upper|lower|great|little|big|small|fort|mount|lake|river|park|valley|hill|beach|bay|port|point|cape|island|isle)' 
            THEN TRUE
            ELSE FALSE
        END as has_generic_prefix
    FROM stores s
    INNER JOIN duplicates d ON s."STORE" = d."STORE"
)
SELECT 
    'STORES NEEDING DISAMBIGUATOR REFINEMENT' as info,
    id,
    "STORE",
    current_disambiguator,
    has_generic_prefix,
    address
FROM store_analysis
WHERE has_generic_prefix = TRUE
ORDER BY "STORE", id
LIMIT 50;

-- Step 3: Update only duplicate STORE values with refined disambiguators
-- This will extend generic prefixes to include the next token
WITH duplicates AS (
    SELECT "STORE"
    FROM stores
    WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
    GROUP BY "STORE"
    HAVING COUNT(*) > 1
),
stores_to_update AS (
    SELECT 
        s.id,
        s."STORE" as current_store,
        s.banner,
        s."BANNER",
        s.city,
        s."CITY",
        s.state,
        s."STATE",
        s.address,
        s."ADDRESS",
        -- Extract base name (Banner – City – State)
        SPLIT_PART(s."STORE", ' – ', 1) || ' – ' || 
        SPLIT_PART(s."STORE", ' – ', 2) || ' – ' || 
        SPLIT_PART(s."STORE", ' – ', 3) as base_name,
        -- Extract current disambiguator
        CASE 
            WHEN s."STORE" LIKE '% – % – % – %' THEN
                SPLIT_PART(s."STORE", ' – ', 4)
            ELSE NULL
        END as current_disambiguator
    FROM stores s
    INNER JOIN duplicates d ON s."STORE" = d."STORE"
    WHERE s."STORE" LIKE '% – % – % – %'  -- Has disambiguator
      AND SPLIT_PART(s."STORE", ' – ', 4) ~* '^(san|saint|st|north|south|east|west|new|old|upper|lower|great|little|big|small|fort|mount|lake|river|park|valley|hill|beach|bay|port|point|cape|island|isle)'  -- Starts with generic prefix
)
UPDATE stores s
SET "STORE" = (
    stu.base_name || ' – ' || 
    UPPER(
        -- Extract extended disambiguator: prefix + next token
        COALESCE(
            -- Try to get prefix + next word from address
            (regexp_match(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(LOWER(TRIM(COALESCE(s.address, s."ADDRESS", ''))), 
                                '^\d+\s*', '', 'g'),  -- Remove leading street number
                            '\b(unit|suite|ste|building|bldg|apt|apartment|#)\s*\w*\b', '', 'gi'  -- Remove unit/suite
                        ),
                        '\b(n|s|e|w)\b', '', 'gi'  -- Remove single letter directions
                    ),
                    '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place|pkwy|parkway|hwy|highway)\b', '', 'gi'  -- Remove street suffixes
                ),
                '^((san|saint|st|north|south|east|west|new|old|upper|lower|great|little|big|small|fort|mount|lake|river|park|valley|hill|beach|bay|port|point|cape|island|isle)\s+[a-z]{3,})'  -- Match prefix + next word
            ))[1],
            -- Fallback: keep current disambiguator if can't extend
            stu.current_disambiguator
        )
    )
)
FROM stores_to_update stu
WHERE s.id = stu.id;

-- Step 4: Verify duplicates after refinement
SELECT 
    'AFTER REFINEMENT: Remaining duplicates' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids
FROM stores
WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, "STORE"
LIMIT 30;

-- Step 5: Show sample of refined STORE values
SELECT 
    'SAMPLE: Refined STORE values' as info,
    id,
    "STORE",
    address,
    CASE 
        WHEN "STORE" LIKE '% – % – % – %' THEN
            'Has disambiguator: ' || SPLIT_PART("STORE", ' – ', 4)
        ELSE 'No disambiguator'
    END as disambiguator_info
FROM stores
WHERE "STORE" IN (
    SELECT "STORE" 
    FROM stores 
    GROUP BY "STORE" 
    HAVING COUNT(*) > 1
)
ORDER BY "STORE", id
LIMIT 30;

-- Step 6: Count improvement
SELECT 
    'IMPROVEMENT SUMMARY' as info,
    (SELECT COUNT(DISTINCT "STORE") FROM stores WHERE "STORE" IS NOT NULL) as unique_store_names,
    (SELECT COUNT(*) FROM stores WHERE "STORE" IS NOT NULL) as total_stores,
    (SELECT COUNT(*) 
     FROM (
         SELECT "STORE" 
         FROM stores 
         GROUP BY "STORE" 
         HAVING COUNT(*) > 1
     ) dupes) as duplicate_groups_remaining,
    CASE 
        WHEN (SELECT COUNT(*) FROM stores WHERE "STORE" IS NOT NULL) = 
             (SELECT COUNT(DISTINCT "STORE") FROM stores WHERE "STORE" IS NOT NULL)
        THEN '✅ All STORE values are unique!'
        ELSE '⚠️ Some duplicates remain'
    END as uniqueness_status;

