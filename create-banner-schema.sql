-- Create banner schema for store selector
-- This adds retailer_banners and retailer_banner_aliases tables

-- 1. Create retailer_banners table (banner = sub-division of retailer, e.g., "Tom Thumb" under Kroger)
CREATE TABLE IF NOT EXISTS retailer_banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  retailer_id UUID NOT NULL REFERENCES retailers(id),
  name TEXT NOT NULL,
  UNIQUE(retailer_id, name)
);

-- 2. Create retailer_banner_aliases table for fuzzy matching
CREATE TABLE IF NOT EXISTS retailer_banner_aliases (
  alias TEXT PRIMARY KEY,
  banner_id UUID NOT NULL REFERENCES retailer_banners(id)
);

-- 3. Insert canonical retailers (if not exists)
INSERT INTO retailers(name) VALUES 
  ('H-E-B'),
  ('Kroger'),
  ('Sprouts Farmers Market')
ON CONFLICT (name) DO NOTHING;

-- 4. Insert retailer_banners (H-E-B, Kroger divisions, etc.)
INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'H-E-B'
FROM retailers r WHERE r.name = 'H-E-B'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, bb.name
FROM retailers r 
CROSS JOIN (VALUES 
  ('Tom Thumb'),
  ('Kroger'),
  ('Marketplace')
) AS bb(name)
WHERE r.name = 'Kroger'
ON CONFLICT (retailer_id, name) DO NOTHING;

INSERT INTO retailer_banners(retailer_id, name)
SELECT r.id, 'Sprouts Farmers Market'
FROM retailers r WHERE r.name = 'Sprouts Farmers Market'
ON CONFLICT (retailer_id, name) DO NOTHING;

-- 5. Insert aliases for banner matching
INSERT INTO retailer_banner_aliases(alias, banner_id)
SELECT alias, b.id
FROM retailer_banners b
CROSS JOIN (VALUES
  ('heb', 'H-E-B'),
  ('h-e-b', 'H-E-B'),
  ('h e b', 'H-E-B'),
  ('tom thumb', 'Tom Thumb'),
  ('tomthumb', 'Tom Thumb'),
  ('kroger', 'Kroger'),
  ('sprouts', 'Sprouts Farmers Market'),
  ('sprouts farmers market', 'Sprouts Farmers Market')
) AS al(alias, banner_name)
WHERE b.name = al.banner_name
ON CONFLICT (alias) DO NOTHING;

-- 6. Add banner_id and status to stores table if missing
ALTER TABLE stores 
  ADD COLUMN IF NOT EXISTS banner_id UUID REFERENCES retailer_banners(id),
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'unverified';

-- 7. Backfill banner_id from retailer_id and store_chain
UPDATE stores s
SET banner_id = b.id
FROM retailers r
JOIN retailer_banners b ON b.retailer_id = r.id
WHERE s.retailer_id = r.id
  AND LOWER(COALESCE(s.store_chain, '')) = LOWER(b.name)
  AND s.banner_id IS NULL;

-- 8. Create unique index on banner_id, street_norm, city_norm, state, zip5
DROP INDEX IF EXISTS stores_unique_norm;
CREATE UNIQUE INDEX stores_unique_norm
ON stores (banner_id, street_norm, city_norm, state, zip5)
WHERE banner_id IS NOT NULL AND street_norm IS NOT NULL 
  AND city_norm IS NOT NULL AND state IS NOT NULL AND zip5 IS NOT NULL;

-- 9. Update v_distinct_banners to use banner_id
DROP VIEW IF EXISTS v_distinct_banners;
CREATE OR REPLACE VIEW v_distinct_banners AS
SELECT DISTINCT
  b.id AS banner_id,
  b.name AS banner_name
FROM stores s
JOIN retailer_banners b ON b.id = s.banner_id
WHERE s.is_active = true
ORDER BY b.name;

GRANT SELECT ON v_distinct_banners TO authenticated;

-- 10. Verify
SELECT 'Retailers' as type, COUNT(*) as count FROM retailers
UNION ALL
SELECT 'Retailer Banners', COUNT(*) FROM retailer_banners
UNION ALL
SELECT 'Stores with banner_id', COUNT(*) FROM stores WHERE banner_id IS NOT NULL
UNION ALL
SELECT 'Total Active Stores', COUNT(*) FROM stores WHERE is_active = true;

