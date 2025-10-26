-- Clean up duplicate "DJ's Boudain" entries
-- This merges all duplicate brands into one record

-- First, let's see what we have
SELECT id, name, website, primary_email, phone, address, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%dj%' 
ORDER BY created_at;

-- Find the oldest "DJ's Boudain" entry to keep as the master
WITH duplicate_brands AS (
  SELECT id, name, created_at,
         ROW_NUMBER() OVER (ORDER BY created_at ASC) as rn
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
)
SELECT id as master_id, name, created_at
FROM duplicate_brands 
WHERE rn = 1;

-- Merge all "DJ's Boudain" entries into the oldest one
-- (Replace 'YOUR_MASTER_ID_HERE' with the actual ID from the query above)
WITH duplicate_brands AS (
  SELECT id, name, created_at,
         ROW_NUMBER() OVER (ORDER BY created_at ASC) as rn
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
),
master_brand AS (
  SELECT id as master_id
  FROM duplicate_brands 
  WHERE rn = 1
),
duplicate_ids AS (
  SELECT id as duplicate_id
  FROM duplicate_brands 
  WHERE rn > 1
)
-- Update products to point to master brand
UPDATE products 
SET brand = (SELECT name FROM brands WHERE id = (SELECT master_id FROM master_brand))
WHERE brand IN (SELECT name FROM brands WHERE id IN (SELECT duplicate_id FROM duplicate_ids));

-- Delete duplicate brand records (keep the master)
DELETE FROM brands 
WHERE id IN (
  SELECT id 
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
  ORDER BY created_at ASC 
  OFFSET 1
);

-- Verify cleanup
SELECT id, name, website, primary_email, phone, address, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%dj%' 
ORDER BY created_at;

