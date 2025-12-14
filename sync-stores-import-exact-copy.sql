-- ========================================
-- Recreate stores_import to match stores table EXACTLY
-- Uses CREATE TABLE AS to copy structure exactly
-- ========================================

-- Step 1: Drop existing stores_import
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import with EXACT same structure as stores
-- This creates an empty table with the same structure
CREATE TABLE stores_import (LIKE stores INCLUDING ALL);

-- Step 3: Verify structures match exactly
SELECT 
    'VERIFICATION: COLUMN COUNT' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_column_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_column_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import')
        THEN '✅ MATCH'
        ELSE '❌ MISMATCH'
    END as status;

-- Step 4: Detailed column-by-column comparison
SELECT 
    s.column_name,
    s.data_type as stores_type,
    s.is_nullable as stores_nullable,
    s.column_default as stores_default,
    si.data_type as stores_import_type,
    si.is_nullable as stores_import_nullable,
    si.column_default as stores_import_default,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ MISSING IN IMPORT'
        WHEN s.column_name IS NULL THEN '⚠️ EXTRA IN IMPORT'
        WHEN s.data_type != si.data_type THEN '❌ TYPE MISMATCH'
        WHEN s.is_nullable != si.is_nullable THEN '⚠️ NULLABLE MISMATCH'
        WHEN COALESCE(s.column_default, '') != COALESCE(si.column_default, '') THEN '⚠️ DEFAULT MISMATCH'
        ELSE '✅ MATCH'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name 
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 5: Show both structures
SELECT 
    'STORES TABLE STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'STORES_IMPORT TABLE STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

