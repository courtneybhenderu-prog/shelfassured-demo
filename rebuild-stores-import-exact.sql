-- ========================================
-- Rebuild stores_import to EXACTLY match stores table
-- This will fix all column mismatches
-- ========================================

-- Step 1: Show what stores actually has (for reference)
SELECT 
    'STORES TABLE STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Step 2: Drop stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 3: Recreate stores_import with EXACT same structure as stores
-- Using CREATE TABLE AS with WHERE 1=0 copies structure exactly
CREATE TABLE stores_import AS 
SELECT * FROM stores WHERE 1=0;

-- Step 4: Verify perfect match
SELECT 
    'VERIFICATION: PERFECT MATCH CHECK' as info,
    s.column_name,
    s.data_type as stores_type,
    si.data_type as stores_import_type,
    s.ordinal_position as stores_pos,
    si.ordinal_position as stores_import_pos,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != si.data_type THEN '⚠️ Type mismatch'
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

-- Step 5: Count columns to confirm
SELECT 
    'COLUMN COUNT VERIFICATION' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import') as stores_import_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import')
        THEN '✅ Count matches'
        ELSE '❌ Count mismatch'
    END as status;

-- Step 6: Show final structures side by side
SELECT 
    'FINAL: STORES STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'FINAL: STORES_IMPORT STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

