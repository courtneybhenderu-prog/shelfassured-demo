-- ========================================
-- Create stores_backup table as a copy of stores table
-- This includes both structure and data
-- ========================================

-- Step 1: Drop stores_backup if it already exists (optional - comment out if you want to keep existing)
DROP TABLE IF EXISTS stores_backup CASCADE;

-- Step 2: Create stores_backup as exact copy of stores (structure + data)
CREATE TABLE stores_backup AS 
SELECT * FROM stores;

-- Step 3: Verify the backup was created successfully
SELECT 
    'BACKUP VERIFICATION' as info,
    (SELECT COUNT(*) FROM stores) as stores_row_count,
    (SELECT COUNT(*) FROM stores_backup) as stores_backup_row_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM stores) = (SELECT COUNT(*) FROM stores_backup)
        THEN '✅ Row counts match'
        ELSE '❌ Row counts differ'
    END as row_count_status;

-- Step 4: Verify column structure matches
SELECT 
    'COLUMN STRUCTURE VERIFICATION' as info,
    s.column_name,
    s.ordinal_position as stores_position,
    s.data_type as stores_type,
    sb.ordinal_position as backup_position,
    sb.data_type as backup_type,
    CASE 
        WHEN sb.column_name IS NULL THEN '❌ Missing in backup'
        WHEN s.column_name != sb.column_name THEN '❌ Name mismatch'
        WHEN s.data_type != sb.data_type THEN '⚠️ Type mismatch'
        WHEN s.ordinal_position != sb.ordinal_position THEN '⚠️ Position mismatch'
        ELSE '✅ Match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns sb 
    ON s.column_name = sb.column_name
    AND s.table_name = 'stores' 
    AND sb.table_name = 'stores_backup'
WHERE s.table_name = 'stores' OR sb.table_name = 'stores_backup'
ORDER BY COALESCE(s.ordinal_position, sb.ordinal_position);

-- Step 5: Show summary
SELECT 
    'BACKUP SUMMARY' as info,
    'stores_backup table created successfully' as message,
    (SELECT COUNT(*) FROM stores_backup) as total_rows_backed_up,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'stores_backup') as total_columns;

-- Step 6: Sample data verification (compare first few rows)
SELECT 
    'SAMPLE DATA: stores' as source,
    id,
    "STORE",
    banner,
    city,
    state
FROM stores
ORDER BY created_at DESC
LIMIT 5;

SELECT 
    'SAMPLE DATA: stores_backup' as source,
    id,
    "STORE",
    banner,
    city,
    state
FROM stores_backup
ORDER BY created_at DESC
LIMIT 5;

