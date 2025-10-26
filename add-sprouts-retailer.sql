-- Add Sprouts Farmers Market to retailers and update existing stores
-- Run this in Supabase SQL editor

-- Add Sprouts to retailers table
INSERT INTO retailers(name) 
VALUES ('Sprouts Farmers Market')
ON CONFLICT (name) DO NOTHING;

-- Add aliases for Sprouts
INSERT INTO retailer_aliases(alias, retailer_id)
SELECT x.alias, r.id
FROM (values
  ('sprouts','Sprouts Farmers Market'),
  ('sprouts farmers market','Sprouts Farmers Market'),
  ('sprouts market','Sprouts Farmers Market'),
  ('sprouts grocery','Sprouts Farmers Market')
) as x(alias, canon)
join retailers r on r.name = x.canon
ON CONFLICT (alias) DO NOTHING;

-- Update existing Sprouts stores to have retailer_id
UPDATE stores s
SET retailer_id = ra.retailer_id
FROM retailer_aliases ra
WHERE lower(s.store_chain) = ra.alias
  AND ra.alias IN ('sprouts', 'sprouts farmers market', 'sprouts market', 'sprouts grocery')
  AND s.retailer_id IS NULL;

-- Verify
SELECT 
  count(*) as sprouts_stores,
  count(retailer_id) as stores_with_retailer_id
FROM stores 
WHERE lower(store_chain) LIKE '%sprouts%';

