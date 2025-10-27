-- COMPLETE FIX - Run this ONCE in Supabase SQL Editor
-- This adds missing retailers/banners, links all stores, and fixes the view

-- Step 1: Add missing retailers (if not exists)
INSERT INTO retailers(name) VALUES 
  ('Sprouts Farmers Market'),
  ('Whole Foods Market'),
  ('Fiesta Mart'),
  ('Lowes Markets'),
  ('Randalls'),
  ('Market Street'),
  ('Natural Grocers')
ON CONFLICT (name) DO NOTHING;

-- Step 2: Add missing banners (if not exists)
INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Trader Joes'
FROM retailers r WHERE r.name = 'Trader Joes'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Whole Foods Market'
FROM retailers r WHERE r.name = 'Whole Foods Market'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Sprouts Farmers Market'
FROM retailers r WHERE r.name = 'Sprouts Farmers Market'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Fiesta Mart'
FROM retailers r WHERE r.name = 'Fiesta Mart'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Lowes Markets'
FROM retailers r WHERE r.name = 'Lowes Markets'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Randalls'
FROM retailers r WHERE r.name = 'Randalls'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Market Street'
FROM retailers r WHERE r.name = 'Market Street'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Natural Grocers'
FROM retailers r WHERE r.name = 'Natural Grocers'
ON CONFLICT (retailer_id, name) DO NOTHING;

-- Step 3: Add Tom Thumb banner (under Kroger)
INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Tom Thumb'
FROM retailers r WHERE r.name = 'Kroger'
ON CONFLICT (retailer_id, name) DO NOTHING;

-- Step 4: Link all stores to banners using normalized matching
-- (This updates stores that don't have banner_id yet)
UPDATE stores s
SET banner_id = (
  SELECT rb.id
  FROM retailer_banners rb
  WHERE s.banner_id IS NULL 
    AND s.is_active = true
    AND (
      UPPER(REGEXP_REPLACE(COALESCE(s.banner, ''), '[^A-Z0-9]', '', 'g')) = 
      UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
      OR
      UPPER(REGEXP_REPLACE(COALESCE(s.store_chain, ''), '[^A-Z0-9]', '', 'g')) = 
      UPPER(REGEXP_REPLACE(rb.name, '[^A-Z0-9]', '', 'g'))
    )
  LIMIT 1
);

-- Step 5: Fix the v_distinct_banners view
DROP VIEW IF EXISTS v_distinct_banners;

CREATE OR REPLACE VIEW v_distinct_banners AS
SELECT DISTINCT
  s.banner_id,
  rb.name AS banner_name
FROM stores s
JOIN retailer_banners rb ON rb.id = s.banner_id
WHERE s.is_active = true AND s.banner_id IS NOT NULL
ORDER BY rb.name;

GRANT SELECT ON v_distinct_banners TO authenticated;

-- Step 6: Verify results
SELECT 
  'Total stores with banner_id' as status,
  COUNT(*) as count
FROM stores 
WHERE banner_id IS NOT NULL AND is_active = true
UNION ALL
SELECT 
  'Total banners in view',
  COUNT(*)
FROM v_distinct_banners;

-- Show all available banners
SELECT * FROM v_distinct_banners ORDER BY banner_name;

