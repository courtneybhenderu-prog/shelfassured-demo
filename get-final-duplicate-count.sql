-- ========================================
-- Get Final Duplicate Count for Documentation
-- Run this to get exact numbers for STORE-NAMING-RULES.md
-- ========================================

SELECT 
    'FINAL DUPLICATE COUNT (December 2025)' as info,
    COUNT(*) as total_active_stores,
    COUNT(DISTINCT "STORE") as unique_store_names,
    COUNT(*) - COUNT(DISTINCT "STORE") as stores_in_duplicate_groups,
    (SELECT COUNT(*) 
     FROM (
         SELECT "STORE" 
         FROM stores 
         WHERE is_active = TRUE
           AND "STORE" IS NOT NULL 
           AND btrim("STORE") != ''
         GROUP BY "STORE" 
         HAVING COUNT(*) > 1
     ) dupes) as duplicate_groups_remaining,
    ROUND(100.0 * COUNT(DISTINCT "STORE") / COUNT(*), 1) as uniqueness_percentage
FROM stores
WHERE is_active = TRUE
  AND "STORE" IS NOT NULL 
  AND btrim("STORE") != '';

