-- ========================================
-- Clear stores_import table completely
-- ========================================

-- OPTION 1: TRUNCATE (Fast - removes all rows, keeps table structure)
-- This is the fastest way to clear all data but keeps the table and columns
TRUNCATE TABLE stores_import;

-- OPTION 2: DELETE (Slower but same result - removes all rows, keeps table structure)
-- DELETE FROM stores_import;

-- OPTION 3: DROP TABLE (Removes table entirely including structure)
-- WARNING: This will delete the table completely. You'll need to recreate it.
-- Uncomment the next two lines if you want to drop the table entirely:
-- DROP TABLE IF EXISTS stores_import CASCADE;

-- Verify the table is empty
SELECT 
    'VERIFICATION' as info,
    COUNT(*) as remaining_rows
FROM stores_import;

-- Show table structure (to confirm it still exists if using TRUNCATE/DELETE)
SELECT 
    'TABLE STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

