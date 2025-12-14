-- ========================================
-- Diagnose actual structure of both tables
-- ========================================

-- Show stores table structure
SELECT 
    'STORES TABLE' as table_name,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Show stores_import table structure
SELECT 
    'STORES_IMPORT TABLE' as table_name,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

-- Compare side by side
SELECT 
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    si.column_name as stores_import_column,
    si.ordinal_position as stores_import_pos,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        ELSE '✅ Match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.ordinal_position = si.ordinal_position
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

