-- ========================================
-- SIMPLE DIRECT FIX: Recreate stores_import to match stores exactly
-- ========================================

-- Step 1: Drop stores_import
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import using CREATE TABLE AS (copies structure exactly)
CREATE TABLE stores_import AS 
SELECT * FROM stores LIMIT 0;

-- Step 3: If generated columns weren't copied, add them manually
-- Check if zip5 exists, if not add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'zip5'
    ) THEN
        ALTER TABLE stores_import 
        ADD COLUMN zip5 TEXT GENERATED ALWAYS AS (LEFT(zip_code, 5)) STORED;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'state_zip'
    ) THEN
        ALTER TABLE stores_import 
        ADD COLUMN state_zip TEXT GENERATED ALWAYS AS (state || '-' || zip5) STORED;
    END IF;
END $$;

-- Step 4: Remove any extra columns that shouldn't be there
DO $$
DECLARE
    extra_col TEXT;
BEGIN
    -- Remove columns that exist in stores_import but not in stores
    FOR extra_col IN 
        SELECT si.column_name
        FROM information_schema.columns si
        WHERE si.table_name = 'stores_import'
          AND NOT EXISTS (
              SELECT 1 FROM information_schema.columns s
              WHERE s.table_name = 'stores' 
                AND s.column_name = si.column_name
          )
    LOOP
        EXECUTE 'ALTER TABLE stores_import DROP COLUMN IF EXISTS ' || quote_ident(extra_col) || ' CASCADE';
    END LOOP;
END $$;

-- Step 5: Add any missing columns
DO $$
DECLARE
    missing_col RECORD;
    col_def TEXT;
BEGIN
    FOR missing_col IN 
        SELECT s.column_name, s.data_type, s.character_maximum_length, 
               s.is_nullable, s.column_default, s.ordinal_position
        FROM information_schema.columns s
        WHERE s.table_name = 'stores'
          AND NOT EXISTS (
              SELECT 1 FROM information_schema.columns si
              WHERE si.table_name = 'stores_import' 
                AND si.column_name = s.column_name
          )
        ORDER BY s.ordinal_position
    LOOP
        -- Build column definition
        col_def := quote_ident(missing_col.column_name) || ' ' ||
            CASE 
                WHEN missing_col.data_type = 'character varying' THEN 
                    'VARCHAR(' || COALESCE(missing_col.character_maximum_length::TEXT, '255') || ')'
                WHEN missing_col.data_type = 'text' THEN 'TEXT'
                WHEN missing_col.data_type = 'uuid' THEN 'UUID'
                WHEN missing_col.data_type = 'boolean' THEN 'BOOLEAN'
                WHEN missing_col.data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
                WHEN missing_col.data_type = 'timestamp without time zone' THEN 'TIMESTAMP'
                ELSE UPPER(missing_col.data_type)
            END ||
            CASE 
                WHEN missing_col.is_nullable = 'NO' THEN ' NOT NULL'
                ELSE ''
            END ||
            CASE 
                WHEN missing_col.column_default IS NOT NULL 
                     AND missing_col.column_default NOT LIKE 'GENERATED%' THEN 
                    ' DEFAULT ' || missing_col.column_default
                WHEN missing_col.column_default LIKE 'GENERATED%' THEN 
                    ' ' || missing_col.column_default
                ELSE ''
            END;
        
        EXECUTE 'ALTER TABLE stores_import ADD COLUMN ' || col_def;
    END LOOP;
END $$;

-- Step 6: Final verification
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
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

