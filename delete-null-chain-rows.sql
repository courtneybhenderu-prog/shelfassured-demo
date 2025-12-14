-- ========================================
-- Delete rows from stores_import_new where chain/store_chain is NULL
-- ========================================

-- Step 1: Check what chain columns exist and show NULL counts
SELECT 
    'BEFORE DELETION: NULL CHAIN ANALYSIS' as info,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE store_chain IS NULL) as null_store_chain_count,
    COUNT(*) FILTER (WHERE "CHAIN" IS NULL) as null_CHAIN_count,
    COUNT(*) FILTER (WHERE store_chain IS NULL OR "CHAIN" IS NULL) as null_chain_total
FROM stores_import_new;

-- Step 2: Show sample rows that will be deleted
SELECT 
    'SAMPLE ROWS TO BE DELETED' as info,
    id,
    "STORE",
    name,
    banner,
    store_chain,
    "CHAIN",
    city,
    state
FROM stores_import_new
WHERE store_chain IS NULL 
   OR "CHAIN" IS NULL
LIMIT 10;

-- Step 3: Delete rows where chain is NULL
-- Check which column name is used (store_chain or CHAIN)
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Delete rows where store_chain is NULL (if column exists)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import_new' AND column_name = 'store_chain'
    ) THEN
        DELETE FROM stores_import_new WHERE store_chain IS NULL;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % rows where store_chain IS NULL', deleted_count;
    END IF;
    
    -- Also delete rows where CHAIN (uppercase) is NULL (if column exists)
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import_new' AND column_name = 'CHAIN'
    ) THEN
        DELETE FROM stores_import_new WHERE "CHAIN" IS NULL;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % rows where CHAIN IS NULL', deleted_count;
    END IF;
    
    -- If both columns exist, delete rows where BOTH are NULL
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import_new' AND column_name = 'store_chain'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import_new' AND column_name = 'CHAIN'
    ) THEN
        DELETE FROM stores_import_new 
        WHERE store_chain IS NULL AND "CHAIN" IS NULL;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE 'Deleted % rows where both store_chain AND CHAIN are NULL', deleted_count;
    END IF;
END $$;

-- Step 4: Verify deletion - show remaining NULL chain rows (should be 0)
SELECT 
    'AFTER DELETION: REMAINING NULL CHAIN ROWS' as info,
    COUNT(*) as remaining_null_chain_rows
FROM stores_import_new
WHERE store_chain IS NULL 
   OR "CHAIN" IS NULL;

-- Step 5: Show final row count
SELECT 
    'FINAL ROW COUNT' as info,
    COUNT(*) as total_rows_remaining,
    COUNT(*) FILTER (WHERE store_chain IS NOT NULL) as rows_with_store_chain,
    COUNT(*) FILTER (WHERE "CHAIN" IS NOT NULL) as rows_with_CHAIN
FROM stores_import_new;

-- Step 6: Show summary of what was deleted
SELECT 
    'DELETION SUMMARY' as info,
    'Rows with NULL chain values have been deleted' as message,
    (SELECT COUNT(*) FROM stores_import_new) as remaining_rows;

