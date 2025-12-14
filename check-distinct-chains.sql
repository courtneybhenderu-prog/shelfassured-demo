-- Count distinct chains in stores table
SELECT 
  store_chain,
  COUNT(*) as store_count
FROM stores
WHERE store_chain IS NOT NULL 
  AND store_chain <> ''
GROUP BY store_chain
ORDER BY store_count DESC;

-- Total count of distinct chains
SELECT 
  COUNT(DISTINCT store_chain) as total_distinct_chains
FROM stores
WHERE store_chain IS NOT NULL 
  AND store_chain <> '';


