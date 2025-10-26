-- Fix ON CONFLICT to match existing index
-- Run this in Supabase SQL editor

-- Drop old index if it exists
DROP INDEX IF EXISTS stores_unique_norm;

-- Create index WITHOUT zip5 (generated column can't be in unique constraint easily)
CREATE UNIQUE INDEX IF NOT EXISTS stores_unique_norm
ON stores (retailer_id, street_norm, city_norm, state)
WHERE retailer_id IS NOT NULL 
  AND street_norm IS NOT NULL 
  AND city_norm IS NOT NULL 
  AND state IS NOT NULL;

-- Verify index was created
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'stores' 
AND indexdef LIKE '%UNIQUE%';

