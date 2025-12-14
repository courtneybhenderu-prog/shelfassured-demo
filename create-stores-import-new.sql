-- ========================================
-- Delete stores_import and create stores_import_new as exact replica of stores
-- ========================================

-- Step 1: Drop stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import_new as exact replica of stores
-- Using LIKE with INCLUDING ALL copies everything: columns, types, defaults, constraints, indexes, generated columns
CREATE TABLE stores_import_new (LIKE stores INCLUDING ALL);

-- Step 3: Verify stores_import_new matches stores exactly
SELECT 
    'VERIFICATION: stores vs stores_import_new' as info,
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    s.data_type as stores_type,
    si.column_name as stores_import_new_column,
    si.ordinal_position as stores_import_new_pos,
    si.data_type as stores_import_new_type,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import_new'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import_new'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != si.data_type THEN '⚠️ Type mismatch'
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Perfect match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import_new'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Step 4: Count verification
SELECT 
    'COUNT VERIFICATION' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import_new') as stores_import_new_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') = 
             (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import_new')
        THEN '✅ Counts match'
        ELSE '❌ Counts differ'
    END as status;

-- Step 5: Show both structures
SELECT 
    'STORES TABLE STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'STORES_IMPORT_NEW TABLE STRUCTURE' as info,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores_import_new'
ORDER BY ordinal_position;

