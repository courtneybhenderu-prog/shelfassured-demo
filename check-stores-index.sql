-- Check what unique index exists on stores
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'stores' 
AND indexdef LIKE '%UNIQUE%';

