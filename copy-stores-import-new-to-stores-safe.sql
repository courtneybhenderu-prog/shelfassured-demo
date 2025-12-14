-- ========================================
-- SAFE VERSION: Delete all data from stores and copy from stores_import_new
-- Uses DELETE instead of TRUNCATE to preserve data in referencing tables
-- ========================================

-- Step 1: Show counts before operation
SELECT 
    'BEFORE OPERATION' as info,
    (SELECT COUNT(*) FROM stores) as stores_row_count,
    (SELECT COUNT(*) FROM stores_import_new) as stores_import_new_row_count;

-- Step 2: Verify column structures match (safety check)
SELECT 
    'COLUMN STRUCTURE CHECK' as info,
    COUNT(*) FILTER (WHERE s.column_name = si.column_name AND s.data_type = si.data_type) as matching_columns,
    COUNT(*) FILTER (WHERE s.column_name IS NULL) as missing_in_stores,
    COUNT(*) FILTER (WHERE si.column_name IS NULL) as missing_in_import,
    CASE 
        WHEN COUNT(*) FILTER (WHERE s.column_name IS NULL OR si.column_name IS NULL) = 0
        THEN '✅ Structures match - safe to copy'
        ELSE '⚠️ Structure mismatch - review before copying'
    END as safety_status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import_new';

-- Step 3: Delete all data from stores (preserves foreign key relationships)
-- This is slower than TRUNCATE but doesn't affect referencing tables
DELETE FROM stores;

-- Step 4: Copy all data from stores_import_new to stores
INSERT INTO stores 
SELECT * FROM stores_import_new;

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

-- Step 6: Sample data comparison
SELECT 
    'SAMPLE: stores_import_new (source)' as source,
    id,
    "STORE",
    banner,
    city,
    state,
    "CHAIN"
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
    store_chain
FROM stores
ORDER BY id
LIMIT 5;

-- Step 7: Final summary
SELECT 
    'FINAL SUMMARY' as info,
    'All data copied from stores_import_new to stores' as message,
    (SELECT COUNT(*) FROM stores) as total_rows_in_stores,
    (SELECT COUNT(*) FROM stores_import_new) as total_rows_in_import;

