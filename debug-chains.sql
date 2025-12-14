-- Check total stores
SELECT COUNT(*) as total_stores FROM stores WHERE state = 'TX';

-- Check stores with null or empty store_chain
SELECT 
  CASE 
    WHEN store_chain IS NULL THEN 'NULL'
    WHEN store_chain = '' THEN 'EMPTY'
    ELSE 'HAS VALUE'
  END as status,
  COUNT(*) as count
FROM stores
WHERE state = 'TX'
GROUP BY status;

-- Show all stores with their store_chain values
SELECT id, name, store_chain, address, city
FROM stores
WHERE state = 'TX'
ORDER BY store_chain, created_at DESC;

