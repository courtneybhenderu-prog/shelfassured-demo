-- Fix store_chain column for Whole Foods Market stores
-- Extract chain name from the store name

-- Step 1: Check current store_chain values for Whole Foods stores
SELECT name, store_chain, city, state
FROM stores 
WHERE name ILIKE '%whole%foods%'
LIMIT 10;

-- Step 2: Update store_chain for Whole Foods Market stores
UPDATE stores 
SET store_chain = 'Whole Foods Market'
WHERE name ILIKE '%whole%foods%market%';

-- Step 3: Verify the update
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain = 'Whole Foods Market'
GROUP BY store_chain;

-- Step 4: Check all store chains now
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain IS NOT NULL
GROUP BY store_chain
ORDER BY store_chain;
