-- ========================================
-- FINAL: Rebuild stores_import to EXACTLY match stores table
-- This explicitly handles all columns including generated ones
-- ========================================

-- Step 1: Drop stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Get exact column definitions from stores
-- First, let's see the actual structure
SELECT 
    'STORES ACTUAL STRUCTURE' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Step 3: Create stores_import using LIKE with INCLUDING DEFAULTS
-- This should copy structure including generated columns
CREATE TABLE stores_import (LIKE stores INCLUDING DEFAULTS INCLUDING GENERATED);

-- Step 4: Verify the match
SELECT 
    'VERIFICATION' as info,
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    si.column_name as stores_import_column,
    si.ordinal_position as stores_import_pos,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 5: Count verification
SELECT 
    'COUNT VERIFICATION' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import')
        THEN '✅ Counts match'
        ELSE '❌ Counts differ'
    END as status;

