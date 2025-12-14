-- ========================================
-- Dynamically recreate stores_import to match stores table EXACTLY
-- This script reads the stores table structure and creates an exact copy
-- ========================================

-- Step 1: First, let's see what the stores table structure is
SELECT 
    'STORES TABLE STRUCTURE' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Step 2: Drop and recreate stores_import
DO $$
DECLARE
    col_def TEXT;
    create_sql TEXT;
BEGIN
    -- Drop existing table
    DROP TABLE IF EXISTS stores_import CASCADE;
    
    -- Build CREATE TABLE statement dynamically from stores structure
    SELECT 
        'CREATE TABLE stores_import (' || 
        string_agg(
            column_name || ' ' || 
            CASE 
                WHEN data_type = 'character varying' THEN 'VARCHAR(' || COALESCE(character_maximum_length::TEXT, '255') || ')'
                WHEN data_type = 'text' THEN 'TEXT'
                WHEN data_type = 'uuid' THEN 'UUID'
                WHEN data_type = 'boolean' THEN 'BOOLEAN'
                WHEN data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
                WHEN data_type = 'timestamp without time zone' THEN 'TIMESTAMP'
                ELSE UPPER(data_type)
            END ||
            CASE 
                WHEN is_nullable = 'NO' THEN ' NOT NULL'
                ELSE ''
            END ||
            CASE 
                WHEN column_default IS NOT NULL AND column_default NOT LIKE 'GENERATED%' THEN ' DEFAULT ' || column_default
                WHEN column_default LIKE 'GENERATED%' THEN ' ' || column_default
                ELSE ''
            END,
            ', '
            ORDER BY ordinal_position
        ) || 
        ')'
    INTO create_sql
    FROM information_schema.columns
    WHERE table_name = 'stores';
    
    -- Execute the CREATE TABLE
    EXECUTE create_sql;
    
    RAISE NOTICE 'Table stores_import created to match stores structure exactly';
END $$;

-- Step 3: Verify structures match
SELECT 
    'VERIFICATION: COLUMN COUNT' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_column_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_column_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import')
        THEN 'MATCH'
        ELSE 'MISMATCH'
    END as status;

-- Step 4: Show detailed comparison
SELECT 
    s.column_name,
    s.data_type as stores_type,
    si.data_type as stores_import_type,
    s.ordinal_position as stores_position,
    si.ordinal_position as stores_import_position,
    CASE 
        WHEN si.column_name IS NULL THEN 'MISSING IN IMPORT'
        WHEN s.column_name IS NULL THEN 'EXTRA IN IMPORT'
        WHEN s.data_type != si.data_type THEN 'TYPE MISMATCH'
        WHEN s.ordinal_position != si.ordinal_position THEN 'POSITION MISMATCH'
        ELSE 'MATCH'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name 
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

