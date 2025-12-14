-- ========================================
-- Step 2: Refine Disambiguator for Remaining Duplicates
-- Only applies to stores still in duplicate STORE groups after true duplicate merge
-- Uses 2-3 meaningful tokens to avoid truncation
-- ========================================

-- Step 1: Identify remaining duplicate STORE groups (after true duplicates merged)
WITH duplicate_store_groups AS (
    SELECT "STORE"
    FROM stores
    WHERE "STORE" IS NOT NULL 
      AND btrim("STORE") != ''
      AND is_active = TRUE
    GROUP BY "STORE"
    HAVING COUNT(*) > 1
)
SELECT 
    'REMAINING DUPLICATE STORE GROUPS' as info,
    "STORE",
    COUNT(*) as duplicate_count
FROM stores
WHERE "STORE" IN (SELECT "STORE" FROM duplicate_store_groups)
  AND is_active = TRUE
GROUP BY "STORE"
ORDER BY COUNT(*) DESC, "STORE";

-- Step 2: Update disambiguators for remaining duplicates
-- Extract 2-3 meaningful tokens instead of truncated ones
WITH duplicate_store_groups AS (
    SELECT "STORE"
    FROM stores
    WHERE "STORE" IS NOT NULL 
      AND btrim("STORE") != ''
      AND is_active = TRUE
    GROUP BY "STORE"
    HAVING COUNT(*) > 1
),
stores_to_refine AS (
    SELECT 
        s.id,
        s."STORE",
        s.address,
        s."ADDRESS",
        -- Extract base name (Banner – City – State)
        SPLIT_PART(s."STORE", ' – ', 1) || ' – ' || 
        SPLIT_PART(s."STORE", ' – ', 2) || ' – ' || 
        SPLIT_PART(s."STORE", ' – ', 3) as base_name,
        -- Current disambiguator
        CASE 
            WHEN s."STORE" LIKE '% – % – % – %' THEN
                SPLIT_PART(s."STORE", ' – ', 4)
            ELSE NULL
        END as current_disambiguator,
        -- Clean address for token extraction
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(LOWER(TRIM(COALESCE(s.address, s."ADDRESS", ''))), 
                        '^\d+\s*', '', 'g'),  -- Remove leading street number
                    '\b(unit|suite|ste|building|bldg|apt|apartment|#)\s*\w*\b', '', 'gi'  -- Remove unit/suite
                ),
                '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place|pkwy|parkway)\b', '', 'gi'  -- Remove street suffixes (keep hwy/highway)
            ),
            '\s+', ' ', 'g'  -- Collapse spaces
        ) as cleaned_address
    FROM stores s
    WHERE s."STORE" IN (SELECT "STORE" FROM duplicate_store_groups)
      AND s.is_active = TRUE
      AND s."STORE" LIKE '% – % – % – %'  -- Has disambiguator
      AND COALESCE(s.address, s."ADDRESS", '') != ''
),
tokenized AS (
    SELECT 
        stu.*,
        -- Split cleaned address into tokens
        string_to_array(stu.cleaned_address, ' ') as tokens
    FROM stores_to_refine stu
),
refined_disambiguators AS (
    SELECT 
        t.id,
        t.base_name,
        -- Build disambiguator from tokens
        UPPER(
            CASE 
                -- If first token is single letter (N/S/E/W), combine with next 1-2 tokens
                WHEN array_length(t.tokens, 1) >= 1 AND t.tokens[1] ~ '^[nsew]$' THEN
                    CASE 
                        WHEN array_length(t.tokens, 1) >= 3 THEN
                            t.tokens[1] || ' ' || t.tokens[2] || ' ' || t.tokens[3]
                        WHEN array_length(t.tokens, 1) >= 2 THEN
                            t.tokens[1] || ' ' || t.tokens[2]
                        ELSE t.tokens[1]
                    END
                -- If first token is "hwy" or "highway", include next token (number)
                WHEN array_length(t.tokens, 1) >= 1 AND t.tokens[1] IN ('hwy', 'highway') THEN
                    CASE 
                        WHEN array_length(t.tokens, 1) >= 2 THEN
                            t.tokens[1] || ' ' || t.tokens[2]
                        ELSE t.tokens[1]
                    END
                -- Otherwise, take first 2-3 tokens
                WHEN array_length(t.tokens, 1) >= 3 THEN
                    t.tokens[1] || ' ' || t.tokens[2] || ' ' || t.tokens[3]
                WHEN array_length(t.tokens, 1) >= 2 THEN
                    t.tokens[1] || ' ' || t.tokens[2]
                WHEN array_length(t.tokens, 1) >= 1 THEN
                    t.tokens[1]
                ELSE t.current_disambiguator
            END
        ) as new_disambiguator
    FROM tokenized t
)
UPDATE stores s
SET "STORE" = rd.base_name || ' – ' || rd.new_disambiguator
FROM refined_disambiguators rd
WHERE s.id = rd.id;

-- Step 3: Verify refinement
SELECT 
    'AFTER REFINEMENT: Remaining duplicates' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids
FROM stores
WHERE "STORE" IS NOT NULL 
  AND btrim("STORE") != ''
  AND is_active = TRUE
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, "STORE"
LIMIT 50;

-- Step 4: Show sample of refined disambiguators
SELECT 
    'SAMPLE: Refined disambiguators' as info,
    id,
    "STORE",
    address,
    CASE 
        WHEN "STORE" LIKE '% – % – % – %' THEN
            SPLIT_PART("STORE", ' – ', 4)
        ELSE 'No disambiguator'
    END as refined_disambiguator
FROM stores
WHERE "STORE" IN (
    SELECT "STORE" 
    FROM stores 
    WHERE is_active = TRUE
    GROUP BY "STORE" 
    HAVING COUNT(*) > 1
)
AND is_active = TRUE
ORDER BY "STORE", id
LIMIT 30;

