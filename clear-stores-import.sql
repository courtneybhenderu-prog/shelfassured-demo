-- ========================================
-- Clear stores_import table for re-import
-- Run this before re-importing your fixed spreadsheet
-- ========================================

-- Option 1: Truncate (keeps table structure, removes all rows)
TRUNCATE TABLE stores_import;

-- Verify it's empty
SELECT 
    '✅ stores_import table cleared' as status,
    COUNT(*) as remaining_rows
FROM stores_import;

-- Note: If you want to completely drop and recreate instead, use:
-- DROP TABLE IF EXISTS stores_import;
-- Then run create-stores-import-table.sql again

