-- FINAL FIX - Team Approved Plan
-- Run this ONCE - all steps in a transaction for safety

BEGIN;

-- STEP 1: Diagnostics (for verification)
-- A) Banners with store counts
SELECT rb.id as banner_id, rb.name as banner_name, COUNT(s.id) as store_count
FROM retailer_banners rb
LEFT JOIN stores s ON s.banner_id = rb.id
GROUP BY rb.id, rb.name
ORDER BY rb.name;

-- B) How many stores still lack banner_id
SELECT COUNT(*) as stores_without_banner FROM stores WHERE banner_id IS NULL;

-- STEP 2: Ensure canonical retailers exist first
INSERT INTO retailers(name) VALUES 
  ('Albertsons Companies'),
  ('Kroger'),
  ('H-E-B'),
  ('Trader Joe''s'),
  ('Whole Foods Market'),
  ('Fiesta Mart'),
  ('Brookshire Grocery Company')
ON CONFLICT (name) DO NOTHING;

-- STEP 3: Ensure canonical banners exist (insert if missing)
INSERT INTO retailer_banners (retailer_id, name)
SELECT r.id, bname FROM (
  VALUES
    ('Albertsons Companies','Tom Thumb'),
    ('Albertsons Companies','Randalls'),
    ('Trader Joe''s','Trader Joe''s'),
    ('H-E-B','H-E-B'),
    ('Kroger','Kroger'),
    ('Whole Foods Market','Whole Foods Market'),
    ('Fiesta Mart','Fiesta Mart'),
    ('Brookshire Grocery Company','Brookshire''s')
) v(parent, bname)
JOIN retailers r ON r.name = v.parent
ON CONFLICT (retailer_id, name) DO NOTHING;

-- STEP 4: Point aliases at canonical banners
-- Kroger marketplace should map to Kroger
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('kroger marketplace'), ('marketplace')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Kroger'
ON CONFLICT (alias) DO NOTHING;

-- Trader Joe's apostrophes/variants
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('trader joe''s'), ('trader joe''s'), ('trader joes')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Trader Joe''s'
ON CONFLICT (alias) DO NOTHING;

-- Whole Foods variants
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('whole foods'), ('whole foods market')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Whole Foods Market'
ON CONFLICT (alias) DO NOTHING;

-- H-E-B variants
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('heb'), ('h-e-b'), ('h e b'), ('heb grocery')) x(alias)
JOIN retailer_banners rb ON rb.name = 'H-E-B'
ON CONFLICT (alias) DO NOTHING;

-- Brookshire's variants
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('brookshire''s'), ('brookshires'), ('brookshire brothers')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Brookshire''s'
ON CONFLICT (alias) DO NOTHING;

-- Tom Thumb / Randalls (Albertsons)
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('tom thumb')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Tom Thumb'
ON CONFLICT (alias) DO NOTHING;

INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('randalls')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Randalls'
ON CONFLICT (alias) DO NOTHING;

-- Fiesta
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT x.alias, rb.id
FROM (VALUES ('fiesta'), ('fiesta mart')) x(alias)
JOIN retailer_banners rb ON rb.name = 'Fiesta Mart'
ON CONFLICT (alias) DO NOTHING;

-- STEP 5: Remove orphan banners (accidental ones like "Marketplace")
DELETE FROM retailer_banners rb
WHERE rb.name IN ('Marketplace')
  AND NOT EXISTS (SELECT 1 FROM stores s WHERE s.banner_id = rb.id);

-- STEP 6: Backfill stores that still don't have a banner
UPDATE stores s
SET banner_id = (
  SELECT rb.id
  FROM retailer_banner_aliases rba
  JOIN retailer_banners rb ON rb.id = rba.banner_id
  WHERE LOWER(REGEXP_REPLACE(COALESCE(s.store_chain, s.banner, s.name), '[^a-z0-9]', '', 'g')) = 
        LOWER(REGEXP_REPLACE(rba.alias, '[^a-z0-9]', '', 'g'))
  LIMIT 1
)
WHERE s.banner_id IS NULL AND s.is_active = true;

-- STEP 7: Fix the view to power the dropdown
DROP VIEW IF EXISTS v_distinct_banners;

CREATE OR REPLACE VIEW v_distinct_banners AS
SELECT rb.id  AS banner_id,
       rb.name AS banner_name,
       COUNT(s.id) AS store_count
FROM retailer_banners rb
JOIN stores s ON s.banner_id = rb.id
WHERE s.is_active = true
GROUP BY rb.id, rb.name
ORDER BY rb.name;

GRANT SELECT ON v_distinct_banners TO authenticated;

-- STEP 8: Verify (shows final results)
SELECT 'BANNERS IN VIEW (with stores)' as info, banner_name, store_count
FROM v_distinct_banners
ORDER BY banner_name;

-- Show banners with zero stores (should not be in view)
SELECT rb.name as orphan_banner
FROM retailer_banners rb
LEFT JOIN stores s ON s.banner_id = rb.id
GROUP BY rb.name
HAVING COUNT(s.id) = 0;

COMMIT;

