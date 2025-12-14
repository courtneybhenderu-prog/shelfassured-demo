-- Check distinct values in each potential chain column
-- Count distinct values in lowercase columns
SELECT 'store_chain' as column_name, COUNT(DISTINCT store_chain) as distinct_count
FROM stores WHERE store_chain IS NOT NULL AND store_chain <> ''
UNION ALL
SELECT 'banner', COUNT(DISTINCT banner) FROM stores WHERE banner IS NOT NULL AND banner <> ''
UNION ALL
SELECT 'CHAIN (uppercase)', COUNT(DISTINCT "CHAIN") FROM stores WHERE "CHAIN" IS NOT NULL AND "CHAIN" <> '';

-- Show sample values from each
SELECT 'store_chain samples' as info, store_chain, COUNT(*) 
FROM stores 
WHERE store_chain IS NOT NULL AND store_chain <> ''
GROUP BY store_chain 
LIMIT 10;

SELECT 'banner samples' as info, banner, COUNT(*) 
FROM stores 
WHERE banner IS NOT NULL AND banner <> ''
GROUP BY banner 
LIMIT 10;

SELECT 'CHAIN samples' as info, "CHAIN", COUNT(*) 
FROM stores 
WHERE "CHAIN" IS NOT NULL AND "CHAIN" <> ''
GROUP BY "CHAIN" 
LIMIT 10;


