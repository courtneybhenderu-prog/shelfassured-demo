-- Quick comparison of column names only
SELECT 
    s.column_name as stores_column,
    si.column_name as stores_import_column,
    CASE 
        WHEN si.column_name IS NULL THEN 'Missing in stores_import'
        WHEN s.column_name IS NULL THEN 'Extra in stores_import'
        WHEN s.column_name != si.column_name THEN 'Name mismatch'
        ELSE 'Match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.ordinal_position = si.ordinal_position
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

