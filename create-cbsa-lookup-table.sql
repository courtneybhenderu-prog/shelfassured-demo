-- ========================================
-- Create CBSA (Metro Statistical Area) Lookup Table
-- Import your "CBSA LIST" tab data here
-- ========================================

-- Create the CBSA lookup table
CREATE TABLE IF NOT EXISTS cbsa_lookup (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    zip_code TEXT NOT NULL,
    state TEXT,
    msa_number TEXT,
    county_number TEXT,
    msa_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_cbsa_lookup_zip ON cbsa_lookup(zip_code);
CREATE INDEX IF NOT EXISTS idx_cbsa_lookup_state ON cbsa_lookup(state);

-- Add comment
COMMENT ON TABLE cbsa_lookup IS 'CBSA (Metro Statistical Area) lookup table for ZIP code to MSA mapping';

-- Verify table creation
SELECT 
    '✅ cbsa_lookup table created' as status,
    COUNT(*) as existing_rows
FROM cbsa_lookup;

-- ========================================
-- After importing your CBSA LIST tab:
-- 1. Import the "CBSA LIST" tab to this table
-- 2. Map columns: ZIP CODE → zip_code, STATE → state, MSA No. → msa_number, 
--    County No. → county_number, MSA Name → msa_name
-- 3. Then run the store reconciliation scripts which will JOIN to this table
-- ========================================

