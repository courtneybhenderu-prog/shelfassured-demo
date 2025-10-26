-- Deduplicate brands before creating unique index
-- Run this in Supabase SQL editor

-- Delete duplicate brands (keep the oldest one)
DELETE FROM brands
WHERE id IN (
  SELECT id FROM (
    SELECT id, row_number() over (
      partition by lower(name), coalesce(website, '') 
      order by created_at
    ) as rn
    FROM brands
  ) sub
  WHERE rn > 1
);

-- Now create the unique index
CREATE UNIQUE INDEX IF NOT EXISTS brands_unique_name_site
ON brands (lower(name), coalesce(website, ''));

-- Verify
SELECT 
  name, 
  website, 
  count(*) as duplicates
FROM brands 
GROUP BY name, website 
HAVING count(*) > 1;

-- Should return 0 rows if deduplication worked

