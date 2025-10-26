-- Step 1: Run diagnostic queries on CURRENT schema (before migrations)
-- Copy and paste this to Supabase SQL Editor

-- 1. stores schema (check what columns exist NOW)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='stores' ORDER BY 1;

-- 2. sample stores (showing banner column since banner_id doesn't exist yet)
SELECT id, banner, store_chain, name, address, city, state, zip_code
FROM stores ORDER BY created_at DESC NULLS LAST LIMIT 25;

-- 3. check if retailer_banners table exists
SELECT 
  table_name, 
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name IN ('retailers', 'retailer_banners', 'retailer_aliases')
GROUP BY table_name;

-- 4. check distinct store_chain/banner values in stores
SELECT 
  COALESCE(store_chain, banner, 'Unknown') as chain_name,
  COUNT(*) as store_count
FROM stores 
WHERE is_active = true
GROUP BY chain_name
ORDER BY store_count DESC;

-- 5. check v_distinct_banners if it exists
SELECT * FROM v_distinct_banners ORDER BY 1;

