-- Check store data to understand what's being returned
SELECT 
    COUNT(*) as total_stores,
    COUNT(CASE WHEN store_chain LIKE '%Sprouts%' THEN 1 END) as sprouts_stores,
    COUNT(CASE WHEN store_chain LIKE '%HEB%' OR store_chain LIKE '%H-E-B%' THEN 1 END) as heb_stores,
    COUNT(CASE WHEN store_chain LIKE '%Whole Foods%' THEN 1 END) as whole_foods_stores
FROM stores 
WHERE state = 'TX' 
AND is_active = true;

-- Sample stores with different chains
SELECT name, store_chain, city, state
FROM stores 
WHERE state = 'TX' AND is_active = true
ORDER BY store_chain, city
LIMIT 20;
