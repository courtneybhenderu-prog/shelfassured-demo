-- ========================================
-- Delete all data from stores and copy all data from stores_import_new to stores
-- FIXED: Excludes generated columns (zip5, state_zip)
-- ========================================

-- Step 1: Show counts before operation
SELECT 
    'BEFORE OPERATION' as info,
    (SELECT COUNT(*) FROM stores) as stores_row_count,
    (SELECT COUNT(*) FROM stores_import_new) as stores_import_new_row_count;

-- Step 2: Get list of non-generated columns from stores
-- This will be used to build the INSERT statement
SELECT 
    'NON-GENERATED COLUMNS IN stores' as info,
    string_agg(column_name, ', ' ORDER BY ordinal_position) as column_list
FROM information_schema.columns
WHERE table_name = 'stores'
  AND (column_default IS NULL OR column_default NOT LIKE 'GENERATED%');

-- Step 3: Delete all data from stores
-- Using CASCADE to handle foreign key constraints
TRUNCATE TABLE stores CASCADE;

-- Step 4: Copy all data from stores_import_new to stores
-- Dynamically build INSERT statement excluding generated columns
DO $$
DECLARE
    col_list TEXT;
    insert_sql TEXT;
BEGIN
    -- Build column list (excluding generated columns: zip5, state_zip)
    SELECT string_agg(quote_ident(column_name), ', ' ORDER BY ordinal_position)
    INTO col_list
    FROM information_schema.columns
    WHERE table_name = 'stores'
      AND column_name NOT IN ('zip5', 'state_zip')
      AND (column_default IS NULL OR column_default NOT LIKE 'GENERATED%');
    
    -- Build INSERT statement
    insert_sql := 'INSERT INTO stores (' || col_list || ') SELECT ' || col_list || ' FROM stores_import_new';
    
    -- Execute the INSERT
    EXECUTE insert_sql;
    
    RAISE NOTICE 'Data copied successfully. Generated columns (zip5, state_zip) will be auto-calculated.';
END $$;

-- Step 5: Verify the copy was successful
SELECT 
    'AFTER COPY: VERIFICATION' as info,
    (SELECT COUNT(*) FROM stores) as stores_row_count,
    (SELECT COUNT(*) FROM stores_import_new) as stores_import_new_row_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM stores) = (SELECT COUNT(*) FROM stores_import_new)
        THEN '✅ Row counts match - copy successful'
        ELSE '❌ Row counts differ - check for errors'
    END as copy_status;

-- Step 6: Verify generated columns were auto-calculated
SELECT 
    'GENERATED COLUMNS VERIFICATION' as info,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE zip5 IS NOT NULL) as rows_with_zip5,
    COUNT(*) FILTER (WHERE state_zip IS NOT NULL) as rows_with_state_zip,
    CASE 
        WHEN COUNT(*) FILTER (WHERE zip5 IS NOT NULL) = COUNT(*)
         AND COUNT(*) FILTER (WHERE state_zip IS NOT NULL) = COUNT(*)
        THEN '✅ All generated columns populated'
        ELSE '⚠️ Some generated columns missing'
    END as generated_status
FROM stores;

-- Step 7: Sample data comparison
SELECT 
    'SAMPLE: stores_import_new (source)' as source,
    id,
    "STORE",
    banner,
    city,
    state,
    zip_code,
    zip5 as zip5_generated
FROM stores_import_new
ORDER BY id
LIMIT 5;

SELECT 
    'SAMPLE: stores (copied)' as source,
    id,
    "STORE",
    banner,
    city,
    state,
    zip_code,
    zip5 as zip5_generated
FROM stores
ORDER BY id
LIMIT 5;

-- Step 8: Final summary
SELECT 
    'FINAL SUMMARY' as info,
    'All data copied from stores_import_new to stores' as message,
    (SELECT COUNT(*) FROM stores) as total_rows_in_stores,
    (SELECT COUNT(*) FROM stores_import_new) as total_rows_in_import;

