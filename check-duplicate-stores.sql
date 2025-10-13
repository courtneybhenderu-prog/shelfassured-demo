-- Check for duplicate stores in the database
-- This will help us identify why HEB - ALVIN appears twice

-- Check for exact duplicates by name and address
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

-- Show all HEB - ALVIN entries specifically
SELECT 
    id,
    name,
    address,
    city,
    state,
    zip_code,
    created_at,
    updated_at
FROM public.stores 
WHERE name LIKE '%ALVIN%' 
ORDER BY created_at;

-- Count total stores by name to see duplicates
SELECT 
    name,
    COUNT(*) as count
FROM public.stores 
WHERE state = 'TX'
GROUP BY name
ORDER BY count DESC;
