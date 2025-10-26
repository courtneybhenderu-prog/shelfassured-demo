-- Ultra-simple cleanup: Keep the first "DJ's Boudain", delete the rest
-- This is a one-shot cleanup that doesn't require manual ID replacement

-- First, let's see what we have
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
ORDER BY created_at;

-- Delete all "DJ's Boudain" entries except the very first one (oldest by created_at)
DELETE FROM brands 
WHERE LOWER(TRIM(name)) = 'dj''s boudain'
AND id NOT IN (
  SELECT id 
  FROM brands 
  WHERE LOWER(TRIM(name)) = 'dj''s boudain'
  ORDER BY created_at ASC 
  LIMIT 1
);

-- Verify cleanup worked
SELECT id, name, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%dj%'
ORDER BY created_at;

