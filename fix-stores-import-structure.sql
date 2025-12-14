-- ========================================
-- Fix stores_import to EXACTLY match stores table
-- This uses a dynamic approach to ensure perfect match
-- ========================================

-- Step 1: First, run this to see what stores actually has
SELECT 
    'STEP 1: STORES TABLE STRUCTURE' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Step 2: Drop stores_import
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 3: Create stores_import using CREATE TABLE AS with zero rows
-- This copies the exact structure including generated columns
CREATE TABLE stores_import AS 
SELECT * FROM stores WHERE 1=0;

-- Step 4: Verify structures match
SELECT 
    'STEP 4: VERIFICATION' as info,
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
        ELSE '✅ Perfect match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 5: Show final structures
SELECT 
    'STORES FINAL STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'STORES_IMPORT FINAL STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

