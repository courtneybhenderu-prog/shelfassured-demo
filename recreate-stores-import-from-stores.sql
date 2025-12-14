-- ========================================
-- Recreate stores_import to EXACTLY match stores table structure
-- This script explicitly lists all columns from stores
-- ========================================

-- Step 1: Drop existing stores_import completely
DROP TABLE IF EXISTS stores_import CASCADE;

-- Step 2: Get the exact column definition from stores and create stores_import
-- First, let's see what stores actually has
SELECT 
    'STORES ACTUAL STRUCTURE' as info,
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

-- Step 3: Create stores_import with EXACT same columns as stores
-- Based on the stores table structure, create matching table
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
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    banner_norm TEXT,
    address_norm TEXT,
    city_norm TEXT,
    state_norm TEXT,
    zip5_norm TEXT,
    match_key TEXT,
    store_number VARCHAR(50),
    phone TEXT,
    zip5 TEXT GENERATED ALWAYS AS (LEFT(zip_code, 5)) STORED,
    state_zip TEXT GENERATED ALWAYS AS (state || '-' || zip5) STORED
);

-- Step 4: Verify they match
SELECT 
    s.column_name as stores_column,
    si.column_name as stores_import_column,
    CASE 
        WHEN si.column_name IS NULL THEN '❌ Missing in stores_import'
        WHEN s.column_name IS NULL THEN '⚠️ Extra in stores_import'
        WHEN s.column_name != si.column_name THEN '❌ Name mismatch'
        ELSE '✅ Match'
    END as status
FROM information_schema.columns s
FULL OUTER JOIN information_schema.columns si 
    ON s.column_name = si.column_name
    AND s.table_name = 'stores' 
    AND si.table_name = 'stores_import'
WHERE s.table_name = 'stores' OR si.table_name = 'stores_import'
ORDER BY COALESCE(s.ordinal_position, si.ordinal_position);

