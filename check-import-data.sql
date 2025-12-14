-- ========================================
-- Check stores_import data quality
-- ========================================

-- Total rows in stores_import
SELECT 
    'Total rows in stores_import' as check_type,
    COUNT(*) as count
FROM stores_import;

-- Rows with data (non-empty BANNER or ADDRESS)
SELECT 
    'Rows with actual data' as check_type,
    COUNT(*) as count
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Empty rows (no BANNER and no ADDRESS)
SELECT 
    'Empty rows (no BANNER, no ADDRESS)' as check_type,
    COUNT(*) as count
FROM stores_import
WHERE ("BANNER" IS NULL OR "BANNER" = '') 
  AND ("ADDRESS" IS NULL OR "ADDRESS" = '');

-- Duplicate rows (same BANNER + ADDRESS + CITY + STATE + ZIP)
SELECT 
    'Duplicate rows (same match key)' as check_type,
    COUNT(*) - COUNT(DISTINCT match_key) as duplicate_count
FROM stores_import
WHERE match_key IS NOT NULL;

-- Sample of rows to check data quality
SELECT 
    id,
    "BANNER",
    "ADDRESS",
    "CITY",
    "STATE",
    "ZIP",
    match_key
FROM stores_import
ORDER BY id
LIMIT 10;

-- Check for rows with missing critical fields
SELECT 
    'Rows missing BANNER' as issue,
    COUNT(*) as count
FROM stores_import
WHERE "BANNER" IS NULL OR "BANNER" = ''

UNION ALL

SELECT 
    'Rows missing ADDRESS' as issue,
    COUNT(*) as count
FROM stores_import
WHERE "ADDRESS" IS NULL OR "ADDRESS" = ''

UNION ALL

SELECT 
    'Rows missing CITY' as issue,
    COUNT(*) as count
FROM stores_import
WHERE "CITY" IS NULL OR "CITY" = ''

UNION ALL

SELECT 
    'Rows missing STATE' as issue,
    COUNT(*) as count
FROM stores_import
WHERE "STATE" IS NULL OR "STATE" = ''

UNION ALL

SELECT 
    'Rows missing ZIP' as issue,
    COUNT(*) as count
FROM stores_import
WHERE "ZIP" IS NULL OR "ZIP" = '';

