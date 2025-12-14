-- ========================================
-- Step 3: Final Duplicate Report
-- Shows remaining duplicates after all refinements
-- ========================================

-- Final duplicate count
SELECT 
    'FINAL DUPLICATE REPORT' as info,
    COUNT(DISTINCT "STORE") as unique_store_names,
    COUNT(*) as total_active_stores,
    (SELECT COUNT(*) 
     FROM (
         SELECT "STORE" 
         FROM stores 
         WHERE is_active = TRUE
         GROUP BY "STORE" 
         HAVING COUNT(*) > 1
     ) dupes) as duplicate_groups_remaining,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT "STORE")
        THEN '✅ All STORE values are unique!'
        ELSE '⚠️ Some duplicates remain (may be legitimate - different stores with same name)'
    END as uniqueness_status
FROM stores
WHERE is_active = TRUE
  AND "STORE" IS NOT NULL 
  AND btrim("STORE") != '';

-- All remaining duplicates
SELECT 
    'ALL REMAINING DUPLICATES' as info,
    "STORE",
    COUNT(*) as duplicate_count,
    string_agg(id::text, ', ' ORDER BY id) as store_ids,
    string_agg(COALESCE(address, "ADDRESS", 'No address'), ' | ' ORDER BY id) as addresses,
    string_agg(COALESCE(store_number, 'No number'), ' | ' ORDER BY id) as store_numbers
FROM stores
WHERE is_active = TRUE
  AND "STORE" IS NOT NULL 
  AND btrim("STORE") != ''
GROUP BY "STORE"
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, "STORE";

