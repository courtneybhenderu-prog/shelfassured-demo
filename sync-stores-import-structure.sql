-- ========================================
-- Sync stores_import table structure to match stores table
-- ========================================

-- Step 1: Check current structure of both tables
SELECT 
    'STORES TABLE COLUMNS' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

SELECT 
    'STORES_IMPORT TABLE COLUMNS (BEFORE)' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

-- Step 2: Clear all data from stores_import
TRUNCATE TABLE stores_import;

-- Step 3: Add columns from stores table that don't exist in stores_import
-- (Only add columns that make sense for import - skip generated columns and internal IDs)

-- Add id column (if importing with IDs, otherwise skip)
-- ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS id UUID;

-- Add columns that exist in stores but not in stores_import
-- Note: Adjust these based on what columns stores_import currently has

-- Core display columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS "STORE" TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS banner TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS store_chain TEXT;

-- Location columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS zip_code TEXT;

-- Metro columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS metro TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS "METRO" TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS metro_norm TEXT;

-- Status columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Timestamp columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Reconciliation columns (for matching)
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS banner_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS address_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS city_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS state_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS zip5_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS match_key TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS store_number VARCHAR(50);

-- Note: zip5 and state_zip are GENERATED columns in stores table
-- They cannot be added to stores_import (generated columns are table-specific)
-- They will be computed when data is inserted into stores table

-- Step 4: Verify final structure
SELECT 
    'STORES_IMPORT TABLE COLUMNS (AFTER)' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

-- Step 5: Compare structures
SELECT 
    'COLUMN COMPARISON' as info,
    s.column_name as stores_column,
    si.column_name as stores_import_column,
    CASE 
        WHEN si.column_name IS NULL THEN 'MISSING IN IMPORT'
        WHEN s.column_name IS NULL THEN 'EXTRA IN IMPORT'
        ELSE 'MATCH'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name 
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY 
    CASE 
        WHEN si.column_name IS NULL THEN 1
        WHEN s.column_name IS NULL THEN 2
        ELSE 3
    END,
    COALESCE(s.column_name, si.column_name);

