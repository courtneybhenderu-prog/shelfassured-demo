-- Step 1: Diagnostics - locked decisions
-- Run in Supabase SQL Editor and paste results

-- 1. columns present
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='stores' ORDER BY 1;

-- 2. sample rows for sanity
SELECT id, name AS store_display, banner_id, metro, metro_norm, address, city, state, zip_code
FROM stores ORDER BY created_at DESC NULLS LAST LIMIT 25;

-- 3. banners available (will error if tables don't exist yet)
SELECT rb.id AS banner_id, rb.name AS banner_name, r.name AS parent
FROM retailer_banners rb 
JOIN retailers r ON r.id = rb.retailer_id
ORDER BY banner_name;

-- 4. view output used by selector
SELECT * FROM v_distinct_banners ORDER BY 1;

-- 5. Check for metro_norm column specifically
SELECT column_name 
FROM information_schema.columns 
WHERE table_name='stores' AND column_name IN ('metro', 'metro_norm');

-- 6. Check for generated columns
SELECT column_name 
FROM information_schema.columns 
WHERE table_name='stores' AND column_name IN ('zip5', 'state_zip');

