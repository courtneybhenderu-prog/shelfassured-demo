-- Simple cleanup of duplicate "DJ's Boudain" entries
-- This will merge all duplicates into the oldest entry

-- Step 1: Find all "DJ's Boudain" entries
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
ORDER BY created_at;

-- Step 2: Get the ID of the oldest "DJ's Boudain" (this will be our master)
-- Replace 'OLDEST_ID_HERE' with the actual ID from Step 1
WITH oldest_dj AS (
  SELECT id, created_at
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
  ORDER BY created_at ASC
  LIMIT 1
)
SELECT id as master_id FROM oldest_dj;

-- Step 3: Update all products to point to the master brand
-- Replace 'MASTER_ID_HERE' with the ID from Step 2
UPDATE products 
SET brand = 'DJ''s Boudain'
WHERE brand = 'DJ''s Boudain';

-- Step 4: Delete all "DJ's Boudain" entries except the oldest one
-- Replace 'MASTER_ID_HERE' with the ID from Step 2
DELETE FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
AND id != 'MASTER_ID_HERE';

-- Step 5: Verify only one "DJ's Boudain" remains
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%dj%'
ORDER BY created_at;

