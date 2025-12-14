-- ========================================
-- Fix the final 4 errors:
-- 1. banner_norm name mismatch (stores_import has match_key at position 45)
-- 2. address_norm missing
-- 3. state_norm missing  
-- 4. zip5_norm missing
-- 5. match_key missing (after fixing banner_norm)
-- ========================================

-- Step 1: Fix the name mismatch at position 45
-- If stores_import has 'match_key' where 'banner_norm' should be, rename it
DO $$
BEGIN
    -- Check if match_key exists and banner_norm doesn't
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' 
          AND column_name = 'match_key'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' 
          AND column_name = 'banner_norm'
    ) THEN
        -- Rename match_key to banner_norm
        ALTER TABLE stores_import RENAME COLUMN match_key TO banner_norm;
        RAISE NOTICE 'Renamed match_key to banner_norm';
    END IF;
END $$;

-- Step 2: Add missing columns in the correct order
-- Add address_norm (should be at position 46)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'address_norm'
    ) THEN
        ALTER TABLE stores_import ADD COLUMN address_norm TEXT;
        RAISE NOTICE 'Added address_norm';
    END IF;
END $$;

-- Add state_norm (should be at position 47)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'state_norm'
    ) THEN
        ALTER TABLE stores_import ADD COLUMN state_norm TEXT;
        RAISE NOTICE 'Added state_norm';
    END IF;
END $$;

-- Add zip5_norm (should be at position 48)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'zip5_norm'
    ) THEN
        ALTER TABLE stores_import ADD COLUMN zip5_norm TEXT;
        RAISE NOTICE 'Added zip5_norm';
    END IF;
END $$;

-- Add match_key (should be at position 49, after banner_norm was renamed)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'stores_import' AND column_name = 'match_key'
    ) THEN
        ALTER TABLE stores_import ADD COLUMN match_key TEXT;
        RAISE NOTICE 'Added match_key';
    END IF;
END $$;

-- Step 3: Verify all columns now exist
SELECT 
    s.column_name as stores_column,
    s.ordinal_position as stores_pos,
    si.column_name as stores_import_column,
    si.ordinal_position as stores_import_pos,
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

-- Step 4: Final check - verify these specific columns exist
SELECT 
    'FINAL CHECK' as info,
    column_name,
    ordinal_position,
    '✅ EXISTS' as status
FROM information_schema.columns
WHERE table_name = 'stores_import'
  AND column_name IN ('banner_norm', 'address_norm', 'state_norm', 'zip5_norm', 'match_key')
ORDER BY ordinal_position;

