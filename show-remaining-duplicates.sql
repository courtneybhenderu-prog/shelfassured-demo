-- ========================================
-- Show remaining duplicate STORE values after refinement
-- ========================================

-- Show all remaining duplicates
SELECT 
    'REMAINING DUPLICATES' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids,
    string_agg(COALESCE(address, "ADDRESS", 'No address'), ' | ' ORDER BY id) as addresses
FROM stores
WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, "STORE";

-- Show detailed view of each duplicate group
SELECT 
    'DETAILED DUPLICATE ANALYSIS' as info,
    s.id,
    s."STORE",
    s.banner,
    s.city,
    s.state,
    s.address,
    s."ADDRESS",
    CASE 
        WHEN s."STORE" LIKE '% – % – % – %' THEN
            SPLIT_PART(s."STORE", ' – ', 4)
        ELSE 'No disambiguator'
    END as current_disambiguator,
    ROW_NUMBER() OVER (PARTITION BY s."STORE" ORDER BY s.id) as duplicate_rank
FROM stores s
WHERE s."STORE" IN (
    SELECT "STORE" 
    FROM stores 
    WHERE "STORE" IS NOT NULL AND btrim("STORE") != ''
    GROUP BY "STORE" 
    HAVING COUNT(*) > 1
)
ORDER BY s."STORE", s.id;

