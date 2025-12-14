-- ========================================
-- Compare stores and stores_import_new tables
-- Shows column names, data types, and definitions side by side
-- ========================================

-- Comparison 1: Side-by-side column comparison
SELECT 
    COALESCE(s.column_name, si.column_name) as column_name,
    s.ordinal_position as stores_position,
    s.data_type as stores_data_type,
    s.character_maximum_length as stores_max_length,
    s.numeric_precision as stores_numeric_precision,
    s.numeric_scale as stores_numeric_scale,
    s.is_nullable as stores_nullable,
    s.column_default as stores_default,
    si.ordinal_position as stores_import_new_position,
    si.data_type as stores_import_new_data_type,
    si.character_maximum_length as stores_import_new_max_length,
    si.numeric_precision as stores_import_new_numeric_precision,
    si.numeric_scale as stores_import_new_numeric_scale,
    si.is_nullable as stores_import_new_nullable,
    si.column_default as stores_import_new_default,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import_new'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import_new'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != si.data_type THEN '⚠️ Data type mismatch'
        WHEN s.character_maximum_length != si.character_maximum_length THEN '⚠️ Length mismatch'
        WHEN s.numeric_precision != si.numeric_precision THEN '⚠️ Precision mismatch'
        WHEN s.numeric_scale != si.numeric_scale THEN '⚠️ Scale mismatch'
        WHEN s.is_nullable != si.is_nullable THEN '⚠️ Nullable mismatch'
        WHEN COALESCE(s.column_default, '') != COALESCE(si.column_default, '') THEN '⚠️ Default mismatch'
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Perfect match'
    END as comparison_status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import_new'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

-- Comparison 2: Summary statistics
SELECT 
    'SUMMARY STATISTICS' as info,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores') as stores_column_count,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_import_new') as stores_import_new_column_count,
    (SELECT COUNT(*) 
     FROM information_schema.columns s
     INNER JOIN information_schema.columns si ON s.column_name = si.column_name
     WHERE s.table_name = 'stores' AND si.table_name = 'stores_import_new') as matching_column_count,
    (SELECT COUNT(*) 
     FROM information_schema.columns s
     LEFT JOIN information_schema.columns si ON s.column_name = si.column_name AND si.table_name = 'stores_import_new'
     WHERE s.table_name = 'stores' AND si.column_name IS NULL) as missing_in_import_new,
    (SELECT COUNT(*) 
     FROM information_schema.columns si
     LEFT JOIN information_schema.columns s ON si.column_name = s.column_name AND s.table_name = 'stores'
     WHERE si.table_name = 'stores_import_new' AND s.column_name IS NULL) as extra_in_import_new;

-- Comparison 3: Detailed data type comparison
SELECT 
    s.column_name,
    s.data_type as stores_data_type,
    CASE 
        WHEN s.character_maximum_length IS NOT NULL THEN s.data_type || '(' || s.character_maximum_length || ')'
        WHEN s.numeric_precision IS NOT NULL THEN s.data_type || '(' || s.numeric_precision || ',' || COALESCE(s.numeric_scale, 0) || ')'
        ELSE s.data_type
    END as stores_full_type,
    si.data_type as stores_import_new_data_type,
    CASE 
        WHEN si.character_maximum_length IS NOT NULL THEN si.data_type || '(' || si.character_maximum_length || ')'
        WHEN si.numeric_precision IS NOT NULL THEN si.data_type || '(' || si.numeric_precision || ',' || COALESCE(si.numeric_scale, 0) || ')'
        ELSE si.data_type
    END as stores_import_new_full_type,
    CASE 
        WHEN s.data_type != si.data_type THEN '❌ Type differs'
        WHEN s.character_maximum_length != si.character_maximum_length THEN '⚠️ Length differs'
        WHEN s.numeric_precision != si.numeric_precision OR s.numeric_scale != si.numeric_scale THEN '⚠️ Precision/scale differs'
        ELSE '✅ Types match'
    END as type_comparison
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
ORDER BY s.ordinal_position;

-- Comparison 4: Columns only in stores (missing in stores_import_new)
SELECT 
    'MISSING IN stores_import_new' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
  AND column_name NOT IN (
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'stores_import_new'
  )
ORDER BY ordinal_position;

-- Comparison 5: Columns only in stores_import_new (extra columns)
SELECT 
    'EXTRA IN stores_import_new' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores_import_new'
  AND column_name NOT IN (
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'stores'
  )
ORDER BY ordinal_position;

-- Comparison 6: Default value differences
SELECT 
    'DEFAULT VALUE DIFFERENCES' as info,
    s.column_name,
    s.column_default as stores_default,
    si.column_default as stores_import_new_default,
    CASE 
        WHEN COALESCE(s.column_default, '') != COALESCE(si.column_default, '') THEN '❌ Defaults differ'
        ELSE '✅ Defaults match'
    END as status
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE COALESCE(s.column_default, '') != COALESCE(si.column_default, '')
ORDER BY s.column_name;

-- Comparison 7: Nullable differences
SELECT 
    'NULLABLE DIFFERENCES' as info,
    s.column_name,
    s.is_nullable as stores_nullable,
    si.is_nullable as stores_import_new_nullable,
    CASE 
        WHEN s.is_nullable != si.is_nullable THEN '❌ Nullable differs'
        ELSE '✅ Nullable matches'
    END as status
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.is_nullable != si.is_nullable
ORDER BY s.column_name;

-- Comparison 8: Position differences (columns in different order)
SELECT 
    'POSITION DIFFERENCES' as info,
    s.column_name,
    s.ordinal_position as stores_position,
    si.ordinal_position as stores_import_new_position,
    CASE 
        WHEN s.ordinal_position != si.ordinal_position THEN '⚠️ Position differs'
        ELSE '✅ Position matches'
    END as status
FROM information_schema.columns s
INNER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import_new'
WHERE s.ordinal_position != si.ordinal_position
ORDER BY s.ordinal_position;

