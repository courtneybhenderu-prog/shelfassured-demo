-- Fix v_distinct_banners view to use banner_id properly

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

-- Verify it works
SELECT * FROM v_distinct_banners ORDER BY banner_name;
