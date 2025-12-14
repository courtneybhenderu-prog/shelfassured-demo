-- ========================================
-- COMPLETE FIX: Recreate stores_import to EXACTLY match stores
-- This script gets the exact structure and recreates it precisely
-- ========================================

-- Step 1: Drop stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Get the exact column definitions from stores and create stores_import
-- Using a DO block to dynamically build the CREATE TABLE statement
DO $$
DECLARE
    col_defs TEXT;
    create_stmt TEXT;
BEGIN
    -- Build column definitions from stores table
    SELECT string_agg(
        quote_ident(column_name) || ' ' ||
        CASE 
            WHEN data_type = 'character varying' THEN 
                'VARCHAR(' || COALESCE(character_maximum_length::TEXT, '255') || ')'
            WHEN data_type = 'text' THEN 'TEXT'
            WHEN data_type = 'uuid' THEN 'UUID'
            WHEN data_type = 'boolean' THEN 'BOOLEAN'
            WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
            WHEN data_type = 'timestamp without time zone' THEN 'TIMESTAMP'
            WHEN data_type = 'integer' THEN 'INTEGER'
            WHEN data_type = 'bigint' THEN 'BIGINT'
            WHEN data_type = 'numeric' THEN 
                'NUMERIC(' || numeric_precision || ',' || COALESCE(numeric_scale, 0) || ')'
            ELSE UPPER(data_type)
        END ||
        CASE 
            WHEN is_nullable = 'NO' THEN ' NOT NULL'
            ELSE ''
        END ||
        CASE 
            WHEN column_default IS NOT NULL AND column_default NOT LIKE 'GENERATED%' THEN 
                ' DEFAULT ' || column_default
            WHEN column_default LIKE 'GENERATED%' THEN 
                ' ' || column_default
            ELSE ''
        END,
        ', ' ORDER BY ordinal_position
    )
    INTO col_defs
    FROM information_schema.columns
    WHERE table_name = 'stores'
    ORDER BY ordinal_position;
    
    -- Build CREATE TABLE statement
    create_stmt := 'CREATE TABLE stores_import (' || col_defs || ')';
    
    -- Execute it
    EXECUTE create_stmt;
    
    RAISE NOTICE 'Table stores_import created successfully';
END $$;

-- Step 3: Verify perfect match - check by column name (not position)
SELECT 
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    si.column_name as stores_import_column,
    si.ordinal_position as stores_import_pos,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != si.data_type THEN '⚠️ Type mismatch'
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Perfect match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 4: Count verification
SELECT 
    'FINAL VERIFICATION' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_column_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_column_count,
    (SELECT COUNT(*) 
     FROM information_schema.columns s
     INNER JOIN information_schema.columns si ON s.column_name = si.column_name
     WHERE s.table_name = 'stores' AND si.table_name = 'stores_import') as matching_columns,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import')
        AND (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
            (SELECT COUNT(*) 
             FROM information_schema.columns s
             INNER JOIN information_schema.columns si ON s.column_name = si.column_name
             WHERE s.table_name = 'stores' AND si.table_name = 'stores_import')
        THEN '✅ PERFECT MATCH - All columns match!'
        ELSE '❌ Still has mismatches'
    END as final_status;

