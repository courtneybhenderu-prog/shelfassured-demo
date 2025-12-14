-- ========================================
-- Simple version: Clear stores_import and match stores structure
-- ========================================

-- Step 1: Clear all data
TRUNCATE TABLE stores_import;

-- Step 2: Drop and recreate stores_import to match stores structure exactly
-- (This is the cleanest approach if you don't need to preserve the table)

-- First, let's see what we're working with
DO $$
BEGIN
    -- Drop the table if it exists
    DROP TABLE IF EXISTS stores_import CASCADE;
    
    -- Recreate it matching stores table structure
    CREATE TABLE stores_import (
        -- Excel import columns (keep original column names from Excel for import mapping)
        "BANNER" TEXT,
        "CHAIN" TEXT,
        "ADDRESS" TEXT,
        "CITY" TEXT,
        "STATE" TEXT,
        "ZIP" TEXT,
        "METRO" TEXT,
        "PHONE" TEXT,
        "Store #" TEXT,
        
        -- Matching stores table columns (for data after processing)
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
        -- Note: "METRO" (uppercase) already defined above in Excel columns
        metro_norm TEXT,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        
        -- Reconciliation columns
        banner_norm TEXT,
        address_norm TEXT,
        city_norm TEXT,
        state_norm TEXT,
        zip5_norm TEXT,
        match_key TEXT,
        store_number VARCHAR(50)
        
        -- Note: zip5 and state_zip are GENERATED columns in stores
        -- They cannot exist in stores_import (generated columns are computed)
    );
    
    RAISE NOTICE 'Table stores_import recreated to match stores structure';
END $$;

-- Step 3: Verify structure
SELECT 
    'FINAL STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'stores_import'
ORDER BY ordinal_position;

