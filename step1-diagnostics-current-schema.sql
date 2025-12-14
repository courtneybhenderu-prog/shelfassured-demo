-- Step 1: Diagnostics for CURRENT schema (before migrations)
-- Run in Supabase SQL Editor and paste ALL results

-- 1. columns present in stores table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='stores' ORDER BY 1;

-- 2. sample store rows (current structure)
SELECT id, name AS store_display, banner, store_chain, metro, address, city, state, zip_code
FROM stores ORDER BY created_at DESC NULLS LAST LIMIT 25;

-- 3. Check if banner tables exist
SELECT 
  table_name, 
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name IN ('retailers', 'retailer_banners', 'retailer_aliases', 'retailer_banner_aliases')
GROUP BY table_name
ORDER BY table_name;

-- 4. Check v_distinct_banners view (will error if doesn't exist)
SELECT * FROM v_distinct_banners ORDER BY 1;

-- 5. Check for metro_norm and generated columns
SELECT column_name, data_type, is_generated
FROM information_schema.columns 
WHERE table_name='stores' AND column_name IN ('metro', 'metro_norm', 'zip5', 'state_zip')
ORDER BY column_name;

-- 6. Count stores by banner/chain
SELECT 
  COALESCE(banner, store_chain, 'Unknown') AS banner_name,
  COUNT(*) AS store_count
FROM stores 
WHERE is_active = true
GROUP BY banner_name
ORDER BY store_count DESC
LIMIT 20;
