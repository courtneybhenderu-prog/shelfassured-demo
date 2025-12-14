-- ========================================
-- Delete rows from stores_import_new where CHAIN is NULL
-- Keep all rows where CHAIN is NOT NULL
-- ========================================

-- Step 1: Show count before deletion
SELECT 
    'BEFORE DELETION' as info,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE "CHAIN" IS NULL) as rows_with_null_CHAIN,
    COUNT(*) FILTER (WHERE "CHAIN" IS NOT NULL) as rows_with_CHAIN_value
FROM stores_import_new;

-- Step 2: Show sample rows that will be deleted
SELECT 
    'SAMPLE ROWS TO BE DELETED (where CHAIN IS NULL)' as info,
    id,
    "STORE",
    name,
    banner,
    "CHAIN",
    store_chain,
    city,
    state
FROM stores_import_new
WHERE "CHAIN" IS NULL
LIMIT 10;

-- Step 3: Delete rows where CHAIN is NULL
DELETE FROM stores_import_new 
WHERE "CHAIN" IS NULL;

-- Step 4: Show count after deletion
SELECT 
    'AFTER DELETION' as info,
    COUNT(*) as total_rows_remaining,
    COUNT(*) FILTER (WHERE "CHAIN" IS NULL) as remaining_null_CHAIN_rows,
    COUNT(*) FILTER (WHERE "CHAIN" IS NOT NULL) as rows_with_CHAIN_value
FROM stores_import_new;

-- Step 5: Verify - should show 0 rows with NULL CHAIN
SELECT 
    'VERIFICATION' as info,
    CASE 
        WHEN COUNT(*) FILTER (WHERE "CHAIN" IS NULL) = 0 
        THEN '✅ All NULL CHAIN rows deleted successfully'
        ELSE '⚠️ Some NULL CHAIN rows still exist'
    END as status,
    COUNT(*) FILTER (WHERE "CHAIN" IS NULL) as remaining_null_count
FROM stores_import_new;

-- Step 6: Final summary
SELECT 
    'FINAL SUMMARY' as info,
    COUNT(*) as total_rows,
    'All remaining rows have CHAIN value (not NULL)' as message
FROM stores_import_new;

