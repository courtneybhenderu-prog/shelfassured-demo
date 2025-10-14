-- Check what store chains actually exist in the database
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain IS NOT NULL
GROUP BY store_chain
ORDER BY store_chain;
