-- Clean up duplicate stores in the database
-- This will keep only the most recent entry for each store

-- Step 1: Check how many duplicates we have
SELECT 
    name,
    address,
    city,
    state,
    COUNT(*) as duplicate_count
FROM public.stores 
WHERE state = 'TX'
GROUP BY name, address, city, state
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Step 2: Delete duplicate stores (keep the most recent one)
-- This uses a window function to identify and remove duplicates
WITH duplicate_stores AS (
    SELECT 
        id,
        name,
        address,
        city,
        state,
        ROW_NUMBER() OVER (
            PARTITION BY name, address, city, state 
            ORDER BY created_at DESC
        ) as row_num
    FROM public.stores 
    WHERE state = 'TX'
)
DELETE FROM public.stores 
WHERE id IN (
    SELECT id 
    FROM duplicate_stores 
    WHERE row_num > 1
);

-- Step 3: Verify cleanup worked
SELECT COUNT(*) as total_texas_stores FROM public.stores WHERE state = 'TX';

-- Step 4: Show final store list
SELECT 
    name,
    address,
    city,
    state,
    zip_code,
    store_chain
FROM public.stores 
WHERE state = 'TX' 
ORDER BY name
LIMIT 10;
