-- Step 1: Run diagnostic queries to understand current state
-- Copy and paste this to Supabase SQL Editor

-- stores schema
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='stores' ORDER BY 1;

-- sample stores
SELECT id, banner_id, store_chain, name, address, city, state, zip_code
FROM stores ORDER BY created_at DESC NULLS LAST LIMIT 25;

-- canonical banners (after schema is created)
SELECT rb.id AS banner_id, rb.name AS banner_name, r.name AS parent
FROM retailer_banners rb 
JOIN retailers r ON r.id = rb.retailer_id
ORDER BY banner_name;

-- view output
SELECT * FROM v_distinct_banners ORDER BY 1;

-- mismatches: store_chain that don't match any banner name (case-insensitive)
WITH chains AS (
  SELECT LOWER(store_chain) AS chain FROM stores
  WHERE store_chain IS NOT NULL GROUP BY 1
),
banners AS (
  SELECT LOWER(name) AS banner FROM retailer_banners
)
SELECT c.chain FROM chains c
WHERE c.chain NOT IN (SELECT banner FROM banners);

