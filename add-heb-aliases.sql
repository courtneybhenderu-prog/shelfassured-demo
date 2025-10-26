-- Add H-E-B aliases including "Heb" without hyphens
-- Run this in Supabase SQL editor

-- Add more aliases for H-E-B
INSERT INTO retailer_aliases(alias, retailer_id)
SELECT x.alias, r.id
FROM (values
  ('heb','H-E-B'),
  ('h-e-b','H-E-B'),
  ('h e b','H-E-B'),
  ('heb grocery','H-E-B'),
  ('heb plus','H-E-B'),
  ('heb efc','H-E-B'),
  ('heb fresh bites','H-E-B'),
  ('heb rx','H-E-B')
) as x(alias, canon)
join retailers r on r.name = x.canon
ON CONFLICT (alias) DO NOTHING;

-- Verify
SELECT alias, retailer_id 
FROM retailer_aliases 
WHERE alias LIKE '%heb%' 
ORDER BY alias;

