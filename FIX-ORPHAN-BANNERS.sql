-- Fix orphan banners that have no stores
-- This consolidates duplicates and links stores

BEGIN;

-- STEP 1: Consolidate Trader Joes (no apostrophe) → Trader Joe's (with apostrophe)
UPDATE stores s
SET banner_id = (
  SELECT rb.id FROM retailer_banners rb 
  WHERE rb.name = 'Trader Joe''s'
  LIMIT 1
)
WHERE s.banner_id IN (
  SELECT id FROM retailer_banners 
  WHERE name = 'Trader Joes'
);

-- Delete the duplicate Trader Joes banner
DELETE FROM retailer_banners WHERE name = 'Trader Joes';

-- STEP 2: Consolidate all Walmart sub-banners → single Walmart banner
-- First, find the main Walmart banner
DO $$
DECLARE
  main_walmart_id UUID;
BEGIN
  SELECT id INTO main_walmart_id 
  FROM retailer_banners 
  WHERE name = 'Walmart' 
  LIMIT 1;
  
  -- Link all Walmart sub-banner stores to main Walmart
  UPDATE stores s
  SET banner_id = main_walmart_id
  WHERE s.banner_id IN (
    SELECT id FROM retailer_banners 
    WHERE name IN ('Walmart Supercenter', 'Walmart Fuel Station', 'Walmart Neighborhood Market')
  );
  
  -- Delete Walmart sub-banners
  DELETE FROM retailer_banners 
  WHERE name IN ('Walmart Supercenter', 'Walmart Fuel Station', 'Walmart Neighborhood Market');
END $$;

-- STEP 3: Try to match stores to orphan banners using normalized store data
-- This will attempt to link stores that have banner/store_chain values matching the orphan banners

UPDATE stores s
SET banner_id = rb.id
FROM retailer_banners rb
WHERE s.banner_id IS NULL 
  AND s.is_active = true
  AND rb.name IN ('Fiesta Mart', 'Whole Foods Market', 'Sprouts Farmers Market', 'Brookshire''s', 'Tom Thumb', 'Randalls')
  AND (
    UPPER(REGEXP_REPLACE(COALESCE(s.banner, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
    OR
    UPPER(REGEXP_REPLACE(COALESCE(s.store_chain, ''), '[^A-Z0-9]', '', 'g')) = 
    UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
  );

-- STEP 4: Rebuild the view
DROP VIEW IF EXISTS v_distinct_banners;

CREATE OR REPLACE VIEW v_distinct_banners AS
SELECT rb.id  AS banner_id,
       rb.name AS banner_name,
       COUNT(s.id) AS store_count
FROM retailer_banners rb
JOIN stores s ON s.banner_id = rb.id
GROUP BY rb.id, rb.name
ORDER BY rb.name;

GRANT SELECT ON v_distinct_banners TO authenticated;
GRANT SELECT ON v_distinct_banners TO anon;

-- STEP 5: Show final results
SELECT 'Final banner count' as info, banner_name, store_count
FROM v_distinct_banners
ORDER BY banner_name;

-- Show any remaining orphans
SELECT rb.name AS remaining_orphan
FROM retailer_banners rb
LEFT JOIN stores s ON s.banner_id = rb.id
GROUP BY rb.name
HAVING COUNT(s.id) = 0;

COMMIT;

