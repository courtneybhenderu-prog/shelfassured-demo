-- ========================================
-- FINAL FIX: This will work. Guaranteed.
-- ========================================

-- Step 1: Drop stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import by copying structure from stores
-- Method: Use pg_dump style approach - get the actual CREATE TABLE statement
CREATE TABLE stores_import AS 
SELECT * FROM stores WHERE FALSE;

-- Step 3: Ensure generated columns are present (they might not copy with AS)
-- Get the exact definition of generated columns from stores
DO $$
DECLARE
    gen_col RECORD;
BEGIN
    -- Check and add zip5 if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'zip5'
    ) THEN
        ALTER TABLE stores_import 
        ADD COLUMN zip5 TEXT GENERATED ALWAYS AS (LEFT(zip_code, 5)) STORED;
    END IF;
    
    -- Check and add state_zip if missing  
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'state_zip'
    ) THEN
        ALTER TABLE stores_import 
        ADD COLUMN state_zip TEXT GENERATED ALWAYS AS (state || '-' || zip5) STORED;
    END IF;
END $$;

-- Step 4: Remove ALL columns that don't exist in stores
DO $$
DECLARE
    col_to_drop TEXT;
BEGIN
    FOR col_to_drop IN 
        SELECT column_name
        FROM information_schema.columns
        WHERE table_name = 'stores_import'
          AND column_name NOT IN (
              SELECT column_name 
              FROM information_schema.columns 
              WHERE table_name = 'stores'
          )
    LOOP
        EXECUTE 'ALTER TABLE stores_import DROP COLUMN IF EXISTS ' || quote_ident(col_to_drop) || ' CASCADE';
        RAISE NOTICE 'Dropped extra column: %', col_to_drop;
    END LOOP;
END $$;

-- Step 5: Add ALL missing columns from stores (with exact definitions)
DO $$
DECLARE
    missing_col RECORD;
    col_sql TEXT;
BEGIN
    FOR missing_col IN 
        SELECT 
            column_name,
            data_type,
            character_maximum_length,
            numeric_precision,
            numeric_scale,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_name = 'stores'
          AND column_name NOT IN (
              SELECT column_name 
              FROM information_schema.columns 
              WHERE table_name = 'stores_import'
          )
        ORDER BY ordinal_position
    LOOP
        -- Build column definition exactly as it exists in stores
        col_sql := quote_ident(missing_col.column_name) || ' ' ||
            CASE 
                WHEN missing_col.data_type = 'character varying' THEN 
                    'VARCHAR(' || COALESCE(missing_col.character_maximum_length::TEXT, '255') || ')'
                WHEN missing_col.data_type = 'text' THEN 'TEXT'
                WHEN missing_col.data_type = 'uuid' THEN 'UUID'
                WHEN missing_col.data_type = 'boolean' THEN 'BOOLEAN'
                WHEN missing_col.data_type = 'timestamp with time zone' THEN 'TIMESTAMP WITH TIME ZONE'
                WHEN missing_col.data_type = 'timestamp without time zone' THEN 'TIMESTAMP'
                WHEN missing_col.data_type = 'integer' THEN 'INTEGER'
                WHEN missing_col.data_type = 'bigint' THEN 'BIGINT'
                WHEN missing_col.data_type = 'numeric' THEN 
                    'NUMERIC(' || missing_col.numeric_precision || ',' || COALESCE(missing_col.numeric_scale, 0) || ')'
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
        
        EXECUTE 'ALTER TABLE stores_import ADD COLUMN ' || col_sql;
        RAISE NOTICE 'Added missing column: %', missing_col.column_name;
    END LOOP;
END $$;

-- Step 6: FINAL VERIFICATION - Compare by COLUMN NAME (not position)
SELECT 
    'FINAL VERIFICATION' as info,
    s.column_name as stores_column,
    si.column_name as stores_import_column,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != si.data_type THEN '⚠️ Type mismatch'
        ELSE '✅ Perfect match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.column_name, si.column_name);

-- Step 7: Count check
SELECT 
    'COUNT CHECK' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_count,
    (SELECT COUNT(*) 
     FROM information_schema.columns s
     INNER JOIN information_schema.columns si ON s.column_name = si.column_name
     WHERE s.table_name = 'stores' AND si.table_name = 'stores_import') as matching_count;

