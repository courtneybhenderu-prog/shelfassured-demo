-- ========================================
-- Check dependencies before deleting columns
-- ========================================

-- 1. Check all columns in stores table
SELECT 
    'ALL COLUMNS IN STORES TABLE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_default LIKE 'GENERATED%' THEN 'GENERATED COLUMN'
        WHEN column_name LIKE '%_norm' OR column_name = 'match_key' OR column_name = 'store_number' THEN 'RECONCILIATION COLUMN'
        WHEN column_name IN ('id', 'STORE', 'name', 'address', 'city', 'state', 'zip_code', 'metro', 'METRO', 'metro_norm', 'is_active', 'banner', 'store_chain', 'created_at', 'updated_at') THEN 'USED BY APP'
        ELSE 'UNKNOWN'
    END as column_category
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- 2. Check indexes on stores table (might reference columns)
SELECT 
    'INDEXES ON STORES TABLE' as info,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'stores'
ORDER BY indexname;

-- 3. Check foreign key constraints (other tables referencing stores)
SELECT 
    'FOREIGN KEYS REFERENCING STORES' as info,
    tc.table_name as referencing_table,
    kcu.column_name as referencing_column,
    ccu.column_name as referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'stores'
ORDER BY tc.table_name, kcu.column_name;

-- 4. Check if any views reference stores columns
SELECT 
    'VIEWS REFERENCING STORES' as info,
    table_name as view_name,
    view_definition
FROM information_schema.views
WHERE view_definition LIKE '%stores%'
  AND table_schema = 'public';

-- 5. Check generated columns and their dependencies
SELECT 
    'GENERATED COLUMNS' as info,
    column_name,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores'
  AND column_default LIKE 'GENERATED%';

