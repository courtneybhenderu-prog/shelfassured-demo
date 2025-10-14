-- Check actual chain names for H-E-B and Tom Thumb
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain ILIKE '%heb%' OR store_chain ILIKE '%tom%thumb%'
GROUP BY store_chain
ORDER BY store_chain;
