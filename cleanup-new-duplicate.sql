-- Clean up the new duplicate "DJ's Boudain" entry
-- Keep the original one, delete the new one

-- First, see what we have
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
ORDER BY created_at;

-- Delete the newer duplicate (keep the original from earlier)
DELETE FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
AND id NOT IN (
  SELECT id 
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
  ORDER BY created_at ASC 
  LIMIT 1
);

-- Verify cleanup
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%dj%'
ORDER BY created_at;


