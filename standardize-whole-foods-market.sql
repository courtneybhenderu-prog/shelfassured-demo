-- Standardize "Whole Foods Market" across the database
-- This script updates all variations of Whole Foods to the consistent "Whole Foods Market"

-- Step 1: Check current Whole Foods variations in the database
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain ILIKE '%whole%foods%' 
GROUP BY store_chain
ORDER BY store_chain;

-- Step 2: Update all Whole Foods variations to "Whole Foods Market"
UPDATE stores 
SET store_chain = 'Whole Foods Market'
WHERE store_chain ILIKE '%whole%foods%';

-- Step 3: Verify the update
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain ILIKE '%whole%foods%' 
GROUP BY store_chain
ORDER BY store_chain;

-- Step 4: Check for any remaining variations
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores 
WHERE store_chain ILIKE '%whole%' 
GROUP BY store_chain
ORDER BY store_chain;
