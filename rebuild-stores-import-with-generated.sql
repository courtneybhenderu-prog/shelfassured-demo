-- ========================================
-- Rebuild stores_import to EXACTLY match stores
-- Uses LIKE with INCLUDING GENERATED to copy generated columns
-- ========================================

-- Step 1: Drop stores_import
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import using LIKE with all INCLUDING options
-- This copies: columns, types, defaults, constraints, indexes, and GENERATED columns
CREATE TABLE stores_import (LIKE stores INCLUDING ALL);

-- Step 3: Verify perfect match
SELECT 
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    si.column_name as stores_import_column,
    si.ordinal_position as stores_import_pos,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Perfect match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 4: Show column counts
SELECT 
    'COLUMN COUNT' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_count;

