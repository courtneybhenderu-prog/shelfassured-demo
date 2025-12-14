-- ========================================
-- Recreate stores_import to match stores table EXACTLY
-- Same column names, same data types, same structure
-- ========================================

-- Step 1: Clear and drop existing stores_import
TRUNCATE TABLE IF EXISTS stores_import;
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Create stores_import with EXACT same structure as stores
-- This matches the stores table column-for-column
CREATE TABLE stores_import (
    id UUID,
    "STORE" TEXT,
    name TEXT,
    banner TEXT,
    store_chain TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    metro TEXT,
    "METRO" TEXT,
    metro_norm TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    banner_norm TEXT,
    address_norm TEXT,
    city_norm TEXT,
    state_norm TEXT,
    zip5_norm TEXT,
    match_key TEXT,
    store_number VARCHAR(50),
    zip5 TEXT GENERATED ALWAYS AS (LEFT(zip_code, 5)) STORED,
    state_zip TEXT GENERATED ALWAYS AS (state || '-' || zip5) STORED
);

-- Step 3: Verify the structures match
SELECT 
    'COLUMN COMPARISON' as info,
    s.column_name as stores_column,
    s.data_type as stores_type,
    si.column_name as stores_import_column,
    si.data_type as stores_import_type,
    CASE 
        WHEN si.column_name IS NULL THEN 'MISSING IN IMPORT'
        WHEN s.column_name IS NULL THEN 'EXTRA IN IMPORT'
        WHEN s.data_type != si.data_type THEN 'TYPE MISMATCH'
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
        WHEN s.data_type != si.data_type THEN 3
        ELSE 4
    END,
    COALESCE(s.column_name, si.column_name);

-- Step 4: Show both structures side by side
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

