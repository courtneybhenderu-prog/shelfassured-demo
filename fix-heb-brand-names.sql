-- Update brand names from "Heb" to "H-E-B"
-- Run this in Supabase SQL editor

UPDATE brands
SET name = 'H-E-B'
WHERE name = 'Heb' 
   OR name LIKE 'Heb %'
   OR name = 'H-E-B'
   OR name LIKE 'H-E-B %';

-- Verify
SELECT name, count(*) 
FROM brands 
WHERE name LIKE '%heb%' OR name LIKE '%H-E-B%'
GROUP BY name 
ORDER BY name;

