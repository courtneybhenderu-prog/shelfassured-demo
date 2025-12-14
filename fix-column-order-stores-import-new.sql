-- ========================================
-- Fix column order in stores_import_new to match stores exactly
-- PostgreSQL doesn't allow reordering columns, so we recreate the table
-- ========================================

-- Step 1: Get the exact column order from stores and build CREATE TABLE statement
DO $$
DECLARE
    col_defs TEXT;
    create_stmt TEXT;
    col_rec RECORD;
BEGIN
    -- Build column definitions in exact order from stores
    col_defs := '';
    
    FOR col_rec IN 
        SELECT 
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default,
            ordinal_position
        FROM information_schema.columns
        WHERE table_name = 'stores'
        ORDER BY ordinal_position
    LOOP
        IF col_defs != '' THEN
            col_defs := col_defs || ', ';
        END IF;
        
        col_defs := col_defs || quote_ident(col_rec.column_name) || ' ' ||
            CASE 
                WHEN col_rec.data_type = 'character varying' THEN 
                    'VARCHAR(' || COALESCE(col_rec.character_maximum_length::TEXT, '255') || ')'
                WHEN col_rec.data_type = 'text' THEN 'TEXT'
                WHEN col_rec.data_type = 'uuid' THEN 'UUID'
                WHEN col_rec.data_type = 'boolean' THEN 'BOOLEAN'
                WHEN col_rec.data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
                WHEN col_rec.data_type = 'timestamp without time zone' THEN 'TIMESTAMP'
                WHEN col_rec.data_type = 'integer' THEN 'INTEGER'
                WHEN col_rec.data_type = 'bigint' THEN 'BIGINT'
                WHEN col_rec.data_type = 'numeric' THEN 
                    'NUMERIC(' || col_rec.numeric_precision || ',' || COALESCE(col_rec.numeric_scale, 0) || ')'
                ELSE UPPER(col_rec.data_type)
            END ||
            CASE 
                WHEN col_rec.is_nullable = 'NO' THEN ' NOT NULL'
                ELSE ''
            END ||
            CASE 
                WHEN col_rec.column_default IS NOT NULL 
                     AND col_rec.column_default NOT LIKE 'GENERATED%' THEN 
                    ' DEFAULT ' || col_rec.column_default
                WHEN col_rec.column_default LIKE 'GENERATED%' THEN 
                    ' ' || col_rec.column_default
                ELSE ''
            END;
    END LOOP;
    
    -- Drop existing table
    DROP TABLE IF EXISTS stores_import_new CASCADE;
    
    -- Create new table with correct column order
    create_stmt := 'CREATE TABLE stores_import_new (' || col_defs || ')';
    EXECUTE create_stmt;
    
    RAISE NOTICE 'Table stores_import_new recreated with correct column order';
END $$;

-- Step 2: Verify column positions now match
SELECT 
    'POSITION VERIFICATION' as info,
    s.column_name,
    s.ordinal_position as stores_position,
    si.ordinal_position as stores_import_new_position,
    CASE 
        WHEN s.ordinal_position = si.ordinal_position THEN '✅ Position matches'
        ELSE '❌ Position differs'
    END as status
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
ORDER BY s.ordinal_position;

-- Step 3: Check for any remaining position differences
SELECT 
    'REMAINING POSITION DIFFERENCES' as info,
    s.column_name,
    s.ordinal_position as stores_position,
    si.ordinal_position as stores_import_new_position,
    (s.ordinal_position - si.ordinal_position) as position_difference
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.ordinal_position != si.ordinal_position
ORDER BY s.ordinal_position;

-- Step 4: Final verification - all should match now
SELECT 
    'FINAL VERIFICATION' as info,
    COUNT(*) FILTER (WHERE s.ordinal_position = si.ordinal_position) as matching_positions,
    COUNT(*) FILTER (WHERE s.ordinal_position != si.ordinal_position) as mismatched_positions,
    COUNT(*) as total_columns,
    CASE 
        WHEN COUNT(*) FILTER (WHERE s.ordinal_position != si.ordinal_position) = 0 
        THEN '✅ All positions match perfectly!'
        ELSE '❌ Some positions still differ'
    END as status
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new';

