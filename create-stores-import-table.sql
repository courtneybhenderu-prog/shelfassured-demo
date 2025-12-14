-- ========================================
-- Create stores_import table with proper structure
-- Run this BEFORE importing your Excel/CSV file
-- ========================================

-- Create the table with all columns and a primary key
CREATE TABLE IF NOT EXISTS stores_import (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CHAIN" TEXT,
    "DIVISION" TEXT,
    "BANNER" TEXT,
    "STORE LOCATION NAME" TEXT,
    "STORE" TEXT,
    "Store #" TEXT,
    "ADDRESS" TEXT,
    "CITY" TEXT,
    "STATE" TEXT,
    "ZIP" TEXT,
    "METRO" TEXT,
    "PHONE" TEXT,
    -- Normalized columns (will be populated by diagnostics script)
    banner_norm TEXT,
    address_norm TEXT,
    city_norm TEXT,
    state_norm TEXT,
    zip5 TEXT,
    match_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add comment
COMMENT ON TABLE stores_import IS 'Temporary table for store reconciliation import. Can be dropped after reconciliation is complete.';

-- Verify table creation
SELECT 
    '✅ stores_import table created successfully' as status,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'stores_import';

