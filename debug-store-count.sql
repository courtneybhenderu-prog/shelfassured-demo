-- Test query to check actual store count and limits
-- This will help us understand if the issue is with Supabase limits or our queries

-- Step 1: Check total store count
SELECT COUNT(*) as total_stores FROM stores;

-- Step 2: Check active Texas stores count
SELECT COUNT(*) as active_tx_stores 
FROM stores 
WHERE state = 'TX' AND is_active = true;

-- Step 3: Check if there are any stores beyond 1000
SELECT name, city, state, is_active, created_at
FROM stores 
WHERE state = 'TX' AND is_active = true
ORDER BY name
LIMIT 5 OFFSET 1000;

-- Step 4: Check the last few stores alphabetically
SELECT name, city, state, is_active, created_at
FROM stores 
WHERE state = 'TX' AND is_active = true
ORDER BY name DESC
LIMIT 5;
