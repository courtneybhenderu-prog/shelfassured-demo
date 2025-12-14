-- Create view for distinct banners (for dropdown)
-- This provides a clean list of unique banner names from active stores

CREATE OR REPLACE VIEW store_banners AS
SELECT DISTINCT 
    banner,
    COUNT(*) as store_count
FROM stores
WHERE is_active = TRUE
  AND banner IS NOT NULL
  AND banner != ''
GROUP BY banner
ORDER BY banner;

-- Grant access
GRANT SELECT ON store_banners TO authenticated;
GRANT SELECT ON store_banners TO anon;

-- Verify the view
SELECT * FROM store_banners ORDER BY banner LIMIT 20;

