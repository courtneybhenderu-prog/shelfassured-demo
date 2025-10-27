-- Convert existing text columns to generated columns for zip5 and state_zip
-- zip5 and state_zip already exist as regular text columns, need to convert them

-- Step 1: Drop existing columns
ALTER TABLE stores DROP COLUMN IF EXISTS zip5;
ALTER TABLE stores DROP COLUMN IF EXISTS state_zip;

-- Step 2: Add as generated columns
ALTER TABLE stores 
ADD COLUMN zip5 TEXT GENERATED ALWAYS AS (
  SUBSTRING(REGEXP_REPLACE(zip_code, '\D', '', 'g') FROM 1 FOR 5)
) STORED;

ALTER TABLE stores 
ADD COLUMN state_zip TEXT GENERATED ALWAYS AS (
  state || ' ' || zip_code
) STORED;

-- Verify columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name='stores' 
  AND column_name IN ('banner_id', 'status', 'zip5', 'state_zip')
ORDER BY column_name;

