-- ========================================
-- Check if stores_import table exists
-- Run this first to see what tables you have
-- ========================================

-- Check if stores_import exists
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'stores_import'
        ) THEN '✅ stores_import table EXISTS'
        ELSE '❌ stores_import table DOES NOT EXIST'
    END as table_status;

-- If it doesn't exist, show all tables that might be your import table
SELECT 
    'Available tables (might be your import table):' as info,
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name 
     AND column_name IN ('BANNER', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'CHAIN')) as matching_columns
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
  AND table_name LIKE '%import%' 
     OR table_name LIKE '%store%'
     OR table_name LIKE '%excel%'
ORDER BY table_name;

-- Show column structure if stores_import exists
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

