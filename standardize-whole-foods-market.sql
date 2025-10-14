-- Standardize "Whole Foods Market" across the database
-- This script updates all variations of Whole Foods to the consistent "Whole Foods Market"

-- Step 1: Check current Whole Foods variations in the database
SELECT DISTINCT chain, COUNT(*) as store_count
FROM stores 
WHERE chain ILIKE '%whole%foods%' 
GROUP BY chain
ORDER BY chain;

-- Step 2: Update all Whole Foods variations to "Whole Foods Market"
UPDATE stores 
SET chain = 'Whole Foods Market'
WHERE chain ILIKE '%whole%foods%';

-- Step 3: Verify the update
SELECT DISTINCT chain, COUNT(*) as store_count
FROM stores 
WHERE chain ILIKE '%whole%foods%' 
GROUP BY chain
ORDER BY chain;

-- Step 4: Check for any remaining variations
SELECT DISTINCT chain, COUNT(*) as store_count
FROM stores 
WHERE chain ILIKE '%whole%' 
GROUP BY chain
ORDER BY chain;
