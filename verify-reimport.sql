-- ========================================
-- Verify the re-imported data
-- Run this after importing your fixed spreadsheet
-- ========================================

-- Total rows
SELECT 
    'Total rows imported' as check_type,
    COUNT(*) as count
FROM stores_import;

-- Rows with actual data (should be close to 2596)
SELECT 
    'Rows with data (BANNER or ADDRESS)' as check_type,
    COUNT(*) as count
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Empty rows (should be 0 or very few)
SELECT 
    'Empty rows' as check_type,
    COUNT(*) as count
FROM stores_import
WHERE ("BANNER" IS NULL OR "BANNER" = '') 
  AND ("ADDRESS" IS NULL OR "ADDRESS" = '');

-- Rows with METRO data (should be populated now)
SELECT 
    'Rows with METRO data' as check_type,
    COUNT(*) as count
FROM stores_import
WHERE "METRO" IS NOT NULL AND "METRO" != '';

-- Sample rows to verify data quality
SELECT 
    "BANNER",
    "ADDRESS",
    "CITY",
    "STATE",
    "ZIP",
    "METRO",
    "Store #"
FROM stores_import
WHERE "BANNER" IS NOT NULL
ORDER BY id
LIMIT 10;

